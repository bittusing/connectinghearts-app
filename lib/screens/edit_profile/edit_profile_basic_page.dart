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

class EditProfileBasicPage extends StatefulWidget {
  const EditProfileBasicPage({super.key});

  @override
  State<EditProfileBasicPage> createState() => _EditProfileBasicPageState();
}

class _EditProfileBasicPageState extends State<EditProfileBasicPage> {
  final ProfileService _profileService = ProfileService();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  bool _isSubmitting = false;
  Map<String, dynamic>? _profileData;
  String? _error;

  // Form fields
  String? _religion;
  String? _residentialStatus;
  String? _motherTongue;
  String? _country;
  String? _state;
  String? _city;
  String? _income;
  String? _caste;
  String? _height;

  // Location options
  List<LookupOption> _stateOptions = [];
  List<LookupOption> _cityOptions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
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
        final basic = data['basic'] as Map<String, dynamic>? ?? {};
        final misc = data['miscellaneous'] as Map<String, dynamic>? ?? {};

        setState(() {
          _profileData = data;
          _religion = basic['religion']?.toString();
          _residentialStatus = misc['residentialStatus']?.toString() ??
              basic['residentialStatus']?.toString();
          _motherTongue = basic['motherTongue']?.toString();
          _country =
              misc['country']?.toString() ?? basic['country']?.toString();
          _income = basic['income']?.toString();
          _caste = basic['cast']?.toString();
          _height = basic['height']?.toString();
          _state = misc['state']?.toString() ?? basic['state']?.toString();
          _city = misc['city']?.toString() ?? basic['city']?.toString();
        });

        // Load states and cities if country/state are available
        if (_country != null && _country!.isNotEmpty) {
          try {
            final states = await lookupProvider.getStates(_country!);
            setState(() => _stateOptions = states);

            if (_state != null && _state!.isNotEmpty) {
              try {
                final cities = await lookupProvider.getCities(_state!);
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
      _country = countryId;
      _state = null;
      _city = null;
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
      _state = stateId;
      _city = null;
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
        'section': 'basic',
      };

      if (_religion != null && _religion!.isNotEmpty)
        payload['religion'] = _religion;
      if (_residentialStatus != null && _residentialStatus!.isNotEmpty) {
        payload['residentialStatus'] = _residentialStatus;
      }
      if (_motherTongue != null && _motherTongue!.isNotEmpty) {
        payload['motherTongue'] = _motherTongue;
      }
      if (_country != null && _country!.isNotEmpty)
        payload['country'] = _country;
      if (_state != null && _state!.isNotEmpty) payload['state'] = _state;
      if (_city != null && _city!.isNotEmpty) payload['city'] = _city;
      if (_income != null && _income!.isNotEmpty) {
        payload['income'] = int.tryParse(_income!) ?? _income;
      }
      if (_caste != null && _caste!.isNotEmpty) payload['cast'] = _caste;
      if (_height != null && _height!.isNotEmpty) {
        payload['height'] = int.tryParse(_height!) ?? _height;
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
                        'Update your basic profile information',
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
                        label: 'Religion',
                        value: _religion,
                        options: lookupProvider.religions,
                        hint: 'Select Religion',
                        onChanged: (value) => setState(() => _religion = value),
                      ),
                      const SizedBox(height: 16),
                      SearchableDropdown(
                        label: 'Residential Status',
                        value: _residentialStatus,
                        options: lookupProvider.residentialStatuses,
                        hint: 'Select Residential Status',
                        onChanged: (value) =>
                            setState(() => _residentialStatus = value),
                      ),
                      const SizedBox(height: 16),
                      SearchableDropdown(
                        label: 'Mother Tongue',
                        value: _motherTongue,
                        options: lookupProvider.motherTongues,
                        hint: 'Select Mother Tongue',
                        onChanged: (value) =>
                            setState(() => _motherTongue = value),
                      ),
                      const SizedBox(height: 16),
                      SearchableDropdown(
                        label: 'Country',
                        value: _country,
                        options: lookupProvider.countries,
                        hint: 'Select Country',
                        onChanged: _handleCountryChange,
                      ),
                      const SizedBox(height: 16),
                      SearchableDropdown(
                        label: 'State',
                        value: _state,
                        options: _stateOptions,
                        hint: 'Select State',
                        enabled: _country != null && _country!.isNotEmpty,
                        onChanged: _handleStateChange,
                      ),
                      const SizedBox(height: 16),
                      SearchableDropdown(
                        label: 'City',
                        value: _city,
                        options: _cityOptions,
                        hint: 'Select City',
                        enabled: _state != null && _state!.isNotEmpty,
                        onChanged: (value) => setState(() => _city = value),
                      ),
                      const SizedBox(height: 16),
                      SearchableDropdown(
                        label: 'Income',
                        value: _income,
                        options: lookupProvider.incomeOptions,
                        hint: 'Select Income',
                        onChanged: (value) => setState(() => _income = value),
                      ),
                      const SizedBox(height: 16),
                      SearchableDropdown(
                        label: 'Caste',
                        value: _caste,
                        options: lookupProvider.castes,
                        hint: 'Select Caste',
                        onChanged: (value) => setState(() => _caste = value),
                      ),
                      const SizedBox(height: 16),
                      SearchableDropdown(
                        label: 'Height',
                        value: _height,
                        options: lookupProvider.heightOptions,
                        hint: 'Select Height',
                        onChanged: (value) => setState(() => _height = value),
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




