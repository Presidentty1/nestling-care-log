# Viewing App Logs in Xcode

## To See Console Logs (JavaScript Errors):

1. **In Xcode**, make sure the app is running on your device
2. At the **bottom of Xcode**, click the **"Debug Area"** button (or press **Cmd+Shift+Y**)
3. You'll see two panes:
   - **Left**: Console output (JavaScript logs, errors)
   - **Right**: Variables/debugger
4. Look for errors in red - these will tell you what's wrong

## Common Issues to Check:

### 1. JavaScript Errors
- Look for red error messages in the console
- Common: "Failed to load resource", "Module not found", etc.

### 2. Network Errors
- Check if assets are loading: Look for 404 errors
- Assets should load from `capacitor://localhost/assets/...`

### 3. Capacitor Bridge Issues
- Look for "Capacitor" related errors
- Should see "Capacitor initialized" message

## Alternative: Safari Web Inspector (Better for Web Debugging)

1. On your **Mac**: Open **Safari**
2. Go to **Safari → Settings → Advanced**
3. Check **"Show Develop menu in menu bar"**
4. Connect your iPhone via USB
5. In Safari: **Develop → [Your iPhone Name] → [App Name]**
6. This opens Web Inspector with full console, network, and debugging tools

## Quick Check Commands

In Xcode console, you can also type:
- Look for any red error messages
- Check if you see "Capacitor initialized"
- Check for any 404 or network errors
