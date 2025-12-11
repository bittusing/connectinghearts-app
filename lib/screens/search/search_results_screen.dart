import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../widgets/profile/profile_match_card.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../services/profile_service.dart';
import '../../models/profile_models.dart';
import '../../utils/profile_utils.dart';

class SearchResultsScreen extends StatefulWidget {
  final ProfileSearchPayload filters;

  const SearchResultsScreen({
    super.key,
    required this.filters,
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  final ProfileService _profileService = ProfileService();
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _profiles = [];

  @override
  void initState() {
    super.initState();
    _searchProfiles();
  }

  Future<void> _searchProfiles() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _profileService.searchProfiles(widget.filters);
      setState(() {
        _profiles = response.data.map((p) => transformProfile(p)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }

  Future<void> _handleSendInterest(String profileId) async {
    try {
      await _profileService.sendInterest(profileId);
      _showToast('Interest sent successfully');
    } catch (e) {
      _showToast(e.toString(), isError: true);
    }
  }

  Future<void> _handleShortlist(String profileId) async {
    try {
      await _profileService.shortlistProfile(profileId);
      _showToast('Profile shortlisted successfully');
    } catch (e) {
      _showToast(e.toString(), isError: true);
    }
  }

  Future<void> _handleIgnore(String profileId) async {
    try {
      await _profileService.ignoreProfile(profileId);
      _showToast('Profile ignored successfully');
      _searchProfiles();
    } catch (e) {
      _showToast(e.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Search Results')),
      body: RefreshIndicator(
        onRefresh: _searchProfiles,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _error!,
                          style: const TextStyle(color: AppColors.error),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _searchProfiles,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _profiles.isEmpty
                    ? const EmptyStateWidget(
                        message: 'No profiles found matching your criteria.',
                        icon: Icons.search_off,
                      )
                    : CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: Container(
                              margin: const EdgeInsets.all(16),
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
                                    'Search Results',
                                    style:
                                        theme.textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Found ${_profiles.length} profiles matching your criteria.',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final profile = _profiles[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 10,
                                  ),
                                  child: ProfileMatchCard(
                                    id: profile['id'] ?? '',
                                    name: profile['name'] ?? '',
                                    age: profile['age'] ?? 0,
                                    height: profile['height'] ?? '',
                                    location: profile['location'] ?? '',
                                    religion: profile['religion'],
                                    salary: profile['income'],
                                    imageUrl: profile['imageUrl'],
                                    gender: profile['gender'],
                                    onSendInterest: () =>
                                        _handleSendInterest(profile['id']),
                                    onShortlist: () =>
                                        _handleShortlist(profile['id']),
                                    onIgnore: () =>
                                        _handleIgnore(profile['id']),
                                  ),
                                );
                              },
                              childCount: _profiles.length,
                            ),
                          ),
                          const SliverToBoxAdapter(
                            child: SizedBox(height: 100),
                          ),
                        ],
                      ),
      ),
    );
  }
}
