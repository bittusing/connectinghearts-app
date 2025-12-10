# Onboarding Screens Implementation Status

## ✅ Completed
- VerificationPendingScreen - Simple screen showing verification pending message

## 🚧 In Progress
All onboarding screens need to be created with full API integration:

1. **PersonalDetailsScreen** - Basic personal info
   - Gender, DOB, Height
   - Country/State/City
   - Residence status
   - Mother tongue, Religion, Caste
   - Horoscope, Manglik
   - Income, Employment, Occupation
   - Education
   - Marital status, Children
   - API: `PATCH /personalDetails`
   - Next: `/career-details`

2. **CareerDetailsScreen** - Career information
   - Education (qualification, other degree)
   - Employment type
   - Occupation
   - Income
   - API: `PATCH /personalDetails`
   - Next: `/social-details`

3. **SocialDetailsScreen** - Social information
   - Marital status
   - Mother tongue
   - Religion
   - Caste (with castNoBar option)
   - Horoscope
   - Manglik
   - API: `PATCH /personalDetails`
   - Next: `/srcm-details`

4. **SRCMDetailsScreen** - SRCM verification
   - ID proof upload
   - SRCM ID number
   - Satsang center
   - Preceptor details (name, mobile, email)
   - API: `POST /srcmDetails/uploadSrcmId` (image), `PATCH /srcmDetails/updateSrcmDetails`
   - Next: `/family-details`

5. **FamilyDetailsScreen** - Family information
   - Family status, type, values
   - Family income
   - Father/Mother occupation
   - Brothers/Sisters count (married/unmarried)
   - Living with parents
   - Gothra
   - Family base location
   - API: `PATCH /personalDetails`
   - Next: `/about-you`

6. **AboutYouScreen** - About me and profile picture
   - About me description
   - Profile picture upload
   - API: `POST /personalDetails/uploadProfilePic` (image), `PATCH /personalDetails`
   - Next: `/verification-pending`

## Common Features Needed
- ScreenName-based navigation (check `GET /auth/getUser` for `screenName`)
- Update last active screen (`PATCH /auth/updateLastActiveScreen/{screenName}`)
- Lookup data integration (countries, states, cities, occupations, etc.)
- Form validation
- Error handling
- Loading states
- Image upload support (multipart/form-data)

## API Endpoints Summary
- `PATCH /personalDetails` - Update personal/career/social/family/about details
- `PATCH /srcmDetails/updateSrcmDetails` - Update SRCM details
- `POST /srcmDetails/uploadSrcmId` - Upload SRCM ID image
- `POST /personalDetails/uploadProfilePic` - Upload profile picture
- `GET /auth/getUser` - Get user data with screenName
- `PATCH /auth/updateLastActiveScreen/{screenName}` - Update onboarding progress

