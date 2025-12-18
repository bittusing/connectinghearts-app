import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../theme/colors.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  int _currentStep = 0; // 0: Phone, 1: OTP, 2: New Password
  bool _isLoading = false;
  bool _showPassword = false;
  String? _forgotPasswordToken;
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> _sendOtp() async {
    if (_phoneController.text.trim().isEmpty) {
      _showError('Please enter your mobile number');
      return;
    }

    final phoneNumber =
        _phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
    if (phoneNumber.length < 10) {
      _showError('Please enter a valid mobile number');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Match webapp: GET /auth/forgetPassword/{phoneNumber}
      final response = await _authService.forgetPassword(phoneNumber);

      if (response.success && mounted) {
        setState(() {
          _isLoading = false;
          _currentStep = 1;
        });
        _showSuccess(response.message ?? 'OTP sent successfully!');
      } else {
        setState(() => _isLoading = false);
        _showError(response.message ?? 'Failed to send OTP. Please try again.');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      String errorMsg = e.toString().replaceAll(RegExp(r'^Exception:\s*'), '');
      _showError(errorMsg.isNotEmpty
          ? errorMsg
          : 'Failed to send OTP. Please try again.');
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.length != 6) {
      _showError('Please enter a valid 6-digit OTP');
      return;
    }

    final phoneNumber =
        _phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
    setState(() => _isLoading = true);

    try {
      // Match webapp: POST /auth/verifyForgottenOTP
      final response = await _authService.verifyForgottenOtp(
          phoneNumber, _otpController.text);

      // Response structure: { code, status, message, token }
      final status = response['status']?.toString() ?? '';
      final token = response['token']?.toString();

      if (status == 'success' && token != null && token.isNotEmpty) {
        // Store the token temporarily (like webapp)
        _forgotPasswordToken = token;

        setState(() {
          _isLoading = false;
          _currentStep = 2;
        });
        _showSuccess(
            response['message']?.toString() ?? 'OTP verified successfully!');
      } else {
        setState(() => _isLoading = false);
        _showError(response['message']?.toString() ??
            'Invalid OTP. Please try again.');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      String errorMsg = e.toString().replaceAll(RegExp(r'^Exception:\s*'), '');
      _showError(
          errorMsg.isNotEmpty ? errorMsg : 'Invalid OTP. Please try again.');
    }
  }

  Future<void> _resetPassword() async {
    if (_newPasswordController.text.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showError('Passwords do not match');
      return;
    }

    if (_forgotPasswordToken == null) {
      _showError('Session expired. Please start again.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Store original token temporarily (like webapp)
      final originalToken = await _storageService.getToken();

      // Set forgot password token temporarily
      if (_forgotPasswordToken != null) {
        await _storageService.setToken(_forgotPasswordToken!);
      }

      // Match webapp: POST /auth/updateForgottenPassword
      final response = await _authService
          .updateForgottenPassword(_newPasswordController.text);

      // Restore original token (or remove if there wasn't one)
      if (originalToken != null && originalToken.isNotEmpty) {
        await _storageService.setToken(originalToken);
      } else {
        await _storageService.deleteToken();
      }

      if (response.success && mounted) {
        setState(() => _isLoading = false);
        _showSuccess(response.message ?? 'Password updated successfully!');
        _forgotPasswordToken = null;

        // Navigate to login after delay (like webapp)
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) {
          context.go('/login');
        }
      } else {
        setState(() => _isLoading = false);
        _showError(
            response.message ?? 'Failed to update password. Please try again.');
      }
    } catch (e) {
      // Restore original token on error
      final originalToken = await _storageService.getToken();
      if (originalToken != null && originalToken.isNotEmpty) {
        await _storageService.setToken(originalToken);
      } else {
        await _storageService.deleteToken();
      }

      setState(() => _isLoading = false);
      String errorMsg = e.toString().replaceAll(RegExp(r'^Exception:\s*'), '');
      _showError(errorMsg.isNotEmpty
          ? errorMsg
          : 'Failed to update password. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Progress Indicator
              Row(
                children: [
                  _buildStepIndicator(0, 'Phone'),
                  _buildStepConnector(0),
                  _buildStepIndicator(1, 'OTP'),
                  _buildStepConnector(1),
                  _buildStepIndicator(2, 'Reset'),
                ],
              ),
              const SizedBox(height: 32),
              // Form
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getStepTitle(),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getStepSubtitle(),
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    if (_currentStep == 0) ...[
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Mobile Number',
                          hintText: '+91 90000 00000',
                        ),
                      ),
                    ] else if (_currentStep == 1) ...[
                      TextFormField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          letterSpacing: 8,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Enter OTP',
                          hintText: '••••••',
                          counterText: '',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _sendOtp,
                        child: const Text('Resend OTP'),
                      ),
                    ] else ...[
                      TextFormField(
                        controller: _newPasswordController,
                        obscureText: !_showPassword,
                        decoration: InputDecoration(
                          labelText: 'New Password',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () =>
                                setState(() => _showPassword = !_showPassword),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: !_showPassword,
                        decoration: const InputDecoration(
                          labelText: 'Confirm Password',
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                if (_currentStep == 0) {
                                  _sendOtp();
                                } else if (_currentStep == 1) {
                                  _verifyOtp();
                                } else {
                                  _resetPassword();
                                }
                              },
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : Text(_getButtonText()),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    final isActive = _currentStep >= step;
    final isCurrent = _currentStep == step;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary : Colors.grey.shade300,
              shape: BoxShape.circle,
              border: isCurrent
                  ? Border.all(color: AppColors.primary, width: 2)
                  : null,
            ),
            child: Center(
              child: isActive && !isCurrent
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : Text(
                      '${step + 1}',
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? AppColors.primary : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepConnector(int step) {
    final isActive = _currentStep > step;
    return Container(
      width: 40,
      height: 2,
      color: isActive ? AppColors.primary : Colors.grey.shade300,
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Enter Mobile Number';
      case 1:
        return 'Verify OTP';
      case 2:
        return 'Set New Password';
      default:
        return '';
    }
  }

  String _getStepSubtitle() {
    switch (_currentStep) {
      case 0:
        return 'We will send you an OTP to verify your identity.';
      case 1:
        return 'Enter the 6-digit code sent to your mobile number.';
      case 2:
        return 'Create a new password for your account.';
      default:
        return '';
    }
  }

  String _getButtonText() {
    switch (_currentStep) {
      case 0:
        return 'Send OTP';
      case 1:
        return 'Verify OTP';
      case 2:
        return 'Reset Password';
      default:
        return '';
    }
  }
}
