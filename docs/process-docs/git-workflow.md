# Git Workflow

This document explains how our team uses Git and GitHub to manage changes. We use branches and pull requests to review changes before merging them into master.

## 1. Create a Branch

Start from the latest version of `master`.
Create a separate branch for your task.
Use a clear name, such as `it0-docs-sprint0`.
Make your changes on this branch.

## 2. Make and Commit Changes

Follow the team's programming standards.
Keep each commit focused on a clear change.
Start each commit message with a sentence that explains what changed.

For example:
`Added technology decisions to sprint0.md`

If you work locally, push your commits to your branch on GitHub.

## 3. Check your Work

Review your changes before opening a PR.
Run the tests and build checks that apply to your changes.
For documentation, check the text, formatting, and links.

Do not open a PR with broken code.
Ask teammates for help if needed.

## 4. Open a Pull Request

Open a PR from your branch into `master`.
The PR title must match the branch name.

Use the team's `pull_request_template.md`.
Explain what changed and why, list the changes, describe how to test them, and include the risk level and rollback plan.

Check off only completed items.
Explain any items that do not apply.

## 5. Review and Merge

At least two other team members must approve the PR before it is merged.
Respond to review comments and make any needed changes.

If there are conflicts with `master`, resolve them on your branch.
Discuss unclear conflicts with the teammate whose work is affected, then check again.

Merge only after approval, all review comments are addressed, and required checks pass.

## 6. Finish the Task

After merging, delete the completed branch.
Close the related issue if the task is finished.
If you work locally, update your local `master` before starting your next task.

