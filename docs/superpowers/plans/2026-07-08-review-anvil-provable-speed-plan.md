# review-anvil provable-speed plan

Status: research draft for adversarial review

## 1. Objective and decision

Make review-anvil materially faster while preserving its existing review,
reproduction, verification, approval, and failure-conservatism contracts.

The plan separates two claims that must never be conflated:

1. **Assurance-preserving engine acceleration.** Remove unnecessary dependency
   edges, bound failure waste, and reuse mechanically valid work while keeping
   the same reviewer evidence and decision gates. These changes belong in the
   existing engine and should become automatic after validation.
2. **Reduced-depth bounded review.** Fewer reviewers or rounds may be useful as
   an explicit service tier, but this changes the evidence budget. It requires
   separate non-inferiority evidence and must not be presented as the primary
   fix for current latency.

Product decision: improve the existing engine first. Do not add a slash
command or a fifth skill during the acceleration work. Reconsider a thin,
shared-engine bounded-review surface only if the post-optimization evidence and
user research satisfy the go/no-go test in section 12.

Execution uses two lanes:

- **Immediate operational lane:** land fresh-base/head-drift protection,
  bounded fast-failure retry, attempt timing, and descendant cleanup with
  focused deterministic tests. These remove known waste and do not wait for the
  semantic corpus or structural scheduler.
- **Proof-grade structural lane:** build the binding adapter, enforced
  isolation, controller state machine, hidden evaluation, and causal analysis
  needed before promoting baseline/gate overlap, super-waves, changed prompts,
  chunked reproduction, or reduced signal.

The immediate lane may claim only the measured failure modes it fixes. It does
not borrow the structural lane's registered non-inferiority or population-wide
speed claim.

## 2. What "provably faster" means

A universal proof that every real run is faster is impossible. Controller
startup, hashing, worktree creation, provider contention, retries, cold caches,
and stochastic model latency can make an individual run slower.

The release claim must instead be an intersection of three narrower results:

1. **Mechanical path proof.** For deterministic workloads whose independent
   task durations are held fixed, the candidate dependency graph has a critical
   path no longer than the legacy graph. Each feature uses an explicit
   equivalence relation: overlap-only features require identical normalized
   accepted evidence and decisions; retry and freshness features use outcome
   oracles because they intentionally change the available evidence or target.
2. **Semantic non-inferiority.** On held-out clean/mutant fixtures and paired
   live runs, the candidate meets pre-registered recall, precision, completion,
   reproduction, fix-safety, convergence, and approval thresholds.
3. **Observed end-to-end superiority.** Paired runs show a statistically
   credible reduction in restricted time to a contract-valid result, counting
   failures, partial runs, candidate-only eligibility probes, and fallbacks
   against a pre-registered horizon rather than treating fast failure as
   success.

Reserve "proved" for the deterministic statement: "Under fixed task durations
and registered eligibility conditions, the validated candidate DAG has a
non-increasing critical path." Live claims say: "For the registered population,
versions, result contract, and horizon, the candidate's upper one-sided 95%
confidence bound met the registered restricted-time superiority margin. No
quality endpoint exceeded its registered non-inferiority or safety boundary in
the locked evaluation and live trial." This does not establish equal quality or
zero future risk outside the evaluated population.

## 3. Current evidence and gaps

Wave 1 from the existing latency audit is already present in commit `f94617d`:
host-timeout discipline, parallel/deadlined synthesis agents, small-diff
reviewer timeout reduction, a smaller adaptive budget, the new-finding
continuation gate, and codex stdin isolation.

The remaining current path is still predominantly serial:

```text
baseline
  -> reviewer wave 1 -> synthesis/reproduction -> fixes -> gate 1
  -> reviewer wave 2 -> synthesis/reproduction -> fixes -> gate 2
  -> reviewer wave 3 -> synthesis/reproduction -> fixes -> gate 3
  -> report -> push/post
```

The repository has useful component tests, but no executable end-to-end engine,
versioned timing schema, deterministic scheduler benchmark, frozen trace corpus,
or semantic quality corpus. `test-reproduction-policy.sh` reimplements policy
selection; it does not invoke reviewers or score missed findings.

Baseline checks on 2026-07-08:

| Check | Result | Wall time |
|---|---:|---:|
| reviewer-wrapper fixtures | pass | 1.83 s |
| reproduction-policy fixtures | pass | 0.11 s |
| PR-helper end-to-end fixtures | pass | 8.70 s |

Four independent live architecture reviews dispatched concurrently through the
current wrapper all succeeded. Their individual durations were 150.30 s,
156.30 s, 186.55 s, and 198.51 s. This is not a controlled speed benchmark,
but it corroborates the previously observed 98--213 s healthy-reviewer range
and demonstrates why each serial reviewer-wave barrier is expensive.

A second independent four-reviewer plan wave also succeeded at 124.40 s,
156.28 s, 245.17 s, and 249.36 s. The longer tail reinforces the need to measure
provider/version strata and wave maxima; these eight heterogeneous tasks are
observational evidence only, not a candidate/control effect estimate.

Across those eight shell-dispatched Codex/Claude calls, wrapper stdout contained
only `STATUS=ok` while review prose remained in separate output files until
explicitly opened. This demonstrates basic parent-side output opacity for the
CLI path. It does not establish two-plane tool confinement, secret/FD isolation,
or native-Agent opacity.

A metadata-only scan found nine top-level local Claude sessions whose initial
user prompt named review-anvil. Session-envelope durations ranged from 180.0 s
to 738.2 s, with median 325.7 s and mean 348.0 s. No prompt/code content was
exported. These envelopes are selection-biased and do not identify phases,
retries, completion validity, or subagent time, so they support instrumentation
priority but not a speed effect claim.

A disposable fork/upstream PR topology showed that fetching `origin/main` from
the contributor fork remained stale after the canonical upstream advanced,
while a separately resolved canonical remote matched the true base OID and left
local `main` unchanged. Freshness logic must therefore use PR base-repository
identity plus an exact base object/ref; the current branch's configured remote
is insufficient for fork PRs.

The earlier audit's estimate of 5--15 minutes is a forecast, not proof. The raw
timing corpus behind the mined sessions is not committed, so this plan starts
with instrumentation and replay rather than treating that estimate as an
acceptance result.

Deterministic toy experiments run against the current wrapper during this
planning exercise produced the following fixed-sleep scheduling results:

| Experiment | Control | Candidate/model | Result |
|---|---:|---:|---:|
| 2 s baseline + 3 s reviewer | 5.214 s serial | 3.130 s overlapped | 40.0% faster |
| Three read-only rounds, 3 reviewers each | 3.323 s serial rounds | 1.149 s unbounded super-wave | 65.4% faster |
| 25-candidate proportional verifier | 2.628 s monolithic | 1.135 s, 3 parallel chunks | 56.8% faster |
| Same nine read-only jobs, bounded | 3.323 s round barriers | 2.988 s at cap 3; 2.568 s at cap 4 | 10.1%; 22.7% faster |

These illustrate scheduling behavior under fixed mock durations. The bounded
results show that realistic admission limits can erase most of the headline
super-wave gain. The one-off commands, raw samples, clock/environment manifest,
and disposable fixtures were not retained, so every number in this section is
exploratory non-acceptance evidence. Reproducible deterministic proof begins
only with the committed D01--D15 harness and artifacts specified in section 8.

The same fixture pass confirmed five current hazards:

- `run-reviewer.sh` timed out with exit 124 while a spawned grandchild survived;
- fetching `origin/main` left an existing local `main` stale, confirming that a
  bare local base ref must not be used after fetch;
- a detached Git worktree contained tracked mutation but a simulated external
  resource remained shared;
- the current `mkdir -p` plus artifact write pattern followed a pre-existing
  `.review-anvil`-style directory symlink.
- `run-reviewer.sh` followed an output-file symlink and overwrote its external
  target, confirming that Phase 0 attempt files need exclusive no-follow
  creation rather than ordinary shell redirection.

A retry-budget model recovered full evidence after a 0.1 s fast failure plus a
0.5 s successful attempt in about 0.75 s; two fast failures ended in about
0.38 s; and a fast failure followed by a hang stopped at the original 1 s total
budget. This validates the shared-deadline shape, not the production wrapper.

On this macOS host, Python `start_new_session` plus process-group termination
killed an ordinary grandchild, while a child that called `setsid()` escaped and
survived until explicitly cleaned up. That experimentally supports Phase 0's
cooperative process-group improvement and the stricter kernel-containment
requirement for proof-grade cleanup.

A provider-capacity mock with threshold four completed all nine jobs at local
concurrency three, but an unbounded nine-job launch produced five immediate
capacity failures. This is a model, not provider evidence, yet it demonstrates
why super-wave timeout/failure/quality behavior cannot be inferred from ideal
`max()` arithmetic and why admission caps must be measured.

In a disposable repository, `git diff --textconv` executed a repository-
configured textconv helper, and ordinary `git diff` executed a helper supplied
through `GIT_EXTERNAL_DIFF`. Both wrote harmless external sentinels. Therefore
`Bash(git:*)` is not by itself a proof-grade read-only capability: eligible
adapters must neutralize repository/user/system config, attributes/drivers,
hooks, pagers, filters, relevant environment, and option injection inside the
enforced executor.

A Python `dir_fd`/`O_CREAT|O_EXCL|O_NOFOLLOW` prototype rejected pre-existing
regular files, symlinks, and hardlinks. After the parent path was renamed and
replaced with a symlink, creation through the already-open directory descriptor
landed in the original `0700` directory at mode `0600`, not the attacker path.
This demonstrates a viable secure Phase 0 attempt-file primitive on this macOS
host; other OS/filesystem classes still require capability fixtures.

All three existing harnesses passed from a detached worktree under the normal
environment. Under private `HOME`/`TMPDIR`, the wrapper and reproduction tests
still passed but the PR-helper suite failed its prior-feedback refresh path.
Thus checkout isolation is locally feasible for these scripts, while environment
isolation changes behavior and must be calibrated per command rather than
applied as a universal safety wrapper.

In 100 local no-op invocations, direct shell execution averaged 11.1 ms and the
current wrapper averaged 69.4 ms, about 58.3 ms incremental overhead per attempt.
This is platform-specific microbenchmark data, but it suggests timing/status
instrumentation has room within long LLM calls while warning that repeated
controller/helper processes can dominate tiny fixtures.

Seven detached-worktree lifecycle trials on this host averaged 65.7 ms to add
and 31.4 ms to remove, or 97.0 ms per boundary. Running all three existing
harnesses inside one detached worktree took 12.01 s and passed. This establishes
that Git worktree mechanics themselves are negligible next to the observed
multi-minute reviewer envelopes in this repository; it does not price cold
dependency caches, external services, large repositories, or the stronger
environment/tool confinement required for a binding adapter. Those costs remain
part of the registered per-repository ROI measurement.

Those observations directly justify Phase 0 process cleanup/exact base refs and
the proof-grade confinement/authoritative-artifact requirements. Temporary
fixtures were removed after each experiment.

## 4. Architecture: a small internal attempt supervisor

review-anvil is prose-orchestrated. Prose can request concurrency, but it cannot
mechanically reject stale attempts, establish worktree provenance, or prove
event ordering. Add a trusted internal supervisor for mechanics while retaining
host-model judgment.

### 4.1 Supervisor responsibilities

The supervisor owns:

- run, snapshot, phase, round, reviewer-slot, and attempt identities;
- content hashes for the materialized diff, prompts, candidate sets, commands,
  and outputs;
- atomic phase-result envelopes and append-only timing fragments;
- shell-backend process supervision, deadlines, process-group termination, and
  bounded mechanical retries;
- isolated verification-worktree creation and cleanup;
- primary-worktree ownership, post-fix sealing, gate state, attempt
  invalidation, and exact acceptance checks;
- authoritative report/sidecar storage and terminal artifact hashes (semantic
  report and approval judgment remains with the orchestrator);
- reproduction-chunk fan-out for a host-supplied candidate manifest;
- deterministic event validation and critical-path calculation.

The supervisor does not own:

- natural-language parameter parsing;
- scope, prior-feedback, or root-cause interpretation;
- reviewer-lens content or prompts;
- semantic deduplication and reproduction-candidate selection;
- reproduction/adversarial verdict judgment;
- edits, fix grouping, commits, convergence, approval judgment, or report prose
  content;
- GitHub posting.

### 4.2 Host-native Agent compatibility

A portable local process cannot launch or reliably cancel every host-native
Agent tool. The supervisor therefore emits task descriptors and validates
results; it is not a universal backend launcher.

Suggested verbs:

```text
init
snapshot
plan-round
start-shell-task
record-agent-output
register-fix-set
seal-post-fix-snapshot
start-gate
invalidate-attempt
accept-task
release-for-synthesis
record-final-artifact
seal-report-set
finalize
cleanup
```

Shell backends may be launched directly. A host-native Agent receives the task
descriptor from the orchestrator and submits completed bytes through
`record-agent-output` on stdin. The supervisor writes those bytes itself using
exclusive creation, `fsync`, and atomic rename; it never accepts repository or
host-supplied paths. Correctness comes from `accept-task` rejecting stale or
mismatched output, not from assuming cancellation succeeds.

`register-fix-set` records the intended commits. `seal-post-fix-snapshot`
verifies exact HEAD, ancestry, clean index/worktree, and materialized diff
before creating the gate/reviewer task set. `release-for-synthesis` returns
opaque accepted handles only after required task tokens and gate state satisfy
the transition. In controller mode, SKILL.md must consume only these returned
bytes/handles. Reading raw Agent responses or output files is a fail-closed
conformance violation.

Revalidate exact primary HEAD, index tree, tracked/untracked manifest, and
registered lineage at `release-for-synthesis`, before authorizing edits, at
commit registration, before the final gate, and before push/post. Any
non-cooperating user/IDE/hook/git-process drift invalidates the attempt and
stops or safely restarts; the ownership lock is not treated as enforcement
against outside processes.

Host adapters declare capabilities. Shell adapters can expose exact launch,
deadline, and cancellation events. A native Agent adapter must report a
host-issued `started` event to qualify for queue-aware deadlines; otherwise its
timeout begins at descriptor dispatch and it is ineligible for scheduler claims
that require exact admission timing.

Adapters also declare one of two evidence-delivery classes:

1. **Binding adapter:** the supervisor captures output before the orchestrator
   sees it, and the host receives only an opaque completion token plus accepted
   controller-owned bytes. Use a supervised shell CLI or a host callback/file
   API that does not inject raw Agent prose into model context.
2. **Advisory adapter:** native Agent prose appears directly in orchestrator
   context before validation. Such adapters may run the legacy serial path but
   are ineligible for speculation, stale-output-exclusion claims, and any
   feature where pre-acceptance visibility is unsafe. A prompt cannot repair
   this boundary.

The single-use submission capability/nonce remains inside the trusted adapter;
the model receives only a public task ID. Results and lifecycle events arrive
through an authenticated callback, inherited private descriptor, or equivalent
channel bound to the pinned adapter binary/version and active attempt. Consume
the capability atomically with state validation. Controller-mode finalization
fails when any expected task token is unresolved. Claims are scoped per
validated binding adapter; observed advisory-host compliance is not mechanical
enforcement.

A proof-grade binding adapter uses two planes. The trusted control plane owns
model-provider transport, credentials, task capability, and output capture, and
may reach only the pinned provider. Every model-generated tool subprocess runs
in a separate executor with no credential/callback/state-FD inheritance, no
provider socket, no general network/services, private process/resource
namespaces, and the declared filesystem/tool policy. The adapter parent alone
submits captured bytes after child exit. Test environment/FD dumps, recursive
children, public-ID guessing, replay, forged early completion, credential/
socket inheritance, localhost/DNS/provider endpoint, and service access. A
backend that cannot separate transport and tool execution is advisory/serial.

Target Python 3.9+ stdlib semantics and preflight them explicitly (including
process-group behavior on each supported OS). Resolve `uv run --no-project
python3`, then `python3`, from trusted paths. Absence or failed capability checks
before controller initialization select the existing serial engine; Python is
not a new hard dependency for legacy local review.

### 4.3 Trusted state

Control state must live outside the reviewed repository:

```text
$TMPDIR/review-anvil/<repo-hash>/<run-id>/
  run.json
  events/fragments/
  prompts/
  outputs/
  worktrees/
```

The supervisor must be resolved from the same trusted install roots as the
existing helpers. It accepts argv arrays, not interpolated shell strings.
Canonicalize the state root and git common directory with `realpath`; reject a
state root within the worktree/common directory, symlinks, and existing run
IDs. Create state with mode `0700` and exclusive files. Repository identity
includes canonical common directory and remote identity. Use a primary-worktree
ownership lock and a repo/verification-resource lock across concurrent runs,
not merely within one run.

Trusted resolution validates owner, mode, every symlink-free ancestor, and
content identity, then executes an immutable opened/copied helper rather than a
PATH lookup vulnerable to replacement. Revalidate identity per invocation.
Mechanical tasks use a typed argv schema with absolute pinned executables and a
sanitized environment/cwd. Shell-parsed `verify_cmd`, Git hooks/aliases/pagers/
filters, Python import paths, option-like values, and control characters are
either neutralized and modeled or excluded from proof-grade eligibility.

State transitions use a write-ahead protocol: persist and `fsync` the transition
and parent directory before each external side effect. Startup scans and
quarantines nonterminal runs, rotates the acceptance epoch so pre-crash
capabilities fail, and requires recovery before new work on the same resource.
Descriptor-held OS locks live in a protected global registry keyed by canonical
git-common-directory plus normalized resource set, use fixed acquisition order
and close-on-exec, and refuse filesystems without required lock/durability
semantics. Crash injection covers every persistence boundary.

Non-idempotent effects use intent/result/reconcile records. Commits reconcile by
exact OID/tree/parent/message; push by remote ref OID plus expected lease;
GitHub post/update by run marker and returned comment/review ID; artifact
publication by terminal-manifest hash. Recovery either proves the intended
effect occurred exactly once and records completion or fails closed for manual
intervention—never blindly retries. If this transaction surface is deferred,
keep commit/push/post outside the proof-grade controller and end the structural
claim at validated report finalization.

Ephemeral control state may contain prompts and outputs required during the
run. Exported telemetry is a separate sanitized product containing only hashes,
counts, state transitions, and timings. Define crash cleanup, terminal-state
refusal, opt-in resume retention, and a bounded TTL; never describe ephemeral
control state as telemetry.

Process groups are a cooperative cleanup improvement, not proof-grade
containment: descendants can escape with `setsid`/double-fork. Binding adapters
requiring hard termination must use kernel-backed containment (for example a
cgroup, job object, or supported container/sandbox) and verify empty membership
after kill. Unsupported hosts stay advisory/serial. Test grandchildren,
session escape, double-fork, spawn-at-deadline, TERM-ignore, and PID reuse.

### 4.4 Snapshot and result identity

At minimum, the snapshot identity covers:

```text
repository identity
target kind
base and head object IDs
canonical materialized diff hash
explicit untracked-input manifest when relevant
PR head/base and coalesced-history hashes when relevant
resolved configuration and prompt-template hashes
```

An accepted result must match:

```text
(run_id, phase, round, attempt, snapshot_id,
 backend, reviewer_slot, lens, prompt_hash, output_hash, protocol)
```

The orchestrator consumes only accepted results returned by the supervisor. It
must not glob output files directly. Every controller contract is versioned and
fail-closed: run state, task descriptor, stored result, candidate-chunk
manifest, accepted-output handle, and event envelope. Golden compatibility
fixtures cover supported versions; unknown versions are rejected.

Reports, `.inline.json`, `.approval.json`, and `.followups.json` are
authoritative only inside trusted controller state. Finalization emits an
authenticated terminal manifest binding their hashes to run/config/snapshot,
PR identity/head, decision, and accepted task set. The posting helper accepts
only this manifest, opens artifacts relative to a trusted directory descriptor
without following symlinks, and revalidates every hash immediately before the
external action. Optional worktree copies are non-authoritative exports.

`record-final-artifact` ingests each typed artifact on stdin into controller
storage. `seal-report-set` schema-checks and cross-checks finding IDs, decision,
snapshot, and accepted task set, then revalidates primary/PR state and emits one
single-use terminal-manifest capability for posting.

## 5. Critical-path design

Let `B` be baseline verification, `W_r` reviewer wave `r`, `S_r` synthesis,
`P_r` reproduction, `E_r` edits/commits, `G_r` the post-fix gate, `Q` report
rendering, and `U` external push/post work.

Ignoring small setup costs, the current productive path is:

```text
T_legacy = H + B + sum_r(W_r + S_r + P_r + E_r + G_r) + Q + U
```

The first mechanically eligible candidate changes only baseline scheduling:

```text
T_baseline_candidate = H
  + max(B, W_1)
  + S_1 + P_1 + E_1
  + G_1
  + sum_r=2..R(W_r + S_r + P_r + E_r + G_r)
  + Q + U + O_B
```

Its ideal structural saving is only:

```text
min(B, W_1) - O_B
```

where `O_B` includes adapter migration, supervisor, snapshot, worktree, cache,
and contention overhead. Phase C must pass on that bound without credit from
later features.

The later context-changing gate-overlap candidate has an additional bound:

```text
sum_r=1..R-1(min(G_r, W_r+1)) - O_G
```

and is evaluated independently in Phase D. A combined candidate may sum the
two bounds only after both features have separately passed their own safety,
quality, and net-ROI gates. The worked 6.5-minute combined example below is a
sensitivity illustration for that eventual bundle, never justification for
baseline overlap by itself.

Eligibility is computed from a frozen pre-treatment manifest by one classifier
used for both arms. Candidate-only probes, worktree setup, calibration, and
fallback are charged to candidate intention-to-treat time. Never select the
reported eligible population after observing candidate overhead or success.
Control runs execute the same classifier in shadow mode. Eligibility uses only
pre-assignment certificate/manifest/adapter/mode/verification-class fields; an
eligible candidate remains in that stratum even when its probe fails or it
falls back. Missing manifests are ineligible for the stratum but remain in
all-run intention-to-treat analysis. Deployment reach is eligible assignments
divided by all assignments in the registered population.
Overlap is enabled only when prior development data—not the held-out evaluation
set—shows `O` is smaller than the removed serial work for the declared tier.

### 5.1 Baseline and round-one overlap

Resolve `verify_cmd` before dispatch. Launch the isolated baseline and first
reviewer wave together. Join the baseline before reproduction, deletion
execution checks, or edits consume it.

Fast-path preconditions:

- clean, committed productive snapshot;
- the repository/verify command has a current isolation capability
  certification, keyed by verify command, dependency/configuration manifest,
  environment allowlist, platform, and relevant setup hashes;
- reviewer backend policy mechanically forbids project tests, builds, runtime
  processes, network/service access, and shared mutable caches during overlap;
  a prompt request alone is not eligibility;
- no conflicting engine-owned suite is active;
- the cross-run repo/resource verification lock is held;
- tracked mutation and declared external-state probes pass.

Certification is established outside the held-out trial by paired live and
isolated calibration runs, then expires when any invalidation key changes. Its
cost is measured and reported separately. On an eligible production run, an
isolated green baseline enables overlap without duplicating a live baseline. An
isolated failure invalidates its candidate-baseline token and starts a new,
recorded serial-binding fallback attempt while retaining all verification and
resource locks. Preserve the already-running `W_1` only when its adapter,
prompt bytes, capability hash, snapshot, deadlines, and policy are exactly the
serial-binding contract; otherwise cancel and invalidate it, prove contained
termination, and redispatch before synthesis. Never switch to the advisory
native adapter mid-run. Charge retained, cancelled, and repeated work to the
candidate intention-to-treat endpoint. If the
isolated baseline mutates tracked files, lacks dependencies, or touches
undeclared resources, disable overlap. Never repair the user's worktree to make
the fast path work. Repositories with service/integration suites or unrestricted
Agent reviewers remain serial.

Capability restriction is itself semantic unless control and candidate use the
same resolved tool policy. Record `legacy_capability_hash` and require exact
capability equality for a mechanical overlap claim. A candidate-only reduction
in reviewer tools moves the feature to the context-changing semantic rail. The
isolation certificate is controller-issued, signed/versioned, and stored
outside the repo; repository content may request calibration but cannot assert
success. Its envelope includes repo identity, exact verify argv/executable and
toolchain versions, lockfile/submodule/LFS/sparse hashes, environment allowlist,
platform/container identity, reviewer capability hash, resource-policy and
supervisor versions, calibration results, issue/expiry times, and invalidation
keys. Missing, forged, expired, relocated, or changed fields force serial.

Certification caches compatibility; it never substitutes for production-time
confinement. Both verification and overlapping reviewers run under an enforced
deny-by-default policy with filesystem allowlists, network/service denial,
private process/resource namespaces, private temporary/home directories, and
controlled caches. Define protected issuer key custody, key ID/rotation/
revocation, expiry, monotonic policy/version anti-rollback, and an issuer process
unreachable by repository code. A command that can observe or escape the
enforced policy is ineligible regardless of prior calibration.

Before Phase A implementation, run the adapter-feasibility milestone: enumerate
the actual tool/sandbox/resource policy for every default backend/host and prove
denial fixtures. If no default mixed flow has a binding adapter with legacy-
equivalent capabilities and safe resource isolation, narrow the population or
do not implement automatic baseline overlap. Partial-wave overlap may be
considered only with a new DAG proof; prompt-only restriction is forbidden.

### 5.2 Gate and next requested reviewer-wave overlap

After round `r` fixes are committed, create snapshot-pinned gate and reviewer
checkouts at the same post-fix object ID. Launch `G_r` and `W_r+1` together.
Reviewer output cannot enter synthesis until `G_r` is green and the supervisor
accepts its exact snapshot/attempt identity.

The candidate reviewer prompt must say `verification pending — gate running`;
it must never fabricate `passed`. Because this differs from the legacy prompt,
gate overlap is a context-changing experiment requiring the hidden/live
semantic rail. It is not covered by strict replay artifact-equivalence claims
unless the control prompt contract is separately changed to match first.

A red gate:

1. increments the next-round attempt;
2. invalidates every speculative output immediately;
3. best-effort terminates pending reviewers;
4. performs the existing fix-forward/revert behavior;
5. redispatches only after a new accepted snapshot exists.

Persist transitions
`gate_red -> attempt_invalidated -> children_terminating -> repair_in_progress
-> new_snapshot_sealed`. On controller crash, refuse further acceptance,
preserve primary commits, and require explicit recovery/cleanup. Reviewer
checkout mutation or HEAD/index drift invalidates the task and disables overlap.

Adaptive rounds stay serial because their existence depends on the prior gate
and continuation decision.

### 5.3 One suite at a time

Baseline, deletion execution, and gates acquire a cross-run repository/resource
verification lock. Worktrees isolate repository files, not databases, ports,
daemons, caches, `$HOME`, credentials, or external services. Productive overlap
is therefore restricted to mechanically constrained reviewers and certified
verification commands. Fault fixtures cover attempted reviewer tests/builds,
ports, databases, `$HOME`, caches, daemons, and network/service access.
Repositories or host adapters that cannot enforce these capabilities remain
serial.

Local descriptor locks prove exclusion only within one kernel/registry domain.
The initial proof population requires private namespaced resources in that
domain. A declared shared database, cache, port-forward, SaaS tenant, or remote
service needs a real distributed/exclusive lease visible to every contender;
unleaseable resources are ineligible. Never infer cross-host mutual exclusion
from a local repository lock.

### 5.4 Worked bounds

For a three-round eligible productive run with:

```text
B = 180 s
W1 = W2 = W3 = 200 s
G1 = G2 = 120 s
baseline-overlap overhead O_B = 15 s
gate-overlap overhead O_G = 15 s
```

Phase C baseline overlap alone can remove at most:

```text
min(B, W1) - O_B = 180 - 15 = 165 s (2.75 min)
```

Only after Phase D gate overlap independently passes can the eventual combined
bundle remove:

```text
min(B, W1) + min(G1, W2) + min(G2, W3) - O
= 180 + 120 + 120 - 30
= 390 s (6.5 min)
```

where combined `O = O_B + O_G = 30 s`.

The 6.5-minute figure is a fixed-duration combined-bundle DAG bound, not a
Phase C justification or production forecast. If verification
is absent, `B` and `G` are near zero and productive overlap has little value;
freshness/retry, reproduction/report work, or read-only scheduling dominate.
If confinement/cold-cache overhead reaches the removed serial work, the feature
fails its eligibility/effect gate and remains disabled.

An illustrative bootstrap using only the eight heterogeneous reviewer durations
observed during this planning exercise gives a mean maximum-of-three wave near
220 s. With 30 s of setup overhead and three removable boundaries, the idealized
sensitivity is:

| Baseline/gate duration | Ideal saving |
|---:|---:|
| 60 s | 150 s (2.5 min) |
| 120 s | 330 s (5.5 min) |
| 240 s | about 631 s (10.5 min) |

This table is not evidence for promotion: tasks were heterogeneous, gates were
hypothetical, and provider correlation/contention was ignored. It only shows
why verification duration is the decisive stratification variable. The savings
are arithmetically attainable under the selected durations, but the table makes
no claim about how frequently those durations occur or what production effect
to expect.

## 6. Read-only multi-round super-waves

In `commit_mode=none`, requested rounds intentionally review the same baseline
for independent redundancy. Their normal reviewer calls have no code-state
dependency, so they are candidates for a bounded super-wave.

This feature is not strict semantic equivalence to the current implementation:
serial rounds may observe changing PR history/head state, and a burst changes
provider contention and temporal diversity. Treat it as an experimental
scheduler until live non-inferiority passes.

Required semantics:

- freeze one run-level target, PR metadata, and coalesced-history manifest;
- preserve original `(round, slot, backend, lens)` identities and byte-identical
  prompts apart from dispatch metadata;
- use per-backend admission limits, with timeout starting at actual launch, not
  queue entry;
- isolate reviewer checkouts or mechanically restrict mutating commands;
- process outputs in canonical round/slot order;
- synthesize, deduplicate, assign IDs, reproduce, and adversarially review each
  round under its current boundaries;
- never count matching findings from different rounds as same-round reviewer
  consensus;
- never globally pool reproduction candidates unless a separate semantic test
  proves that change safe;
- define the earliest canonical abort by ascending round; discard later-round
  results after that abort while including all already-dispatched cost and
  failure effects in intention-to-treat metrics;
- retain final PR-head drift and approval safeguards.

With backend capacity `C`, the reviewer portion changes from roughly
`sum_r(W_r)` to the bounded scheduling makespan. With sufficient capacity the
lower bound approaches the slowest call, but no production claim is made until
429, failure, timeout, and quality rates remain within gates. Initially only
normal reviewers enter the super-wave; round synthesis, reproduction, and
adversarial stages remain in canonical legacy order.

Because frozen state and temporal/provider diversity change, move this feature
to the context-changing experiment tier. Define one review-snapshot contract:
either control runs freeze the same run-level head/history, or the candidate is
invalidated/restarted when head/history hashes change before each nominal
round's synthesis. Test both head changes and feedback resolution/comment
changes. Do not promote on deterministic scheduling evidence alone.

The invalidation/restart contract requires a binding adapter: prose from a
discarded advisory Agent result may already have entered orchestrator context.
Advisory adapters may participate only when control and candidate share one
immutable run-level snapshot and make no claim of mechanical stale-output
exclusion. Otherwise disable super-waves for that host.

## 7. Other candidate speedups and proof classes

### 7.1 Fresh base and head-drift checks

In verified PR/improve-PR context, unconditionally fetch the remote PR base into
an isolated remote-tracking namespace (or resolve an exact fetched object ID)
and pin that object in snapshot identity. Resolve the PR's base-repository
identity/OID from GitHub; do not assume the feature branch's configured remote
contains the canonical base, especially for forks. Never update a checked-out
or local base branch. Generic local branch targets without a verified remote
remain local.
Before each improve-PR wave, compare the remote head with the recorded head and
local lineage. Stop before dispatch when the author has pushed a divergent
head. This prevents bogus large diffs and doomed final pushes; it is primarily
tail-waste elimination rather than a healthy-path p50 improvement.

### 7.2 Bounded fast-failure retry

Initially classify `failed` and `empty` attempts in shadow telemetry without
automatic retry, including whether an operator or same-slot rerun later
succeeds. Enable the following automatic policy for a backend/stratum only
after the registered minimum exposure and incidence gate in section 14 passes.

Retry one `failed` or `empty` reviewer only when the first attempt ended before
`min(30 seconds, 25% of reviewer_timeout)`. Both attempts share the original
total budget. Never retry a full timeout. Keep the existing protocol-only retry
separate. One invocation chain may receive either one infrastructure retry or
one protocol retry, never an unbounded combination; every invocation shares the
original wall budget. Specify the state table, including failed-to-protocol,
empty-to-protocol, and protocol-to-failed outcomes. Preserve attempt-one stderr
and emit attempt/timing fields.

This may make a persistent failure slightly slower. Until production incidence
is measured, claim only that the injected fast-failure-to-success fixture
recovers full evidence within the original deadline; do not impute hypothetical
manual-rerun time. Measure restricted mean time to valid result, not
successful-run latency alone.

### 7.3 Parallel reproduction chunks

Partition candidates into:

- Tier 1: deletion/dead-code, public or compatibility surface, all critical/high
  candidates, and orchestrator-uncertain high-risk candidates;
- Tier 2: ordinary single-reviewer or uncertain medium candidates.

Define a deterministic candidate graph from explicit shared root-cause/evidence
links, stable-sort connected components, and pack them into chunks using exact
ID-count plus prompt byte/token-estimate ceilings. Use at most four concurrent
chunks. A component that exceeds the ceiling runs alone or is conservatively
deferred; it is never silently split. Tier 1 is never dropped merely because of
a global cap. A failed chunk conservatively defers only its own IDs. Hash the
candidate manifest and grouping-algorithm version.

Chunking is context-changing because prompts and available cross-candidate
context differ. Deterministic/replay tests prove partition coverage, failure
isolation, and merge behavior only; they do not prove verdict equivalence.
Locked live semantic fixtures must establish disposition non-inferiority for
linked and independent findings before promotion.

### 7.4 Evidence-backed refutation reuse

Carry prior refutations with explicit dependency manifests. Reuse only for an
allowlisted class of deterministic file/content evidence when all anchor and
evidence hashes match and the re-raised finding supplies no new counter-evidence.
Never cache `unclear`, no-file, transitive/implicit-runtime, generated,
configuration, environment, or external-contract verdicts; reverify them.

Later-round prompts include `CHANGED SINCE LAST ROUND` and require
`sweep: completed|partial`; a partial sweep cannot declare convergence.

## 8. Proof and benchmark system

All rails share a versioned event schema and config hash.

### 8.1 Telemetry

Each process writes a separate NDJSON fragment to avoid concurrent append
corruption. Supervisor-issued transition sequence and parent/span relationships
are the authoritative causal order; timestamps measure durations and diagnose
queueing but never infer happens-before across host/native processes. A
finalizer validates and merges fragments. Required fields include:

```text
schema_version, run_id, engine_sha, preset, config_hash,
target_type, target_sha/diff_sha, host, backend/model/version,
phase, round, slot, attempt, span_id, parent_span_id,
queued_at, started_at, ended_at, duration_ms, outcome,
prompt_hash, output_hash, changed_lines, meaningful_lines, files,
candidate_count, retry/failure class, token counts when available
```

The export schema is an allowlist. `files` means count only. Replace repository,
commit, prompt, output, and diff identifiers with study-scoped keyed pseudonyms;
rotate and retain keys separately. Raw paths, URLs, prose findings, code,
environment values, and low-entropy hashes are forbidden. Apply local secret
scanning/redaction, per-field consent, access control, retention/deletion
periods, and symlink-safe destinations. Raw fragments remain ephemeral local
control state and never enter exported replay bundles.

The validator rejects missing span ends, duplicate IDs, impossible serial-only
overlap, report-before-gate, stale snapshot acceptance, and terminal runs that
accept later events.

### 8.2 Deterministic fault-injected harness

Invoke the executable supervisor with fake codex, claude, GitHub, and test
commands. Required workloads:

1. healthy three-reviewer wave with unequal latency;
2. hard hang/timeout and descendant cleanup;
3. fast failure then retry success/failure;
4. protocol retry;
5. reproduction sets of 1, 10, 25, and 45 candidates, including linked IDs;
6. challenge/targeted/full adversaries with unequal latency;
7. slow baseline/gate overlap and mutating-test fallback;
8. red gate plus late speculative output;
9. stale base and mid-run head drift;
10. early convergence and adaptive-cap decisions;
11. interrupt/terminal-state cleanup and moved-head rejection; add resume tamper
    fixtures only when resume is implemented;
12. read-only super-wave admission, ordering, and consensus isolation;
13. report-tail invalidation;
14. deterministic barrier-controlled interleavings for red gate vs completion,
    TERM-ignore, partial envelope, late alarm, and PR movement, plus supplemental
    repeated platform stress;
15. actual host-adapter conformance: unresolved-token finalization failure,
    stale-result refusal, controller-unavailable serial fallback, and proof that
    synthesis cannot consume raw output.

Each feature declares a canonicalizer and equivalence relation. Overlap-only
fixtures require identical normalized accepted reviewer, verdict, fix, report,
and sidecar records. Retry and freshness fixtures require specified outcome
oracles rather than identity. Any unlisted difference fails. Candidate critical
path must match the computed DAG within `max(100 ms, 3%)` and be no slower on
every deterministic scheduling fixture. Race tests use controllable barriers
and exhaust enumerated transition orderings; repeated stress runs are
supplemental, not the proof.

### 8.3 Frozen trace replay

Collect consented, sanitized per-run joint event DAGs containing config/snapshot
hashes, structured sanitized findings/candidate/verdict/state-transition
records where consent permits, accepted output/status hashes, correlated phase
durations, censoring/failure classes, and gate outcomes. Do not store repository
code, raw prompts, secrets, or independently sampled phase distributions that
erase within-run correlation.

Timing replay uses status, dependency, and joint-duration vectors. Decision
replay additionally requires sanitized structured evidence and transitions or
runs locally against retained consented artifacts. Hashes alone cannot
reconstruct decisions. Mechanical features pass only under their declared
equivalence relation. Replay establishes counterfactual scheduling behavior;
it does not prove that changed prompts, concurrency conditions, or fewer
reviewers retain quality.

### 8.4 Hidden semantic corpus

Use clean/mutant repository twins with hidden oracles outside reviewer
worktrees. Include reverse-real-bug and hand-built cases for:

- boundaries, null/error handling, retries, serialization and API compatibility;
- auth order, validation, unsafe fallback, money and time logic;
- concurrency, cancellation, cleanup, migrations and rollback;
- live docs versus archived/generated/vendor decoys;
- genuinely dead code versus compatibility hooks and caller traps;
- scope, open/resolved/suppressed prior feedback, and approval;
- second-order regressions from plausible fixes;
- genuinely clean diffs and unsafe one-line suggestion traps.

Each oracle records root cause, mechanism, acceptable anchors/severity,
required evidence, expected disposition, accepted fix properties, forbidden
actions, visible/hidden tests, risk tags, and approval expectation. Findings are
matched one-to-one by root cause and mechanism, not wording; deduplicate before
scoring. Strict binary credit is primary and partial credit is diagnostic only.
Score detection, final retention/defer/drop, fix, gate, report, and approval as
separate transitions. Two blinded adjudicators classify every unmatched
material finding as gold, genuine unseeded/pre-existing, or false, report
agreement, and resolve uncertain matches before arm labels are revealed.

Mutation validity requirements:

- clean and mutant snapshots build under the fixture contract;
- clean visible and hidden tests pass;
- each mutant has one intended causal change or an exhaustive manifest of all
  introduced defects, independently validated;
- tests, comments, names, and gold data do not reveal the mutation;
- private/held-out transformations reduce public-history memorization risk;
- gold manifests and hidden tests remain outside reviewer worktrees.

Split fixtures into development, variance-pilot, and cryptographically locked
evaluation sets. Never tune prompts, eligibility, thresholds, or sample size on
unblinded evaluation results. Stratify by repository/language/framework,
root-cause family, risky surface, reviewer lens, and side-effect mode. Set
per-family minimums for auth/security, concurrency, migration/data,
compatibility/public API, deletion traps, second-order fixes, scope/history,
approval, and every lens; an aggregate score cannot rescue a failed family.

The locked evaluation runs under a separate service or OS principal. Reviewer
and prompt-builder processes receive only visible fixture checkouts; hidden
tests, gold manifests, allocation, and scoring are inaccessible. Commit the
preregistration and analysis image to an externally timestamped append-only
registry signed by a separately controlled key, audit access, and invalidate an
evaluation after unauthorized pre-unblinding access. A hash stored beside
same-user files is integrity evidence, not blinding.

Minimum non-overlapping corpus targets before a broad claim:

- at least 150 independent critical/high defect opportunities;
- at least 150 high-risk negative traps;
- at least 100 clean twins;
- at least 400 total semantic opportunities.

Repeated model seeds do not count as independent defects.

### 8.5 Randomized paired live trials

Run control and candidate on the same immutable fixture and resolved
configuration, but materialize each arm into a distinct fresh checkout from the
same exact object/diff/untracked manifest. Give each arm a unique run namespace,
private `HOME`/`TMPDIR`/cache where compatibility permits, and reset or ephemeral
external resources. Declare caches cold, shared, or identically prewarmed before
evaluation. Verify checkout, environment, cache-policy, and declared-resource
hashes before and after each arm; on contamination, discard and rerun the whole
pair. Quality trials must not push/post to the same real PR: use mocked isolated
destinations or distinct disposable PRs. Use AB/BA order randomized within
workload/model blocks; do not run paired arms concurrently because provider
contention would couple them. Define washout or block exclusion for provider
rate-limit/capacity carryover. Pin and record CLI/model versions. Close a block
when versions change.

For any proof-grade adapter migration, preregister three arms: `A`, today's
production-native legacy; `B`, the serial binding adapter with no scheduling
feature; and `C`, the identical binding adapter with candidate scheduling.
`C/B` identifies the scheduling effect, `B/A` measures migration tax and
semantic compatibility, and `C/A` is the product speed/quality contrast. The
candidate may be called “faster review-anvil” only if `C/A` independently
passes restricted-time, valid/full-evidence completion, degraded-rate, and all
applicable quality/safety gates. If arm `A` cannot run on a host, scope the claim
to “faster than the serial binding baseline.” A production canary uses `A` as
control until `B` has itself been promoted as the production baseline.

Use only the disjoint pilot set to estimate paired variance and effect size.
Before unblinding evaluation arms, freeze the population, eligibility
classifier, horizon, valid-result contracts, primary estimand, margins,
multiplicity/gatekeeping, stopping rule, analysis code, and main sample size.
Power on independent repository/root-cause clusters, not repeated calls. If a
sequential design is necessary, preregister a valid group-sequential rule;
otherwise no optional stopping.

Use short randomized AB/BA blocks with a maximum pair separation, capture
provider capacity/429/load proxies, and record explicit backend/model build IDs
where available. Predefine handling of incomplete/version-changed pairs. If
stable identity is unavailable, narrow the claim to the measurement window.
Bootstrap or model by paired workload/repository cluster, never by individual
findings.

Define two result contracts:

1. **Current-contract terminal result:** any terminal result valid under today's
   requested-round failure policy.
2. **Full-planned-evidence result:** every expected lens/gate required by the
   resolved plan completed.

Freeze a versioned machine-evaluable terminal-state table shared by both arms.
`success_full` and a precisely bounded `success_degraded` are current-contract
valid; `failure_report`, `controller_abort`, `invalid_artifact`, `timeout`, and
incomplete required sidecars are invalid and receive `tau`. Define degraded
minimum lenses and require all applicable reproduction, verification, approval,
and artifact checks. Start the clock before eligibility/controller work. Stop
at validated report finalization for local flows and successful push/post for
external flows. Completion exactly at `tau` is censored by the frozen rule.

For assurance-preserving features, the primary latency endpoint is paired
restricted time to the **current-contract terminal result**:
`Y = min(time_to_valid_result, tau)`, assigning `tau` when no such result exists.
`tau` is selected from user/product SLOs using baseline-only data before any
candidate evaluation, using historical or disjoint pilot data—not the main
trial control arm. Declare one global horizon or separately registered stratum
horizons; if censoring makes a tail quantile unidentified, report it as
inconclusive. Candidate-only probes and fallbacks are included. The
primary estimand is the ratio of cluster-weighted mean `Y`
(`candidate/control`), with a one-sided 95% cluster-bootstrap bound and fixed
superiority margin. Sensitivity at adjacent horizons is descriptive.

Define a provenance cluster spanning source repository, ancestor snapshot, bug
lineage, transformation family, and all derived twins/mutants. Assign whole
clusters to development/pilot/evaluation. For an equal-repository claim,
`mu_arm = (1/C) * sum_c(mean_i(Y_arm,c,i))` and
`R = mu_candidate / mu_control`; an invocation-population claim instead uses
traffic weights frozen from a pre-evaluation period. Bootstrap whole clusters
while preserving pairs, repetitions, and AB/BA blocks. Report raw opportunities
and effective provenance clusters separately.

Full-planned-evidence completion and degraded-result rate are separate binding
non-inferiority/harm gates. A feature that improves current-contract time but
fails either may claim only faster current-policy terminal output, not preserved
evidence.
Never impute a hypothetical manual rerun unless both arms actually execute the
same preregistered recovery protocol.

Geometric mean and p50 are secondary. Tail quantiles are descriptive until the
canary has enough independent clusters for powered inference. Tokens, cost,
discarded work, and time to full planned evidence are reported alongside the
primary result. Use fixed hierarchical gatekeeping (feature, then bundle, then
promotion). Each intersection-union quality family uses one-sided 95% bounds
and requires every member to pass; no exploratory endpoint rescues a failed
primary family. `preregistration.json` contains the complete hypothesis tree
and fixed-sequence/closed-testing or Holm allocation across features,
populations, horizons, subgroup harm checks, bundles, and canary looks; use a
named group-sequential spending function when applicable. The signed/hashed
`preregistration.json` and analysis-code
commit, including `tau`, cluster weights, margins, and gate order, must exist
before candidate evaluation data is generated or inspected.

The preregistration also contains the cluster-simulation operating-
characteristic table, minimum independent effective clusters for every primary
and family contrast, bootstrap method/replicates/seed, and a predeclared
small-cluster alternative such as exact/randomization inference. The analyzer
must refuse to emit `pass` or `fail` below the relevant minimum and return
`inconclusive`; this applies separately to `C/B`, `B/A`, `C/A`, catastrophic
families, and canary looks.

## 9. Acceptance gates

All applicable gates must pass; aggregate wins cannot average away a red-line
failure.

### 9.1 Primary speed and completion gates

Final margins are justified from baseline distributions, user SLOs, miss/false
action cost, and achievable power, then frozen before candidate evaluation. The
initial design targets are:

- primary restricted-time ratio: one-sided 95% cluster-bootstrap confidence
  bound demonstrating at least 10% improvement
  (`candidate/control <= 0.90`) for the declared contract/population/horizon;
- valid completion-rate difference lower bound `>= -2 percentage points`;
- full-planned-evidence completion difference lower bound
  `>= -2 percentage points` and degraded-result-rate increase upper bound
  `<= +2 points`, each with explicit denominators;
- all-run intention-to-treat and pre-treatment eligible-stratum results both
  reported; only all-run results support a default-population claim;
- geometric mean/p50, tail quantiles, cost, tokens, discarded work, fallback,
  and full-evidence time reported as secondary outcomes;
- predeclared harm checks for mode, diff tier, backend mix, verification tier,
  and PR/local strata, with minimum effective cluster counts. Sparse strata are
  inconclusive, never silently pooled.

### 9.2 Feature-specific quality gates

Do not average semantically risky features into a mechanical bundle.

- Mechanical overlap/provenance features: normalized accepted evidence and
  decisions must be identical on deterministic and decision-replay fixtures;
  any difference fails that feature.
- Retry/freshness features: outcome-specific oracles must pass; measure both
  current-contract completion and full-planned-evidence completion.
- Context-changing features (pending-verification prompt, super-wave,
  reproduction chunks, refutation reuse, delta prompts, reduced signal):
  critical/high recall difference lower bound `>= -2 points`, medium recall
  lower bound `>= -3 points`, actionable precision lower bound `>= -2 points`,
  and false-action increase upper bound `<= +1 point`, each by cluster and with
  family-specific floors.
- Recall counts one-to-one adjudicated oracle opportunities. False-action rate
  is binding both per randomized run and per negative trap. Actionable precision
  is secondary unless its zero-action convention is frozen. Every arm
  difference uses the same provenance-cluster standardization as latency;
  family floors and minimum effective clusters are numeric in preregistration,
  with sample size obtained by cluster simulation rather than raw finding count.
- Deterministic safety sentinels (stale acceptance, reproduction bypass,
  approval, deletion/fix, and gate state) are zero tolerance and have no recall
  CI.
- Stochastic must-detect critical/high scenarios form a locked catastrophic
  sentinel panel sampled from a declared taxonomy, with predeclared independent
  clusters and repetitions. For every scenario/family, require a one-sided
  cluster-aware lower confidence bound on the candidate's absolute single-run
  detection probability to clear a safety-contract floor frozen before
  evaluation. A majority-across-repetitions label may be diagnostic but cannot
  determine acceptance. The candidate must pass every absolute floor regardless
  of control and may have no candidate-only loss under the separately frozen
  paired decision rule. Across all
  locked critical/high opportunities, also require the one-sided 95% upper
  confidence bound on paired excess miss risk `<=2%`, powered from cluster
  discordance and intracluster correlation. An underpowered zero-event result
  is inconclusive. Repeated calls are not
  independent clusters; report uncertainty and never claim zero true risk.
- Severity-weighted diagnostics, if retained, freeze weights
  `critical=8, high=4, medium=2` and cannot override severity/family gates.

### 9.3 Zero-tolerance deterministic and catastrophic red lines

- no candidate-only miss under the fixed decision rule in the locked
  catastrophic critical/high family;
- no harmful deletion or harmful applied fix;
- no newly red terminal gate;
- no stale snapshot/attempt output accepted;
- no required-reproduction bypass or promotion on verifier failure;
- no unsafe approval, push, or convergence claim;
- no report/suggestion anchor against the wrong final snapshot;
- no all-reviewer failure interpreted as clean;
- no degraded single-reviewer small wave allowed to converge;
- no user-pinned mix, rounds, timeout, or focus silently overridden.

### 9.4 Infrastructure overhead and fallback

- measure controller startup, hashing, eligibility, calibration, worktree, and
  fallback overhead from user invocation to valid result; omit none from the
  primary endpoint;
- initial overhead target `<1%` median for eligible long runs, with fixed and
  per-task budgets set only after Phase A no-op measurements rather than an
  arbitrary absolute threshold;
- legacy/serial fallback differs only by measured helper overhead;
- artifact validator failure rate `<0.5%` before default promotion;
- telemetry completeness `>=99%` on controller runs;
- deterministic race and cleanup suite passes on every supported host adapter.

## 10. Implementation sequence

Each behavior change remains independently ablatable. Suggested controls:

```text
REVIEW_ANVIL_ENGINE=legacy|controller
REVIEW_ANVIL_EXPERIMENTS=<comma-separated feature IDs>
REVIEW_ANVIL_DISABLE_FAST=1
REVIEW_ANVIL_TELEMETRY_DIR=<trusted external path>
REVIEW_ANVIL_RUN_ID=<uuid>
```

The emergency switch keeps controller telemetry but forces the legacy DAG and
legacy sizing. Explicit user parameters always win.

Automatic serial fallback is permitted only before controller `init` creates
run state. After initialization, controller loss is an abort/recovery path:
invalidate outstanding capabilities, persist a terminal/recovery marker,
preserve user commits, clean only owned resources, and require explicit resume
or cleanup. `REVIEW_ANVIL_DISABLE_FAST=1` starts a new legacy run; it never
mutates an active controller run.

Before candidate trials, define the registered claim population from hosts,
adapters, repositories, and modes whose binding and eligibility are known from
pre-treatment fields. Report deployment reach across all invocations. A claim
about review-anvil overall requires a predeclared minimum treatment-reachable
fraction and all-run intention-to-treat evidence across supported hosts;
otherwise scope the claim narrowly to the capable population.

Initial structural claims are narrow: name exact binding adapters, OS/container,
modes, verification classes, and diff tiers. An overall default-engine claim is
permitted only if at least 60% of invocations in the registered supported
population are treatment-reachable from pre-treatment fields and the all-run
intention-to-treat gate passes. Report reach over every assignment, including
advisory, ineligible, and fallback runs; README/report wording is generated from
this registered population rather than generalized manually.

Scope the proof machinery to the feature being promoted:

- A local per-run recomputed compatibility envelope needs no certificate PKI;
  protected issuer/rotation/revocation is required only for persistent or shared
  certificates.
- Kernel containment is an adapter capability for hard cleanup/speculation, not
  a prerequisite for immediate timing, freshness, or retry.
- Full WAL/external-effect reconciliation lands before gate overlap, resume, or
  proof claims spanning push/post—not before Phase 0.
- One versioned tagged-union controller schema may replace multiple schema files
  initially if strict validation and compatibility tests remain equivalent.
- Corpus size is power-derived per feature and family. The 400-opportunity
  target is for a broad multi-feature registered non-inferiority claim, not
  every narrow overlap experiment.
- An internal evaluation may use an independent custodian, protected branch/tag,
  precommitted image digest, and blinded labels; a separate service/principal
  and external registry are mandatory for a public auditable claim or realistic
  same-user leakage threat.
- Super-wave, report pre-drafting, refutation cache, reduced confirmation,
  resume, and stall detection are not prerequisites for the first structural
  speed result.

### Phase 0: immediate operational lane

A. Extend `run-reviewer.sh` with elapsed/attempt/failure-class fields and
   per-run timing fragments while preserving its status/exit contract. For
   shell-dispatched reviewers, add exclusive per-run output namespaces and a
   machine-checked attempt header containing run/round/slot/attempt/snapshot/
   backend/lens/prompt hash. This is a useful shell safety check, not a claim
   that native Agent prose is hidden before acceptance.
B. Refresh exact verified-PR base refs and check remote head before every
   improve-PR wave; add stale-base, local-ahead, divergent-head, and retry
   fixtures.
C. Add shadow fast-failure classification with the complete attempt state table
   and wrapper fixtures. Enable one shared-budget automatic infrastructure retry
   only after the section 14 incidence/exposure gate passes for that stratum.
D. Improve descendant cleanup with process groups and explicit descendant
   tests. Label this cooperative cleanup, not kernel containment; escaped
   descendants keep the adapter out of proof-grade eligibility.

Retry buffering uses a per-run external `0700` directory, `umask 077`,
exclusive no-symlink creation, separate stdout/stderr per attempt, and cleanup
traps for success/failure/signal. Compute one monotonic absolute deadline before
attempt one; attempt two receives only remaining time including termination
grace. Only a fully classified accepted attempt reaches the legacy output.
Diagnostic `.err.1` retention is explicit opt-in; otherwise sanitize/delete it.

Cooperative cleanup creates a dedicated child session/group through a tested
platform primitive and receives/verifies the actual PGID through a parent-owned
channel. Never assume `PGID == PID`, never target the wrapper/orchestrator group,
and revalidate identity before TERM/KILL to avoid PID/PGID reuse. On setup or
verification failure, kill only the known direct child, mark cleanup degraded,
and make no descendant claim. Test sibling survival, setup failure, shared PGID,
reuse simulation, grandchildren, spawn-at-deadline, and TERM-ignore.

Run the three existing harnesses plus new focused fixtures. Roll out with local
timing before/after and claim only bounded/recovered failure cases. These steps
do not wait for schemas, the hidden corpus, or controller promotion.

### Pre-Phase A: time-boxed structural feasibility kill gate

Before building proof infrastructure, spike one real mixed-backend serial
binding wave. The spike must keep model output opaque until validation, retain
provider connectivity and legacy-equivalent review capabilities, neutralize
Git/config/environment escape paths, pass denial canaries, and contain the
complete child/resource tree. Measure reachable target traffic with a
predeclared floor. If no adapter passes, or reachable traffic cannot meet the
section 14 reach/ROI gate, terminate the structural-controller project and keep
Phase 0 plus bounded advisory scheduling. Do not build schemas, replay, corpus,
PKI, or the overlap controller first.

### Phase A: establish proof infrastructure

Enter this phase only after the pre-Phase-A binding/reach gate passes.

1. Add the versioned event schema, fragment writer, merger, validator, and unit
   tests. No behavior change.
2. Ingest the immediate lane's timing/attempt fields into the versioned event
   system while preserving status and exit compatibility.
3. Add versioned run-state, task-descriptor, stored-result, candidate-manifest,
   accepted-handle, and event schemas plus the attempt supervisor with legacy
   DAG, result acceptance, worktree capabilities, and host-result ingestion.
   Keep legacy engine default. Use Python stdlib/manual schema validation with
   schema-parity tests, or explicitly pin/preflight a validator dependency.
4. Add deterministic D01--D15 workloads and critical-path analyzer.
5. Add sanitized frozen trace bundles and replay-equivalence tests.
6. Add golden controller/legacy host-conformance flows for productive,
   read-only, PR, and improve-PR success/failure paths. Validate each supported
   host adapter and exact serial fallback when Python/controller/capability is
   unavailable.
7. Add a development/pilot quality corpus, blinded scorer, and preregistered
   paired-analysis implementation. Grow the locked evaluation corpus in
   parallel; it is required for semantic-feature promotion, not for the first
   operational waste fix.
8. Assign owners for controller/security, benchmark/statistics, corpus curation,
   two blinded adjudicators, and privacy/consent. Establish the separate
   evaluation principal/service, timestamped append-only registry, signing-key
   custody/verification, and consented trace policy.
9. Freeze, externally timestamp, and sign `preregistration.json` plus the
   analysis image/commit using only baseline/development/pilot data. Locked
   evaluation and candidate canary data remain inaccessible until this gate
   passes.

Exit: instrumentation overhead passes; legacy controller reproduces all current
host-level flows and sidecars; no speed claim yet.

### Phase B: validate and integrate operational waste fixes

10. Replay and fault-test the Phase 0 fresh-ref/head-drift, shadow failure
    classification, and any incidence-gated retry behavior through the
    controller legacy DAG; add file-list and host-adapter conformance fixtures.

Exit: fault fixtures prove earlier valid completion or earlier safe stop; live
telemetry passes the registered restricted-time and completion harm gates.

### Phase C: remove a mechanically eligible dependency edge

11. Reconfirm the adapter-feasibility and target-population reach assumptions
    against the implementation candidate.
12. Establish a **serial binding baseline** using the exact same adapter binary,
    model/version, prompt bytes, tool executor, confinement policy, environment,
    snapshot, and deadlines intended for overlap. Run the registered three-arm
    design: current production-native `A`, serial binding `B`, and overlap `C`.
    `C/B` estimates scheduling; `B/A` estimates migration; `C/A` must pass for a
    product-level speed claim.
13. Add isolation certification, mechanically restricted reviewer capability,
    cross-run verification locking, and isolated baseline/round-one overlap
    behind `baseline-overlap`.

Exit: deterministic and replay equivalence pass; the pre-treatment eligible
stratum and all-run intention-to-treat endpoint both improve against `A` and
`B`; baseline-only removed time `min(B, W_1) - O_B` is positive without credit
from gate overlap; the explicit isolated-baseline failure state machine and
fallback race fixtures pass. Prompt/capability-identical paired live runs also pass
completion, full-evidence completion, degraded-rate, C/H and medium recall,
false-action, and catastrophic-sentinel gates; provider failure/truncation is an
evidence outcome. If this live gate is omitted, claim only a mechanically
shorter fixed-input DAG, not assurance-preserving live review within registered
margins.

### Phase D: evaluate context-changing concurrency and reuse

14. Add isolated gate/next-requested-wave overlap with explicit
    `verification pending` context behind `isolated-gate-overlap`; adaptive
    rounds remain serial.
15. Add parallel reproduction chunks behind `repro-chunks`.
16. Add read-only bounded super-waves behind `readonly-superwave`, preserving
    per-round semantics and per-backend admission caps.
17. Add allowlisted explicit-dependency refutation reuse and delta/sweep prompts.
18. Add incremental report ledger and only then provisional report drafting with
    strict invalidation.

Exit per feature: full locked-corpus and live semantic non-inferiority passes.
Do not infer safety from replay because these changes influence model context,
provider contention, or prose.

### Phase E: evaluate signal-reducing policies

19. Evaluate two-reviewer small-diff sizing and reduced confirmation waves only
    as experiments. Keep them out of the default engine until the full hidden
    corpus and live gates pass.
20. Evaluate stall detection only after retry is stable and redirected non-TTY
    first-byte telemetry proves a threshold with `<1%` false-stall upper bound.
21. Evaluate tamper-aware resume after controller state and telemetry have
    soaked; reuse only accepted reviewer artifacts and completed green-gated
    rounds, never semantic judgments.

### Phase F: promote

22. Run a contemporaneous hashed control/candidate canary by stable repository
    unit, stratified by backend/model/tier/mode. Each stage requires both a
    minimum duration and a pre-registered minimum number of eligible runs,
    independent clusters, and failure/risk exposures; calendar time alone is
    insufficient. Use current production-native arm `A` as canary control until
    serial binding arm `B` has itself been promoted. Use a sequential alpha-
    spending rule if inspecting interim results.
23. Promote only passed assurance-preserving features to the existing engine's
    automatic scheduler. Retain `REVIEW_ANVIL_DISABLE_FAST=1` for rollback.
24. Publish the committed summary data, claim boundary, version/model strata,
    and rejected/disabled features.

The canary has its own cluster-randomized analysis contract, not the paired
fixture estimator: secret salted hash of canonical repository identity, fixed
predeclared allocation per stage, assignment logged before engine resolution,
no crossover within a stage, identical assignment for new repos, repository-
cluster intention-to-treat, and a predeclared cluster-weighted estimator with
backend/model/tier/mode stratification or covariate adjustment. Define minimum
clusters/events per arm, model-version epochs, missing/incomplete handling, and
randomization/cluster-robust inference. Tail quantiles remain descriptive until
powered.

Automatic rollback triggers:

- any zero-tolerance violation;
- primary restricted-time confidence bound fails the registered superiority or
  harm threshold after the minimum canary information is reached;
- completion regression lower bound worse than 2 points;
- artifact/DAG validation failure above 0.5%;
- telemetry missing on more than 1% of controller runs;
- any accepted stale attempt.

Missing telemetry is treated as candidate failure in sensitivity analysis,
because missingness may be caused by the treatment. Deterministic safety
violations roll back immediately without waiting for statistical thresholds.

Separate operational pause from formal reject/promote. A deterministic red
line, adapter/controller integrity failure, or predeclared severe timeout/
completion/latency guardrail triggers an immediate kill switch for new runs,
using an anytime-valid confidence sequence or deliberately conservative
threshold. Formal superiority/rejection still follows the preregistered
cluster analysis after minimum information. Name the on-call owner/automation
that flips `REVIEW_ANVIL_DISABLE_FAST=1` and test that active controller runs
abort/recover under their own protocol rather than changing mode in place.

## 11. Concrete commit and file plan

### 11.1 Reviewable commit units

Every behavior change is separately revertible and benchmarkable. Subjects are
illustrative Conventional Commits; each eventual commit body must be written
from its staged diff.

| Unit | Illustrative subject | Main proof before merge |
|---|---|---|
| P0.1 | `chore(review-anvil): record reviewer attempt timing` | existing wrapper tests + timing/privacy fixtures |
| P0.2 | `fix(review-anvil): refresh PR bases and stop on head drift` | PR-helper stale/fork/divergence fixtures |
| P0.3 | `fix(review-anvil): retry transient reviewer startup failures` | shared-budget attempt-state matrix |
| P0.4 | `fix(review-anvil): clean up reviewer process groups safely` | identity/sibling/escape cleanup fixtures |
| A1 | `test(review-anvil): add versioned controller contracts` | schema/transition/privacy tests, no behavior change |
| A2 | `feat(review-anvil): add the legacy orchestration controller` | four-flow host conformance and fallback |
| A3 | `test(review-anvil): add deterministic critical-path workloads` | D01--D15 expected DAG/outcomes |
| A4 | `test(review-anvil): add frozen timing and decision replay` | tamper/correlation/equivalence tests |
| A5 | `test(review-anvil): add locked quality scoring` | mutation validity, blind adjudication, power simulation |
| C1 | `feat(review-anvil): add a serial binding adapter baseline` | native-vs-binding semantic and reach results |
| C2 | `perf(review-anvil): overlap certified baseline verification` | mechanical equivalence + live NI + RMST superiority |
| D1 | `perf(review-anvil): overlap isolated gates and requested waves` | pending-context semantic NI and stale-attempt races |
| D2 | `perf(review-anvil): parallelize reproduction candidate chunks` | partition proof + linked-candidate semantic NI |
| D3 | `perf(review-anvil): schedule read-only reviewer super-waves` | canonical-round semantics + provider/diversity NI |
| D4 | `perf(review-anvil): reuse explicit file-evidence refutations` | dependency invalidation + semantic NI |
| D5 | `perf(review-anvil): assemble reports incrementally` | final-state invalidation and artifact-manifest tests |
| E1 | `perf(review-anvil): size low-risk reviewer waves` | full locked signal-reduction NI only |
| E2 | `feat(review-anvil): resume accepted review artifacts` | tamper/head/terminal/interruption fixtures |
| F1 | `feat(review-anvil): promote the measured scheduler path` | registered canary/promotion gates and kill switch |

Do not combine P0 operational fixes with controller/scheduler behavior in one
commit. Do not bundle multiple context-changing features before each has an
individual causal/semantic result; otherwise regressions cannot be attributed
or reverted safely.

### 11.2 Files

New proof/controller files:

```text
plugins/review-anvil/skills/review-anvil/references/run-event-v1.schema.json
plugins/review-anvil/skills/review-anvil/references/run-state-v1.schema.json
plugins/review-anvil/skills/review-anvil/references/task-descriptor-v1.schema.json
plugins/review-anvil/skills/review-anvil/references/task-result-v1.schema.json
plugins/review-anvil/skills/review-anvil/references/candidate-manifest-v1.schema.json
plugins/review-anvil/skills/review-anvil/references/accepted-handle-v1.schema.json
plugins/review-anvil/skills/review-anvil/scripts/review_anvil_events.py
plugins/review-anvil/skills/review-anvil/scripts/review_anvil_controller.py
plugins/review-anvil/skills/review-anvil/scripts/test_review_anvil_events.py
plugins/review-anvil/skills/review-anvil/scripts/test_review_anvil_controller.py
benchmarks/review-anvil/README.md
benchmarks/review-anvil/run_benchmark.py
benchmarks/review-anvil/replay.py
benchmarks/review-anvil/analyze.py
benchmarks/review-anvil/preregistration.json
benchmarks/review-anvil/mocks/
benchmarks/review-anvil/workloads/
benchmarks/review-anvil/traces/
benchmarks/review-anvil/fixtures/
```

Existing files changed over the phases:

```text
plugins/review-anvil/skills/review-anvil/SKILL.md
plugins/review-anvil/skills/review-anvil/references/fix-application.md
plugins/review-anvil/skills/review-anvil/references/reviewer-prompt.md
plugins/review-anvil/skills/review-anvil/references/reproduction-prompt.md
plugins/review-anvil/skills/review-anvil/scripts/run-reviewer.sh
plugins/review-anvil/skills/review-anvil/scripts/test-run-reviewer.sh
plugins/review-anvil/skills/review-anvil/scripts/test-reproduction-policy.sh
plugins/review-anvil/skills/review-anvil-pr/scripts/pr-helper.sh
plugins/review-anvil/skills/review-anvil-pr/scripts/test-pr-helper.sh
plugins/review-anvil/skills/review-anvil-improve-pr/SKILL.md
README.md
plugins/review-anvil/.claude-plugin/plugin.json
.claude-plugin/marketplace.json
```

## 12. New fast surface: falsifiable go/no-go

History matters: commit `8bd02e9` intentionally removed host-specific slash
commands in favor of cross-agent skills. Do not reintroduce a slash command.

After the optimized balanced engine is measured, first test an explicit engine
option such as `latency_budget:` or `profile: quick`. It must compose with the
four existing side-effect/destination flows and label reports as partial or
reduced-depth. It cannot weaken reproduction, deletion, verification,
freshness, head-drift, or conservative failure rules.

The budget is an end-to-end soft objective, not permission to kill or skip a
required gate. Enumerate partial states and completed/skipped lenses, rounds,
reproduction, adversarial, verification, and external effects. Budget expiry on
an improve-PR flow may leave local commits but must not push without the full
required final gate; comprehension testing must cover that outcome. Refuse the
budgeted profile on adapters that cannot enforce its termination/partial-state
contract.

Create a thin named cross-agent skill only if all conditions pass:

- at least 70% of explicitly speed-requesting runs are eligible without
  disabling safety floors, and fallback is at most 30%;
- after sufficient independent canary clusters, all-run intention-to-treat p95
  in the speed-requesting population—including probes and fallbacks—improves by
  at least 30% and at least 120 seconds versus the optimized balanced engine,
  and simultaneous confidence support clears both product margins under a
  predeclared unpaired cluster-randomized quantile estimator, censoring rule,
  and minimum effective cluster count. Eligible-stratum p95 is secondary; if
  censoring reaches p95, the gate is inconclusive;
- every catastrophic scenario/family clears its preregistered absolute single-
  run detection-probability lower bound, with zero candidate-only critical/high
  sentinel losses and a passing upper confidence bound on excess miss risk;
- material-finding recall lower bound is no worse than -5 points;
- false-actionable increase upper bound is no worse than +5 points;
- zero newly red pushed/committed outcomes attributable to the profile;
- forced-timeout fixtures label partial coverage correctly 100% of the time,
  and partial runs never approve, claim convergence, push, or apply an
  unreproduced material fix;
- randomized discoverability testing shows a named skill improves correct
  first-attempt selection by at least 10 points over the engine option without
  increasing wrong mutating-flow selection or stealing intents from any of the
  four incumbent skills. Pre-register ground-truth labeling for ambiguous
  prompts and stratify deadline, thorough-review, PR-comment, improve-PR, and
  local-read-only intents across supported hosts/models;
- blinded comprehension testing shows users understand the actual name and
  report label as reduced-depth/possibly partial, not equal-thoroughness final
  pre-merge review;
- parity tests show the thin preset resolves to identical engine policy on all
  supported hosts except declared budget/profile fields.

No-go: keep only the engine option if eligibility, residual speed, quality,
safety, or discoverability fails. Abandon the quick mode entirely if the
optimized balanced engine already closes the latency gap or if users do not
demonstrate a distinct deadline/partial-result job.

The provisional eligibility, 30%/120-second, discoverability, and `-5/+5`
thresholds are placeholders until Phase-A baselines, user cost/SLO evidence,
power, and adapter reach are known; justify and freeze them before budgeted-mode
candidate evaluation. The provisional `-5/+5` material-recall/false-action
margins describe an explicitly reduced-depth product; passing them does not
establish equivalent quality and must not authorize substitution for final
pre-merge review. If the
product wants the balanced engine's assurance-preserving non-inferiority claim,
apply the tighter section 9 gates and
derive powered margins before evaluation.

If eventually justified, name the product for its actual contract, for example
`review-anvil-budgeted`, rather than implying universally equal thoroughness
with `review-anvil-fast`.

## 13. Questions that experiments must answer

1. What fraction of current productive runs can execute verification faithfully
   in an isolated checkout?
2. How often do remote base staleness, author head drift, transient startup
   failure, and interruption actually occur?
3. What per-backend concurrency caps avoid increased 429/capacity failures?
4. Does temporal separation across read-only rounds add measurable finding
   diversity beyond independent model calls on one frozen snapshot?
5. Which test suites mutate tracked files, share external state, or lose warm
   caches in worktrees?
6. Does reproduction chunking change verdicts for linked findings?
7. Is report composition a material end-to-end tail after the current report
   compaction work?
8. Do users want lower average latency with unchanged assurance, or a hard
   deadline that can return an explicitly partial result?

Until these questions have measured answers, keep fallback conservative and
claims narrow.

## 14. Decisive experiments and stop rules before structural overlap

Do not implement the proof-grade overlap controller merely because the DAG
arithmetic is attractive. Run these experiments in order and stop spending on
the structural lane as soon as a prerequisite fails. Phase 0 remains valuable
and independent of every stop below.

1. **Attempt/phase census.** Instrument at least 50 representative attempts per
   supported backend/repository stratum. Record terminal validity, phase spans,
   retries, interruptions, verification duration, provider wait, and report
   time. Continue retry-specific work only if at least two recoverable startup
   incidents occur in a stratum or the registered recoverable rate is at least
   2%; otherwise retain timing and cooperative cleanup but do not add retry
   complexity for that stratum.
2. **Secure-attempt primitive matrix.** On every supported OS/filesystem class,
   run regular-file, symlink, hardlink, parent-swap, permission, crash-before-
   rename, and concurrent-writer fixtures. Any accepted collision, write outside
   the opened controller directory, or ambiguous terminal manifest blocks that
   platform from authoritative sidecars. The macOS host probe in section 3 is
   evidence for one class only.
3. **Exact-base topology matrix.** Cover same-repository PRs, contributor forks,
   renamed/default branches, force-pushed heads, deleted heads, stale local
   branches, missing remotes, and GitHub Enterprise host/repository identity.
   Every accepted run must bind the exact API-reported base and author-head OIDs;
   any silent fallback to a branch name or contributor `origin` blocks PR-flow
   rollout.
4. **Binding/confinement feasibility probe.** Build the smallest two-plane
   adapter spike for one backend. It must prove that model prose cannot reach
   the orchestrator before validation, that the executor cannot escape its
   declared capability/resource domain under the section 8 adversarial suite,
   and that controller cancellation reaches the complete contained process
   tree. If no adapter can satisfy all three, terminate the proof-grade overlap
   lane; keep only Phase 0, bounded scheduling, and honest advisory-output
   optimizations.
5. **Sequential isolated-verification reach and ROI census.** Before enabling
   overlap, run the unchanged verification command serially in both legacy and
   isolated environments across at least five independent eligible repositories
   (or every repository if fewer exist). Require equivalent terminal verdicts
   under the registered equivalence relation. Proceed only when the median
   removable serial boundary is at least 60 s or 10% of valid-result duration,
   and remains positive after subtracting the stratum's p90 isolation/setup
   overhead. If isolation equivalence is below 30% of the target population, or
   net saving is non-positive, stop the structural lane rather than weakening
   isolation.
6. **Only then run paired overlap replay and live canaries.** Reuse the same
   binding adapter in serial control and overlap candidate, freeze eligibility
   before treatment, and apply sections 9 and 10 without optional stopping.
   Deterministic replay may validate state transitions and stale-result
   rejection, but only the preregistered live experiment may support an effect
   claim.

These gates deliberately make “do not build it” a successful experimental
outcome. The convincing claim is therefore conditional and falsifiable: Phase
0 improves known failure paths immediately; structural overlap ships only where
binding, reach, net critical-path removal, and quality non-inferiority are all
measured rather than assumed.
