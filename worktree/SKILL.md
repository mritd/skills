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
- **New branch:** Keep the user's exact name. Otherwise infer `<type>/<description>` from a clear task, for example `perf/startup-slow-sql` or `fix/refresh-loop`. Generated names have exactly two slash-separated segments. Write a concise kebab-case description from the task intent; no scope or component prefix is required. Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `perf`, `hotfix`, `build`. This borrows commit types, not commit-header syntax. If neither a name nor clear intent exists, ask for one.
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
git worktree add --no-track -b "$worktree_branch" "$worktree_path" "$worktree_base_oid"
git -C "$worktree_path" branch --show-current
git -C "$worktree_path" rev-parse HEAD
git worktree list --porcelain
```

The variables above represent the already validated branch, absolute destination, and full base commit ID. Verify registration, branch, and HEAD before setup. Do not use `-B` or `--force`. On failure, inspect partial state and report it; do not delete existing paths or switch to working in the original checkout.

### Configure the same-name upstream

The new branch must track the **same branch name on the intended remote**, never the base branch merely because it was created from main/master. Resolve `worktree_remote` from the user's requested publishing remote, an unambiguous repository convention, or the sole remote; do not assume the base remote is also the publishing remote. If no remote exists, report upstream setup as unavailable; if the intended remote is ambiguous, ask.

Configure only the newly created branch, including when a native worktree tool created it:

```bash
git -C "$worktree_path" config --local --replace-all "branch.$worktree_branch.remote" "$worktree_remote"
git -C "$worktree_path" config --local --replace-all "branch.$worktree_branch.merge" "refs/heads/$worktree_branch"
git -C "$worktree_path" config --local --replace-all "branch.$worktree_branch.pushRemote" "$worktree_remote"
git -C "$worktree_path" config --get "branch.$worktree_branch.remote"
git -C "$worktree_path" config --get-all "branch.$worktree_branch.merge"
git -C "$worktree_path" config --get "branch.$worktree_branch.pushRemote"
```

Verify the effective remote and pushRemote equal the intended remote, and merge has exactly one value, `refs/heads/<new-branch>`. Set these configuration values directly even if the remote branch does not exist yet; `branch --set-upstream-to` requires an existing remote-tracking ref. In that case, report the upstream target as configured but not yet published; do not fabricate a remote-tracking ref or push to create it. Do not change global or repository-wide push settings. If an existing remote push refspec or push mode would override same-name pushing, report the conflict rather than claiming a bare `git push` is safe.

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

Report completion in Chinese with ASCII punctuation. Always include separate list items for the directory (`目录`), branch (`分支`), base ref and commit (`基点`), and whether CodeGraph was initialized. These are required information, not a verbatim template or fixed field order. Add other necessary context as appropriate. The following is only an example; replace its values and status claims with verified facts:

```text
kovacs, worktree 已创建

- 目录: .worktrees/docs-ops-docs-cleanup
- 分支: docs/ops-docs-cleanup
- 基点: 最新拉取的远端 main, 3971d652
- 同名上游已配置, 尚未发布
- CodeGraph 已初始化, 索引最新
- 工作区干净
```

Use a brief opening that reflects the actual outcome; its wording is flexible. Keep the directory in its own list item rather than embedding it in the opening. Render the response as ordinary text and a Markdown list, not a code block or nested list.

The directory line must contain only `- 目录: ` followed by the plain path. Do not wrap the path in backticks, quotes, or a Markdown link. Do not append punctuation, annotations, trailing spaces, or any other characters after the path. Preserve an explicitly requested path's relative or absolute form; otherwise show a path relative to the source repository root for an internal worktree, and an absolute path for an external worktree. Keep this display choice separate from the absolute path used for execution.

Report the actual base ref and an unambiguous short commit ID; say it was freshly fetched only when it was. Report whether the same-name upstream is configured and published; include the intended remote when needed to disambiguate. Report CodeGraph initialization and index freshness separately if their outcomes differ. Run `git -C "$worktree_path" status --short` after setup and any handoff creation before claiming the workspace is clean; otherwise describe the actual changes or an unavailable check. Never copy the example's success claims without verification. If creation fails, state that outcome instead of using the success opening.

Append separate list items for a handoff path, relevant source work left behind, or concrete failures when applicable; never attach them to the directory line. Distinguish checkout creation from indexing or test success. Continue an already authorized task in the new directory; if the request was only setup, finish here.
