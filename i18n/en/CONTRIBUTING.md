# Contributing Guide

> This guide is for all contributors who want to participate in the vibe-coding-ros2 project, explaining how to contribute code and documentation through standardized open-source collaboration.

---

## Collaboration Workflow

```
[Personal Repository (Fork)] → [Local Changes] → [Submit Pull Request] → [Maintainer Review] → [Merge to Main Repository]
```

### 1. Fork the Project

Click the "Fork" button on the GitHub repository page to copy the project to your personal repository.

```bash
# Clone your Fork
git clone https://github.com/YOUR_USERNAME/vibe-coding-ros2.git
cd vibe-coding-ros2
```

### 2. Create a Feature Branch

Never develop directly on the main branch. Create a feature branch based on main.

```bash
# Sync upstream latest code
git remote add upstream https://github.com/MIUAV/vibe-coding-ros2.git
git fetch upstream
git checkout -b feat/your-feature-name upstream/main
```

### 3. Develop and Commit

Follow the project's commit conventions. Ensure each commit contains actual content changes.

```bash
# Commit your changes
git add .
git commit -m "feat(scope): description of your feature"
```

### 4. Submit Pull Request

Push your feature branch to your Fork repository, then create a PR on the GitHub page.

- PR title format: `feat: brief description`
- PR body should include:
  - Summary of changes
  - Modules or files involved
  - Test verification results (if any)
  - Whether an Issue is linked

### 5. Code Review

Maintainers will review your PR and may suggest changes. Please respond promptly and update your branch.

Once approved, the maintainer will merge your code into the main repository.

---

## Commit Conventions

### Commit Message Format

```
<type>(<scope>): <subject>

<body> (optional)

<footer> (optional)
```

### Type Categories

| Type | Description |
|------|------|
| feat | New feature |
| fix | Bug fix |
| docs | Documentation change |
| style | Code formatting (no logic change) |
| refactor | Refactoring |
| perf | Performance optimization |
| test | Test-related changes |
| chore | Build/tooling changes |

### Example

```
feat(perception): add lidar point cloud processing node

- implement point cloud filtering
- add downsampling
- integrate PCL library

Closes #123
```

### Commit Requirements

- **Must contain actual content changes**: no formatting-only, empty line, or comment-only commits
- **One commit per feature**: don't mix unrelated changes in a single commit
- **Keep clear context**: commit messages should let others quickly understand the change purpose

---

## Pull Request Requirements

### Basic Requirements

1. **Target branch**: PR must target the `latest` branch
2. **No conflicts**: ensure your branch has no conflicts with target, rebase if necessary
3. **Pass basic tests**: if there are tests, ensure they pass locally

### PR Content Template

```markdown
## Summary
[Brief description of changes]

## Changes Details
- Module A: change content
- Module B: change content

## Test Verification
[Explain how you tested]

## Related Issues
[If any, link Issue number]
```

### Review Criteria

Maintainers will review from these aspects:

- [ ] Does the change follow project architecture and design principles?
- [ ] Is the code quality and style consistent?
- [ ] Are there necessary tests or documentation?
- [ ] Is the commit message standardized?

---

## License

By contributing to this project, you agree that your code contributions will be open-sourced under the Apache License 2.0.

---

## Contact

- Submit Issues: https://github.com/MIUAV/vibe-coding-ros2/issues
- Project Maintainer: MIUAV Organization