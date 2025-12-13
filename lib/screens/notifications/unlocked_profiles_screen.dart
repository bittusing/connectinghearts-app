import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../widgets/profile/profile_match_card.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/bottom_navigation_widget.dart';
import '../../services/profile_service.dart';
import '../../utils/profile_utils.dart';

class UnlockedProfilesScreen extends StatefulWidget {
  const UnlockedProfilesScreen({super.key});

  @override
  State<UnlockedProfilesScreen> createState() => _UnlockedProfilesScreenState();
}

class _UnlockedProfilesScreenState extends State<UnlockedProfilesScreen> {
  final ProfileService _profileService = ProfileService();
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _profiles = [];

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _profileService.getUnlockedProfiles();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Unlocked Profiles'),
      ),
      bottomNavigationBar: const BottomNavigationWidget(),
      body: RefreshIndicator(
        onRefresh: _loadProfiles,
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
                          onPressed: _loadProfiles,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _profiles.isEmpty
                    ? const EmptyStateWidget(
                        message: 'No unlocked profiles yet.',
                        icon: Icons.lock_open_outlined,
                      )
                    : CustomScrollView(
                        slivers: [
                          // Header
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
                                    'CONNECTING HEARTS',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Unlocked Profiles',
                                    style:
                                        theme.textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Profiles you have unlocked to view contact details.',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Showing ${_profiles.length} profiles',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Profiles
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final profile = _profiles[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
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

