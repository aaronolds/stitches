# Contributing to Stitches

Thank you for your interest in contributing to Stitches! This document provides guidelines and instructions for contributing.

## Code of Conduct

Please read our [Code of Conduct](CODE_OF_CONDUCT.md) before contributing.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR-USERNAME/stitches.git`
3. Create a feature branch: `git checkout -b feature/your-feature-name`
4. Make your changes
5. Submit a pull request

## Development Setup

See the [README.md](README.md) for detailed setup instructions.

### Prerequisites

- Node.js 20+
- .NET SDK 10+
- Git 2.30+

## Branch Naming Convention

Use the following prefixes for branch names:

| Prefix | Usage |
|--------|-------|
| `feature/` | New feature development |
| `fix/` | Bug fixes |
| `docs/` | Documentation changes |
| `refactor/` | Code refactoring |
| `test/` | Adding or updating tests |
| `chore/` | Maintenance tasks |

Examples:
- `feature/user-authentication`
- `fix/image-upload-error`
- `docs/api-documentation`

## Commit Message Format

We follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

### Types

| Type | Description |
|------|-------------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `style` | Formatting, missing semicolons, etc. |
| `refactor` | Code change that neither fixes a bug nor adds a feature |
| `test` | Adding or updating tests |
| `chore` | Maintenance, dependencies, etc. |

### Examples

```
feat(auth): add OAuth login with Google

fix(editor): resolve canvas rendering on mobile devices

docs(api): update health endpoint documentation

chore(deps): update React to 19.x
```

## Pull Request Process

1. **Update documentation**: If you change functionality, update relevant docs
2. **Add tests**: All new features should include tests
3. **Pass CI checks**: Ensure all tests pass and linting is clean
4. **Request review**: Tag at least one maintainer for review
5. **Address feedback**: Respond to review comments promptly

### PR Title Format

Use the same format as commit messages:
```
feat(scope): brief description
```

### PR Description Template

Describe:
- What changes were made
- Why changes were necessary
- How to test the changes
- Any breaking changes

## Code Style

### Frontend (TypeScript/React)

- Use functional components with hooks
- Use TypeScript strict mode
- Follow ESLint + Prettier configuration
- Use PascalCase for components, camelCase for utilities

### Backend (C#/.NET)

- Follow Microsoft C# coding conventions
- Use async/await for I/O operations
- Use dependency injection
- Follow layered architecture (Api → Application → Domain → Infrastructure)

## Testing

### Frontend Tests

```bash
cd frontend
npm test           # Run tests
npm test -- --ui   # Run with UI
```

### Backend Tests

```bash
cd backend
dotnet test        # Run all tests
```

### Test Requirements

- Unit tests for business logic
- Integration tests for API endpoints
- Minimum 80% code coverage for new code

## Security

- **Never commit secrets** (API keys, passwords, connection strings)
- Use Azure Key Vault for production secrets
- Use User Secrets for local development (.NET)
- Use `.env.local` for local environment variables (gitignored)
- Report security vulnerabilities privately to maintainers

## Questions?

- Open a [GitHub Issue](https://github.com/aaronolds/stitches/issues)
- Check existing issues before creating new ones

---

Thank you for contributing! 🧵
