# Connecting Hearts - Flutter Mobile App

A complete Flutter mobile application converted from the React Native and React Web app for the Connecting Hearts matrimony platform.

## Features

### Authentication
- ✅ Login with phone number and password
- ✅ Registration with OTP verification
- ✅ Forgot password with OTP reset
- ✅ Secure token storage

### Dashboard
- ✅ User profile summary
- ✅ Daily recommendations
- ✅ Profile visitors
- ✅ Statistics cards (Just Joined, Acceptance, etc.)

### Profile Management
- ✅ View own profile with all sections
- ✅ Edit profile (Basic, About, Education, Career, Family, Contact, Horoscope, Lifestyle)
- ✅ Upload/delete profile photos
- ✅ Delete profile

### Profile Browsing
- ✅ All Profiles
- ✅ Daily Recommendations
- ✅ Daily Picks
- ✅ Just Joined
- ✅ Profile Visitors

### Search
- ✅ Search by Profile ID (HEARTS-XXXXX)
- ✅ Advanced search with filters:
  - Country, State, City
  - Religion, Mother Tongue
  - Marital Status
  - Age, Height, Income ranges

### Profile Actions
- ✅ Send/Withdraw Interest
- ✅ Accept/Decline Interest
- ✅ Shortlist/Unshortlist
- ✅ Ignore/Unignore
- ✅ Block/Unblock
- ✅ Unlock Profile (Contact Details)

### Profile Lists
- ✅ Interests Received
- ✅ Interests Sent
- ✅ Shortlisted Profiles
- ✅ Ignored Profiles
- ✅ Blocked Profiles
- ✅ Acceptance (Accepted Me / Accepted By Me)
- ✅ I Declined / They Declined

### Profile Detail View
- ✅ Image carousel with navigation
- ✅ Basic Details tab
- ✅ Family Details tab
- ✅ Kundali & Lifestyle tab
- ✅ Match Compatibility tab
- ✅ Contact details (for unlocked profiles)
- ✅ Action buttons (Interest, Contact, Shortlist, Ignore, Chat)

### Membership
- ✅ View membership plans
- ✅ Active membership status
- ✅ Heart coins balance
- ✅ Purchase membership (Razorpay ready)

### Settings
- ✅ Change Password
- ✅ Delete Profile
- ✅ Help Center
- ✅ Feedback
- ✅ Terms & Conditions
- ✅ Privacy Policy

### UI/UX
- ✅ Light and Dark theme support
- ✅ Responsive design
- ✅ Pull-to-refresh
- ✅ Loading states
- ✅ Error handling
- ✅ Empty states
- ✅ Toast notifications

## Project Structure

```
lib/
├── config/
│   └── api_config.dart          # API endpoints configuration
├── models/
│   ├── api_models.dart          # Auth-related models
│   └── profile_models.dart      # Profile-related models
├── navigation/
│   └── app_router.dart          # GoRouter navigation setup
├── providers/
│   ├── auth_provider.dart       # Authentication state
│   ├── lookup_provider.dart     # Lookup data (religions, etc.)
│   └── theme_provider.dart      # Theme management
├── screens/
│   ├── acceptance/              # Acceptance screen
│   ├── auth/                    # Login, Register, Forgot Password
│   ├── daily_picks/             # Daily picks screen
│   ├── dashboard/               # Main dashboard
│   ├── feedback/                # Feedback screen
│   ├── interests/               # Interests received/sent
│   ├── legal/                   # Terms, Privacy Policy
│   ├── membership/              # Membership plans
│   ├── my_profile/              # User's own profile
│   ├── notifications/           # Notifications
│   ├── profile_actions/         # Shortlisted, Blocked, Ignored
│   ├── profile_detail/          # Profile detail view
│   ├── profile_lists/           # Generic profile list
│   ├── profiles/                # All profiles
│   ├── search/                  # Search & results
│   └── settings/                # Change password, Delete, Help
├── services/
│   ├── api_client.dart          # HTTP client with auth
│   ├── auth_service.dart        # Auth API calls
│   ├── lookup_service.dart      # Lookup API calls
│   ├── membership_service.dart  # Membership API calls
│   ├── profile_service.dart     # Profile API calls
│   └── storage_service.dart     # Secure storage
├── theme/
│   ├── app_theme.dart           # Theme data
│   └── colors.dart              # Color constants
├── utils/
│   ├── constants.dart           # App constants
│   └── profile_utils.dart       # Profile utilities
├── widgets/
│   ├── common/                  # Reusable widgets
│   └── profile/                 # Profile-related widgets
└── main.dart                    # App entry point
```

## Setup

### Prerequisites
- Flutter SDK 3.0.0 or higher
- Dart SDK 3.0.0 or higher
- Android Studio / VS Code with Flutter extensions
- Android SDK (for Android builds)
- Xcode (for iOS builds, macOS only)

### Installation

1. Clone the repository
2. Navigate to the Flutter project:
   ```bash
   cd connectingheart-Mobile-Flutter
   ```

3. Install dependencies:
   ```bash
   flutter pub get
   ```

4. Run the app:
   ```bash
   # Debug mode
   flutter run
   
   # Release mode
   flutter run --release
   ```

### Build

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS (macOS only)
flutter build ios --release
```

## API Configuration

The app connects to the Connecting Hearts backend API. Configuration is in `lib/config/api_config.dart`:

```dart
class ApiConfig {
  static const String apiBaseUrl = 'https://backendapp.connectingheart.co.in/api';
  static const String backendBaseUrl = 'https://backendapp.connectingheart.co.in';
}
```

## Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| provider | ^6.1.1 | State management |
| go_router | ^13.0.0 | Navigation |
| http | ^1.1.2 | HTTP requests |
| flutter_secure_storage | ^9.0.0 | Secure token storage |
| shared_preferences | ^2.2.2 | Local preferences |
| cached_network_image | ^3.3.0 | Image caching |
| image_picker | ^1.0.4 | Photo selection |
| carousel_slider | ^4.2.1 | Image carousels |
| intl | ^0.18.1 | Date/number formatting |

## API Endpoints Used

### Authentication
- `POST /auth/login` - Login
- `POST /auth/signup` - Registration
- `POST /auth/generateOTP` - Generate OTP
- `POST /auth/verifyOTP` - Verify OTP
- `POST /auth/changePassword` - Change password
- `POST /auth/forgotPassword` - Forgot password
- `POST /auth/resetPassword` - Reset password
- `GET /auth/validateToken` - Validate token
- `GET /auth/searchByProfileID/:id` - Search by profile ID

### Profiles
- `GET /dashboard/getAllProfiles` - All profiles
- `GET /interest/getDailyRecommendations` - Daily recommendations
- `GET /dashboard/getProfileVisitors` - Profile visitors
- `GET /dashboard/getjustJoined` - Just joined profiles
- `GET /profile/getProfileDetail/:id` - Profile details
- `GET /profile/getMyProfileData` - Own profile data
- `POST /profile/searchProfiles` - Search profiles

### Profile Actions
- `POST /interest/sendInterest` - Send interest
- `POST /interest/unsendInterest` - Withdraw interest
- `POST /interest/updateInterest` - Accept/decline interest
- `GET /dashboard/shortlist/:id` - Shortlist profile
- `GET /dashboard/unshortlist/:id` - Unshortlist profile
- `GET /dashboard/ignoreProfile/:id` - Ignore profile
- `GET /dashboard/unIgnoreProfile/:id` - Unignore profile
- `GET /dashboard/blockprofile/:id` - Block profile
- `GET /dashboard/unblockprofile/:id` - Unblock profile
- `POST /profile/unlockProfile` - Unlock profile

### Profile Lists
- `GET /interest/getInterests` - Interests received
- `GET /dashboard/getMyInterestedProfiles` - Interests sent
- `GET /dashboard/getMyShortlistedProfiles` - Shortlisted
- `GET /dashboard/getAllIgnoredProfiles` - Ignored
- `GET /dashboard/getMyBlockedProfiles` - Blocked
- `GET /dashboard/getAcceptanceProfiles/:type` - Acceptance

### Membership
- `GET /dashboard/getMembershipList` - Get plans
- `GET /dashboard/getMyMembershipDetails` - My membership
- `POST /dashboard/buyMembership` - Buy membership
- `POST /dashboard/verifyPayment` - Verify payment

### Lookup
- `GET /lookup/getLookup` - All lookups
- `GET /lookup/getCountries` - Countries
- `GET /lookup/getStates/:countryId` - States
- `GET /lookup/getCities/:stateId` - Cities

## License

Proprietary - Connecting Hearts
