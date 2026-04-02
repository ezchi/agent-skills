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

- Do not create commits, merges, tags, pushes, or GitHub releases without explicit user approval.
- Before any release action, inspect the repo state and explain the exact release plan.
- If the working tree is dirty, stop and ask how to proceed.
- If version files do not match the latest release tag, call that out before releasing.

## Interactive Confirmation

This skill must be interactive for the two highest-risk release parameters:

- release branch
- release tag

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
- If GitHub CLI auth is unavailable or invalid, skip the `gh release` step and tell the user why.

Create the GitHub release only when all of these are true:

- the repo remote is GitHub
- the tag already exists
- the user asked to publish the GitHub release
- `gh auth status` succeeds

## Release Flow

Choose the release flow that matches the repo and the user's stated process.

Common direct release flow:

1. Detect the release branch and ask the user to confirm it.
2. Detect the target release tag and ask the user to confirm it.
3. Confirm which version files should be updated.
4. Update version files.
5. Run the relevant build or validation steps to catch obvious release breakage.
6. Commit the version bump on the source branch.
7. Merge the source branch into the confirmed release branch.
8. Create an annotated tag such as `v0.4.0` on the release commit.
9. If the repo workflow requires it, merge the release branch back into the development branch.
10. Push branches and the new tag to `origin`.
11. Only if the repo is on GitHub and `gh` is available and authenticated, create the GitHub Release from the existing tag.

If the repo uses Git Flow or another explicit release-branch workflow, follow that instead of the direct flow.
