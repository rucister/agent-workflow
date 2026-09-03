---
name: review-rounds
description: The standard blind review flow for a branch, diff, or PR — one persistent reviewer from the Reviewer profile, cross-vendor, lens checklist carried in the prompt, three rounds standard, conditional security pass. Use when asked to review a branch/diff/PR outside paseo-dev-loop, when paseo-dev-loop reaches its review phase (§4), or when the owner says "review this" / "run review rounds".
---

# review-rounds — the standard review flow

Policy only; techniques live in the referenced skills. Wraps the atomic review lenses so a review is never assembled by hand.

## Inputs

- **Target:** a branch (diff against its base), a raw diff, or a PR. Default: the current branch against its base.
- **Fix owner:** who receives each round's findings. Inside paseo-dev-loop: the implementer (fix pass, then re-gate). Standalone: **report only** — findings go to the owner, batched per round with severities; nothing is fixed unless the owner asks. Unplanned work never starts itself (paseo-dev-loop entry contract).
- **Bindings:** the repo's declared red lines and gate commands, from its own agent docs — needed to decide the security pass and to re-gate after a fix pass.

## The reviewer

One persistent subagent, launched once from the **Reviewer** profile and re-prompted per round. Resolve it with paseo-dev-loop's launch resolution ladder and fallback table — same tiers, same floor: with no independent reviewer available, stop and say so; never self-review. Blind: it sees the diff and the lens checklist, never the author's or implementer's conversation. Prefer a different vendor than whoever wrote the code; the profile decides the model.

## A round

1. Prompt the reviewer with the target diff and the **lens checklist, always inline** — never assume the reviewer can load Claude plugin skills: `agent-skills:code-review-and-quality`, `agent-skills:code-simplification`. Ask for findings with file:line, severity, and a one-line fix direction.
2. **Security pass** when the diff touches auth, untrusted input, or a declared red line: a separate `security-auditor` subagent (`agent-skills:security-and-hardening`), independent of the reviewer; its findings merge into the round.
3. Batch the round's findings into one deduped list ordered by severity and hand it to the fix owner. If a fix pass happens, re-gate (paseo-dev-loop §3) before the next round.

## Exit

- **Three rounds is the standard.** A zero-findings round closes early.
- High-stakes targets — declared red lines, auth/session code, schema migrations, large branches — get more than three.
- Standalone: the review ends when rounds are exhausted or the owner stops it.

## Reporting

Per round: findings, severities, and each one's disposition (fixed / deferred / disputed). At the end: rounds run, what closed the loop, open items. Never report a round without the reviewer's actual output.

## Not this skill

`/code-review ultra` is rare, manual, and owner-launched — never part of these rounds.
