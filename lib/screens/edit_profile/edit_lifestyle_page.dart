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
import '../../widgets/common/searchable_multi_select.dart';
import '../../models/profile_models.dart';

class EditLifestylePage extends StatefulWidget {
  const EditLifestylePage({super.key});

  @override
  State<EditLifestylePage> createState() => _EditLifestylePageState();
}

class _EditLifestylePageState extends State<EditLifestylePage> {
  final ProfileService _profileService = ProfileService();
  final _formKey = GlobalKey<FormState>();
  final _foodICookController = TextEditingController();
  final _favReadController = TextEditingController();
  final _moviesController = TextEditingController();
  final _favTVShowController = TextEditingController();
  final _vacayDestinationController = TextEditingController();

  bool _isLoading = true;
  bool _isSubmitting = false;
  Map<String, dynamic>? _profileData;
  String? _error;

  String? _dietaryHabits;
  String? _drinkingHabits;
  String? _smokingHabits;
  String? _ownAHouse;
  String? _ownACar;
  String? _openToPets;

  List<String> _languages = [];
  List<String> _hobbies = [];
  List<String> _interest = [];
  List<String> _favMusic = [];
  List<String> _dress = [];
  List<String> _sports = [];
  List<String> _books = [];
  List<String> _cuisine = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _foodICookController.dispose();
    _favReadController.dispose();
    _moviesController.dispose();
    _favTVShowController.dispose();
    _vacayDestinationController.dispose();
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
        final lifestyle = data['lifeStyleData'] as Map<String, dynamic>? ?? {};

        setState(() {
          _profileData = data;
          _dietaryHabits = lifestyle['dietaryHabits']?.toString();
          _drinkingHabits = lifestyle['drinkingHabits']?.toString();
          _smokingHabits = lifestyle['smokingHabits']?.toString();
          _ownAHouse = lifestyle['ownAHouse']?.toString();
          _ownACar = lifestyle['ownACar']?.toString();
          _openToPets = lifestyle['openToPets']?.toString();
          _foodICookController.text = lifestyle['foodICook']?.toString() ?? '';
          _favReadController.text = lifestyle['favRead']?.toString() ?? '';
          _moviesController.text = lifestyle['movies']?.toString() ?? '';
          _favTVShowController.text = lifestyle['favTVShow']?.toString() ?? '';
          _vacayDestinationController.text =
              lifestyle['vacayDestination']?.toString() ?? '';

          // Handle arrays
          if (lifestyle['languages'] is List) {
            _languages = (lifestyle['languages'] as List)
                .map((e) => e.toString())
                .toList();
          }
          if (lifestyle['hobbies'] is List) {
            _hobbies = (lifestyle['hobbies'] as List)
                .map((e) => e.toString())
                .toList();
          }
          if (lifestyle['interest'] is List) {
            _interest = (lifestyle['interest'] as List)
                .map((e) => e.toString())
                .toList();
          }
          if (lifestyle['favMusic'] is List) {
            _favMusic = (lifestyle['favMusic'] as List)
                .map((e) => e.toString())
                .toList();
          }
          if (lifestyle['dress'] is List) {
            _dress =
                (lifestyle['dress'] as List).map((e) => e.toString()).toList();
          }
          if (lifestyle['sports'] is List) {
            _sports =
                (lifestyle['sports'] as List).map((e) => e.toString()).toList();
          }
          if (lifestyle['books'] is List) {
            _books =
                (lifestyle['books'] as List).map((e) => e.toString()).toList();
          }
          if (lifestyle['cuisine'] is List) {
            _cuisine = (lifestyle['cuisine'] as List)
                .map((e) => e.toString())
                .toList();
          }
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

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final payload = <String, dynamic>{
        'section': 'lifestyle',
      };

      if (_dietaryHabits != null && _dietaryHabits!.isNotEmpty) {
        payload['dietaryHabits'] = _dietaryHabits;
      }
      if (_drinkingHabits != null && _drinkingHabits!.isNotEmpty) {
        payload['drinkingHabits'] = _drinkingHabits;
      }
      if (_smokingHabits != null && _smokingHabits!.isNotEmpty) {
        payload['smokingHabits'] = _smokingHabits;
      }
      if (_ownAHouse != null && _ownAHouse!.isNotEmpty) {
        payload['ownAHouse'] = _ownAHouse;
      }
      if (_ownACar != null && _ownACar!.isNotEmpty) {
        payload['ownACar'] = _ownACar;
      }
      if (_openToPets != null && _openToPets!.isNotEmpty) {
        payload['openToPets'] = _openToPets;
      }
      if (_languages.isNotEmpty) payload['languages'] = _languages;
      if (_hobbies.isNotEmpty) payload['hobbies'] = _hobbies;
      if (_interest.isNotEmpty) payload['interest'] = _interest;
      if (_foodICookController.text.isNotEmpty) {
        payload['foodICook'] = _foodICookController.text;
      }
      if (_favMusic.isNotEmpty) payload['favMusic'] = _favMusic;
      if (_favReadController.text.isNotEmpty) {
        payload['favRead'] = _favReadController.text;
      }
      if (_dress.isNotEmpty) payload['dress'] = _dress;
      if (_sports.isNotEmpty) payload['sports'] = _sports;
      if (_books.isNotEmpty) payload['books'] = _books;
      if (_cuisine.isNotEmpty) payload['cuisine'] = _cuisine;
      if (_moviesController.text.isNotEmpty) {
        payload['movies'] = _moviesController.text;
      }
      if (_favTVShowController.text.isNotEmpty) {
        payload['favTVShow'] = _favTVShowController.text;
      }
      if (_vacayDestinationController.text.isNotEmpty) {
        payload['vacayDestination'] = _vacayDestinationController.text;
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

    final yesNoOptions = <LookupOption>[
      LookupOption(label: 'Yes', value: 'Y'),
      LookupOption(label: 'No', value: 'N'),
    ];

    // Get lookup options
    final languagesOptions =
        (lookupProvider.lookupData['languages'] as List<dynamic>?)
                ?.cast<LookupOption>() ??
            lookupProvider.motherTongues;
    final hobbiesOptions =
        (lookupProvider.lookupData['hobbies'] as List<dynamic>?)
                ?.cast<LookupOption>() ??
            <LookupOption>[];
    final interestsOptions =
        (lookupProvider.lookupData['interests'] as List<dynamic>?)
                ?.cast<LookupOption>() ??
            <LookupOption>[];
    final musicOptions = (lookupProvider.lookupData['music'] as List<dynamic>?)
            ?.cast<LookupOption>() ??
        <LookupOption>[];
    final dressOptions =
        (lookupProvider.lookupData['dressStyle'] as List<dynamic>?)
                ?.cast<LookupOption>() ??
            <LookupOption>[];
    final sportsOptions =
        (lookupProvider.lookupData['sports'] as List<dynamic>?)
                ?.cast<LookupOption>() ??
            <LookupOption>[];
    final booksOptions = (lookupProvider.lookupData['books'] as List<dynamic>?)
            ?.cast<LookupOption>() ??
        <LookupOption>[];
    final cuisineOptions =
        (lookupProvider.lookupData['cuisines'] as List<dynamic>?)
                ?.cast<LookupOption>() ??
            <LookupOption>[];

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
                        'Update your lifestyle information',
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
                      // Habits Section
                      Text(
                        'Habits',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SearchableDropdown(
                        label: 'Dietary Habits',
                        value: _dietaryHabits,
                        options: (lookupProvider.lookupData['dietaryHabits']
                                    as List<dynamic>?)
                                ?.cast<LookupOption>() ??
                            <LookupOption>[],
                        hint: 'Select Dietary Habits',
                        onChanged: (value) =>
                            setState(() => _dietaryHabits = value),
                      ),
                      const SizedBox(height: 16),
                      SearchableDropdown(
                        label: 'Drinking Habits',
                        value: _drinkingHabits,
                        options: (lookupProvider.lookupData['drinkingHabits']
                                    as List<dynamic>?)
                                ?.cast<LookupOption>() ??
                            <LookupOption>[],
                        hint: 'Select Drinking Habits',
                        onChanged: (value) =>
                            setState(() => _drinkingHabits = value),
                      ),
                      const SizedBox(height: 16),
                      SearchableDropdown(
                        label: 'Smoking Habits',
                        value: _smokingHabits,
                        options: (lookupProvider.lookupData['smokingHabits']
                                    as List<dynamic>?)
                                ?.cast<LookupOption>() ??
                            <LookupOption>[],
                        hint: 'Select Smoking Habits',
                        onChanged: (value) =>
                            setState(() => _smokingHabits = value),
                      ),
                      const SizedBox(height: 24),
                      // Assets Section
                      Text(
                        'Assets',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SearchableDropdown(
                        label: 'Own a House?',
                        value: _ownAHouse,
                        options: yesNoOptions,
                        hint: 'Select Own a House',
                        onChanged: (value) =>
                            setState(() => _ownAHouse = value),
                      ),
                      const SizedBox(height: 16),
                      SearchableDropdown(
                        label: 'Own A Car?',
                        value: _ownACar,
                        options: yesNoOptions,
                        hint: 'Select Own A Car',
                        onChanged: (value) => setState(() => _ownACar = value),
                      ),
                      const SizedBox(height: 16),
                      SearchableDropdown(
                        label: 'Open To Pets?',
                        value: _openToPets,
                        options: yesNoOptions,
                        hint: 'Select Open To Pets',
                        onChanged: (value) =>
                            setState(() => _openToPets = value),
                      ),
                      const SizedBox(height: 24),
                      // Other Life Style Preferences
                      Text(
                        'Other Life Style Preferences',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SearchableMultiSelect(
                        label: 'Language Known',
                        values: _languages,
                        options: languagesOptions,
                        hint: 'Select languages',
                        onChanged: (values) =>
                            setState(() => _languages = values),
                      ),
                      const SizedBox(height: 16),
                      SearchableMultiSelect(
                        label: 'Hobbies',
                        values: _hobbies,
                        options: hobbiesOptions,
                        hint: 'Select hobbies',
                        onChanged: (values) =>
                            setState(() => _hobbies = values),
                      ),
                      const SizedBox(height: 16),
                      SearchableMultiSelect(
                        label: 'Interests',
                        values: _interest,
                        options: interestsOptions,
                        hint: 'Select interests',
                        onChanged: (values) =>
                            setState(() => _interest = values),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _foodICookController,
                        decoration: InputDecoration(
                          labelText: 'Food I Cook',
                          hintText: 'Enter food you cook',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SearchableMultiSelect(
                        label: 'Favourite Music',
                        values: _favMusic,
                        options: musicOptions,
                        hint: 'Select favourite music',
                        onChanged: (values) =>
                            setState(() => _favMusic = values),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _favReadController,
                        decoration: InputDecoration(
                          labelText: 'Favourite Read',
                          hintText: 'Enter favourite read',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SearchableMultiSelect(
                        label: 'Dress Style',
                        values: _dress,
                        options: dressOptions,
                        hint: 'Select dress style',
                        onChanged: (values) => setState(() => _dress = values),
                      ),
                      const SizedBox(height: 16),
                      SearchableMultiSelect(
                        label: 'Sports',
                        values: _sports,
                        options: sportsOptions,
                        hint: 'Select sports',
                        onChanged: (values) => setState(() => _sports = values),
                      ),
                      const SizedBox(height: 16),
                      SearchableMultiSelect(
                        label: 'Favourite Books',
                        values: _books,
                        options: booksOptions,
                        hint: 'Select favourite books',
                        onChanged: (values) => setState(() => _books = values),
                      ),
                      const SizedBox(height: 16),
                      SearchableMultiSelect(
                        label: 'Favourite Cuisine',
                        values: _cuisine,
                        options: cuisineOptions,
                        hint: 'Select favourite cuisine',
                        onChanged: (values) =>
                            setState(() => _cuisine = values),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _moviesController,
                        decoration: InputDecoration(
                          labelText: 'Favourite Movies',
                          hintText: 'Enter favourite movies',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _favTVShowController,
                        decoration: InputDecoration(
                          labelText: 'Favourite TV Show',
                          hintText: 'Enter favourite TV show',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _vacayDestinationController,
                        decoration: InputDecoration(
                          labelText: 'Vacation Destination',
                          hintText: 'Enter vacation destination',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
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




