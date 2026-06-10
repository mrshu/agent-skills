#!/usr/bin/env bash
# run-reviewer.sh — dispatch wrapper for a single review-anvil reviewer
# subprocess (claude -p, codex exec, ...).
#
# Solves the silent-hang failure mode: a reviewer whose stdout is
# redirected to a file gives the orchestrator no signal to distinguish
# "still thinking" (claude -p text mode prints nothing until the final
# answer) from "hung" or "exited with empty output". The wrapper
# enforces a hard wall-clock timeout, captures the exit status, and
# classifies empty output as an explicit failure instead of a
# zero-byte file the orchestrator waits on forever.
#
# Usage:
#   run-reviewer.sh <out_file> <timeout_seconds> -- <command> [args...]
#
# stdin is inherited by <command> — pipe/redirect the reviewer prompt in:
#   run-reviewer.sh out.md 600 -- claude -p --max-turns 100 ... < prompt.txt
#
# <command>'s stdout goes to <out_file>, stderr to <out_file>.err
# (kept on every outcome so failures are diagnosable).
#
# Prints KEY=VALUE lines on stdout and exits accordingly:
#   STATUS=ok       exit 0    command exited 0 and <out_file> is non-empty
#   STATUS=empty    exit 3    command exited 0 but <out_file> is empty
#   STATUS=failed   exit 1    command exited non-zero (EXIT_CODE=<n> printed)
#   STATUS=timeout  exit 124  hard timeout hit; command killed (TERM, then KILL)
#
# The orchestrator must treat any STATUS other than ok as a failed
# reviewer per the engine's failure-handling rules, with the tail of
# <out_file>.err as the reason.

set -u

die() { printf 'run-reviewer: %s\n' "$*" >&2; exit 2; }

out="${1:-}"; secs="${2:-}"; sep="${3:-}"
[[ -n "$out" && -n "$secs" && "$sep" == "--" ]] \
    || die 'usage: run-reviewer.sh <out_file> <timeout_seconds> -- <command> [args...]'
shift 3
[[ $# -ge 1 ]] || die 'no command given after --'
[[ "$secs" =~ ^[0-9]+$ ]] || die "timeout must be an integer number of seconds, got '$secs'"

err="${out}.err"
stamp="${out}.timedout"
mkdir -p "$(dirname "$out")"
rm -f "$stamp"

# `<&0` re-binds the background job's stdin to the wrapper's: without
# it, non-interactive bash gives async commands /dev/null on fd 0 and
# the piped-in reviewer prompt is silently lost.
"$@" <&0 > "$out" 2> "$err" &
cmd_pid=$!

# Portable watchdog (macOS ships no GNU `timeout`): TERM at the
# deadline, KILL 30s later if the reviewer ignores TERM. The stamp file
# records that the watchdog fired, distinguishing timeout kills from
# the command's own non-zero exits.
(
    sleep "$secs"
    touch "$stamp"
    kill -TERM "$cmd_pid" 2>/dev/null
    sleep 30
    kill -KILL "$cmd_pid" 2>/dev/null
) &
watchdog_pid=$!

wait "$cmd_pid"
status=$?
kill "$watchdog_pid" 2>/dev/null
wait "$watchdog_pid" 2>/dev/null

# Classification order matters: a command that exits 0 with non-empty
# output right at the deadline (stamp present, status 0) still counts
# as ok — the work completed; the kill raced the natural exit.
if [[ -e "$stamp" && "$status" -ne 0 ]]; then
    rm -f "$stamp"
    printf 'STATUS=timeout\n'
    exit 124
fi
rm -f "$stamp"
if [[ "$status" -ne 0 ]]; then
    printf 'EXIT_CODE=%s\n' "$status"
    printf 'STATUS=failed\n'
    exit 1
fi
if [[ ! -s "$out" ]]; then
    printf 'STATUS=empty\n'
    exit 3
fi
printf 'STATUS=ok\n'
