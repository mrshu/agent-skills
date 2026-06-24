#!/usr/bin/env bash
# Deterministic fixtures for the review-anvil reproduction policy.

set -euo pipefail

fail() {
    printf 'test-reproduction-policy: %s\n' "$*" >&2
    exit 1
}

block_external_tools() {
    local tool
    BLOCK_EXTERNAL_TOOLS_DIR="$(mktemp -d)"
    trap 'rm -rf "$BLOCK_EXTERNAL_TOOLS_DIR"' EXIT

    for tool in codex claude gh; do
        {
            printf '#!/usr/bin/env bash\n'
            printf 'printf "unexpected external tool invocation: %s\\n" "$0" >&2\n'
            printf 'exit 97\n'
        } >"$BLOCK_EXTERNAL_TOOLS_DIR/$tool"
        chmod +x "$BLOCK_EXTERNAL_TOOLS_DIR/$tool"
    done

    PATH="$BLOCK_EXTERNAL_TOOLS_DIR:$PATH"
    export PATH
}

severity_rank() {
    case "$1" in
        nit) printf '0' ;;
        low) printf '1' ;;
        medium) printf '2' ;;
        high) printf '3' ;;
        critical) printf '4' ;;
        *) fail "unknown severity: $1" ;;
    esac
}

at_least() {
    local sev="$1" min="$2"
    [[ "$(severity_rank "$sev")" -ge "$(severity_rank "$min")" ]]
}

has_flag() {
    local flags=",$1," flag="$2"
    [[ "$flags" == *",$flag,"* ]]
}

should_reproduce() {
    local severity="$1" reporters="$2" flags="$3"

    if has_flag "$flags" dismissed; then
        printf 'no'
        return
    fi

    if has_flag "$flags" historical || has_flag "$flags" generated || \
       has_flag "$flags" vendored; then
        printf 'no'
        return
    fi

    if at_least "$severity" medium && [[ "$reporters" == "1" ]]; then
        printf 'yes'
        return
    fi

    if (has_flag "$flags" deletion || has_flag "$flags" dead || \
        has_flag "$flags" unused || has_flag "$flags" redundant || \
        has_flag "$flags" simplification) && \
       (at_least "$severity" medium || has_flag "$flags" runtime_cut || \
        has_flag "$flags" public_surface); then
        printf 'yes'
        return
    fi

    if at_least "$severity" high && has_flag "$flags" inferred; then
        printf 'yes'
        return
    fi

    if has_flag "$flags" uncertain; then
        printf 'yes'
        return
    fi

    printf 'no'
}

effect_without_reproduction() {
    local severity="$1" candidate="$2" flags="$3"

    if has_flag "$flags" dismissed; then
        printf 'deferred:previously-dismissed'
    elif has_flag "$flags" historical || has_flag "$flags" generated || \
         has_flag "$flags" vendored; then
        printf 'dropped:out-of-scope'
    elif [[ "$candidate" == "yes" ]]; then
        printf 'deferred:reproduction-disabled'
    elif at_least "$severity" medium; then
        printf 'actionable'
    else
        printf 'suggestion'
    fi
}

effect_with_reproduction() {
    local severity="$1" candidate="$2" flags="$3" verdict="$4" final_severity="$5"

    if has_flag "$flags" dismissed; then
        printf 'deferred:previously-dismissed'
        return
    fi

    if has_flag "$flags" historical || has_flag "$flags" generated || \
       has_flag "$flags" vendored; then
        printf 'dropped:out-of-scope'
        return
    fi

    if [[ "$candidate" == "no" ]]; then
        if at_least "$severity" medium; then
            printf 'actionable'
        else
            printf 'suggestion'
        fi
        return
    fi

    case "$verdict" in
        confirmed)
            if at_least "$final_severity" medium; then
                printf 'actionable'
            else
                printf 'suggestion'
            fi
            ;;
        narrowed)
            if at_least "$final_severity" medium; then
                printf 'actionable:narrowed'
            else
                printf 'suggestion'
            fi
            ;;
        downgraded)
            if at_least "$final_severity" medium; then
                printf 'actionable'
            else
                printf 'suggestion'
            fi
            ;;
        refuted)
            printf 'dropped'
            ;;
        unclear)
            printf 'deferred:failed-reproduction'
            ;;
        verifier_failure)
            printf 'deferred:verifier-unavailable'
            ;;
        none)
            fail "candidate has no reproduction verdict"
            ;;
        *)
            fail "unknown verdict: $verdict"
            ;;
    esac
}

run_case() {
    local id="$1" severity="$2" reporters="$3" flags="$4" verdict="$5"
    local final_severity="$6" want_candidate="$7" want_auto="$8" want_off="$9"
    local candidate auto_effect off_effect

    candidate="$(should_reproduce "$severity" "$reporters" "$flags")"
    [[ "$candidate" == "$want_candidate" ]] || \
        fail "$id: candidate=$candidate, want $want_candidate"

    auto_effect="$(effect_with_reproduction "$severity" "$candidate" "$flags" "$verdict" "$final_severity")"
    [[ "$auto_effect" == "$want_auto" ]] || \
        fail "$id: auto effect=$auto_effect, want $want_auto"

    off_effect="$(effect_without_reproduction "$severity" "$candidate" "$flags")"
    [[ "$off_effect" == "$want_off" ]] || \
        fail "$id: off effect=$off_effect, want $want_off"

    printf 'ok %-30s candidate=%-3s auto=%-32s off=%s\n' \
        "$id" "$candidate" "$auto_effect" "$off_effect"
}

main() {
    block_external_tools

    # id|severity|reporters|flags|verdict|final_severity|candidate|auto_effect|off_effect
    while IFS='|' read -r id severity reporters flags verdict final_severity want_candidate want_auto want_off; do
        [[ -n "$id" && "$id" != \#* ]] || continue
        run_case "$id" "$severity" "$reporters" "$flags" "$verdict" \
            "$final_severity" "$want_candidate" "$want_auto" "$want_off"
    done <<'CASES'
single-reviewer-false-positive|medium|1|none|refuted|medium|yes|dropped|deferred:reproduction-disabled
live-doc-drift|medium|1|none|narrowed|medium|yes|actionable:narrowed|deferred:reproduction-disabled
historical-doc-false-positive|medium|1|historical|none|medium|no|dropped:out-of-scope|dropped:out-of-scope
dependency-doc-drift|medium|1|none|confirmed|medium|yes|actionable|deferred:reproduction-disabled
delete-needed-compat-shim|medium|2|deletion|refuted|medium|yes|dropped|deferred:reproduction-disabled
delete-confirmed-dead-code|medium|2|deletion|confirmed|medium|yes|actionable|deferred:reproduction-disabled
downgrade-to-low|medium|1|none|downgraded|low|yes|suggestion|deferred:reproduction-disabled
unclear-runtime-contract|high|1|inferred,uncertain|unclear|high|yes|deferred:failed-reproduction|deferred:reproduction-disabled
consensus-medium-non-risk|medium|2|none|none|medium|no|actionable|actionable
low-nit-style|low|1|none|none|low|no|suggestion|suggestion
low-simplification|low|1|simplification|none|low|no|suggestion|suggestion
previously-dismissed|high|1|dismissed|none|high|no|deferred:previously-dismissed|deferred:previously-dismissed
verifier-unavailable|high|1|inferred|verifier_failure|high|yes|deferred:verifier-unavailable|deferred:reproduction-disabled
CASES

    printf 'test-reproduction-policy: all reproduction policy examples passed\n'
}

main "$@"
