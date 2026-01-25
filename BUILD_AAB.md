# How to Build AAB File for Google Play Store

## Prerequisites
1. ✅ Signing key configured (key.properties file exists)
2. ✅ Flutter SDK installed
3. ✅ Android build tools installed

## Steps to Build AAB

### 1. Update Version (if needed)
Edit `pubspec.yaml`:
```yaml
version: 1.0.1+2  # Format: versionName+versionCode
```

### 2. Clean Previous Builds
```bash
flutter clean
```

### 3. Get Dependencies
```bash
flutter pub get
```

### 4. Build AAB File
```bash
flutter build appbundle --release
```

### 5. Find Your AAB File
The AAB file will be located at:
```
build/app/outputs/bundle/release/app-release.aab
```

## Alternative: Build with Specific Build Number
```bash
flutter build appbundle --release --build-number=2
```

## Verify AAB File
You can check the AAB file details:
```bash
bundletool build-apks --bundle=build/app/outputs/bundle/release/app-release.aab --output=app.apks
```

## Upload to Play Store
1. Go to Google Play Console
2. Select your app
3. Go to "Production" or "Testing" track
4. Click "Create new release"
5. Upload the `app-release.aab` file
6. Fill in release notes
7. Review and publish

## Troubleshooting

### If signing fails:
- Check `android/key.properties` file exists
- Verify all signing properties are correct:
  - `storeFile`
  - `keyAlias`
  - `storePassword`
  - `keyPassword`

### If build fails:
- Run `flutter doctor` to check setup
- Ensure Android SDK is properly configured
- Check `android/local.properties` has correct SDK path
