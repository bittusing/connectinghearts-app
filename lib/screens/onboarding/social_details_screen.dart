import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/lookup_provider.dart';
import '../../services/auth_service.dart';
import '../../services/api_client.dart';
import '../../theme/colors.dart';
import '../../models/profile_models.dart';
import '../../widgets/common/searchable_dropdown.dart';

class SocialDetailsScreen extends StatefulWidget {
  const SocialDetailsScreen({super.key});

  @override
  State<SocialDetailsScreen> createState() => _SocialDetailsScreenState();
}

class _SocialDetailsScreenState extends State<SocialDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final ApiClient _apiClient = ApiClient();

  String? _selectedMaritalStatus; // Label like "Never married"
  String? _selectedMotherTongue; // Value from lookup
  String? _selectedReligion; // Label like "Hindu"
  String? _selectedCaste; // Value from lookup
  bool _castNoBar = false;
  String? _selectedHoroscope; // Value from lookup
  String? _selectedManglik; // Value from lookup

  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _lookupDataLoaded = false;

  @override
  void initState() {
    super.initState();
    // No defaults - user must select
    _checkScreenName();
    _loadLookupData();
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
          screenName != 'socialdetails') {
        _navigateToScreen(screenName);
      }
    } catch (e) {
      // Handle error silently
    }
  }

  void _navigateToScreen(String screenName) {
    final routeMap = {
      'personaldetails': '/personal-details',
      'careerdetails': '/career-details',
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

      // Lookup data loaded
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
      // Convert marital status to value (like webapp)
      String? maritalStatusValue;
      if (_selectedMaritalStatus != null) {
        if (_selectedMaritalStatus == 'Never married') {
          maritalStatusValue = 'nvm';
        } else {
          maritalStatusValue = _selectedMaritalStatus!.toLowerCase();
        }
      }

      // Convert religion to value (first 3 chars, like webapp)
      String? religionValue;
      if (_selectedReligion != null) {
        religionValue = _selectedReligion!.toLowerCase().substring(0, 3);
      }

      // Prepare payload (match webapp exactly - PATCH /personalDetails)
      final payload = <String, dynamic>{
        if (maritalStatusValue != null) 'maritalStatus': maritalStatusValue,
        if (_selectedMotherTongue != null)
          'motherTongue': _selectedMotherTongue,
        if (religionValue != null) 'religion': religionValue,
        if (!_castNoBar && _selectedCaste != null) 'cast': _selectedCaste,
        'castNoBar': _castNoBar,
        if (_selectedHoroscope != null) 'horoscope': _selectedHoroscope,
        if (_selectedManglik != null) 'manglik': _selectedManglik,
      };

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
                  'Social details updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Update last active screen (like webapp)
        await _authService.updateLastActiveScreen('srcmdetails');

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

            final route = routeMap[screenName] ?? '/srcm-details';
            context.go(route);
          } else if (mounted) {
            // Default to srcm details
            context.go('/srcm-details');
          }
        } catch (e) {
          // If getUser fails, navigate to srcm details
          if (mounted) {
            context.go('/srcm-details');
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message']?.toString() ??
                  'Failed to update social details'),
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
                : 'Failed to update social details'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildToggleGroup({
    required String label,
    required String? value,
    required List<String> options,
    required Function(String) onChanged,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = value == option;
            return GestureDetector(
              onTap: () => onChanged(option),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : theme.dividerColor,
                    width: 2,
                  ),
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : theme.textTheme.bodyLarge?.color,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lookupProvider = Provider.of<LookupProvider>(context);

    // Get marital status options
    final maritalOptions =
        lookupProvider.maritalStatuses.map((m) => m.label).toList();

    // Get religion options
    final religionOptions =
        lookupProvider.religions.map((r) => r.label).toList();

    // Get caste options (webapp filters by religion on backend)
    final casteOptions = lookupProvider.castes;

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
                          widthFactor: 3 / 7,
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
                        'STEP 3 OF 7',
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
                        'Fill in your Social Details',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Provide additional information like your marital status, religion, mother tongue and more.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      // Form Section
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
                            // Marital Status (ToggleGroup)
                            _buildToggleGroup(
                              label: 'Marital Status',
                              value: _selectedMaritalStatus,
                              options: maritalOptions.isNotEmpty
                                  ? maritalOptions
                                  : [
                                      'Never married',
                                      'Divorced',
                                      'Widowed',
                                      'Annulled',
                                      'Pending divorce'
                                    ],
                              onChanged: (value) {
                                setState(() => _selectedMaritalStatus = value);
                              },
                            ),
                            const SizedBox(height: 16),
                            // Mother Tongue (SearchableDropdown)
                            SearchableDropdown(
                              label: 'Mother Tongue',
                              value: _selectedMotherTongue,
                              options: lookupProvider.motherTongues,
                              hint: 'Select mother tongue',
                              onChanged: (value) {
                                setState(() => _selectedMotherTongue = value);
                              },
                            ),
                            const SizedBox(height: 16),
                            // Religion (ToggleGroup)
                            _buildToggleGroup(
                              label: 'Religion',
                              value: _selectedReligion,
                              options: religionOptions.isNotEmpty
                                  ? religionOptions
                                  : [
                                      'Hindu',
                                      'Muslim',
                                      'Christian',
                                      'Sikh',
                                      'Buddhist',
                                      'Jain',
                                      'Parsi',
                                      'Others'
                                    ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedReligion = value;
                                  // Clear caste when religion changes
                                  _selectedCaste = null;
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            // Cast No Bar checkbox
                            Row(
                              children: [
                                Checkbox(
                                  value: _castNoBar,
                                  onChanged: (val) {
                                    setState(() {
                                      _castNoBar = val ?? false;
                                      if (_castNoBar) {
                                        _selectedCaste = null;
                                      }
                                    });
                                  },
                                ),
                                Expanded(
                                  child: Text(
                                    'I am open to marry people of any caste',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                            // Caste (only show if castNoBar is false)
                            if (!_castNoBar) ...[
                              const SizedBox(height: 16),
                              SearchableDropdown(
                                label: 'Caste',
                                value: _selectedCaste,
                                options: casteOptions,
                                hint: 'Select caste',
                                onChanged: (value) {
                                  setState(() => _selectedCaste = value);
                                },
                              ),
                            ],
                            const SizedBox(height: 16),
                            // Horoscope (SearchableDropdown)
                            SearchableDropdown(
                              label: 'Horoscope',
                              value: _selectedHoroscope,
                              options: lookupProvider.horoscopes,
                              hint: 'Select horoscope',
                              onChanged: (value) {
                                setState(() => _selectedHoroscope = value);
                              },
                            ),
                            const SizedBox(height: 16),
                            // Manglik (SearchableDropdown)
                            SearchableDropdown(
                              label: 'Manglik',
                              value: _selectedManglik,
                              options: lookupProvider.manglik,
                              hint: 'Select manglik',
                              onChanged: (value) {
                                setState(() => _selectedManglik = value);
                              },
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
                              context.go('/career-details');
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
