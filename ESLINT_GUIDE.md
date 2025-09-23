# ESLint CI Guide 🔍

## Problem Fixed

The CI build was failing because ESLint warnings were being treated as errors in the GitHub Actions environment (`process.env.CI = true`). This document explains how to prevent this from happening again.

## Quick Fix Commands

If you encounter ESLint errors in CI:

```bash
# Test locally with CI configuration
cd client && npm run lint:ci

# Fix common issues automatically  
cd client && npm run lint -- --fix

# Run the standard lint check
cd client && npm run lint
```

## What Was Fixed

### 1. Removed Unused Imports and Variables
- `CONTRACT_CONSTANTS`, `RegistryStats` from DataBrokers.tsx
- `useEffect`, `Worker`, `TaskStatus`, etc. from ProcessorDashboard.tsx  
- `useEffect` from TokenPage.tsx
- `TASK_STATUS_LABELS`, `TASK_STATUS_COLORS` from UserDashboard.tsx
- Various unused state variables across components
- XMTP-related unused code in XmtpMessageSection.tsx

### 2. Fixed useEffect Dependencies  
- Wrapped `fetchBrokers` functions in `useCallback` to prevent infinite re-renders
- Added proper dependencies to useEffect arrays

### 3. Fixed TypeScript Warnings
- Removed useless constructor in setupTests.ts
- Commented out unused XMTP environment code

## Prevention Tools

### 1. Local CI Linting Script
```bash
# Run this before committing to catch issues early
cd client && npm run lint:ci
```

This script runs ESLint with the same configuration as CI (warnings as errors).

### 2. Pre-commit Hook (Optional)
A pre-commit hook has been created at `.husky/pre-commit` that automatically runs lint:ci before each commit.

To enable it:
```bash
# Install husky (if not already installed)
npm install --save-dev husky

# Initialize husky
npx husky install

# The pre-commit hook should now run automatically
```

## Best Practices

### 1. Remove Unused Code Immediately
- Remove unused imports as soon as you see them
- Delete commented-out code that's no longer needed
- Remove unused state variables and functions

### 2. Fix useEffect Dependencies
- Always include all dependencies in useEffect arrays
- Use `useCallback` for functions that are dependencies
- Consider moving functions inside useEffect if they're only used there

### 3. Regular Linting
- Run `npm run lint` frequently during development
- Use `npm run lint -- --fix` to auto-fix simple issues
- Test with `npm run lint:ci` before pushing

### 4. IDE Configuration
Configure your IDE to show ESLint warnings/errors in real-time:

**VS Code**: Install the ESLint extension
**WebStorm**: ESLint is built-in

## Common ESLint Rules

| Rule | Fix |
|------|-----|
| `@typescript-eslint/no-unused-vars` | Remove or prefix with `_` |
| `react-hooks/exhaustive-deps` | Add to dependency array or use `useCallback` |
| `@typescript-eslint/no-useless-constructor` | Remove empty constructor |

## Troubleshooting

### "Function makes dependencies change on every render"
```typescript
// ❌ Bad - function recreated on every render
const fetchData = async () => { /* ... */ };

// ✅ Good - memoized function
const fetchData = useCallback(async () => { 
  /* ... */ 
}, [dependency1, dependency2]);
```

### "Variable is assigned but never used"
```typescript
// ❌ Bad - unused variable
const [data, setData] = useState();

// ✅ Good - remove unused
const [data] = useState();
// or comment out if temporarily needed
// const [data, setData] = useState();
```

## Summary

The CI linting failure has been completely resolved by:
1. ✅ Fixing all ESLint warnings across 4 files
2. ✅ Creating a `lint:ci` script that matches CI behavior  
3. ✅ Adding a pre-commit hook to prevent future issues
4. ✅ Documenting prevention strategies

**No more CI failures due to ESLint warnings!** 🎉
