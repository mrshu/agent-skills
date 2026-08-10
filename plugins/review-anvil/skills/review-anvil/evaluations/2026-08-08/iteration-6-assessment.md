# Iteration 6 assessment — author work versus no-change constraints

## Design

Iteration six made the Claude distinction explicit:

- only code or test work the author must perform counts as an obligation;
- required tests remain explicit author work;
- permissions, carve-outs, exceptions, and already-correct behavior stay with
  the action they limit or in short modal prose;
- no-change constraints never receive their own action bullet.

The production contract, renderer, reviewer prompt, shared style guide, presets,
and static language assertions use the same rule. The frozen diagnoses and fact
sources were not changed.

Three clean generators (GPT-5.6 Sol, Luna, and Terra) independently rewrote the
22-comment development corpus. The existing frozen fact and readability rubrics
were reused without modification. Claude Opus and GPT-5.6 Sol, Luna, and Terra
judged randomized outputs without seeing version names or label keys.

## Fact gate

Fact-safe comments by generator and judge:

| Judge | Sol generator | Luna generator | Terra generator |
|---|---:|---:|---:|
| GPT-5.6 Sol | 22/22 | 22/22 | 17/22 |
| GPT-5.6 Luna | 21/22 | 22/22 | 20/22 |
| GPT-5.6 Terra | 22/22 | 22/22 | 17/22 |
| Claude Opus | 22/22 | 22/22 | 20/22 |

Only the Luna generator passed the strict unanimous fact gate. Sol lost one
exact test-boundary judgment. Terra omitted or changed several test, scope, and
requested-action boundaries. Those two outputs were rejected before readability
selection.

## Readability gate

The fact-safe Luna output was compared blindly with the `104debc` baseline:

| Judge | Iteration 6 wins | Baseline wins | Ties |
|---|---:|---:|---:|
| GPT-5.6 Sol | 6 | 0 | 16 |
| GPT-5.6 Luna | 4 | 2 | 16 |
| GPT-5.6 Terra | 6 | 0 | 16 |
| Claude Opus | 5 | 0 | 17 |

Claude mean scores:

| Version | Defect clarity | Action recall | Scanability | Naturalness | Cognitive ease |
|---|---:|---:|---:|---:|---:|
| `104debc` baseline | 4.091 | 3.727 | 3.864 | 4.000 | 3.682 |
| Iteration 6 | 4.091 | 4.136 | 4.227 | 4.000 | 3.682 |

Claude no longer preferred the baseline. It found no naturalness or cognitive-
ease regression and preferred iteration six whenever an otherwise hedged test
became explicit. The three GPT judges also preferred iteration six overall.

## Manual action-lock failure

Iteration six is not the finalist despite the judge results.

For comment `3737383919`, the source requests two code changes:

1. require at least one `--models` value;
2. add a no-match check before existing-output discovery or publication.

The Luna output made only the first an explicit request and left the second as:

> A no-match check can stop before existing-output discovery or publication.

The generator treated the modal `can` as a no-change signal. Here it describes a
new check the author must add. This violates the action-lock gate even though all
fact judges accepted the sentence and Claude preferred the comment for naming
`--models` explicitly.

## Decision

Reject iteration six as the final contract, but keep it as the development
reference. The structural distinction fixed Claude's earlier objections and
preserved fact safety with the Luna generator. The remaining defect is narrower:
modal grammar alone cannot classify a source unit.

Iteration seven must classify semantics instead:

- a proposed new check, validation, report, write, or test is author work even
  when the source says it “can” produce the desired result;
- a unit is a no-change constraint only when it preserves current/allowed/
  unchanged behavior, an explicit carve-out, or an unhandled error boundary;
- every action-lock unit must map to either an explicit request or preserved
  constraint sentence before emission.
