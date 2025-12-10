import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../widgets/profile/profile_match_card.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../services/profile_service.dart';
import '../../utils/profile_utils.dart';

class AcceptanceScreen extends StatefulWidget {
  const AcceptanceScreen({super.key});

  @override
  State<AcceptanceScreen> createState() => _AcceptanceScreenState();
}

class _AcceptanceScreenState extends State<AcceptanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ProfileService _profileService = ProfileService();
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _profiles = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadProfiles();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      _loadProfiles();
    }
  }

  Future<void> _loadProfiles() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final endpoint = _tabController.index == 0
          ? 'dashboard/getAcceptanceProfiles/acceptedMe'
          : 'dashboard/getAcceptanceProfiles/acceptedByMe';

      final response = await _profileService.getProfilesByEndpoint(endpoint);
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

  Future<void> _handleChat(String profileId) async {
    _showToast('Chat Coming Soon');
  }

  Future<void> _handleDecline(String profileId) async {
    try {
      await _profileService.declineInterest(profileId);
      _showToast('Interest declined');
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
        title: const Text('Acceptance'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Accepted Me'),
            Tab(text: 'Accepted By Me'),
          ],
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
        ),
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
                    ? EmptyStateWidget(
                        message: _tabController.index == 0
                            ? 'No one has accepted your interest yet.'
                            : 'You haven\'t accepted any interests yet.',
                        icon: Icons.favorite_outline,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _profiles.length,
                        itemBuilder: (context, index) {
                          final profile = _profiles[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: ProfileMatchCard(
                              id: profile['id'] ?? '',
                              name: profile['name'] ?? '',
                              age: profile['age'] ?? 0,
                              height: profile['height'] ?? '',
                              location: profile['location'] ?? '',
                              religion: profile['religion'],
                              salary: profile['income'],
                              imageUrl: profile['imageUrl'],
                              customActions: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildActionButton(
                                    icon: Icons.chat_bubble_outline,
                                    label: 'Chat',
                                    color: Colors.blue,
                                    onTap: () => _handleChat(profile['id']),
                                  ),
                                  const SizedBox(width: 16),
                                  _buildActionButton(
                                    icon: Icons.close,
                                    label: 'Decline',
                                    color: Colors.red,
                                    onTap: () => _handleDecline(profile['id']),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

