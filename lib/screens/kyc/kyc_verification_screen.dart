import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../models/kyc_models.dart';
import '../../services/kyc_service.dart';
import '../../services/auth_service.dart';
import '../../theme/colors.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/kyc/otp_modal.dart';

class KYCVerificationScreen extends StatefulWidget {
  const KYCVerificationScreen({super.key});

  @override
  State<KYCVerificationScreen> createState() => _KYCVerificationScreenState();
}

class _KYCVerificationScreenState extends State<KYCVerificationScreen> {
  final KYCService _kycService = KYCService();
  final AuthService _authService = AuthService();
  final TextEditingController _aadhaarController = TextEditingController();
  
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _referenceId;
  String _kycStatus = 'pending';

  @override
  void initState() {
    super.initState();
    _checkKycStatus();
  }

  @override
  void dispose() {
    _aadhaarController.dispose();
    super.dispose();
  }

  Future<void> _checkKycStatus() async {
    try {
      final userResponse = await _kycService.getUser();
      
      if (userResponse.isSuccess && userResponse.data != null) {
        final userData = userResponse.data!;
        
        // If not Indian user (+91), skip KYC and go to SRCM
        if (userData.countryCode != null && userData.countryCode != '+91') {
          _showToast('Aadhar verification is only for Indian users. Proceeding to next step.');
          await _authService.updateLastActiveScreen('srcmdetails');
          if (mounted) {
            context.go('/srcm-details');
          }
          return;
        }

        // If KYC already verified, go to SRCM
        if (userData.kycStatus == 'verified') {
          _showToast('KYC already verified');
          await _authService.updateLastActiveScreen('srcmdetails');
          if (mounted) {
            context.go('/srcm-details');
          }
          return;
        }

        // Check if should be on this page
        if (userData.screenName != null && 
            userData.screenName!.toLowerCase() != 'kycverification') {
          final routeMap = {
            'personaldetails': '/personal-details',
            'careerdetails': '/career-details',
            'socialdetails': '/social-details',
            'kycverification': '/kyc-verification',
            'srcmdetails': '/srcm-details',
            'familydetails': '/family-details',
            'partnerpreferences': '/partner-preference',
            'aboutyou': '/about-you',
            'underverification': '/verification-pending',
            'dashboard': '/',
          };
          
          final redirectPath = routeMap[userData.screenName!.toLowerCase()];
          if (redirectPath != null && redirectPath != '/kyc-verification') {
            if (mounted) {
              context.go(redirectPath);
            }
            return;
          }
        }

        setState(() {
          _kycStatus = userData.kycStatus ?? 'pending';
        });
      }
    } catch (error) {
      print('Error checking KYC status: $error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleGenerateOtp() async {
    final aadhaarNumber = _aadhaarController.text.trim();
    
    if (aadhaarNumber.isEmpty || aadhaarNumber.length != 12) {
      _showToast('Please enter a valid 12-digit Aadhaar number');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = await _kycService.generateOtp(aadhaarNumber);
      
      if (response.isSuccess && response.referenceId != null) {
        setState(() {
          _referenceId = response.referenceId;
        });
        _showToast(response.message.isNotEmpty 
            ? response.message 
            : 'OTP sent to your Aadhaar registered mobile number');
        _showOtpModal();
      } else {
        _showToast(response.message.isNotEmpty 
            ? response.message 
            : 'Failed to send OTP');
      }
    } catch (error) {
      _showToast(error.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _handleVerifyOtp(String otp) async {
    if (_referenceId == null) {
      _showToast('Reference ID missing. Please try again.');
      return;
    }

    try {
      final response = await _kycService.verifyOtp(_referenceId!, otp);
      
      if (response.isSuccess) {
        setState(() {
          _kycStatus = 'verified';
        });
        
        Navigator.of(context).pop(); // Close OTP modal
        _showToast(response.message.isNotEmpty 
            ? response.message 
            : 'Aadhar verification completed successfully!');
        
        // Update screen name and navigate to SRCM
        await _authService.updateLastActiveScreen('srcmdetails');
        
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            context.go('/srcm-details');
          }
        });
      } else {
        throw Exception(response.message.isNotEmpty 
            ? response.message 
            : 'OTP verification failed');
      }
    } catch (error) {
      _showToast(error.toString().replaceAll('Exception: ', ''));
    }
  }

  void _showOtpModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => OtpModal(
        onVerify: _handleVerifyOtp,
        onClose: () {
          Navigator.of(context).pop();
          setState(() {
            _referenceId = null;
          });
        },
      ),
    );
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF8F2FF), Colors.white],
            ),
          ),
          child: const Center(
            child: Card(
              margin: EdgeInsets.all(32),
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Checking Aadhar status...',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (_kycStatus == 'verified') {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF8F2FF), Colors.white],
            ),
          ),
          child: const Center(
            child: Card(
              margin: EdgeInsets.all(32),
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 64,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Aadhar Verified!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Redirecting to next step...',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8F2FF), Colors.white, Colors.white],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header
                        _buildHeader(),
                        const SizedBox(height: 24),
                        
                        // Info Card
                        _buildInfoCard(),
                        const SizedBox(height: 24),
                        
                        // Form
                        _buildForm(),
                        const SizedBox(height: 24),
                        
                        // Steps Preview
                        _buildStepsPreview(),
                        const SizedBox(height: 24),
                        
                        // Buttons
                        _buildButtons(),
                      ],
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

  Widget _buildHeader() {
    return Column(
      children: [
        // Progress bar
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: 0.42,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF4F8B), Color(0xFFFFA0D2)],
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Step indicator
        const Text(
          'STEP 3.5 OF 7',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.pink,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        
        // Title with icon
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shield,
              color: Colors.pink[500],
              size: 32,
            ),
            const SizedBox(width: 12),
            const Text(
              'Aadhar Verification',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Subtitle
        Text(
          'Verify your identity using Aadhaar for a secure experience',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border.all(color: Colors.blue[100]!),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info,
            color: Colors.blue[500],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Why Aadhar?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Aadhar verification ensures authenticity and builds trust in our community. Your Aadhaar details are securely stored and never shared.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step indicator
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.pink[100],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '1',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.pink[600],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter Aadhaar Number',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '12-digit Aadhaar number',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Aadhaar input
          CustomTextField(
            controller: _aadhaarController,
            labelText: 'Aadhaar Number',
            hintText: 'Enter 12-digit Aadhaar number',
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(12),
            ],
          ),
          const SizedBox(height: 16),
          
          // Note
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Note: OTP will be sent to the mobile number registered with your Aadhaar.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepsPreview() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Verification Steps:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          _buildStep(1, 'Enter your 12-digit Aadhaar number', true),
          const SizedBox(height: 8),
          _buildStep(2, 'Receive OTP on Aadhaar registered mobile', false),
          const SizedBox(height: 8),
          _buildStep(3, 'Enter OTP to complete verification', false),
        ],
      ),
    );
  }

  Widget _buildStep(int number, String text, bool isActive) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number.toString(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildButtons() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () => context.go('/social-details'),
              child: Text(
                '← Back',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[500],
                ),
              ),
            ),
            CustomButton(
              text: _isSubmitting ? 'Sending OTP...' : 'Send OTP',
              onPressed: _isSubmitting || _aadhaarController.text.length != 12
                  ? null
                  : _handleGenerateOtp,
              isLoading: _isSubmitting,
            ),
          ],
        ),
      ],
    );
  }
}