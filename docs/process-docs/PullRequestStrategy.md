# Pull Request Strategy

Do not create merge requests on broken Code

**IMPORTANT**

All merge requests require at least 2 other people to approve before the merge is allowed!

If you need help ask. We are all available to help


# Pull Request Naming Strategy
Branch title + Pull Request title should be the same.

# Pull Request Documentation
## What & Why

Summarize what the purpose of the pull request is and why it is needed.

## Changes Made
Make a itemized list of changes made within the pull request

Ex.

- renamed `MyManager` to `MyLife` to better reflect the purpose of the class
- added settings menu to client side app to allow changing preferences.


## How to Test
Suggestions on how to test the changes made in the pull request. Preferably a numbered list of steps to follow


## Risk Assessment & Rollback Plan
- **Risk Level:** [Low / Medium / High]
- **Rollback:** Strategy to revert changes made in the pull request if needed. This could be a git command or a description of what to change.

## Checklist
- [ ] Tests added/updated
- [ ] Tests and builds pass on CI/CD pipeline
- [ ] No merge conflicts with base branch.
- [ ] No sensitive information (passwords, API keys, etc.) included in the pull request.
- [ ] Code adheres to the project's coding standards and guidelines.
- [ ] Documentation updated
- [ ] Self-reviewed locally before opening
- [ ] Peer-reviewed by at least 2 other team members
- [ ] All comments addressed and resolved
- [ ] Have fun!

