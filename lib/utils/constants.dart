// Search Options
const List<String> countryOptions = [
  'India',
  'USA',
  'UK',
  'Canada',
  'Australia',
  'UAE',
  'Singapore',
  'Germany',
];

const List<String> religionOptions = [
  'Hindu',
  'Muslim',
  'Christian',
  'Sikh',
  'Jain',
  'Buddhist',
  'Parsi',
  'Jewish',
  'Other',
];

const List<String> motherTongueOptions = [
  'Hindi',
  'English',
  'Punjabi',
  'Tamil',
  'Telugu',
  'Marathi',
  'Gujarati',
  'Bengali',
  'Kannada',
  'Malayalam',
  'Odia',
  'Urdu',
  'Other',
];

const List<String> maritalStatusOptions = [
  'Never Married',
  'Divorced',
  'Widowed',
  'Awaiting Divorce',
  'Annulled',
];

// Generate age options (18-60)
List<String> generateAgeOptions() {
  return List.generate(43, (i) => '${18 + i}');
}

// Generate height options
List<String> generateHeightOptions() {
  final heights = <String>[];
  for (int feet = 4; feet <= 7; feet++) {
    for (int inches = 0; inches < 12; inches++) {
      if (feet == 7 && inches > 0) break;
      heights.add("$feet'$inches\"");
    }
  }
  return heights;
}

// Generate income options
List<String> generateIncomeOptions() {
  return [
    '0-2 LPA',
    '2-4 LPA',
    '4-6 LPA',
    '6-8 LPA',
    '8-10 LPA',
    '10-15 LPA',
    '15-20 LPA',
    '20-30 LPA',
    '30-50 LPA',
    '50+ LPA',
  ];
}

// App Constants
const String appName = 'Connecting Hearts';
const String appTagline = 'Find Your Perfect Match';

// Validation Constants
const int minPasswordLength = 6;
const int otpLength = 6;
const int minPhoneLength = 10;

// API Response Messages
const String loginSuccessMessage = 'Login successful';
const String registerSuccessMessage = 'Registration successful';
const String otpSentMessage = 'OTP sent successfully';
const String otpVerifiedMessage = 'OTP verified successfully';
const String interestSentMessage = 'Interest sent successfully';
const String interestAcceptedMessage = 'Interest accepted successfully';
const String interestDeclinedMessage = 'Interest declined';
const String profileShortlistedMessage = 'Profile shortlisted successfully';
const String profileIgnoredMessage = 'Profile ignored successfully';
const String profileBlockedMessage = 'Profile blocked successfully';
const String profileUnlockedMessage = 'Profile unlocked successfully';
const String passwordChangedMessage = 'Password changed successfully';
