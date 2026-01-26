# App Version Update & Release Guide

## Complete Flow: Development → Play Store/App Store

---

## Step 1: Update Version Number

### In `pubspec.yaml`:

```yaml
version: 1.0.0+2
```

**Format:** `MAJOR.MINOR.PATCH+BUILD_NUMBER`

- **1.0.0** = Version Name (user sees this)
- **+2** = Build Number (internal, must increase)

**Example Updates:**
- Bug fix: `1.0.0+2` → `1.0.1+3`
- New feature: `1.0.1+3` → `1.1.0+4`
- Major update: `1.1.0+4` → `2.0.0+5`

**Rules:**
- Build number (+2) MUST always increase
- Version name can be anything
- Play Store/App Store checks build number

---

## Step 2: Clean & Build

### Clean previous builds:
```bash
flutter clean
flutter pub get
```

### For Android (APK):
```bash
flutter build apk --release
```

**Output:** `build/app/outputs/flutter-apk/app-release.apk`

### For Android (App Bundle - Play Store):
```bash
flutter build appbundle --release
```

**Output:** `build/app/outputs/bundle/release/app-release.aab`

### For iOS:
```bash
flutter build ios --release
```

---

## Step 3: Test the Build

### Install APK on device:
```bash
flutter install
```

### Or manually:
1. Copy APK to phone
2. Install and test
3. Check all features work
4. Verify version number in app

---

## Step 4: Upload to Play Store (Android)

### A. First Time Setup:

1. **Create Play Console Account**
   - Go to: https://play.google.com/console
   - Pay $25 one-time fee
   - Complete registration

2. **Create App**
   - Click "Create app"
   - Fill app details
   - Set up store listing

3. **Generate Signing Key** (if not done):
   ```bash
   keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

4. **Configure Signing** in `android/key.properties`:
   ```properties
   storePassword=your_password
   keyPassword=your_password
   keyAlias=upload
   storeFile=path/to/upload-keystore.jks
   ```

### B. Upload New Version:

1. **Build App Bundle:**
   ```bash
   flutter build appbundle --release
   ```

2. **Go to Play Console:**
   - Select your app
   - Click "Production" (or "Internal testing" for testing)
   - Click "Create new release"

3. **Upload AAB:**
   - Upload `app-release.aab`
   - Add release notes
   - Click "Review release"
   - Click "Start rollout to Production"

4. **Wait for Review:**
   - Usually takes 1-3 days
   - Check email for approval/rejection

---

## Step 5: Upload to App Store (iOS)

### A. First Time Setup:

1. **Apple Developer Account**
   - Go to: https://developer.apple.com
   - Pay $99/year
   - Complete registration

2. **Create App in App Store Connect**
   - Go to: https://appstoreconnect.apple.com
   - Click "My Apps" → "+"
   - Fill app details

3. **Configure Xcode:**
   - Open `ios/Runner.xcworkspace` in Xcode
   - Select team
   - Configure signing

### B. Upload New Version:

1. **Build iOS:**
   ```bash
   flutter build ios --release
   ```

2. **Open in Xcode:**
   ```bash
   open ios/Runner.xcworkspace
   ```

3. **Archive:**
   - Product → Archive
   - Wait for build to complete

4. **Upload to App Store:**
   - Window → Organizer
   - Select archive
   - Click "Distribute App"
   - Choose "App Store Connect"
   - Follow wizard

5. **Submit for Review:**
   - Go to App Store Connect
   - Select your app
   - Add screenshots, description
   - Submit for review

6. **Wait for Review:**
   - Usually takes 1-2 days
   - Check email for approval/rejection

---

## Version Update Checklist

### Before Building:
- [ ] Update version in `pubspec.yaml`
- [ ] Increase build number
- [ ] Test app thoroughly
- [ ] Update changelog/release notes
- [ ] Check all features work
- [ ] Test on multiple devices

### Android Release:
- [ ] Run `flutter clean`
- [ ] Run `flutter pub get`
- [ ] Build app bundle: `flutter build appbundle --release`
- [ ] Test APK on device
- [ ] Upload to Play Console
- [ ] Add release notes
- [ ] Submit for review

### iOS Release:
- [ ] Run `flutter clean`
- [ ] Run `flutter pub get`
- [ ] Build iOS: `flutter build ios --release`
- [ ] Archive in Xcode
- [ ] Upload to App Store Connect
- [ ] Add screenshots & description
- [ ] Submit for review

---

## Common Issues & Solutions

### Issue 1: "Version code already exists"
**Solution:** Increase build number in `pubspec.yaml`
```yaml
version: 1.0.0+3  # Increase +3 to +4
```

### Issue 2: "Signing key not found"
**Solution:** Check `android/key.properties` exists and is correct

### Issue 3: "Build failed"
**Solution:** 
```bash
flutter clean
flutter pub get
flutter build appbundle --release
```

### Issue 4: "App not installing"
**Solution:** Uninstall old version first, then install new one

---

## Quick Commands Reference

```bash
# Update version (manual in pubspec.yaml)
# version: 1.0.0+2 → 1.0.1+3

# Clean & prepare
flutter clean
flutter pub get

# Build Android APK
flutter build apk --release

# Build Android App Bundle (Play Store)
flutter build appbundle --release

# Build iOS
flutter build ios --release

# Install on connected device
flutter install

# Check version
flutter --version
```

---

## Version Naming Convention

### Semantic Versioning: MAJOR.MINOR.PATCH

**MAJOR (1.x.x):**
- Breaking changes
- Complete redesign
- Major new features

**MINOR (x.1.x):**
- New features
- Non-breaking changes
- Improvements

**PATCH (x.x.1):**
- Bug fixes
- Small improvements
- Security patches

**Examples:**
- `1.0.0` → Initial release
- `1.0.1` → Bug fix
- `1.1.0` → New feature added
- `2.0.0` → Major redesign

---

## Release Notes Template

```
Version 1.0.1 (Build 3)

What's New:
- Added dark mode support
- Improved profile loading speed
- Fixed login issue

Bug Fixes:
- Fixed crash on splash screen
- Resolved image upload error
- Fixed notification badge count

Improvements:
- Better error messages
- Faster app startup
- Optimized memory usage
```

---

## Important Notes

1. **Always increase build number** - Play Store/App Store won't accept same build number
2. **Test before uploading** - Can't undo after submission
3. **Keep signing keys safe** - Losing them means you can't update your app
4. **Review takes time** - Plan releases in advance
5. **Read rejection reasons** - Fix issues and resubmit

---

## Your Current Version

```yaml
version: 1.0.0+2
```

**Next update should be:** `1.0.1+3` or higher

---

## Summary

1. ✅ Update version in `pubspec.yaml`
2. ✅ Clean & build: `flutter clean && flutter build appbundle --release`
3. ✅ Test the build
4. ✅ Upload to Play Console/App Store Connect
5. ✅ Add release notes
6. ✅ Submit for review
7. ✅ Wait for approval (1-3 days)
8. ✅ App goes live!

**Remember:** Build number must ALWAYS increase! 🚀
