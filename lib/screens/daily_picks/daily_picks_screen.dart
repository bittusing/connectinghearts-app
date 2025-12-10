import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../widgets/profile/profile_match_card.dart';
import '../../widgets/common/empty_state_widget.dart';

class DailyPicksScreen extends StatefulWidget {
  const DailyPicksScreen({super.key});

  @override
  State<DailyPicksScreen> createState() => _DailyPicksScreenState();
}

class _DailyPicksScreenState extends State<DailyPicksScreen> {
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
        _profiles.addAll([
          {
            'id': '1',
            'name': 'HEARTS-2001',
            'age': 26,
            'height': "5'5\"",
            'location': 'Chennai, Tamil Nadu',
            'religion': 'Hindu',
            'salary': '12-18 LPA',
          },
          {
            'id': '2',
            'name': 'HEARTS-2002',
            'age': 28,
            'height': "5'7\"",
            'location': 'Hyderabad, Telangana',
            'religion': 'Hindu',
            'salary': '18-25 LPA',
          },
          {
            'id': '3',
            'name': 'HEARTS-2003',
            'age': 25,
            'height': "5'3\"",
            'location': 'Pune, Maharashtra',
            'religion': 'Hindu',
            'salary': '10-15 LPA',
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
                      'Loading recommendations...',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              )
            : _profiles.isEmpty
                ? const EmptyStateWidget(
                    message: 'No daily picks available.',
                    icon: Icons.favorite_outline,
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
                            showCompatibilityTag: true,
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
