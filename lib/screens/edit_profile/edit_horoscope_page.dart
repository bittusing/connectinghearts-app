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

// Import LookupOption explicitly

class EditHoroscopePage extends StatefulWidget {
  const EditHoroscopePage({super.key});

  @override
  State<EditHoroscopePage> createState() => _EditHoroscopePageState();
}

class _EditHoroscopePageState extends State<EditHoroscopePage> {
  final ProfileService _profileService = ProfileService();
  final _formKey = GlobalKey<FormState>();
  final _timeOfBirthController = TextEditingController();

  bool _isLoading = true;
  bool _isSubmitting = false;
  Map<String, dynamic>? _profileData;
  String? _error;

  String? _rashi;
  String? _nakshatra;
  String? _manglik;
  String? _horoscope;
  String? _countryOfBirth;
  String? _stateOfBirth;
  String? _cityOfBirth;

  // Location options
  List<LookupOption> _stateOptions = [];
  List<LookupOption> _cityOptions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _timeOfBirthController.dispose();
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
        final horoscope = data['horoscope'] as Map<String, dynamic>? ?? {};

        setState(() {
          _profileData = data;
          _rashi = horoscope['rashi']?.toString();
          _nakshatra = horoscope['nakshatra']?.toString();
          _manglik = horoscope['manglik']?.toString();
          _horoscope = horoscope['horoscope']?.toString();
          _countryOfBirth = horoscope['countryOfBirth']?.toString();
          _stateOfBirth = horoscope['stateOfBirth']?.toString();
          _cityOfBirth = horoscope['cityOfBirth']?.toString();
          _timeOfBirthController.text =
              horoscope['timeOfBirth']?.toString() ?? '';
        });

        // Load states and cities if country/state are available
        if (_countryOfBirth != null && _countryOfBirth!.isNotEmpty) {
          try {
            final states = await lookupProvider.getStates(_countryOfBirth!);
            setState(() => _stateOptions = states);

            if (_stateOfBirth != null && _stateOfBirth!.isNotEmpty) {
              try {
                final cities = await lookupProvider.getCities(_stateOfBirth!);
                setState(() => _cityOptions = cities);
              } catch (_) {}
            }
          } catch (_) {}
        }
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleCountryChange(String? countryId) async {
    setState(() {
      _countryOfBirth = countryId;
      _stateOfBirth = null;
      _cityOfBirth = null;
      _stateOptions = [];
      _cityOptions = [];
    });

    if (countryId != null && countryId.isNotEmpty) {
      try {
        final lookupProvider =
            Provider.of<LookupProvider>(context, listen: false);
        final states = await lookupProvider.getStates(countryId);
        setState(() => _stateOptions = states);
      } catch (_) {}
    }
  }

  Future<void> _handleStateChange(String? stateId) async {
    setState(() {
      _stateOfBirth = stateId;
      _cityOfBirth = null;
      _cityOptions = [];
    });

    if (stateId != null && stateId.isNotEmpty) {
      try {
        final lookupProvider =
            Provider.of<LookupProvider>(context, listen: false);
        final cities = await lookupProvider.getCities(stateId);
        setState(() => _cityOptions = cities);
      } catch (_) {}
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final payload = <String, dynamic>{
        'section': 'horoscope',
      };

      if (_rashi != null && _rashi!.isNotEmpty) payload['rashi'] = _rashi;
      if (_nakshatra != null && _nakshatra!.isNotEmpty) {
        payload['nakshatra'] = _nakshatra;
      }
      if (_manglik != null && _manglik!.isNotEmpty)
        payload['manglik'] = _manglik;
      if (_horoscope != null && _horoscope!.isNotEmpty) {
        payload['horoscope'] = _horoscope;
      }
      if (_countryOfBirth != null && _countryOfBirth!.isNotEmpty) {
        payload['countryOfBirth'] = _countryOfBirth;
      }
      if (_stateOfBirth != null && _stateOfBirth!.isNotEmpty) {
        payload['stateOfBirth'] = _stateOfBirth;
      }
      if (_cityOfBirth != null && _cityOfBirth!.isNotEmpty) {
        payload['cityOfBirth'] = _cityOfBirth;
      }
      if (_timeOfBirthController.text.isNotEmpty) {
        payload['timeOfBirth'] = _timeOfBirthController.text;
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
                        'Update your horoscope information',
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
                      SearchableDropdown(
                        label: 'Rashi',
                        value: _rashi,
                        options: lookupProvider.horoscopes,
                        hint: 'Select Rashi',
                        onChanged: (value) => setState(() => _rashi = value),
                      ),
                      const SizedBox(height: 16),
                      SearchableDropdown(
                        label: 'Nakshatra',
                        value: _nakshatra,
                        options: (lookupProvider.lookupData['nakshatra']
                                    as List<dynamic>?)
                                ?.cast<LookupOption>() ??
                            <LookupOption>[],
                        hint: 'Select Nakshatra',
                        onChanged: (value) =>
                            setState(() => _nakshatra = value),
                      ),
                      const SizedBox(height: 16),
                      SearchableDropdown(
                        label: 'Country Of Birth',
                        value: _countryOfBirth,
                        options: lookupProvider.countries,
                        hint: 'Select Country Of Birth',
                        onChanged: _handleCountryChange,
                      ),
                      const SizedBox(height: 16),
                      SearchableDropdown(
                        label: 'State Of Birth',
                        value: _stateOfBirth,
                        options: _stateOptions,
                        hint: 'Select State Of Birth',
                        enabled: _countryOfBirth != null &&
                            _countryOfBirth!.isNotEmpty,
                        onChanged: _handleStateChange,
                      ),
                      const SizedBox(height: 16),
                      SearchableDropdown(
                        label: 'City Of Birth',
                        value: _cityOfBirth,
                        options: _cityOptions,
                        hint: 'Select City Of Birth',
                        enabled:
                            _stateOfBirth != null && _stateOfBirth!.isNotEmpty,
                        onChanged: (value) =>
                            setState(() => _cityOfBirth = value),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _timeOfBirthController,
                        decoration: InputDecoration(
                          labelText: 'Time Of Birth',
                          hintText: 'Enter Time Of Birth (e.g., 05-07-1995)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SearchableDropdown(
                        label: 'Horoscope',
                        value: _horoscope,
                        options: lookupProvider.horoscopes,
                        hint: 'Select Horoscope',
                        onChanged: (value) =>
                            setState(() => _horoscope = value),
                      ),
                      const SizedBox(height: 16),
                      SearchableDropdown(
                        label: 'Manglik',
                        value: _manglik,
                        options: lookupProvider.manglik,
                        hint: 'Select Manglik',
                        onChanged: (value) => setState(() => _manglik = value),
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




