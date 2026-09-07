---
name: worktree
description: Use when the user requests a new Git worktree or an authorized task needs an isolated checkout, including debugging handoffs into a new worktree.
---

# Worktree

Create an isolated checkout from a verified base, with a meaningful branch and its own CodeGraph index. This skill is self-contained: it requires Git and attempts CodeGraph initialization, but requires no other skill, plugin, or agent-specific tool.

Follow user authorization and repository instructions. A request to create a worktree authorizes the steps below; do not ask for the same permission again. Merely discussing worktree options does not authorize creation.

## 1. Resolve the request

Read applicable repository instructions. Inspect the repository root, current branch and commit, `git status --short`, `git worktree list --porcelain`, and remote names. Inspect relevant source changes only as needed; do not read secret stores or copy secrets.

Resolve these inputs independently:

- **Base:** Use an explicitly requested base. Otherwise use the latest remote `main` or `master`, never current HEAD, local main/master, or an unrefreshed remote-tracking ref.
- **New branch:** Keep the user's exact name. Otherwise infer `<type>/<scope>/<short-kebab-description>` from a clear task, for example `fix/auth/refresh-loop`. Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `perf`, `hotfix`, `build`. Use `general` when scope is unclear. This borrows commit naming concepts, not commit-header syntax. If neither a name nor clear intent exists, ask for one.
- **Location:** Honor an explicit path, then repository conventions. Otherwise use a sibling directory named `<repo-name>-<branch-with-slashes-replaced-by-hyphens>`. Check the exact destination for collisions, including symlinks. For a generated path, choose an unused suffix; for an occupied explicit path, ask rather than overwrite or redirect it. For a location inside the source repository, verify it is ignored. If it is not, use the sibling default unless the user explicitly required the internal location; then resolve the ignore change with the user. Do not silently edit or commit `.gitignore`.

Validate the branch with `git check-ref-format --branch`. Check local branch and worktree collisions. An invalid or already existing user-supplied name requires clarification, not renaming, reset, or forced reuse. For generated names, choose a clear unused suffix. A remote branch with that name may contain previous work; resolve that collision before creating an unrelated local branch.

Existing isolation is evidence, not an automatic reason to skip the request. Reuse it only if the request permits reuse and its branch/base match; an explicit new-worktree request still means create a new worktree.

## 2. Pin the base

For a remote base, use the requested remote, an unambiguous repository convention, or the sole remote. If multiple remotes leave the intended source unclear, ask. For default base selection, inspect live remote heads and the default using `git ls-remote --symref <remote> HEAD refs/heads/main refs/heads/master`. An explicitly local base requires no remote lookup.

For the default base, choose the sole available main/master. If both exist, prefer the remote default only when it is one of them; otherwise ask which to use. If neither exists, ask for a base. Do not silently substitute `develop` or another default branch.

Fetch the selected remote branch explicitly and resolve the fetched commit immediately. For example, after resolving `origin` and `main`:

```bash
git fetch --no-tags origin refs/heads/main
git rev-parse --verify 'FETCH_HEAD^{commit}'
```

Record that full commit ID as the creation base. This avoids relying on custom fetch mappings or stale tracking refs. For an explicit remote branch override, fetch that exact branch similarly. For an explicitly local branch, tag, or commit, resolve and pin it as requested; do not replace it with remote main/master. Clarify an ambiguous ref.

If remote verification or fetch fails, investigate within existing permissions. Do not fall back to cached state without the user's explicit acceptance of a stale/local base. Report freshness as of the successful fetch, not as a promise that the remote cannot subsequently advance.

## 3. Create and verify

Briefly state the resolved path, branch, and base. Prefer a native worktree tool only if it can honor the exact branch and pinned base; otherwise use Git. Quote resolved arguments and run from the intended repository:

```bash
git worktree add -b "$worktree_branch" "$worktree_path" "$worktree_base_oid"
git -C "$worktree_path" branch --show-current
git -C "$worktree_path" rev-parse HEAD
git worktree list --porcelain
```

The variables above represent the already validated branch, absolute destination, and full base commit ID. Verify registration, branch, and HEAD before setup. Do not use `-B` or `--force`. On failure, inspect partial state and report it; do not delete existing paths or switch to working in the original checkout.

Leave the source checkout's dirty files and index untouched. Uncommitted changes and commits outside the chosen base are not transferred. Never automatically stash, copy WIP, stage, commit, push, pull, rebase, reset, or merge. Carrying work across requires separate authorization.

## 4. Initialize CodeGraph

Read the new checkout's applicable instructions, then run `codegraph init .` with the new worktree as the working directory. Verify with `codegraph status .`. Do not copy an index from the original checkout. If an index already exists, inspect its status and follow the installed CLI's documented refresh behavior rather than overwriting it blindly.

If CodeGraph is missing or fails, preserve the worktree and report the exact failure separately. Do not install tools automatically or claim initialization succeeded. Continue independent authorized work using available search tools. Do not install project dependencies or run a full test suite merely to create a checkout; follow the active implementation task's setup and verification requirements when applicable.

## 5. Write a debugging handoff when triggered

Automatically write a debugging handoff only when **both** are present in the conversation: an explicit preceding debugging task, and a handoff request such as `handoff`, `交接`, or `移交`. A generic worktree request or the word `debug` alone is insufficient. Honor an explicit request for another kind of document in its own scope.

Use the project's handoff convention; otherwise create `HANDOFF.md` at the new worktree root. Preserve existing files and use a descriptive unused filename if needed. Keep it concise and actionable:

- Objective, symptom, and reproduction commands or missing reproduction details.
- Confirmed findings with file/symbol references; hypotheses labeled separately.
- Attempts and observed results, including failed approaches and verification limits.
- Source checkout path, branch, and commit; new branch and pinned base commit.
- Relevant WIP or source-only commits not present here, with paths and implications. Do not imply they were transferred or reproduced on the new base.
- Next investigation steps, open questions, and relevant CodeGraph status.

Record unavailable facts as unknown. Exclude secrets and sensitive log contents. Leave the document uncommitted; submission and cleanup remain the user's decision.

## Completion

Report the absolute worktree path, branch, base ref and commit, CodeGraph outcome, handoff path if created, and any source work left behind that matters. Distinguish checkout creation from indexing or test success. Continue an already authorized task in the new directory; if the request was only setup, finish here.
