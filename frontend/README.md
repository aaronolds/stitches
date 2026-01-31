# Stitches Frontend

React + Vite + TypeScript frontend for the Stitches application.

## Prerequisites

- **Node.js**: 20.0+ (check with `node --version`)
- **npm**: 10.0+ (check with `npm --version`)

Use [nvm](https://github.com/nvm-sh/nvm) and the `.nvmrc` file in the repo root to ensure correct Node version:

```bash
nvm use
```

## Setup

```bash
# Install dependencies
npm install

# Copy environment template
cp .env.example .env.local

# Start development server
npm run dev
```

Open [http://localhost:5173](http://localhost:5173) to view the application.

## Available Scripts

| Command | Description |
|---------|-------------|
| `npm run dev` | Start development server with HMR |
| `npm run build` | Build for production |
| `npm run preview` | Preview production build locally |
| `npm test` | Run tests in watch mode |
| `npm run test:ui` | Run tests with Vitest UI |
| `npm run test:coverage` | Run tests with coverage report |
| `npm run lint` | Run ESLint |
| `npm run format` | Format code with Prettier |
| `npm run type-check` | Run TypeScript type checking |

## Project Structure

```text
src/
├── assets/         # Static assets (images, fonts)
├── components/     # Reusable UI components
├── pages/          # Page-level components (routes)
├── services/       # API client and business logic
├── styles/         # Global styles and theme
├── App.tsx         # Root component
└── main.tsx        # Entry point

tests/
├── unit/           # Component unit tests
├── integration/    # User flow tests
└── setup.ts        # Test configuration
```

## Environment Variables

Environment variables are prefixed with `VITE_` and loaded at build time.

| Variable | Description | Default |
|----------|-------------|---------|
| `VITE_API_URL` | Backend API URL | `http://localhost:5000` |

### Local Development

Create `.env.local` (gitignored) for local overrides:

```bash
VITE_API_URL=http://localhost:5000
```

### Accessing Environment Variables

```typescript
const apiUrl = import.meta.env.VITE_API_URL;
```

## Development Workflow

### Hot Module Replacement (HMR)

Changes to React components automatically update in the browser without page refresh.

Target: HMR updates appear in < 1 second.

### API Proxy

The Vite dev server proxies `/api` requests to `http://localhost:5000` (backend).

```typescript
// This request is proxied to http://localhost:5000/api/health
fetch('/api/health')
```

## Testing

Uses [Vitest](https://vitest.dev/) with [React Testing Library](https://testing-library.com/docs/react-testing-library/intro/).

```bash
# Run tests in watch mode
npm test

# Run with coverage
npm run test:coverage
```

### Writing Tests

```typescript
import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import MyComponent from '@/components/MyComponent';

describe('MyComponent', () => {
  it('renders correctly', () => {
    render(<MyComponent />);
    expect(screen.getByText('Hello')).toBeInTheDocument();
  });
});
```

## Linting & Formatting

### ESLint

```bash
npm run lint
```

### Prettier

```bash
npm run format
```

### Pre-commit Hook

Husky runs `lint-staged` on commit to lint and format staged files.

## Troubleshooting

### Port 5173 already in use

```bash
# Find and kill process
lsof -i :5173
kill -9 <PID>
```

Or change port in `vite.config.ts`:

```typescript
server: {
  port: 3000,
}
```

### Module not found errors

```bash
rm -rf node_modules
npm install
```

### TypeScript errors

```bash
npm run type-check
```

---

**Last Updated**: 2026-01-31
