#!/bin/bash
# Script to help capture Xcode console output

echo "=== Xcode Console Log Capture ==="
echo ""
echo "Since the app is running, here's how to see the logs:"
echo ""
echo "1. IN XCODE (Easiest):"
echo "   - Make sure app is running on your iPhone"
echo "   - Press Cmd+Shift+Y to open Debug Area"
echo "   - Look at the bottom console pane"
echo "   - Copy any red error messages you see"
echo ""
echo "2. SAFARI WEB INSPECTOR (Best for JavaScript errors):"
echo "   - Connect iPhone via USB"
echo "   - On Mac: Safari → Settings → Advanced → Show Develop menu"
echo "   - Safari → Develop → [Your iPhone] → nestling-care-log"
echo "   - Check Console tab for JavaScript errors"
echo "   - Check Network tab to see if assets load (look for 404s)"
echo ""
echo "3. COMMON ISSUES TO LOOK FOR:"
echo "   - 'Failed to load resource' (404 errors)"
echo "   - 'Uncaught Error' or 'Uncaught TypeError'"
echo "   - 'Capacitor is not defined'"
echo "   - 'Module not found'"
echo "   - Network requests failing"
echo ""
echo "=== Checking if assets exist ==="
if [ -f "App/public/assets/index-BZLTVvEU.js" ]; then
    echo "✅ Main JS file exists"
    ls -lh App/public/assets/index-BZLTVvEU.js
else
    echo "❌ Main JS file missing!"
fi

if [ -f "App/public/assets/index-5yfAFOFj.css" ]; then
    echo "✅ CSS file exists"
else
    echo "❌ CSS file missing!"
fi

echo ""
echo "=== Next Steps ==="
echo "Please check Xcode console (Cmd+Shift+Y) and share any errors you see."
