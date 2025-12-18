import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/lookup_provider.dart';
import '../../services/auth_service.dart';
import '../../services/api_client.dart';
import '../../theme/colors.dart';
import '../../models/profile_models.dart';
import '../../widgets/common/searchable_dropdown.dart';

class CareerDetailsScreen extends StatefulWidget {
  const CareerDetailsScreen({super.key});

  @override
  State<CareerDetailsScreen> createState() => _CareerDetailsScreenState();
}

class _CareerDetailsScreenState extends State<CareerDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final ApiClient _apiClient = ApiClient();
  final TextEditingController _otherDegreeController = TextEditingController();

  String? _selectedQualification; // Value from lookup
  String? _selectedEmployedIn; // Value from lookup, default 'pvtSct'
  String? _selectedOccupation; // Value from lookup
  String? _selectedIncome; // Value from lookup

  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _lookupDataLoaded = false;

  @override
  void initState() {
    super.initState();
    _selectedEmployedIn = 'pvtSct'; // Default as per webapp
    _checkScreenName();
    _loadLookupData();
  }

  @override
  void dispose() {
    _otherDegreeController.dispose();
    super.dispose();
  }

  Future<void> _checkScreenName() async {
    try {
      final userResponse = await _authService.getUser();
      final responseStatus = userResponse['status']?.toString() ?? '';
      final userData = userResponse['data'] as Map<String, dynamic>?;
      final screenName = userData?['screenName']
              ?.toString()
              .toLowerCase()
              .replaceAll(RegExp(r'\s+'), '') ??
          '';

      if (responseStatus == 'success' &&
          screenName.isNotEmpty &&
          screenName != 'careerdetails') {
        _navigateToScreen(screenName);
      }
    } catch (e) {
      // Handle error silently
    }
  }

  void _navigateToScreen(String screenName) {
    final routeMap = {
      'personaldetails': '/personal-details',
      'socialdetails': '/social-details',
      'srcmdetails': '/srcm-details',
      'familydetails': '/family-details',
      'partnerpreferences': '/partner-preference',
      'aboutyou': '/about-you',
      'underverification': '/verification-pending',
      'dashboard': '/',
    };
    final route = routeMap[screenName];
    if (route != null && mounted) {
      context.go(route);
    }
  }

  Future<void> _loadLookupData() async {
    setState(() => _isLoading = true);
    try {
      final lookupProvider =
          Provider.of<LookupProvider>(context, listen: false);
      await lookupProvider.loadLookupData();

      // Also call validateToken API (like webapp)
      try {
        await _authService.validateToken();
      } catch (e) {
        // Silently fail
      }

      setState(() => _lookupDataLoaded = true);
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final lookupProvider =
          Provider.of<LookupProvider>(context, listen: false);

      // Get income value - convert to number
      num? incomeValue;
      if (_selectedIncome != null) {
        try {
          final incomeOption = lookupProvider.incomeOptions.firstWhere(
            (i) => i.value?.toString() == _selectedIncome,
          );
          if (incomeOption.value != null) {
            incomeValue = incomeOption.value is num
                ? incomeOption.value as num
                : (incomeOption.value is String
                    ? num.tryParse(incomeOption.value.toString())
                    : null);
          }
        } catch (e) {
          // Income option not found, try parsing directly
          incomeValue = num.tryParse(_selectedIncome!);
        }
      }

      // Prepare payload (match webapp exactly - PATCH /personalDetails)
      final payload = <String, dynamic>{
        if (_selectedEmployedIn != null) 'employed_in': _selectedEmployedIn,
        if (_selectedOccupation != null) 'occupation': _selectedOccupation,
        if (incomeValue != null) 'income': incomeValue,
      };

      // Always include education if qualification exists (like webapp)
      if (_selectedQualification != null) {
        payload['education'] = {
          'qualification': _selectedQualification,
          if (_otherDegreeController.text.isNotEmpty)
            'otherUGDegree': _otherDegreeController.text,
        };
      }

      // Call PATCH /personalDetails (like webapp)
      final response = await _apiClient.patch<Map<String, dynamic>>(
        '/personalDetails',
        body: payload,
      );

      // Check response
      final status = response['status']?.toString() ?? '';
      final code = response['code']?.toString() ?? '';

      if (status == 'success' || code == 'CH200') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message']?.toString() ??
                  'Career details updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Update last active screen (like webapp)
        await _authService.updateLastActiveScreen('socialdetails');

        // Get user data and navigate (like webapp)
        try {
          final userResponse = await _authService.getUser();
          final responseStatus = userResponse['status']?.toString() ?? '';
          final userData = userResponse['data'] as Map<String, dynamic>?;
          final screenName = userData?['screenName']
                  ?.toString()
                  .toLowerCase()
                  .replaceAll(RegExp(r'\s+'), '') ??
              '';

          if (responseStatus == 'success' && screenName.isNotEmpty && mounted) {
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

            final route = routeMap[screenName] ?? '/social-details';
            context.go(route);
          } else if (mounted) {
            // Default to social details
            context.go('/social-details');
          }
        } catch (e) {
          // If getUser fails, navigate to social details
          if (mounted) {
            context.go('/social-details');
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message']?.toString() ??
                  'Failed to update career details'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMsg =
            e.toString().replaceAll(RegExp(r'^Exception:\s*'), '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg.isNotEmpty
                ? errorMsg
                : 'Failed to update career details'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lookupProvider = Provider.of<LookupProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Progress indicator
                      Container(
                        height: 2,
                        decoration: BoxDecoration(
                          color: theme.dividerColor.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(1),
                        ),
                        child: FractionallySizedBox(
                          widthFactor: 2 / 7,
                          alignment: Alignment.centerLeft,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: AppColors.gradientColors,
                              ),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Step indicator
                      Text(
                        'STEP 2 OF 7',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                          color: AppColors.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      // Title
                      Text(
                        'Fill in your Career Details',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Provide additional information like your education, profession and income.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      // Education Section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: theme.dividerColor.withOpacity(0.5),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'EDUCATION',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SearchableDropdown(
                              label: 'Highest Qualification',
                              value: _selectedQualification,
                              options: lookupProvider.highestEducation,
                              hint: 'Select education',
                              onChanged: (value) {
                                setState(() => _selectedQualification = value);
                              },
                            ),
                            // Other UG Degree - only show when qualification is selected
                            if (_selectedQualification != null) ...[
                              const SizedBox(height: 16),
                              _buildLabel('Other UG Degree'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _otherDegreeController,
                                decoration: InputDecoration(
                                  hintText: 'Enter degree name',
                                  filled: true,
                                  fillColor: theme.cardColor,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide:
                                        BorderSide(color: theme.dividerColor),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide:
                                        BorderSide(color: theme.dividerColor),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                        color: AppColors.primary, width: 2),
                                  ),
                                ),
                                style: TextStyle(
                                  color: theme.textTheme.bodyLarge?.color,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Work Experience Section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: theme.dividerColor.withOpacity(0.5),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'WORK EXPERIENCE',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SearchableDropdown(
                              label: 'Employed In',
                              value: _selectedEmployedIn,
                              options: lookupProvider.employedInOptions,
                              hint: 'Select Employed In',
                              onChanged: (value) {
                                setState(() => _selectedEmployedIn = value);
                              },
                            ),
                            const SizedBox(height: 16),
                            // Occupation and Income in row
                            Row(
                              children: [
                                Expanded(
                                  child: SearchableDropdown(
                                    label: 'Occupation',
                                    value: _selectedOccupation,
                                    options: lookupProvider.occupations,
                                    hint: 'Select occupation',
                                    onChanged: (value) {
                                      setState(
                                          () => _selectedOccupation = value);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: SearchableDropdown(
                                    label: 'Income',
                                    value: _selectedIncome,
                                    options: lookupProvider.incomeOptions,
                                    hint: 'Select income',
                                    onChanged: (value) {
                                      setState(() => _selectedIncome = value);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Back and Next buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () {
                              context.go('/personal-details');
                            },
                            child: const Text('← Back'),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              gradient: const LinearGradient(
                                colors: AppColors.gradientColors,
                              ),
                            ),
                            child: ElevatedButton(
                              onPressed: _isSubmitting ? null : _handleSubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 12,
                                ),
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
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    )
                                  : const Text(
                                      'Next',
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
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
