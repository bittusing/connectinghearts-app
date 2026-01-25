# Flutter Development Commands Guide

## Essential Flutter Commands

### 1. Check Flutter Installation
```bash
flutter doctor
```
Shows the status of your Flutter installation and any missing dependencies.

### 2. Get Dependencies
```bash
flutter pub get
```
Downloads all the packages listed in `pubspec.yaml`. Run this after adding new dependencies.

### 3. Clean Build
```bash
flutter clean
```
Removes build artifacts and cached files. Use when facing build issues.

---

## Running the App

### 4. Run App (Basic)
```bash
flutter run
```
Builds and runs the app on connected device/emulator.

### 5. Run with Hot Reload (RECOMMENDED)
```bash
flutter run
```
**Hot Reload Features:**
- Press `r` in terminal - Hot reload (reflects most changes instantly)
- Press `R` in terminal - Hot restart (full app restart)
- Press `q` - Quit the app

**Auto Hot Reload on Save:**
When you run `flutter run`, Flutter automatically watches for file changes. When you save a file (Ctrl+S), it will automatically hot reload!

### 6. Run on Specific Device
```bash
# List all connected devices
flutter devices

# Run on specific device
flutter run -d <device-id>

# Examples:
flutter run -d chrome          # Run on Chrome browser
flutter run -d windows         # Run on Windows desktop
flutter run -d emulator-5554   # Run on Android emulator
```

### 7. Run in Release Mode
```bash
flutter run --release
```
Optimized build for testing performance.

---

## Development Modes

### 8. Debug Mode (Default)
```bash
flutter run
```
- Hot reload enabled
- Debugging tools available
- Slower performance

### 9. Profile Mode
```bash
flutter run --profile
```
- Performance profiling
- Some debugging features
- Better performance than debug

### 10. Release Mode
```bash
flutter run --release
```
- No debugging
- Best performance
- Optimized build

---

## Building the App

### 11. Build APK (Android)
```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# Split APKs by ABI (smaller size)
flutter build apk --split-per-abi
```

### 12. Build App Bundle (Android - for Play Store)
```bash
flutter build appbundle --release
```

### 13. Build for Windows
```bash
flutter build windows --release
```

### 14. Build for Web
```bash
flutter build web --release
```

---

## Testing & Analysis

### 15. Run Tests
```bash
flutter test
```

### 16. Analyze Code
```bash
flutter analyze
```
Checks for code issues, warnings, and errors.

### 17. Format Code
```bash
# Format all Dart files
flutter format .

# Format specific file
flutter format lib/main.dart
```

---

## Package Management

### 18. Add Package
```bash
flutter pub add <package_name>

# Example:
flutter pub add http
flutter pub add provider
```

### 19. Remove Package
```bash
flutter pub remove <package_name>
```

### 20. Upgrade Packages
```bash
# Upgrade all packages
flutter pub upgrade

# Upgrade specific package
flutter pub upgrade <package_name>
```

### 21. Show Outdated Packages
```bash
flutter pub outdated
```

---

## Useful Development Commands

### 22. Generate Icons
```bash
flutter pub run flutter_launcher_icons
```

### 23. Generate Splash Screen
```bash
flutter pub run flutter_native_splash:create
```

### 24. Clear Cache
```bash
flutter pub cache clean
flutter pub cache repair
```

### 25. Check App Size
```bash
flutter build apk --analyze-size
flutter build appbundle --analyze-size
```

---

## Hot Reload vs Hot Restart

### Hot Reload (Press `r`)
- **Fast** - Takes milliseconds
- Preserves app state
- Updates UI changes
- Updates method implementations
- **Use for:** UI changes, logic updates

### Hot Restart (Press `R`)
- **Slower** - Takes a few seconds
- Resets app state
- Rebuilds entire widget tree
- **Use for:** Adding new files, changing app initialization

### Full Restart (Press `q` then `flutter run`)
- **Slowest** - Full rebuild
- **Use for:** Changing dependencies, native code changes, pubspec.yaml changes

---

## Auto Reload Setup (RECOMMENDED WORKFLOW)

### Option 1: Using Flutter Run (Built-in)
```bash
cd connectingheart-Mobile-Flutter
flutter run
```
**This is the BEST option!**
- Automatically watches for file changes
- Hot reloads when you save (Ctrl+S)
- No additional setup needed

### Option 2: VS Code Extension
1. Install "Flutter" extension in VS Code
2. Press F5 or click "Run > Start Debugging"
3. Auto hot reload on save is enabled by default

### Option 3: Android Studio
1. Click "Run" button
2. Auto hot reload on save is enabled by default

---

## Common Issues & Solutions

### Issue: Changes not reflecting
```bash
# Try hot restart
Press R in terminal

# If still not working, full restart
Press q
flutter run
```

### Issue: Build errors after adding package
```bash
flutter clean
flutter pub get
flutter run
```

### Issue: Gradle build fails (Android)
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

### Issue: "Waiting for another flutter command to release the startup lock"
```bash
# Delete the lock file
# Windows:
del %LOCALAPPDATA%\flutter\.flutter_lock

# Linux/Mac:
rm ~/.flutter_lock
```

---

## Quick Reference for Your Project

### Daily Development Workflow:
```bash
# 1. Navigate to project
cd connectingheart-Mobile-Flutter

# 2. Start the app (ONE TIME)
flutter run

# 3. Make changes in your code editor
# 4. Save file (Ctrl+S) - Auto hot reload happens!
# 5. If needed, press 'r' for manual hot reload
# 6. If needed, press 'R' for hot restart
# 7. Press 'q' to quit when done
```

### After Adding New Package:
```bash
flutter pub get
# Then restart the app (press q, then flutter run)
```

### Before Committing Code:
```bash
flutter analyze
flutter format .
flutter test
```

### Building Release APK:
```bash
flutter build apk --release --split-per-abi
```

---

## Pro Tips

1. **Keep `flutter run` running** - Don't stop and restart unnecessarily
2. **Use hot reload (r)** for most changes - It's instant!
3. **Use hot restart (R)** when hot reload doesn't work
4. **Full restart only** when changing dependencies or native code
5. **Run `flutter doctor`** regularly to check for issues
6. **Use `flutter analyze`** before committing code

---

## Keyboard Shortcuts in Flutter Run

| Key | Action |
|-----|--------|
| `r` | Hot reload |
| `R` | Hot restart |
| `h` | List all available commands |
| `c` | Clear the screen |
| `q` | Quit |
| `d` | Detach (leave app running) |
| `s` | Save screenshot |
| `w` | Dump widget hierarchy |
| `t` | Dump rendering tree |
| `L` | Dump layer tree |
| `S` | Dump accessibility tree |
| `U` | Dump semantics tree |
| `i` | Toggle widget inspector |
| `p` | Toggle performance overlay |
| `P` | Toggle platform |
| `o` | Simulate different OS |
| `b` | Toggle brightness |

---

## Your Project Specific Commands

### Run on Windows (Your current platform):
```bash
cd connectingheart-Mobile-Flutter
flutter run -d windows
```

### Run on Chrome (for web testing):
```bash
cd connectingheart-Mobile-Flutter
flutter run -d chrome
```

### Build for Android:
```bash
cd connectingheart-Mobile-Flutter
flutter build apk --release
```

The APK will be at: `build/app/outputs/flutter-apk/app-release.apk`

---

**Remember: `flutter run` with auto hot reload is your best friend for development! Just save your files and changes will reflect automatically.** 🚀
