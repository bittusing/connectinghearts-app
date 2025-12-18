import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/lookup_provider.dart';
import '../../services/auth_service.dart';
import '../../services/api_client.dart';
import '../../theme/colors.dart';
import '../../models/profile_models.dart';
import '../../widgets/common/searchable_dropdown.dart';

class FamilyDetailsScreen extends StatefulWidget {
  const FamilyDetailsScreen({super.key});

  @override
  State<FamilyDetailsScreen> createState() => _FamilyDetailsScreenState();
}

class _FamilyDetailsScreenState extends State<FamilyDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final ApiClient _apiClient = ApiClient();
  final TextEditingController _gothraController = TextEditingController();

  String? _selectedFamilyStatus; // Value from lookup
  String? _selectedFamilyType; // Value from lookup
  String? _selectedFamilyValues; // Value from lookup
  String? _selectedFamilyIncome; // Value from lookup
  String? _selectedFatherOccupation; // Value from lookup
  String? _selectedMotherOccupation; // Value from lookup
  int _brothers = 0; // None = 0
  int _sisters = 0; // None = 0
  int _marriedBrothers = 0; // None = 0
  int _marriedSisters = 0; // None = 0
  String? _livingWithParents; // Value from lookup, default 'Y'
  String? _selectedFamilyBaseLocation; // Country value
  String? _selectedFamilyBaseLocationLabel; // Country label

  bool _isLoading = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _livingWithParents = 'Y'; // Default as per webapp
    _checkScreenName();
    _loadLookupData();
  }

  @override
  void dispose() {
    _gothraController.dispose();
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
          screenName != 'familydetails') {
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
      'socialdetails': '/social-details',
      'srcmdetails': '/srcm-details',
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
      final lookupProvider =
          Provider.of<LookupProvider>(context, listen: false);

      // Get family income value - convert to number
      num? familyIncomeValue;
      if (_selectedFamilyIncome != null) {
        try {
          final incomeOption = lookupProvider.incomeOptions.firstWhere(
            (i) => i.value?.toString() == _selectedFamilyIncome,
          );
          if (incomeOption.value != null) {
            familyIncomeValue = incomeOption.value is num
                ? incomeOption.value as num
                : (incomeOption.value is String
                    ? num.tryParse(incomeOption.value.toString())
                    : null);
          }
        } catch (e) {
          // Income option not found, try parsing directly
          familyIncomeValue = num.tryParse(_selectedFamilyIncome!);
        }
      }

      // Prepare payload (match webapp exactly - PATCH /family)
      final payload = <String, dynamic>{
        if (_selectedFamilyStatus != null)
          'familyStatus': _selectedFamilyStatus,
        if (_selectedFamilyType != null) 'familyType': _selectedFamilyType,
        if (_selectedFamilyValues != null)
          'familyValues': _selectedFamilyValues,
        if (familyIncomeValue != null) 'familyIncome': familyIncomeValue,
        if (_selectedFatherOccupation != null)
          'fatherOccupation': _selectedFatherOccupation,
        if (_selectedMotherOccupation != null)
          'motherOccupation': _selectedMotherOccupation,
        'brothers': _brothers, // None = 0
        'sisters': _sisters, // None = 0
        'marriedBrothers': _marriedBrothers, // None = 0
        'marriedSisters': _marriedSisters, // None = 0
        if (_livingWithParents != null) 'livingWithParents': _livingWithParents,
        if (_gothraController.text.trim().isNotEmpty)
          'gothra': _gothraController.text.trim(),
        if (_selectedFamilyBaseLocation != null)
          'familyBasedOutOf': _selectedFamilyBaseLocation,
      };

      // Call PATCH /family (like webapp)
      final response = await _apiClient.patch<Map<String, dynamic>>(
        '/family',
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
                  'Family details updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Update last active screen (like webapp)
        await _authService.updateLastActiveScreen('partnerpreferences');

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

            final route = routeMap[screenName] ?? '/partner-preference';
            context.go(route);
          } else if (mounted) {
            // Default to partner preferences
            context.go('/partner-preference');
          }
        } catch (e) {
          // If getUser fails, navigate to partner preferences
          if (mounted) {
            context.go('/partner-preference');
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message']?.toString() ??
                  'Failed to update family details'),
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
                : 'Failed to update family details'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildCountSelector({
    required String label,
    required int value,
    required Function(int) onChanged,
    int max = 4,
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
          children: List.generate(max + 1, (index) {
            final count = index;
            final isSelected = value == count;
            return GestureDetector(
              onTap: () => onChanged(count),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : theme.dividerColor,
                    width: 2,
                  ),
                ),
                child: Text(
                  count == 0 ? 'None' : count.toString(),
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
          }),
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
                          widthFactor: 5 / 7,
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
                        'STEP 5 OF 7',
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
                        'Family details',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Provide additional information about your family.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      // Family Background Section
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
                              'FAMILY BACKGROUND',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: SearchableDropdown(
                                    label: 'Family Status',
                                    value: _selectedFamilyStatus,
                                    options: lookupProvider.familyStatusOptions,
                                    hint: 'Select family status',
                                    onChanged: (value) {
                                      setState(
                                          () => _selectedFamilyStatus = value);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: SearchableDropdown(
                                    label: 'Family Type',
                                    value: _selectedFamilyType,
                                    options: lookupProvider.familyTypeOptions,
                                    hint: 'Select family type',
                                    onChanged: (value) {
                                      setState(
                                          () => _selectedFamilyType = value);
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: SearchableDropdown(
                                    label: 'Family Values',
                                    value: _selectedFamilyValues,
                                    options: lookupProvider.familyValuesOptions,
                                    hint: 'Select family values',
                                    onChanged: (value) {
                                      setState(
                                          () => _selectedFamilyValues = value);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: SearchableDropdown(
                                    label: 'Family Income',
                                    value: _selectedFamilyIncome,
                                    options: lookupProvider.incomeOptions,
                                    hint: 'Select family income',
                                    onChanged: (value) {
                                      setState(
                                          () => _selectedFamilyIncome = value);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Family Members Section
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
                              'FAMILY MEMBERS',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: SearchableDropdown(
                                    label: 'Father\'s Occupation',
                                    value: _selectedFatherOccupation,
                                    options:
                                        lookupProvider.fathersOccupationOptions,
                                    hint: 'Select father\'s occupation',
                                    onChanged: (value) {
                                      setState(() =>
                                          _selectedFatherOccupation = value);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: SearchableDropdown(
                                    label: 'Mother\'s Occupation',
                                    value: _selectedMotherOccupation,
                                    options:
                                        lookupProvider.mothersOccupationOptions,
                                    hint: 'Select mother\'s occupation',
                                    onChanged: (value) {
                                      setState(() =>
                                          _selectedMotherOccupation = value);
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Brothers
                            _buildCountSelector(
                              label: 'Brothers',
                              value: _brothers,
                              onChanged: (count) {
                                setState(() {
                                  _brothers = count;
                                  // Ensure married brothers doesn't exceed brothers
                                  if (_marriedBrothers > count) {
                                    _marriedBrothers = count;
                                  }
                                });
                              },
                              max: 4,
                            ),
                            // Married Brothers (only show if brothers > 0)
                            if (_brothers > 0) ...[
                              const SizedBox(height: 16),
                              _buildCountSelector(
                                label: 'Married Brothers',
                                value: _marriedBrothers,
                                onChanged: (count) {
                                  setState(() => _marriedBrothers = count);
                                },
                                max: _brothers,
                              ),
                            ],
                            const SizedBox(height: 16),
                            // Sisters
                            _buildCountSelector(
                              label: 'Sisters',
                              value: _sisters,
                              onChanged: (count) {
                                setState(() {
                                  _sisters = count;
                                  // Ensure married sisters doesn't exceed sisters
                                  if (_marriedSisters > count) {
                                    _marriedSisters = count;
                                  }
                                });
                              },
                              max: 4,
                            ),
                            // Married Sisters (only show if sisters > 0)
                            if (_sisters > 0) ...[
                              const SizedBox(height: 16),
                              _buildCountSelector(
                                label: 'Married Sisters',
                                value: _marriedSisters,
                                onChanged: (count) {
                                  setState(() => _marriedSisters = count);
                                },
                                max: _sisters,
                              ),
                            ],
                            const SizedBox(height: 16),
                            // Living with parents
                            SearchableDropdown(
                              label: 'Living with parents',
                              value: _livingWithParents,
                              options: lookupProvider.livingWithParentsOptions,
                              hint: 'Select option',
                              onChanged: (value) {
                                setState(() => _livingWithParents = value);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Additional Details Section
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
                              'ADDITIONAL DETAILS',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Gothra (text input)
                            _buildLabel('Gothra'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _gothraController,
                              decoration: InputDecoration(
                                hintText: 'Enter gothra',
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
                            const SizedBox(height: 16),
                            // My family based out of (country dropdown)
                            SearchableDropdown(
                              label: 'My family based out of',
                              value: _selectedFamilyBaseLocation,
                              options: lookupProvider.countries,
                              hint: 'Select country',
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedFamilyBaseLocation = value;
                                  });
                                } else {
                                  setState(() {
                                    _selectedFamilyBaseLocation = null;
                                  });
                                }
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
                              context.go('/srcm-details');
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
