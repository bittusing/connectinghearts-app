# Webapp to Flutter Conversion Status

## ✅ Completed Screens
- Login, Register, Forgot Password
- Dashboard, Search, Profiles, Daily Picks, Membership
- Profile Detail, My Profile (basic)
- Interests Received/Sent, Shortlisted, Blocked, Ignored
- Acceptance, Notifications
- Feedback, Terms, Privacy Policy, Delete Profile
- Change Password, Help Center
- Partner Preferences (basic)

## 🔄 In Progress / Needs Completion
- My Profile (needs full edit functionality)
- Onboarding flow screens
- Edit profile screens

## ❌ Missing Screens from Webapp

### Onboarding Flow (6 steps)
1. **PersonalDetailsPage** - Personal details (gender, DOB, height, location, etc.)
2. **CareerDetailsPage** - Education, occupation, income
3. **SocialDetailsPage** - Marital status, mother tongue, religion, caste, horoscope
4. **SRCMDetailsPage** - ID proof, SRCM details, preceptor info
5. **FamilyDetailsPage** - Family information
6. **AboutYouPage** - About me, profile picture upload

### Edit Profile Screens (8 screens)
1. **EditProfileBasicPage** - Edit basic details
2. **EditCareerPage** - Edit career/education
3. **EditEducationPage** - Edit education details
4. **EditFamilyPage** - Edit family information
5. **EditContactPage** - Edit contact details
6. **EditHoroscopePage** - Edit horoscope details
7. **EditLifestylePage** - Edit lifestyle information
8. **EditAboutPage** - Edit about me section

### Other Pages
1. **VerificationPendingPage** - ✅ Created
2. **PartnerPreferenceEditPage** - Edit partner preferences

## API Endpoints Needed

### Auth Service
- ✅ `auth/getUser` - Get user with screenName
- ✅ `auth/updateLastActiveScreen` - Update onboarding progress

### Profile Service
- ✅ `personalDetails` - PATCH for onboarding steps
- ✅ `personalDetails/editProfile` - PATCH for editing with section parameter
- ⚠️ `profile/uploadImage` - Image upload (needs multipart/form-data)

## Next Steps
1. Create all onboarding screens with API integration
2. Create all edit profile screens
3. Update MyProfileScreen with edit navigation
4. Add image upload functionality
5. Update router with all routes
6. Test complete flow

