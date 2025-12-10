import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../widgets/profile/profile_match_card.dart';
import '../../widgets/common/empty_state_widget.dart';

class ProfilesScreen extends StatefulWidget {
  const ProfilesScreen({super.key});

  @override
  State<ProfilesScreen> createState() => _ProfilesScreenState();
}

class _ProfilesScreenState extends State<ProfilesScreen> {
  bool _isLoading = true;
  bool _isRefreshing = false;
  final List<Map<String, dynamic>> _profiles = [];

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {
        _isLoading = false;
        // Add mock data for demonstration
        _profiles.addAll([
          {
            'id': '1',
            'name': 'HEARTS-1001',
            'age': 25,
            'height': "5'6\"",
            'location': 'Mumbai, Maharashtra',
            'religion': 'Hindu',
            'salary': '10-15 LPA',
          },
          {
            'id': '2',
            'name': 'HEARTS-1002',
            'age': 27,
            'height': "5'8\"",
            'location': 'Delhi, NCR',
            'religion': 'Hindu',
            'salary': '15-20 LPA',
          },
          {
            'id': '3',
            'name': 'HEARTS-1003',
            'age': 24,
            'height': "5'4\"",
            'location': 'Bangalore, Karnataka',
            'religion': 'Hindu',
            'salary': '8-12 LPA',
          },
        ]);
      });
    }
  }

  Future<void> _onRefresh() async {
    setState(() => _isRefreshing = true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  void _handleSendInterest(String profileId) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Interest sent successfully'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _handleShortlist(String profileId) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile shortlisted successfully'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _handleIgnore(String profileId) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile ignored successfully'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Loading profiles...',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              )
            : _profiles.isEmpty
                ? const EmptyStateWidget(
                    message: 'No profiles found.',
                    icon: Icons.people_outline,
                  )
                : RefreshIndicator(
                    onRefresh: _onRefresh,
                    color: AppColors.primary,
                    child: PageView.builder(
                      scrollDirection: Axis.vertical,
                      itemCount: _profiles.length,
                      itemBuilder: (context, index) {
                        final profile = _profiles[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 10,
                          ),
                          child: ProfileMatchCard(
                            id: profile['id'],
                            name: profile['name'],
                            age: profile['age'],
                            height: profile['height'],
                            location: profile['location'],
                            religion: profile['religion'],
                            salary: profile['salary'],
                            onSendInterest: () => _handleSendInterest(profile['id']),
                            onShortlist: () => _handleShortlist(profile['id']),
                            onIgnore: () => _handleIgnore(profile['id']),
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}
