---
name: review-rounds
description: Runs the standard blind review of a branch, diff, or PR against the agreed plan — one persistent reviewer from the Reviewer profile, cross-vendor, deliverable verdict first, blocking vs polish findings, three rounds standard. Use when the owner says "review this", "review the branch / PR / diff", "check what the implementer built", "quality pass on this", "second opinion on the code", "run review rounds", or when paseo-dev-loop reaches its review phase (§4).
---

# review-rounds — the standard review flow

Policy only; techniques live in the referenced skills. A review judges the deliverable first and the code second — a round whose findings all sit in test files means the reviewer lost the goal.

## Inputs

- **Target:** a complete deliverable (paseo-dev-loop §4 entry) — never a helper in isolation — as a branch (diff against its base), a raw diff, or a PR. Default: the current branch against its base.
- **Goal — required:** the agreed plan, acceptance criteria, or ticket the target claims to deliver. Without one, ask the owner for a one-line statement of what the change should do. A review without the goal is a code-shape review, the failure this skill exists to prevent.
- **Evidence record:** the orchestrator's boundary record (real / controlled / untested) travels with the brief, so the reviewer knows what was proven and what was supplied.
- **Fix owner:** who receives findings. Inside paseo-dev-loop: the implementer (fix pass, then re-gate). Standalone: **report only** — nothing is fixed unless the owner asks (paseo-dev-loop entry contract).
- **Bindings:** the repo's declared red lines and gate commands, from its own agent docs.

## The reviewer

One persistent subagent, launched once from the **Reviewer** profile and re-prompted per round. Resolve it with paseo-dev-loop's launch resolution ladder and fallback table — same tiers, same floor: no independent reviewer, stop and say so; never self-review. **Blind to the conversation, never to the goal:** it gets the diff, the goal, and the lens content — not the implementer's or author's chat. Prefer a different vendor than whoever wrote the code; the profile decides the model.

## A round

1. **Brief = diff + goal + lens content, in this order.** Paste condensed lens content, not skill names — the reviewer may run under any provider and may not be able to load skills by name.
   1. **Deliverable** — does the change do what the goal says? What is missing or different? What would the owner notice at UAT?
   2. **Correctness of product code** — edge cases, error paths, state (`code-review-and-quality`, correctness axis).
   3. **Security** — only when the diff touches auth, untrusted input, or a declared red line; see step 2.
   4. **Readability and architecture** (`code-review-and-quality` remaining axes, `code-simplification`).
   5. **Tests as evidence only** — do they prove the acceptance criteria? Test style, naming, and structure are out of scope unless a test is wrong or missing.
   Every round opens with a **deliverable verdict**: delivers / partial (what is missing) / does not.
2. **Security pass** when lens 3 applies: a separate subagent briefed with `security-and-hardening`, independent of the reviewer; its findings merge into the round.
3. **Classify, then hand off.** `blocking` = deliverable gap, product correctness, security. `polish` = readability, architecture, simplification, test hygiene. Dedupe, blocking first. A fix pass is for blocking findings; polish accumulates into one fix pass at the end of the loop, or is deferred with the owner's ok. Re-gate (paseo-dev-loop §3) after every fix pass. Every fix pass re-runs the evidence scenarios; a pass that breaks a working scenario is not done.

## Exit

- **A round with no blocking findings closes the loop.** Polish never extends rounds.
- **Three rounds is the standard budget**; high-stakes targets — declared red lines, auth/session code, schema migrations, large branches — get more.
- Standalone: the review ends when the budget is spent or the owner stops it.

## Reporting

Per round: deliverable verdict, then findings by class, each tagged `open` / `fixed` / `deferred` / `disputed` / `regressed` / `new` — a repair that breaks something else is a new finding, not a disposition. An accepted finding reopens only with concrete new evidence. At the end: rounds run, what closed the loop, polish deferred. Never report a round without the reviewer's actual output.

## Red flags

- All findings in one round are test-file nits: the reviewer lost the goal — re-brief with the plan.
- No deliverable verdict in a round: the brief carried skill names, not lens content.

## Not this skill

`/code-review ultra` is rare, manual, and owner-launched — never part of these rounds.
