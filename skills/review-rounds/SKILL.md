---
name: review-rounds
description: Runs the standard blind review of a branch, diff, or PR against the agreed plan — one persistent reviewer from the Reviewer profile, cross-vendor, an executed counterexample per acceptance clause, blocking vs polish findings, a three-round budget that closes on clause survival. Use when the owner says "review this", "review the branch / PR / diff", "check what the implementer built", "quality pass on this", "second opinion on the code", "run review rounds", or when paseo-dev-loop reaches its review phase.
---

# review-rounds

The reviewer tries to break the deliverable. Reading is not a verdict. Policy only — techniques live in the referenced skills.

## Inputs

- **Target:** a complete deliverable — never a helper — as a branch (diff against its base), a raw diff, or a PR.
- **Goal, required:** the plan with its acceptance clauses. Missing → ask the owner for one; a review without the goal is a code-shape review.
- **Evidence record:** the boundary table (real / controlled / untested), so the reviewer knows what was proven and what was supplied.
- **Fix owner:** inside paseo-dev-loop, the implementer. Standalone, **report only**; nothing is fixed unless the owner asks.
- **Bindings:** the repo's declared red lines and gate commands.

## The reviewer

One persistent subagent from the **Reviewer** profile, resolved through paseo-dev-loop's launch ladder — no independent reviewer means stop, never self-review. A different vendor than whoever wrote the code; a same-vendor round can only yield **provisional**. Blind to the author's conversation, never to the goal. **Security:** a separate subagent briefed with `security-and-hardening` whenever the diff touches auth, untrusted input, or a declared red line; its findings merge into the round.

## A round

1. **Brief** = diff with generated files excluded + goal + lens content pasted inline (the reviewer may run under any provider).
2. **Per acceptance clause:** construct a counterexample and execute it against the real boundary — a real database, a real request, a real lock schedule. The clause survives only when the counterexample fails. Reading the code or re-running the existing suite is not a verdict on a clause. Then product correctness (`code-review-and-quality`), then readability and architecture (`code-simplification`). Tests are evidence only: do they prove the clauses? Their style is out of scope unless a test is wrong or missing.
3. **Classify and hand off.** `blocking` = clause gap, product correctness, security. `polish` = readability, architecture, simplification, test hygiene. Blocking → one fix pass, which commits the executed counterexamples as tests, then re-gate; a fix pass that breaks a working scenario is reverted, not repaired. Polish → one batch at the end, or deferred with the owner's ok.

Every finding carries id · class · round · disposition (`open` / `fixed` / `deferred` / `disputed` / `regressed` / `new`) · commit. A repair that breaks something else is a new finding.

## Exit

- The loop closes when every clause survived its executed counterexample and open blocking findings = 0.
- Budget: three rounds. Spent → report pass/fail per clause to the owner, who decides on more.
- An accepted finding reopens only with concrete new evidence.
- Verdict words: **delivers** / **partial** (what is missing) / **does not**; **provisional** when the reviewer was same-vendor.

## Red flags

- All findings in one round sit in test files: the reviewer lost the goal — re-brief with the plan.
- A verdict with no executed counterexample per clause is a reading verdict; it closes nothing.
- `/code-review ultra` is manual and owner-launched, never part of these rounds.
