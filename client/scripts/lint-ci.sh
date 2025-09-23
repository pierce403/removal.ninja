#!/bin/bash

# This script runs ESLint with the same configuration as CI
# Set CI=true to treat warnings as errors (same as GitHub Actions)

echo "🔍 Running ESLint with CI configuration (warnings as errors)..."
echo "This matches the GitHub Actions environment."
echo ""

# Set CI environment variable to match GitHub Actions
export CI=true

# Change to client directory
cd "$(dirname "$0")/.."

# Run ESLint on src directory with same settings as build
echo "Checking TypeScript/React files for linting errors..."
npx eslint src --ext .ts,.tsx --max-warnings 0

exit_code=$?

if [ $exit_code -eq 0 ]; then
    echo ""
    echo "✅ All ESLint checks passed! Your code is ready for CI."
else
    echo ""
    echo "❌ ESLint found issues. Please fix them before committing."
    echo ""
    echo "💡 Tips:"
    echo "  - Remove unused imports and variables"
    echo "  - Add missing dependencies to useEffect arrays"
    echo "  - Fix TypeScript warnings"
    echo ""
    echo "Run this script again after fixing to verify:"
    echo "  ./scripts/lint-ci.sh"
fi

exit $exit_code
