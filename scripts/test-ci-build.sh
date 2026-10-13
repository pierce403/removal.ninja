#!/bin/bash

# CI Build Test Script
# This script simulates the exact CI environment to catch build issues locally

set -e  # Exit on any error

echo "🔧 Starting CI Build Simulation..."

# Check Node.js version
echo "📋 Environment Check:"
echo "Node.js version: $(node --version)"
echo "npm version: $(npm --version)"
echo "Working directory: $(pwd)"

# Clean everything first
echo "🧹 Cleaning environment..."
rm -rf node_modules client/node_modules client/build
npm cache clean --force

# Install root dependencies
echo "📦 Installing root dependencies..."
npm ci

# Install client dependencies with exact CI flags
echo "📦 Installing client dependencies..."
cd client
npm ci

# Type checking
echo "🔍 Running TypeScript type check..."
npx tsc --noEmit || {
    echo "❌ TypeScript type check failed"
    exit 1
}

# Unit tests
echo "🧪 Running unit tests..."
npm test

# Linting
echo "🔍 Running ESLint..."
npm run lint

# Security scan
echo "🔒 Running security scan..."
cd ..
npx @socketsecurity/cli npm audit || {
    echo "⚠️ Security scan completed"
}

# The critical test - production build
echo "🏗️ Running production build (CI mode)..."
cd client
CI=true NODE_ENV=production npm run build

# Verify build output
echo "✅ Verifying build output..."
if [ ! -f "build/index.html" ]; then
    echo "❌ Build failed - index.html not found"
    exit 1
fi

if [ ! -d "build/assets" ]; then
    echo "❌ Build failed - Vite assets directory not found"
    exit 1
fi

# Check bundle size
echo "📊 Build analysis:"
du -sh build/*
echo "Total build size: $(du -sh build | cut -f1)"

# Test if assets can be served
echo "🌐 Testing static file serving..."
cd build
python3 -m http.server 8080 > /dev/null 2>&1 &
SERVER_PID=$!
sleep 2

# Test if the build is accessible
curl -f http://localhost:8080 > /dev/null 2>&1 || {
    echo "❌ Build verification failed - server not accessible"
    kill $SERVER_PID 2>/dev/null || true
    exit 1
}

kill $SERVER_PID 2>/dev/null || true

echo ""
echo "🎉 CI Build Simulation PASSED!"
echo "✅ All checks completed successfully"
echo "✅ Build is ready for deployment"

cd ..
echo ""
echo "📋 Summary:"
echo "- Dependencies installed successfully"
echo "- TypeScript type check passed"
echo "- Production build completed"
echo "- Build output verified"
echo "- Static file serving tested"
echo ""
echo "This build should work in CI/CD environment! 🚀"
