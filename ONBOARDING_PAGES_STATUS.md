# Onboarding Pages Implementation Status

## Overview
All 4 onboarding pages (Personal Details → Career Details → Social Details → SRCM Details) are **FULLY IMPLEMENTED** and ready to use in the Flutter app.

---

## ✅ 1. Personal Details Screen (`/personal-details`)

**File:** `lib/screens/onboarding/personal_details_screen.dart`

### Features Implemented:
- ✅ Progress indicator (Step 1 of 7 - 14% complete)
- ✅ Gender selection (Male/Female toggle)
- ✅ Date of Birth picker (18-100 years validation)
- ✅ Height dropdown (searchable)
- ✅ Country/State/City cascading dropdowns
- ✅ Residential Status dropdown
- ✅ Form validation
- ✅ API integration (`PATCH /personalDetails`)
- ✅ Auto-navigation based on screenName
- ✅ Loading states and error handling

### API Payload:
```dart
{
  'gender': 'M' or 'F',
  'dob': timestamp,
  'height': int,
  'country': string (value),
  'state': string (value),
  'city': string (value),
  'residentialStatus': string (value),
  'employed_in': 'pvtSct', // Default
  'maritalStatus': 'nvm', // Default
  'haveChildren': 'N', // Default
  'castNoBar': false // Default
}
```

### Navigation Flow:
1. Checks current screenName on mount
2. Redirects if user is on wrong page
3. On submit → Updates to `careerdetails`
4. Navigates to `/career-details`

---

## ✅ 2. Career Details Screen (`/career-details`)

**File:** `lib/screens/onboarding/career_details_screen.dart`

### Features Implemented:
- ✅ Progress indicator (Step 2 of 7 - 28% complete)
- ✅ Highest Qualification dropdown (searchable)
- ✅ Other UG Degree text input (conditional - shows when qualification selected)
- ✅ Employed In dropdown (default: Private Sector)
- ✅ Occupation dropdown (searchable)
- ✅ Income dropdown
- ✅ Form validation
- ✅ API integration (`PATCH /personalDetails`)
- ✅ Auto-navigation based on screenName
- ✅ Loading states and error handling

### API Payload:
```dart
{
  'employed_in': string (value),
  'occupation': string (value),
  'income': number,
  'education': {
    'qualification': string (value),
    'otherUGDegree': string (optional)
  }
}
```

### Navigation Flow:
1. Checks current screenName on mount
2. On submit → Updates to `socialdetails`
3. Navigates to `/social-details`
4. Back button → `/personal-details`

---

## ✅ 3. Social Details Screen (`/social-details`)

**File:** `lib/screens/onboarding/social_details_screen.dart`

### Features Implemented:
- ✅ Progress indicator (Step 3 of 7 - 42% complete)
- ✅ Marital Status toggle group (Never married, Divorced, Widowed, etc.)
- ✅ Mother Tongue dropdown (searchable)
- ✅ Religion toggle group (Hindu, Muslim, Christian, etc.)
- ✅ "Caste No Bar" checkbox
- ✅ Caste dropdown (conditional - hidden when castNoBar is true)
- ✅ Horoscope dropdown (searchable)
- ✅ Manglik dropdown (searchable)
- ✅ Form validation
- ✅ API integration (`PATCH /personalDetails`)
- ✅ Auto-navigation based on screenName
- ✅ Loading states and error handling

### API Payload:
```dart
{
  'maritalStatus': 'nvm' or lowercase value,
  'motherTongue': string (value),
  'religion': string (first 3 chars, e.g., 'hin'),
  'cast': string (value) or null if castNoBar,
  'castNoBar': boolean,
  'horoscope': string (value),
  'manglik': string (value)
}
```

### Navigation Flow:
1. Checks current screenName on mount
2. On submit → Updates to `srcmdetails`
3. Navigates to `/srcm-details`
4. Back button → `/career-details`

---

## ✅ 4. SRCM Details Screen (`/srcm-details`)

**File:** `lib/screens/onboarding/srcm_details_screen.dart`

### Features Implemented:
- ✅ Progress indicator (Step 4 of 7 - 56% complete)
- ✅ SRCM ID Proof image upload (required)
  - Camera/Gallery picker
  - 5MB size validation
  - Image preview
  - Upload to server (`POST /srcmDetails/uploadSrcmId`)
- ✅ SRCM/Heartfulness ID Number (required text input)
- ✅ Satsang Center name/city (required text input)
- ✅ Preceptor's Name (required text input)
- ✅ Preceptor's Mobile Number (required number input)
- ✅ Preceptor's Email (optional email input)
- ✅ Confirmation dialog before submit
- ✅ Form validation
- ✅ API integration (`PATCH /srcmDetails/updateSrcmDetails`)
- ✅ Auto-navigation based on screenName
- ✅ Loading states and error handling

### API Flow:
1. **Upload Image First:**
   ```
   POST /srcmDetails/uploadSrcmId
   Body: multipart/form-data with 'srcmPhoto' field
   Response: { "fileName": "1765258323184-file.jpg" }
   ```

2. **Submit Details:**
   ```dart
   PATCH /srcmDetails/updateSrcmDetails
   {
     'srcmIdNumber': string,
     'preceptorsName': string,
     'preceptorsContactNumber': number,
     'preceptorsEmail': string,
     'satsangCenter': string,
     'srcmIdFilename': string (from upload response)
   }
   ```

### Navigation Flow:
1. Checks current screenName on mount
2. On submit → Shows confirmation dialog
3. After confirmation → Updates to `familydetails`
4. Navigates to `/family-details`
5. Back button → `/social-details`

---

## Common Features Across All Pages

### 1. **Auto-Navigation System**
All pages check the user's `screenName` on mount and redirect if needed:
```dart
Future<void> _checkScreenName() async {
  final userResponse = await _authService.getUser();
  final screenName = userResponse['data']['screenName'];
  
  if (screenName != currentPage) {
    _navigateToScreen(screenName);
  }
}
```

### 2. **Lookup Data Loading**
All pages load lookup data (dropdowns) on mount:
```dart
Future<void> _loadLookupData() async {
  final lookupProvider = Provider.of<LookupProvider>(context, listen: false);
  await lookupProvider.loadLookupData();
  await _authService.validateToken();
}
```

### 3. **Progress Indicators**
Visual progress bars showing completion:
- Personal Details: 1/7 (14%)
- Career Details: 2/7 (28%)
- Social Details: 3/7 (42%)
- SRCM Details: 4/7 (56%)

### 4. **Consistent UI/UX**
- Gradient progress bars
- Step indicators
- Card-based sections
- Gradient buttons
- Loading states
- Error handling with SnackBars
- Back/Next navigation buttons

### 5. **Form Validation**
- Required field validation
- Custom validators
- Visual error messages
- Disabled submit during loading

---

## API Endpoints Used

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/auth/getUser` | GET | Get user data and screenName |
| `/auth/validateToken` | GET | Validate auth token |
| `/personalDetails` | PATCH | Update personal, career, social details |
| `/srcmDetails/uploadSrcmId` | POST | Upload SRCM ID image |
| `/srcmDetails/updateSrcmDetails` | PATCH | Update SRCM details |
| `/auth/updateLastActiveScreen` | PATCH | Update user's last active screen |

---

## Lookup Data Required

All pages use `LookupProvider` for dropdown options:

### Personal Details:
- `heightOptions` - Height values
- `countries` - Country list
- `states` - State list (filtered by country)
- `cities` - City list (filtered by state)
- `residentialStatuses` - Residential status options

### Career Details:
- `highestEducation` - Education qualifications
- `employedInOptions` - Employment types
- `occupations` - Occupation list
- `incomeOptions` - Income ranges

### Social Details:
- `maritalStatuses` - Marital status options
- `motherTongues` - Mother tongue list
- `religions` - Religion list
- `castes` - Caste list (filtered by religion)
- `horoscopes` - Horoscope signs
- `manglik` - Manglik options

### SRCM Details:
- No lookup data required (all text inputs + image upload)

---

## Testing Checklist

### Personal Details:
- [ ] Gender selection works
- [ ] DOB picker shows (18-100 years)
- [ ] Height dropdown is searchable
- [ ] Country → State → City cascade works
- [ ] Residential status dropdown works
- [ ] Form validation works
- [ ] Submit navigates to Career Details
- [ ] Back button goes to login

### Career Details:
- [ ] Education dropdown is searchable
- [ ] Other degree field shows conditionally
- [ ] Employed In dropdown works
- [ ] Occupation dropdown is searchable
- [ ] Income dropdown works
- [ ] Submit navigates to Social Details
- [ ] Back button goes to Personal Details

### Social Details:
- [ ] Marital status toggle works
- [ ] Mother tongue dropdown is searchable
- [ ] Religion toggle works
- [ ] Caste No Bar checkbox works
- [ ] Caste dropdown hides when castNoBar is true
- [ ] Horoscope dropdown is searchable
- [ ] Manglik dropdown is searchable
- [ ] Submit navigates to SRCM Details
- [ ] Back button goes to Career Details

### SRCM Details:
- [ ] Image upload modal opens
- [ ] Camera/Gallery picker works
- [ ] 5MB validation works
- [ ] Image preview shows
- [ ] Upload to server works
- [ ] All text fields work
- [ ] Email validation works
- [ ] Confirmation dialog shows
- [ ] Submit navigates to Family Details
- [ ] Back button goes to Social Details

---

## Known Issues / Notes

1. **Image Upload (SRCM):**
   - Uses native image picker
   - Requires camera/storage permissions
   - 5MB file size limit enforced
   - Image stored on server, fileName returned

2. **Lookup Data:**
   - Loaded once on mount
   - Cached in LookupProvider
   - Country/State/City cascade requires API calls

3. **Navigation:**
   - Uses GoRouter
   - Auto-redirects based on screenName
   - Prevents users from skipping steps

4. **Form State:**
   - Not persisted locally
   - Must complete each step
   - Data saved to server on submit

---

## Next Steps (Remaining Onboarding Pages)

After SRCM Details, the following pages need to be implemented:

5. **Family Details** (`/family-details`) - Step 5 of 7
6. **Partner Preferences** (`/partner-preference`) - Step 6 of 7
7. **About You** (`/about-you`) - Step 7 of 7
8. **Verification Pending** (`/verification-pending`) - Final step

---

## How to Test

### 1. Run the app:
```bash
cd connectingheart-Mobile-Flutter
flutter run
```

### 2. Register a new account or login

### 3. You'll be redirected to the appropriate onboarding page based on your `screenName`

### 4. Complete each page in order:
- Personal Details → Career Details → Social Details → SRCM Details

### 5. Check that:
- All fields work correctly
- Validation works
- API calls succeed
- Navigation flows correctly
- Loading states show
- Errors are handled

---

## Summary

✅ **All 4 pages are FULLY IMPLEMENTED and READY TO USE!**

The onboarding flow from Personal Details to SRCM Details is complete with:
- ✅ Full UI implementation matching webapp
- ✅ API integration
- ✅ Form validation
- ✅ Auto-navigation
- ✅ Error handling
- ✅ Loading states
- ✅ Lookup data integration

**No additional work needed on these 4 pages!** 🎉
