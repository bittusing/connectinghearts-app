import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../theme/colors.dart';

class CountryCode {
  final String code;
  final String dialCode;
  final String name;

  CountryCode({
    required this.code,
    required this.dialCode,
    required this.name,
  });
}

// Match webapp country codes list
final List<CountryCode> countryCodes = [
  CountryCode(code: 'IN', dialCode: '+91', name: 'India'),
  CountryCode(code: 'US', dialCode: '+1', name: 'United States'),
  CountryCode(code: 'GB', dialCode: '+44', name: 'United Kingdom'),
  CountryCode(code: 'CA', dialCode: '+1', name: 'Canada'),
  CountryCode(code: 'AU', dialCode: '+61', name: 'Australia'),
  CountryCode(code: 'DE', dialCode: '+49', name: 'Germany'),
  CountryCode(code: 'FR', dialCode: '+33', name: 'France'),
  CountryCode(code: 'IT', dialCode: '+39', name: 'Italy'),
  CountryCode(code: 'ES', dialCode: '+34', name: 'Spain'),
  CountryCode(code: 'NL', dialCode: '+31', name: 'Netherlands'),
  CountryCode(code: 'BE', dialCode: '+32', name: 'Belgium'),
  CountryCode(code: 'CH', dialCode: '+41', name: 'Switzerland'),
  CountryCode(code: 'AT', dialCode: '+43', name: 'Austria'),
  CountryCode(code: 'SE', dialCode: '+46', name: 'Sweden'),
  CountryCode(code: 'NO', dialCode: '+47', name: 'Norway'),
  CountryCode(code: 'DK', dialCode: '+45', name: 'Denmark'),
  CountryCode(code: 'FI', dialCode: '+358', name: 'Finland'),
  CountryCode(code: 'PL', dialCode: '+48', name: 'Poland'),
  CountryCode(code: 'PT', dialCode: '+351', name: 'Portugal'),
  CountryCode(code: 'GR', dialCode: '+30', name: 'Greece'),
  CountryCode(code: 'IE', dialCode: '+353', name: 'Ireland'),
  CountryCode(code: 'NZ', dialCode: '+64', name: 'New Zealand'),
  CountryCode(code: 'SG', dialCode: '+65', name: 'Singapore'),
  CountryCode(code: 'MY', dialCode: '+60', name: 'Malaysia'),
  CountryCode(code: 'AE', dialCode: '+971', name: 'UAE'),
  CountryCode(code: 'SA', dialCode: '+966', name: 'Saudi Arabia'),
  CountryCode(code: 'QA', dialCode: '+974', name: 'Qatar'),
  CountryCode(code: 'KW', dialCode: '+965', name: 'Kuwait'),
  CountryCode(code: 'BH', dialCode: '+973', name: 'Bahrain'),
  CountryCode(code: 'OM', dialCode: '+968', name: 'Oman'),
  CountryCode(code: 'JP', dialCode: '+81', name: 'Japan'),
  CountryCode(code: 'KR', dialCode: '+82', name: 'South Korea'),
  CountryCode(code: 'CN', dialCode: '+86', name: 'China'),
  CountryCode(code: 'HK', dialCode: '+852', name: 'Hong Kong'),
  CountryCode(code: 'TW', dialCode: '+886', name: 'Taiwan'),
  CountryCode(code: 'TH', dialCode: '+66', name: 'Thailand'),
  CountryCode(code: 'ID', dialCode: '+62', name: 'Indonesia'),
  CountryCode(code: 'PH', dialCode: '+63', name: 'Philippines'),
  CountryCode(code: 'VN', dialCode: '+84', name: 'Vietnam'),
  CountryCode(code: 'BD', dialCode: '+880', name: 'Bangladesh'),
  CountryCode(code: 'PK', dialCode: '+92', name: 'Pakistan'),
  CountryCode(code: 'LK', dialCode: '+94', name: 'Sri Lanka'),
  CountryCode(code: 'NP', dialCode: '+977', name: 'Nepal'),
  CountryCode(code: 'BT', dialCode: '+975', name: 'Bhutan'),
  CountryCode(code: 'MV', dialCode: '+960', name: 'Maldives'),
  CountryCode(code: 'AF', dialCode: '+93', name: 'Afghanistan'),
  CountryCode(code: 'MM', dialCode: '+95', name: 'Myanmar'),
  CountryCode(code: 'KH', dialCode: '+855', name: 'Cambodia'),
  CountryCode(code: 'LA', dialCode: '+856', name: 'Laos'),
  CountryCode(code: 'MN', dialCode: '+976', name: 'Mongolia'),
  CountryCode(code: 'RU', dialCode: '+7', name: 'Russia'),
  CountryCode(code: 'TR', dialCode: '+90', name: 'Turkey'),
  CountryCode(code: 'IL', dialCode: '+972', name: 'Israel'),
  CountryCode(code: 'EG', dialCode: '+20', name: 'Egypt'),
  CountryCode(code: 'ZA', dialCode: '+27', name: 'South Africa'),
  CountryCode(code: 'BR', dialCode: '+55', name: 'Brazil'),
  CountryCode(code: 'MX', dialCode: '+52', name: 'Mexico'),
  CountryCode(code: 'AR', dialCode: '+54', name: 'Argentina'),
  CountryCode(code: 'CL', dialCode: '+56', name: 'Chile'),
  CountryCode(code: 'CO', dialCode: '+57', name: 'Colombia'),
  CountryCode(code: 'PE', dialCode: '+51', name: 'Peru'),
  CountryCode(code: 'VE', dialCode: '+58', name: 'Venezuela'),
];

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpController = TextEditingController();

  String _selectedCountryCode = '+91';
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _agreeToTerms = false;
  bool _showOtpDialog = false;
  bool _isSubmitting = false;
  bool _isVerifying = false;
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  bool _validateForm() {
    if (_fullNameController.text.trim().isEmpty) {
      _showError('Please enter your full name');
      return false;
    }
    if (_emailController.text.trim().isEmpty ||
        !_emailController.text.contains('@')) {
      _showError('Please enter a valid email');
      return false;
    }
    if (_phoneController.text.trim().isEmpty ||
        _phoneController.text.length < 10) {
      _showError('Please enter a valid mobile number');
      return false;
    }
    if (_passwordController.text.length < 6) {
      _showError('Password must be at least 6 characters');
      return false;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Passwords do not match');
      return false;
    }
    if (!_agreeToTerms) {
      _showError('Please agree to terms and conditions');
      return false;
    }
    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  Future<void> _handleRegister() async {
    if (!_validateForm()) return;

    // Extract phone number (remove non-digits)
    final phoneNumber =
        _phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
    if (phoneNumber.length < 10) {
      _showError('Please enter a valid mobile number');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Match webapp: generateOtp with extension (not countryCode)
      final response =
          await _authService.generateOtp(phoneNumber, _selectedCountryCode);

      if (response.success && mounted) {
        // Show alert with WhatsApp number (like webapp)
        _showSuccess('OTP sent to your mobile number');
        _showAlertDialog();
      } else {
        _showError(response.message ?? 'Failed to send OTP');
      }
    } catch (e) {
      // Extract error message (remove "API 400: " prefix like webapp)
      String errorMsg = e.toString().replaceAll(RegExp(r'^Exception:\s*'), '');
      errorMsg = errorMsg.replaceAll(RegExp(r'^API\s+\d+:\s*'), '').trim();
      if (errorMsg.isEmpty ||
          errorMsg == 'Bad Request' ||
          errorMsg == 'Unknown error') {
        errorMsg = 'Failed to send OTP';
      }
      _showError(errorMsg);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _handleAlertConfirm() {
    // Open OTP modal after alert is confirmed (like webapp)
    _displayOtpDialog();
  }

  Future<void> _handleVerifyOtp() async {
    if (_otpController.text.length != 6) {
      _showError('Please enter a valid 6-digit OTP');
      return;
    }

    final phoneNumber =
        _phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
    setState(() => _isVerifying = true);

    try {
      // Match webapp: verifyOtp (stores token automatically)
      final verifyResponse =
          await _authService.verifyOtp(phoneNumber, _otpController.text);

      // Response structure: { status, token, message }
      final status = verifyResponse.status ?? '';
      final token = verifyResponse.token;

      if ((status == 'success' || verifyResponse.success) &&
          token != null &&
          token.isNotEmpty &&
          mounted) {
        // Token is already stored by verifyOtp in AuthProvider
        // But ensure it's stored in StorageService
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.verifyOtp(phoneNumber, _otpController.text);

        _showSuccess('OTP verified successfully');

        // Automatically call signup after OTP verification (like webapp)
        try {
          final signupResponse = await _authService.signup(
            name: _fullNameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            confirmPassword: _confirmPasswordController.text,
            source: 'MOBILE',
          );

          // Match webapp: check for success or CH200 code
          if (signupResponse.success ||
              signupResponse.message?.contains('success') == true ||
              signupResponse.message?.contains('CH200') == true) {
            // Immediately call getUser API to get screenName (like webapp)
            try {
              final userResponse = await _authService.getUser();
              // Response structure: { code, status, message, data: { screenName, ... } }
              final responseStatus = userResponse['status']?.toString() ?? '';
              final userData = userResponse['data'] as Map<String, dynamic>?;
              final screenName = userData?['screenName']
                      ?.toString()
                      .toLowerCase()
                      .replaceAll(RegExp(r'\s+'), '') ??
                  '';

              if (responseStatus == 'success' && screenName.isNotEmpty) {
                // Navigate based on screenName (like webapp)
                final routeMap = {
                  'personaldetails': '/personal-details',
                  'careerdetails': '/career-details',
                  'socialdetails': '/social-details',
                  'srcmdetails': '/srcm-details',
                  'familydetails': '/family-details',
                  'partnerpreferences': '/partner-preference',
                  'aboutyou': '/about-you',
                  'underverification': '/verification-pending',
                  'dashboard': '/',
                };

                final route = routeMap[screenName] ?? '/personal-details';
                if (mounted) {
                  context.go(route);
                }
              } else {
                // Default to personal details if screenName not found
                if (mounted) {
                  context.go('/personal-details');
                }
              }
            } catch (e) {
              // If getUser fails, navigate to personal details
              if (mounted) {
                context.go('/personal-details');
              }
            }
          } else {
            // Extract error from signup response (check for err field like webapp)
            final errorMsg = signupResponse.message ?? 'Registration failed';

            // Check if error indicates profile already exists - navigate to login
            if (errorMsg.toLowerCase().contains('profile already exists') ||
                errorMsg.toLowerCase().contains('please login')) {
              _showError(errorMsg);
              // Navigate to login screen after showing error
              if (mounted) {
                Future.delayed(const Duration(seconds: 2), () {
                  if (mounted) {
                    context.go('/login');
                  }
                });
              }
            } else {
              _showError(errorMsg);
            }
          }
        } catch (e) {
          // Extract error message (like webapp)
          String errorMsg =
              e.toString().replaceAll(RegExp(r'^Exception:\s*'), '');
          errorMsg = errorMsg.replaceAll(RegExp(r'^API\s+\d+:\s*'), '').trim();
          if (errorMsg.isEmpty ||
              errorMsg == 'Bad Request' ||
              errorMsg == 'Unknown error') {
            errorMsg = 'Registration failed';
          }

          // Check if error indicates profile already exists - navigate to login
          if (errorMsg.toLowerCase().contains('profile already exists') ||
              errorMsg.toLowerCase().contains('please login')) {
            _showError(errorMsg);
            // Navigate to login screen after showing error
            if (mounted) {
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) {
                  context.go('/login');
                }
              });
            }
          } else {
            _showError(errorMsg);
          }
        }
      } else {
        _showError(verifyResponse.message ?? 'OTP verification failed');
      }
    } catch (e) {
      // Extract error message
      String errorMsg = e.toString().replaceAll(RegExp(r'^Exception:\s*'), '');
      errorMsg = errorMsg.replaceAll(RegExp(r'^API\s+\d+:\s*'), '').trim();
      if (errorMsg.isEmpty ||
          errorMsg == 'Bad Request' ||
          errorMsg == 'Unknown error') {
        errorMsg = 'OTP verification failed';
      }
      _showError(errorMsg);
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
          _showOtpDialog = false;
        });
      }
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showCountryCodePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Country Code',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...countryCodes.map((country) {
                return ListTile(
                  title: Text('${country.name} (${country.dialCode})'),
                  trailing: _selectedCountryCode == country.dialCode
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () {
                    setState(() => _selectedCountryCode = country.dialCode);
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Link
                Align(
                  alignment: Alignment.centerRight,
                  child: Text.rich(
                    TextSpan(
                      text: 'Already have an account? ',
                      style: theme.textTheme.bodyMedium,
                      children: [
                        WidgetSpan(
                          child: GestureDetector(
                            onTap: () => context.pop(),
                            child: const Text(
                              'Log in',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Title
                Text(
                  'Sign Up',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Fill in your basic details.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                // Full Name
                _buildLabel('Full Name'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _fullNameController,
                  hintText: 'Enter full name',
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                // Email
                _buildLabel('Email'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _emailController,
                  hintText: 'Enter email',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                // Mobile Number
                _buildLabel('Mobile Number', isRequired: true),
                const SizedBox(height: 8),
                Row(
                  children: [
                    GestureDetector(
                      onTap: _showCountryCodePicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.dividerColor),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Text(_selectedCountryCode),
                            const SizedBox(width: 8),
                            const Icon(Icons.keyboard_arrow_down, size: 16),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildTextField(
                        controller: _phoneController,
                        hintText: '90000 00000',
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Password
                _buildLabel('Password'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _passwordController,
                  hintText: 'Enter password',
                  obscureText: !_showPassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showPassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => _showPassword = !_showPassword),
                  ),
                ),
                const SizedBox(height: 16),
                // Confirm Password
                _buildLabel('Confirm Password'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _confirmPasswordController,
                  hintText: 'Confirm your password',
                  obscureText: !_showConfirmPassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () => setState(
                        () => _showConfirmPassword = !_showConfirmPassword),
                  ),
                ),
                const SizedBox(height: 16),
                // Terms Checkbox
                Row(
                  children: [
                    GestureDetector(
                      onTap: () =>
                          setState(() => _agreeToTerms = !_agreeToTerms),
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: _agreeToTerms
                                ? AppColors.primary
                                : theme.dividerColor,
                            width: 2,
                          ),
                          color: _agreeToTerms
                              ? AppColors.primary
                              : Colors.transparent,
                        ),
                        child: _agreeToTerms
                            ? const Icon(Icons.check,
                                size: 16, color: Colors.white)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'I agree to terms and conditions',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Register Button
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: const LinearGradient(
                      colors: AppColors.gradientColors,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Register now',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAlertDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assistance'),
        content: const Text(
            'For any assistance, please WhatsApp/Call: +91 9450312512'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _handleAlertConfirm();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _displayOtpDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Enter OTP'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                hintText: 'Enter 6-digit OTP',
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _showOtpDialog = false;
                _otpController.clear();
              });
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _isVerifying
                ? null
                : () async {
                    await _handleVerifyOtp();
                    if (mounted) {
                      Navigator.of(context).pop();
                    }
                  },
            child: _isVerifying
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Verify'),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, {bool isRequired = false}) {
    return Text.rich(
      TextSpan(
        text: text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
        children: isRequired
            ? [
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: AppColors.primary),
                ),
              ]
            : null,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: theme.cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: theme.dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: theme.dividerColor),
        ),
        suffixIcon: suffixIcon,
      ),
    );
  }
}
