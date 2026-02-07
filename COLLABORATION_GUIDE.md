# Team Collaboration Strategy: Authentication App

This guide outlines how your team of five should manage the repository to ensure a smooth development process.

## 1. Branching Model (Git Flow)

To keep the project organized, follow this branching strategy:

| Branch Name | Purpose |
| :--- | :--- |
| `main` | **Production Baseline.** Only stable, reviewed code goes here. Protected branch. |
| `rahul-chauhan` | Rahul's workspace for the Authentication module. |
| `member-2-branch` | Workspace for Module 2. |
| `member-3-branch` | Workspace for Module 3. |
| ... and so on | ... |

### Workflow for Team Members:
1. **Pull** the latest `main` regularly: `git checkout main && git pull origin main`.
2. **Merge** `main` into your module branch to stay updated: `git checkout rahul-chauhan && git merge main`.
3. **Push** your changes to your specific branch on GitHub.

## 2. Integration (Merging to Main)

Wait until a module is finished OR reaches a stable milestone before merging to `main`.

**Steps for merging:**
1. Create a **Pull Request (PR)** on GitHub from `rahul-chauhan` to `main`.
2. Assign at least one other team member to **Review** the code.
3. Once approved and checks pass, merge the PR.

## 3. Handling Conflicts

Since everyone is working on separate modules, conflicts should be rare. However:
- If two people edit `pubspec.yaml` to add dependencies, you will get a conflict.
- Resolve conflicts locally on your module branch *before* merging into `main`.

## 4. GitHub Setup Tips

- **Internal/Private Repo**: Ensure the repository is private if you don't want the public to see your code yet.
- **Collaborators**: Go to `Settings > Collaborators` on GitHub to add your 4 teammates.
- **Branch Protection**: Go to `Settings > Branches` and add a rule for `main` to "Require a pull request before merging".

---
*Prepared by Antigravity*
