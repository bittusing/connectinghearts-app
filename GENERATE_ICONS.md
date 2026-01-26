# Generate App Icons

To generate app icons from the Gemini generated image, run these commands:

```bash
cd d:\conn\connectingheart-Mobile-Flutter
flutter pub get
flutter pub run flutter_launcher_icons
```

After running these commands:
1. The app icons will be generated for Android and iOS
2. You may need to rebuild the app for the new icon to appear:
   - For Android: `flutter run` or rebuild the APK
   - For iOS: Clean build folder and rebuild

**Note:** If the icon doesn't appear immediately:
- Uninstall the app from your device
- Rebuild and reinstall the app
- The icon should now show the new Gemini generated image instead of Flutter default logo
