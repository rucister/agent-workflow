---
name: squash-rebase-merge
description: "Merge an approved GitHub PR the owner's way: fold iteration commits into meaningful commits, rebase onto the latest base, force-push with lease, wait for green CI on that head, then rebase-merge pinned to it. Never a GitHub squash or merge commit. Run only when the owner invokes it with a PR number and an optional shape (one, topics, keep)."
disable-model-invocation: true
argument-hint: "<pr-number> [one|topics|keep]"
---

# squash-rebase-merge

Invoking this skill **is** the owner's merge call: don't ask "merge now?" again. Ask only where a step below says so.

Arguments: a PR number, then an optional commit shape:

| Shape | Final history |
|---|---|
| `one` | one commit for the whole PR |
| `topics` | one commit per separable topic |
| `keep` | the commits as they are |
| *(none)* | step 2 decides |

**Why this flow:** main keeps the commits reviewers read, with full messages. A GitHub squash writes a new commit, often with an empty body, and main can't be rewritten after it lands.

## Stop rules

Stop, say why in one line, and touch nothing else when:

- the PR isn't open, is a draft, or its review decision isn't `APPROVED` (many repos don't enforce reviews, so this skill does)
- the working tree is dirty, the PR branch isn't checked out in this worktree, or the local head ≠ the PR's remote head (someone else pushed: report, never overwrite). Never write into another worktree's checkout.
- a CI check fails on the pushed head: name the job and link it; don't re-run it, don't merge
- a rebase conflict needs a guess about intent

No interactive git (`-i`, editors): every step below is non-interactive.

## 1. Read the state

```bash
gh pr view <n> --json state,isDraft,reviewDecision,baseRefName,headRefName,headRefOid,url
git fetch origin
git status --porcelain                              # must be empty
git branch --show-current; git rev-parse HEAD       # must equal headRefName, headRefOid
git log --reverse --format='%h %s' origin/<base>..HEAD
```

Record `old=$(git rev-parse HEAD)`. The base is whatever `baseRefName` says: a stacked PR targets its feature branch, not main.

## 2. Decide the commit shape

**One topic = one commit.** A topic is a change a reviewer could accept on its own. Iteration commits (fix, polish, address review, the change's own tests or docs) fold into the topic commit they refine.

- Shape given → use it.
- No shape, history already one commit per topic → `keep`.
- No shape, folding needed → show the proposed final list (one subject per commit, plus which commits fold into it) and ask once. A human may have reviewed the fix commits on their own, so folding them is the owner's call.

## 3. Rebase onto the latest base

```bash
git rebase origin/<base>
git range-diff origin/<base> $old HEAD   # every commit maps; changes only from conflict resolution
```

- Never merge the base into the branch.
- If the base already carries the same fix, keep the base's hunk and drop our now-empty commit.

Record `rebased=$(git rev-parse HEAD)`.

## 4. Fold (skip for `keep`)

Rebuild on the base: `git reset --soft origin/<base>` and one commit for `one`; for `topics`, `git reset --hard origin/<base>` (the tree is clean and `$rebased` is in the reflog), then per group `git cherry-pick --no-commit <its commits, oldest first>` and `git commit -F <msg>`.

**Proof:** `git diff $rebased HEAD` prints nothing. Folding changes history, never content.

Each final message:

- starts from the topic commit's own message, the one reviewers read, with the body updated if the folded fixes changed what it describes
- follows the repo's commit convention (from its agent docs), with a body that says what changed and why
- keeps every co-author trailer of the commits folded into it, deduplicated

## 5. Push

Skip when `HEAD` = `$old`.

```bash
git push --force-with-lease=<branch>:$old origin HEAD:<branch>
```

The PR description still matches: content didn't change. Drop any commit list it carries that no longer does.

## 6. Wait for green CI on the pushed head

```bash
gh pr checks <n> --watch --interval 30
```

Run it in the background; it outlives a foreground command. Right after a push GitHub may report no checks yet: wait ~30 s and start it again. Exit 0 = green (skipped checks count as green). Before trusting it, confirm the PR's `headRefOid` is still the SHA you pushed.

Nothing pushed → read `gh pr checks <n>` once; it must already be green.

## 7. Merge

```bash
git fetch origin <base>
comm -12 <(git diff --name-only HEAD...origin/<base> | sort) \
         <(git diff --name-only origin/<base>...HEAD | sort)
```

- Base moved and that prints a file → back to step 3, once. If it moves onto our files again, report and ask.
- Otherwise merge; GitHub replays the commits onto the moved base.

```bash
gh pr merge <n> --rebase --match-head-commit "$(git rev-parse HEAD)"
```

- Never `--squash`, never `--merge`. If the repo disallows rebase merges, stop and ask.
- No `--delete-branch`: it also deletes the local branch and switches this worktree.

## 8. Verify and report

```bash
gh pr view <n> --json state,mergedAt
git fetch origin <base> && git log --format='%h %an | %s' -<k> origin/<base>
```

The state is `MERGED` and the PR's commits sit on top of the base with their messages; same SHAs when the base didn't move.

Report in at most three lines: the merged SHAs and subjects, the CI result, and anything the PR left for after the merge (follow-up tasks fire on their own trigger, usually the deploy, not the merge).
