import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/colors.dart';
import '../../widgets/profile/profile_match_card.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../services/profile_service.dart';
import '../../models/profile_models.dart';
import '../../utils/profile_utils.dart';

class InterestsSentScreen extends StatefulWidget {
  const InterestsSentScreen({super.key});

  @override
  State<InterestsSentScreen> createState() => _InterestsSentScreenState();
}

class _InterestsSentScreenState extends State<InterestsSentScreen> {
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
      final response = await _profileService.getInterestsSent();
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

  Future<void> _handleUnsendInterest(String profileId) async {
    try {
      await _profileService.unsendInterest(profileId);
      _showToast('Interest unsent successfully');
      _loadProfiles();
    } catch (e) {
      _showToast(e.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Interests Sent'),
      ),
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
                        message: 'No interests sent yet.',
                        icon: Icons.send_outlined,
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
                                    'Interests Sent',
                                    style: theme.textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Profiles you have shown interest in.',
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
                                    onSendInterest: () => _handleUnsendInterest(profile['id']),
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
