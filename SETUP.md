# Setup Guide - Connecting Hearts Flutter App

## Prerequisites

1. **Flutter SDK**: Install Flutter SDK (version 3.0.0 or higher)
   - Download from: https://flutter.dev/docs/get-started/install
   - Verify installation: `flutter doctor`

2. **IDE**: 
   - Android Studio / IntelliJ IDEA (recommended)
   - VS Code with Flutter extensions

3. **Platform Setup**:
   - **Android**: Android Studio with Android SDK
   - **iOS**: Xcode (macOS only)

## Installation Steps

### 1. Clone/Navigate to Project
```bash
cd connectingheart-Mobile-Flutter
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Run Flutter Doctor
```bash
flutter doctor
```
Fix any issues reported.

### 4. Configure API Endpoints
The API endpoints are configured in `lib/config/api_config.dart`. 
Default values:
- Base URL: `https://backendapp.connectingheart.co.in/api`
- Backend URL: `https://backendapp.connectingheart.co.in`

### 5. Run the App

#### Android
```bash
flutter run
# Or for specific device
flutter run -d <device-id>
```

#### iOS (macOS only)
```bash
flutter run
# Or for specific device
flutter run -d <device-id>
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── config/
│   └── api_config.dart      # API configuration
├── models/
│   ├── api_models.dart      # API request/response models
│   └── profile_models.dart  # Profile related models
├── services/
│   ├── api_client.dart      # HTTP client
│   ├── auth_service.dart    # Authentication service
│   ├── profile_service.dart  # Profile operations
│   ├── membership_service.dart # Membership operations
│   └── storage_service.dart # Secure storage
├── providers/
│   ├── auth_provider.dart   # Auth state management
│   └── theme_provider.dart  # Theme state management
├── screens/
│   ├── auth/
│   │   └── login_screen.dart
│   ├── dashboard/
│   │   └── dashboard_screen.dart
│   ├── search/
│   ├── profiles/
│   ├── membership/
│   └── daily_picks/
├── widgets/                 # Reusable widgets
├── theme/
│   ├── app_theme.dart       # Theme configuration
│   └── colors.dart          # Color constants
├── navigation/
│   └── app_router.dart      # Navigation setup
└── utils/
    ├── constants.dart       # App constants
    └── profile_utils.dart   # Profile utilities
```

## Key Features

### Authentication
- Login with phone number and password
- OTP-based authentication
- Token-based session management
- Secure token storage

### Profile Management
- View daily recommendations
- Search and filter profiles
- Profile actions (interest, shortlist, block, etc.)
- Profile detail view

### Membership
- View membership plans
- Purchase membership
- Payment integration (Razorpay)

### Theme Support
- Light and dark themes
- Theme persistence

## API Integration

All API calls are handled through:
- `ApiClient`: Centralized HTTP client
- `AuthService`: Authentication endpoints
- `ProfileService`: Profile-related endpoints
- `MembershipService`: Membership endpoints

## State Management

The app uses **Provider** for state management:
- `AuthProvider`: Manages authentication state
- `ThemeProvider`: Manages theme state

## Building for Production

### Android APK
```bash
flutter build apk --release
```

### Android App Bundle
```bash
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## Troubleshooting

### Common Issues

1. **Dependencies not installing**
   ```bash
   flutter clean
   flutter pub get
   ```

2. **Build errors**
   - Check Flutter version: `flutter --version`
   - Update dependencies: `flutter pub upgrade`

3. **API connection issues**
   - Verify API endpoints in `api_config.dart`
   - Check network connectivity
   - Verify token storage

## Next Steps

1. Implement remaining screens
2. Add profile detail screen
3. Implement search functionality
4. Add payment integration
5. Add image caching
6. Implement push notifications
7. Add error handling and retry logic

## Support

For issues or questions, refer to:
- Flutter Documentation: https://flutter.dev/docs
- API Documentation: See `API_INTEGRATION_DOCUMENTATION.md` in parent directory

