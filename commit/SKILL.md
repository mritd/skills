---
name: commit
description: Generate commit messages following the Conventional Commits 1.0.0 spec and commit using gitflow-toolkit (`git ci -F`). Use this skill whenever the user wants to commit changes — phrases like "提交", "帮我提交", "提交变更", "提交一下", "提交代码", "/commit", "commit these changes", "commit this", "create a commit", "help me commit", or any explicit request to create a git commit. Also use when the user finishes a task and asks you to commit the result. This skill auto-stages files — users do not need to stage manually.
---

# Gitflow Commit

Generate a commit message following the [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/) specification by analyzing staged changes, then commit via `git ci -F <file>`.

This skill uses `gitflow-toolkit` which validates the commit header format, auto-appends `Signed-off-by`, and optionally runs lucky commit. Using `git ci -F` instead of raw `git commit` ensures every commit passes format validation.

## Workflow

### 1. Collect changes

Check both staged and unstaged changes:

```bash
git status --short
```

- If changes are already staged (and no unstaged changes exist), proceed to step 2 with the staged changes.
- If there are unstaged/untracked changes, stage them automatically:
  - **Single logical change**: Stage everything with `git add -A` and proceed to step 2.
  - **Multiple unrelated changes** (e.g., a bug fix + a new feature + a config update): Group files by logical change, present the grouping to the user, and **STOP and wait for the user to confirm or adjust** before staging or committing anything. Only after the user explicitly confirms, commit each group separately (one `git add` + `git ci` per group). Keep the grouping summary concise — show file paths and a one-line description per group.
- If there are no changes at all (working tree clean), inform the user and stop.

### 2. Read the diff

```bash
git diff --cached
```

For large diffs (many files or >500 lines), start with an overview:

```bash
git diff --cached --stat
```

Then read diffs selectively, focusing on the most significant changes.

### 3. Analyze and generate the commit message

Study the diff to understand:
- **What** changed (the concrete modifications)
- **What type** of change it is (feature, fix, refactor, etc.)
- **Which component** is most affected (this becomes the scope)

Write the message following the Conventional Commits format:

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

#### Header format

```
type(scope): subject
```

- **type**: `feat` | `fix` | `docs` | `style` | `refactor` | `test` | `chore` | `perf` | `hotfix` | `build`
- **scope** (required): component affected (e.g., `ui`, `config`, `api`, `core`). Use `general` when no specific scope fits
- **subject**: imperative mood, max 50 chars, lowercase start, no trailing period
- For breaking changes, append `!` after the type: `feat!(config): change config format`

#### Body guidelines

- Each line starts with `- ` when present
- 1–5 lines maximum
- Summarize changes, don't enumerate files — "Migrate import paths across all packages" beats listing 20 files
- Describe WHAT changed, not WHY — motivation belongs in PR descriptions
- Only describe what's in the diff — never invent or speculate

#### Language

Default to English. Use Chinese only if the user explicitly says "中文" or "用中文". Use bilingual format only if explicitly requested.

Bilingual format example:
```
feat(ui): add dark mode toggle (添加暗色模式切换)

- 在设置页添加主题切换组件
- 用户偏好持久化到 localStorage
```

#### Do NOT include

- `Signed-off-by` line — the tool appends it automatically
- `Co-Authored-By` or any similar trailer — the commit is authored by the user, not by Claude
- Blank lines at the end
- Markdown formatting or code blocks in the message itself

### 4. Write to file and commit

Split this into three steps so the user can review the message before committing:

**Step 4a** — Generate a unique suffix via shell command to avoid collisions when multiple sessions commit in parallel. Do not invent random strings — LLM sampling lacks real entropy and will collide:

```bash
COMMIT_MSG_FILE=".git/GITFLOW_COMMIT_MSG_$(head -c4 /dev/urandom | xxd -p)"
echo "$COMMIT_MSG_FILE"
```

**Step 4b** — Use the **Write** tool to save the message to the path from 4a. The Write tool displays file content clearly in the UI, making it easy for the user to audit the commit message:

```
Write tool:
  file_path: <repo-root>/<COMMIT_MSG_FILE from 4a>
  content: <the generated message>
```

**Step 4c** — Commit with a short Bash command, then clean up:

```bash
git ci -F <COMMIT_MSG_FILE> && rm -f <COMMIT_MSG_FILE>
```

This separation keeps the Bash command small and auditable — the user sees the message content in the Write call and only a one-liner in Bash.

If `git ci` is not found, the user needs to install gitflow-toolkit:

```bash
gitflow-toolkit install
```

### 5. Handle errors

If the commit fails with a format error, check these common issues:
- First line must match `type(scope): subject` exactly
- Type must not be empty (bad: `(scope): subject`)
- Scope must not be empty (bad: `feat(): subject` or `feat: subject`)
- Subject must not be empty (bad: `feat(scope):`)

## Quick reference: choosing the type

| Type       | When to use                                |
|------------|--------------------------------------------|
| `feat`     | New functionality or capability            |
| `fix`      | Bug fix                                    |
| `docs`     | Documentation only                         |
| `style`    | Formatting, whitespace — no logic change   |
| `refactor` | Restructuring without behavior change      |
| `test`     | Adding or updating tests                   |
| `chore`    | Tooling, CI/CD, maintenance                |
| `perf`     | Performance improvement                    |
| `hotfix`   | Urgent production fix                      |
| `build`    | Build system or dependency changes         |

## Examples

**New feature:**
```
feat(auth): add JWT token refresh endpoint

- Add /auth/refresh endpoint with automatic token rotation
- Set refresh token lifetime to 7 days
```

**Bug fix:**
```
fix(api): prevent nil pointer on missing user profile

- Add nil check before accessing user.Profile
- Return 404 instead of 500 for non-existent users
```

**Large refactoring across many files:**
```
refactor(core): migrate from io/ioutil to io and os

- Replace all deprecated ioutil calls with io/os equivalents
```

**Simple doc change (no body needed):**
```
docs(readme): update installation instructions
```

**Breaking change (scope is still required):**
```
feat!(config): switch config format from YAML to TOML

- Rewrite config parser for TOML format
- Update default config template and documentation
```
