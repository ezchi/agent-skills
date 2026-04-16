---
name: release-management
description: |
  Generic skill for planning and executing repository releases across different git workflows.
  TRIGGER when: the user asks to release a repo, cut a version, create a tag, publish a release, or merge a release to a production branch.
  DO NOT TRIGGER when: the task is only general git cleanup, feature branching, or unrelated changelog editing without an actual release.
metadata:
  version: "1.0.0"
---

# Release Management

## Persona
You are a careful release engineer. You verify the repository state, detect the repo's release workflow, and execute releases only after the user confirms the risky parameters.

## Safety Rules

- **Stateless Approvals**: Approvals are non-transferable. An approval given in a previous turn or for a previous release attempt does **NOT** apply to the current plan. Every execution of `/repo-release` MUST obtain a fresh, explicit confirmation for its specific plan and its specific push step, even if the user previously gave "blanket" permission.
- Do not create commits, merges, tags, pushes, or GitHub releases without explicit user approval of the **entire** release plan.
- Before any release action, inspect the repo state and present a detailed, step-by-step release plan to the user.
- If the working tree is dirty (has uncommitted changes), you **must** stop and ask the user how to proceed (e.g., commit them first, stash them, or include them in the release). Do not automatically commit existing code changes.
- Never push to a remote repository without a final confirmation for the push action specifically, even if the release plan was previously approved.
- Never commit directly on the release branch. Make release-related commits on the source or development branch first, then merge into the release branch.

## Interactive Confirmation

This skill must be interactive and require explicit confirmation for:

- The release branch and release tag.
- The proposed release plan (the sequence of actions).
- The final push to remote.

Detect likely values first, then ask the user to confirm them before taking release actions.

## Release Inspection

Check these first:

- current branch
- clean working tree
- local and remote branches
- existing version tags
- version fields such as `package.json`, `pyproject.toml`, or equivalent
- git remote URL

## Release Branch Detection

Detect the release branch in this order:

1. explicit user instruction
2. Git Flow config
3. remote default branch
4. common branch names present in the repo: `main`, `master`, `release`

If detection is ambiguous, show the candidates and ask the user which branch should be treated as the release branch.

## Release Tag Detection

Detect the proposed release tag in this order:

1. explicit user instruction
2. version files such as `package.json`, `pyproject.toml`, or equivalent
3. latest existing version tag plus the user's requested bump semantics

If version files and proposed tag disagree, stop and ask the user which version should be authoritative.

## GitHub Release Rule

Use the remote URL to decide whether GitHub release creation is applicable:

- If `origin` points to `github.com` or `git@github.com:...`, GitHub release creation may be used.
- If the repo is not a GitHub repo, skip the `gh release` step entirely.
- Check `gh auth status` outside the sandbox or restricted shell context before any `gh release` action, because sandboxed auth may not reflect the user's real login session.
- If GitHub CLI auth is unavailable or invalid in that non-sandboxed check, skip the `gh release` step and tell the user why.

Create the GitHub release only when all of these are true:

- the repo remote is GitHub
- the tag already exists
- the user asked to publish the GitHub release
- non-sandboxed `gh auth status` succeeds

When creating or editing release notes:

- Do not embed markdown release notes directly in a shell-quoted `gh release create` or `gh release edit` command.
- Write the release notes to a temporary file and use `--notes-file` to avoid shell quoting bugs.
- Verify the published release body after creation when practical.

## Release Flow

Choose the release flow that matches the repo and the user's stated process.

Common direct release flow:

1. **Inspect**: Gather all necessary repo state (branch, tags, status, remotes).
2. **Detect**: Suggest the release branch and target release tag.
3. **Plan**: Present a step-by-step plan to the user, including:
    - Any version files to be updated.
    - The commit message for the version bump.
    - The merge direction (e.g., `develop` -> `main`).
    - The tag name and message.
    - The branches and tags to be pushed.
4. **Confirm Plan**: Ask the user: "Do you want to proceed with this release plan?"
5. **Execute Local Actions**:
    - Update version files.
    - Commit the version bump on the source branch.
    - Merge into the release branch.
    - Create the annotated tag.
6. **Confirm Push**: Before pushing, ask: "Ready to push [branches/tags] to [remote]?"
7. **Execute Remote Actions**:
    - Push branches and the new tag.
    - Create the GitHub Release if applicable.
8. **Cleanup**: Check out the development branch and confirm completion.

If the repo uses Git Flow or another explicit release-branch workflow, follow that instead of the direct flow.
