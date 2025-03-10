# Auto-Invoice Service

[![Hyper M](https://sp-ao.shortpixel.ai/client/to_webp,q_glossy,ret_img/https://kdconsult.eu/wp-content/uploads/2020/12/kd-logo.png)](https://kdconsult.eu)

[![Version Control](https://github.com/bogui/auto-invoice-service/actions/workflows/version-control.yml/badge.svg)](https://github.com/bogui/auto-invoice-service/actions/workflows/version-control.yml)

---

A Python microservice that automates invoice generation by processing subscription data from a Node.js backend via Redis Streams.

## Version Control Guidelines

This project follows [Semantic Versioning](https://semver.org/) and maintains a detailed changelog following the [Keep a Changelog](https://keepachangelog.com/) format.

### Branch Strategy

- `main`: Production-ready code
- `develop`: Development branch
- Feature branches: `feature/*`
- Bug fix branches: `fix/*`
- Release branches: `release/*`

### Version Control Workflow

1. **Starting a New Feature**

   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b feature/your-feature-name
   ```

2. **Making Changes**

   - Make your changes
   - Update CHANGELOG.md in the [Unreleased] section
   - Commit with conventional commits format:
     ```
     feat: add new feature
     fix: resolve bug
     chore: update dependencies
     docs: update documentation
     ```

3. **Creating a Pull Request**

   - Push your feature branch
   - Create PR against `develop`
   - Ensure CHANGELOG.md is updated
   - Pass all CI checks

4. **Releasing a New Version**
   ```bash
   # From develop branch
   ./scripts/version.sh [major|minor|patch]
   git push && git push --tags
   ```

### Version Bumping Rules

- **Major** (X.0.0): Breaking changes
- **Minor** (0.X.0): New features, no breaking changes
- **Patch** (0.0.X): Bug fixes only

### Changelog Guidelines

1. Keep the [Unreleased] section up to date
2. Group changes under appropriate categories:

   - Added
   - Changed
   - Deprecated
   - Removed
   - Fixed
   - Security

3. Format entries as:
   ```
   - Description of change (#PR-number)
   ```

### Automated Checks

GitHub Actions automatically:

- Validates CHANGELOG.md format
- Checks version format
- Creates releases on main branch
- Enforces version bumping on PRs

### Scripts

- `./scripts/version.sh`: Version management script
  ```bash
  ./scripts/version.sh major  # 1.0.0 -> 2.0.0
  ./scripts/version.sh minor  # 1.0.0 -> 1.1.0
  ./scripts/version.sh patch  # 1.0.0 -> 1.0.1
  ```

## Development Setup

[Development setup instructions will be added here]

## Configuration

[Configuration instructions will be added here]

## Testing

[Testing instructions will be added here]

## Deployment

[Deployment instructions will be added here]
