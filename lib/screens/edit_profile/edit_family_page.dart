import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../services/profile_service.dart';
import '../../providers/lookup_provider.dart';
import '../../theme/colors.dart';
import '../../widgets/common/header_widget.dart';
import '../../widgets/common/bottom_navigation_widget.dart';
import '../../widgets/common/sidebar_widget.dart';
import '../../widgets/common/searchable_dropdown.dart';
import '../../models/profile_models.dart';

class EditFamilyPage extends StatefulWidget {
  const EditFamilyPage({super.key});

  @override
  State<EditFamilyPage> createState() => _EditFamilyPageState();
}

class _EditFamilyPageState extends State<EditFamilyPage> {
  final ProfileService _profileService = ProfileService();
  final _formKey = GlobalKey<FormState>();
  final _aboutMyFamilyController = TextEditingController();
  final _gothraController = TextEditingController();

  bool _isLoading = true;
  bool _isSubmitting = false;
  Map<String, dynamic>? _profileData;
  String? _error;

  String? _familyStatus;
  String? _familyType;
  String? _familyValues;
  String? _familyIncome;
  String? _fatherOccupation;
  String? _motherOccupation;
  int _brothers = 0;
  int _marriedBrothers = 0;
  int _sisters = 0;
  int _marriedSisters = 0;
  String? _livingWithParents;
  String? _familyBasedOutOf;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _aboutMyFamilyController.dispose();
    _gothraController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final lookupProvider =
          Provider.of<LookupProvider>(context, listen: false);
      await lookupProvider.loadLookupData();

      final response = await _profileService.getUserProfileData();
      if (response['status'] == 'success' && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;
        final family = data['family'] as Map<String, dynamic>? ?? {};

        setState(() {
          _profileData = data;
          _aboutMyFamilyController.text = family['aboutMyFamily']?.toString() ??
              family['aboutFamily']?.toString() ??
              '';
          _familyStatus = family['familyStatus']?.toString();
          _familyType = family['familyType']?.toString();
          _familyValues = family['familyValues']?.toString();
          _familyIncome = family['familyIncome']?.toString();
          _fatherOccupation = family['fatherOccupation']?.toString();
          _motherOccupation = family['motherOccupation']?.toString();
          _brothers = int.tryParse(family['brothers']?.toString() ?? '0') ?? 0;
          _marriedBrothers =
              int.tryParse(family['marriedBrothers']?.toString() ?? '0') ?? 0;
          _sisters = int.tryParse(family['sisters']?.toString() ?? '0') ?? 0;
          _marriedSisters =
              int.tryParse(family['marriedSisters']?.toString() ?? '0') ?? 0;
          _gothraController.text = family['gothra']?.toString() ?? '';
          _livingWithParents = family['livingWithParents']?.toString();
          _familyBasedOutOf = family['familyBasedOutOf']?.toString();
        });
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildCountSelector({
    required String label,
    required int value,
    required Function(int) onChanged,
    int max = 10,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
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

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final payload = <String, dynamic>{
        'section': 'family',
      };

      if (_aboutMyFamilyController.text.isNotEmpty) {
        payload['aboutMyFamily'] = _aboutMyFamilyController.text;
      }
      if (_familyStatus != null && _familyStatus!.isNotEmpty) {
        payload['familyStatus'] = _familyStatus;
      }
      if (_familyType != null && _familyType!.isNotEmpty) {
        payload['familyType'] = _familyType;
      }
      if (_familyValues != null && _familyValues!.isNotEmpty) {
        payload['familyValues'] = _familyValues;
      }
      if (_familyIncome != null && _familyIncome!.isNotEmpty) {
        payload['familyIncome'] = int.tryParse(_familyIncome!) ?? _familyIncome;
      }
      if (_fatherOccupation != null && _fatherOccupation!.isNotEmpty) {
        payload['fatherOccupation'] = _fatherOccupation;
      }
      if (_motherOccupation != null && _motherOccupation!.isNotEmpty) {
        payload['motherOccupation'] = _motherOccupation;
      }
      payload['brothers'] = _brothers.toString();
      payload['marriedBrothers'] = _marriedBrothers.toString();
      payload['sisters'] = _sisters.toString();
      payload['marriedSisters'] = _marriedSisters.toString();
      if (_gothraController.text.isNotEmpty) {
        payload['gothra'] = _gothraController.text;
      }
      if (_livingWithParents != null && _livingWithParents!.isNotEmpty) {
        payload['livingWithParents'] = _livingWithParents;
      }
      if (_familyBasedOutOf != null && _familyBasedOutOf!.isNotEmpty) {
        payload['familyBasedOutOf'] = _familyBasedOutOf;
      }

      final response = await _profileService.updateProfileSection(payload);

      if (response['status'] == 'success' || response['code'] == 'CH200') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          context.go('/my-profile');
        }
      } else {
        throw Exception(response['message'] ?? 'Failed to update profile');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lookupProvider = Provider.of<LookupProvider>(context);

    final livingWithParentsOptions = <LookupOption>[
      LookupOption(label: 'Yes', value: 'Y'),
      LookupOption(label: 'No', value: 'N'),
    ];

    if (_isLoading) {
      return Scaffold(
        appBar: const HeaderWidget(),
        bottomNavigationBar: const BottomNavigationWidget(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _profileData == null) {
      return Scaffold(
        appBar: const HeaderWidget(),
        bottomNavigationBar: const BottomNavigationWidget(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error ?? 'Failed to load profile',
                  style: const TextStyle(color: AppColors.error)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final characterCount = _aboutMyFamilyController.text.length;
    final maxCharacters = 125;
    final isOverLimit = characterCount > maxCharacters;

    return Scaffold(
      appBar: const HeaderWidget(),
      drawer: const SidebarWidget(),
      bottomNavigationBar: const BottomNavigationWidget(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(24),
                    border:
                        Border.all(color: theme.dividerColor.withOpacity(0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Edit Profile',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Update your family information',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Form
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(24),
                    border:
                        Border.all(color: theme.dividerColor.withOpacity(0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // About My Family
                      Text(
                        'About My Family',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _aboutMyFamilyController,
                        maxLines: 6,
                        maxLength: maxCharacters,
                        decoration: InputDecoration(
                          hintText: 'Tell us about your family...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color:
                                  isOverLimit ? Colors.red : theme.dividerColor,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color:
                                  isOverLimit ? Colors.red : theme.dividerColor,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color:
                                  isOverLimit ? Colors.red : AppColors.primary,
                              width: 2,
                            ),
                          ),
                          counterText: '$characterCount / $maxCharacters',
                          counterStyle: TextStyle(
                            color: isOverLimit
                                ? Colors.red
                                : theme.textTheme.bodySmall?.color,
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 24),
                      SearchableDropdown(
                        label: 'Family Status',
                        value: _familyStatus,
                        options: lookupProvider.familyStatusOptions,
                        hint: 'Select Family Status',
                        onChanged: (value) =>
                            setState(() => _familyStatus = value),
                      ),
                      const SizedBox(height: 16),
                      SearchableDropdown(
                        label: 'Family Type',
                        value: _familyType,
                        options: lookupProvider.familyTypeOptions,
                        hint: 'Select Family Type',
                        onChanged: (value) =>
                            setState(() => _familyType = value),
                      ),
                      const SizedBox(height: 16),
                      SearchableDropdown(
                        label: 'Family Values',
                        value: _familyValues,
                        options: lookupProvider.familyValuesOptions,
                        hint: 'Select Family Values',
                        onChanged: (value) =>
                            setState(() => _familyValues = value),
                      ),
                      const SizedBox(height: 16),
                      SearchableDropdown(
                        label: 'Family Income',
                        value: _familyIncome,
                        options: lookupProvider.incomeOptions,
                        hint: 'Select Family Income',
                        onChanged: (value) =>
                            setState(() => _familyIncome = value),
                      ),
                      const SizedBox(height: 16),
                      SearchableDropdown(
                        label: 'Father Occupation',
                        value: _fatherOccupation,
                        options:
                            (lookupProvider.lookupData['fathersOccupation'] ??
                                lookupProvider.occupations),
                        hint: 'Select Father Occupation',
                        onChanged: (value) =>
                            setState(() => _fatherOccupation = value),
                      ),
                      const SizedBox(height: 16),
                      SearchableDropdown(
                        label: 'Mother Occupation',
                        value: _motherOccupation,
                        options:
                            (lookupProvider.lookupData['mothersOccupation'] ??
                                lookupProvider.occupations),
                        hint: 'Select Mother Occupation',
                        onChanged: (value) =>
                            setState(() => _motherOccupation = value),
                      ),
                      const SizedBox(height: 24),
                      _buildCountSelector(
                        label: 'Brothers',
                        value: _brothers,
                        max: 10,
                        onChanged: (value) {
                          setState(() {
                            _brothers = value;
                            if (_marriedBrothers > value) {
                              _marriedBrothers = value;
                            }
                          });
                        },
                      ),
                      if (_brothers > 0) ...[
                        const SizedBox(height: 16),
                        _buildCountSelector(
                          label: 'Married Brothers',
                          value: _marriedBrothers,
                          max: _brothers,
                          onChanged: (value) =>
                              setState(() => _marriedBrothers = value),
                        ),
                      ],
                      const SizedBox(height: 24),
                      _buildCountSelector(
                        label: 'Sisters',
                        value: _sisters,
                        max: 10,
                        onChanged: (value) {
                          setState(() {
                            _sisters = value;
                            if (_marriedSisters > value) {
                              _marriedSisters = value;
                            }
                          });
                        },
                      ),
                      if (_sisters > 0) ...[
                        const SizedBox(height: 16),
                        _buildCountSelector(
                          label: 'Married Sisters',
                          value: _marriedSisters,
                          max: _sisters,
                          onChanged: (value) =>
                              setState(() => _marriedSisters = value),
                        ),
                      ],
                      const SizedBox(height: 24),
                      TextField(
                        controller: _gothraController,
                        decoration: InputDecoration(
                          labelText: 'Gothra',
                          hintText: 'Enter gothra',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SearchableDropdown(
                        label: 'I am Living with Parents',
                        value: _livingWithParents,
                        options: livingWithParentsOptions,
                        hint: 'Select Living with Parents',
                        onChanged: (value) =>
                            setState(() => _livingWithParents = value),
                      ),
                      const SizedBox(height: 16),
                      SearchableDropdown(
                        label: 'My Family Based Out of',
                        value: _familyBasedOutOf,
                        options: lookupProvider.countries,
                        hint: 'Select Family Based Out of',
                        onChanged: (value) =>
                            setState(() => _familyBasedOutOf = value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Submit Button
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
                      padding: const EdgeInsets.symmetric(vertical: 16),
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
                            'Update',
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
}




