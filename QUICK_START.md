# Quick Start Guide - Running Flutter from VS Code

## ⚠️ Common Mistake

**"Flutter: Run Flutter"** is a **VS Code Command Palette command**, NOT a terminal command!

- ❌ **Wrong in Terminal:** `Flutter: Run Flutter` 
- ✅ **Correct in Terminal:** `flutter run`

## Two Ways to Run Flutter

### Method 1: Using VS Code (Easiest)

1. **Open Command Palette:** Press `Ctrl+Shift+P` (Windows/Linux) or `Cmd+Shift+P` (Mac)
2. **Type:** `Flutter: Run Flutter` or `Flutter: Select Device`
3. **Select your device** from the list
4. **Press F5** to start debugging

### Method 2: Using Terminal/PowerShell

#### First, make sure Flutter is in your PATH:

1. **Check if Flutter is installed:**
   ```powershell
   flutter --version
   ```

2. **If not found, add Flutter to PATH:**
   - Find your Flutter installation (usually `C:\src\flutter\bin` or similar)
   - Add it to Windows Environment Variables:
     - Right-click "This PC" → Properties → Advanced System Settings
     - Click "Environment Variables"
     - Under "System Variables", find "Path" → Edit
     - Add your Flutter `bin` folder path
     - Restart VS Code/PowerShell

#### Then use these commands:

**Check available devices:**
```powershell
flutter devices
```

**Run on connected device:**
```powershell
flutter run
```

**Run on specific device (if multiple connected):**
```powershell
flutter run -d <device-id>
```

**Get device ID:**
```powershell
flutter devices
# Output example:
# iPhone 14 Pro (mobile) • 00008030-001A... • ios • iOS 16.0
# Chrome (web)            • chrome           • web-javascript
```

**Example:**
```powershell
flutter run -d chrome
```

## Connecting Your Phone Wirelessly (Android)

1. **Connect via USB first:**
   ```powershell
   adb devices
   ```

2. **Enable Wireless Debugging on your phone:**
   - Settings → Developer Options → Wireless debugging
   - Note the IP and port (e.g., `192.168.1.100:5555`)

3. **Connect wirelessly:**
   ```powershell
   adb connect 192.168.1.100:5555
   ```

4. **Verify connection:**
   ```powershell
   flutter devices
   ```

5. **Disconnect USB** - Now run wirelessly:
   ```powershell
   flutter run
   ```

## Troubleshooting

### Flutter command not found?

**Option 1: Use full path**
```powershell
C:\src\flutter\bin\flutter.exe run
```
(Replace with your actual Flutter path)

**Option 2: Add to PATH** (see above)

**Option 3: Use VS Code Command Palette** (Method 1) - This works even if Flutter isn't in PATH!

### No devices found?

1. **For Android:**
   - Enable USB Debugging in Developer Options
   - Connect via USB
   - Run `adb devices` to verify

2. **For iOS (Mac only):**
   - Connect iPhone via USB
   - Trust the computer on your phone
   - Open Xcode once to set up certificates

### Check Flutter setup:
```powershell
flutter doctor
```

This will show what's missing or needs configuration.

## Quick Reference

| Action | VS Code Command Palette | Terminal Command |
|--------|------------------------|------------------|
| Run app | `Flutter: Run Flutter` | `flutter run` |
| Select device | `Flutter: Select Device` | `flutter devices` then `flutter run -d <id>` |
| Check devices | N/A | `flutter devices` |
| Check setup | N/A | `flutter doctor` |
| Hot reload | Press `r` in terminal | Press `r` in terminal |
| Hot restart | Press `R` in terminal | Press `R` in terminal |
| Quit | Press `q` in terminal | Press `q` in terminal |


