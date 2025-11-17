#!/bin/bash

echo "🔍 Running Lighthouse audit..."

# Start preview server in background
npm run preview &
SERVER_PID=$!

# Wait for server to start
echo "⏳ Waiting for server to start..."
sleep 5

# Run Lighthouse
echo "🚀 Running audit on http://localhost:4173"
npx lighthouse http://localhost:4173 \
  --output=html \
  --output-path=./lighthouse-report.html \
  --chrome-flags="--headless" \
  --only-categories=performance,accessibility,best-practices,seo

# Kill preview server
kill $SERVER_PID

echo ""
echo "✅ Lighthouse report saved to lighthouse-report.html"
echo ""
echo "📊 Target scores:"
echo "   Performance:    > 90"
echo "   Accessibility:  > 95"
echo "   Best Practices: > 95"
echo "   SEO:            > 90"
echo ""
echo "Open the report:"
echo "   open lighthouse-report.html"
