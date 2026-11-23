---
name: review-rounds
description: Runs the standard blind review of a branch, diff, or PR against the agreed plan, or against clauses derived from the PR's own issue and description when there is none — one persistent reviewer from the Reviewer profile, an executed counterexample per acceptance clause, a broad first round (how far a failure spreads, what the change leaves behind, unchecked assumptions, cost as it grows) that later rounds narrow to closure, blocking vs polish findings, and a three-round budget that closes on clause survival. Use when the owner says "review this", "review the branch / PR / diff", "check what the implementer built", "quality pass on this", "second opinion on the code", "run review rounds", or when paseo-dev-loop reaches its review phase.
---

# review-rounds

The reviewer tries to break the deliverable, and the clauses it is judged against are under review too. Reading is not a verdict. Policy only — techniques live in the referenced skills.

## Inputs

- **Target:** a complete deliverable — never a helper — as a branch (diff against its base), a raw diff, or a PR.
- **Goal, required:** the plan with its acceptance clauses, and the documents each clause derives from. A review without a goal is a code-shape review. Read each clause from the plan and its source, never from the implementer's hand-back, summary, or commit messages: a wrong reading of a clause is consistent with the code and with the commit that explains it.
  - **No plan** (a colleague's PR, a task too small for one): derive one to three clauses from the change's own source — the owner's brief or the linked issue first, the PR description only when nothing else exists, since it can share the code's misreading. The orchestrator derives them, since it reads the PR and talks to the owner, and hands them to the reviewer as the goal; the reviewer still tries to break each one. List them at the top of the report as **derived**, so the owner can correct a wrong guess. When the sources contradict the diff or state no intent, ask the owner instead of guessing. A change planned inside paseo-dev-loop always uses its plan.
- **Evidence record:** the boundary table (real / controlled / untested) when one exists, so the reviewer knows what was proven and what was supplied.
- **Fix owner:** inside paseo-dev-loop, the implementer. Standalone, **report only**; nothing is fixed unless the owner asks.
- **Bindings:** the repo's declared red lines, gate commands, and its own review checklists (for example how failures reach on-call, or what counts as a breaking change), which round 1 applies.

## The reviewer

One persistent subagent from the **Reviewer** profile, resolved through paseo-dev-loop's launch ladder — no independent reviewer means stop, never self-review. Independent means a separate agent, blind to the author's conversation and never to the goal — not a particular vendor. A different vendor is a preference when one is available, never a gate and never a reason to wait: execution against a real boundary is what finds defects, not a change of model. **Security:** a separate subagent briefed with `security-and-hardening` whenever the diff touches auth, untrusted input, or a declared red line; its findings merge into the round.

## Rounds narrow as they go

The first round casts wide, and the later rounds close. A review bound to the clauses misses what no clause names, and a round that stays open-ended never closes.

- **Round 1 is broad.** It runs everything in "A round" below, then sweeps past the clauses with four questions that fit any change, each probed by execution where it applies:
  - **How far does a failure spread?** One bad input among good ones, a failing dependency, a stop halfway through: what else breaks, and who notices — the user, the logs, the alerting?
  - **What does it leave behind?** Stored data, state, cache, files, config: does each have a clear meaning and an end, and do the old and new versions work side by side?
  - **What does it assume that nothing checks?** Inputs, callers, order, timing, environment.
  - **What does it cost as it grows?** More users, more data, more time running.

  The repo's own review checklists (Bindings) run in this round too. A finding outside the plan is classified like any other. When fixing it would change scope or behaviour, it goes to the owner as a fork and never becomes a new open clause.
- **Round 2 onward is narrow:**
  - closure of the previous round's findings, with their counterexamples re-run;
  - a re-run of every earlier counterexample, to catch regressions;
  - only new blocking problems that the fix pass introduced.

  No new questions and no new polish.

## A round

1. **Brief** = diff with generated files excluded + goal (marked derived when it is) + the round's scope, with round 1's questions and the repo's checklists pasted inline (the reviewer may run under any provider).
2. **Per acceptance clause:** construct a counterexample and execute it against the real boundary — a real database, a real request, a real lock schedule. The clause survives only when the counterexample fails. Reading the code or re-running the existing suite is not a verdict on a clause. Then product correctness (`code-review-and-quality`), then readability and architecture (`code-simplification`). Tests are evidence only: do they prove the clauses? Their style is out of scope unless a test is wrong or missing.
3. **A clause you cannot violate is a finding against the plan.** If no counterexample can be built from the clause and its source — the text admits an interpretation the code satisfies and the intent does not — stop on that clause and raise it to the owner as a fork. Never invent the missing semantics and resolve it in code. When the owner rules, the ruling goes back into the source document, not only into the code and the ledger; otherwise the next task inherits the same ambiguity.
4. **Classify and hand off.** `blocking` = clause gap, product correctness, security. `polish` = readability, architecture, simplification, test hygiene. Blocking → one fix pass, which commits the executed counterexamples as tests, then re-gate; a fix pass that breaks a working scenario is reverted, not repaired. Polish → one batch at the end, or deferred with the owner's ok.

Every finding carries id · class · round · disposition (`open` / `fixed` / `deferred` / `disputed` / `regressed` / `new`) · commit. A repair that breaks something else is a new finding.

## Exit

- The loop closes when every clause survived its executed counterexample and open blocking findings = 0.
- Budget: three rounds. Spent → report pass/fail per clause to the owner, who decides on more.
- An accepted finding reopens only with concrete new evidence.
- Verdict words: **delivers** / **partial** (what is missing) / **does not**; **unreviewable** for a clause whose text cannot produce a counterexample.

## Red flags

- All findings in one round sit in test files: the reviewer lost the goal — re-brief with it.
- A verdict with no executed counterexample per clause is a reading verdict; it closes nothing.
- From round 2 onward, a counterexample whose rule is nowhere in the plan, its sources, or an accepted earlier finding means you are writing the spec, not reviewing against it. Raise it.
- A round 1 with no finding outside the clauses, on a diff that adds stored state, a long-running process or a new dependency, means the broad sweep did not run. Re-brief with the four questions.
- `/code-review ultra` is manual and owner-launched, never part of these rounds.
