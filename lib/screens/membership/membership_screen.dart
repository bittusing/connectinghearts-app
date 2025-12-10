import 'package:flutter/material.dart';
import '../../theme/colors.dart';

class MembershipScreen extends StatefulWidget {
  const MembershipScreen({super.key});

  @override
  State<MembershipScreen> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends State<MembershipScreen> {
  bool _isLoading = true;
  final List<Map<String, dynamic>> _plans = [];
  Map<String, dynamic>? _activePlan;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {
        _isLoading = false;
        _plans.addAll([
          {
            'id': 'silver',
            'name': 'Silver',
            'price': 999,
            'duration': 1,
            'heartCoins': 30,
            'features': [
              '1 month validity',
              'View 30 contacts',
              'Basic search filters',
            ],
            'cardColor': const Color(0xFFF3F4F6),
            'borderColor': const Color(0xFFE5E7EB),
          },
          {
            'id': 'gold',
            'name': 'Gold',
            'price': 1999,
            'duration': 3,
            'heartCoins': 50,
            'features': [
              '3 months validity',
              'View 50 contacts',
              '3X faster matches',
              'Profile boost',
            ],
            'cardColor': const Color(0xFFFEF3C7),
            'borderColor': const Color(0xFFFDE68A),
          },
          {
            'id': 'platinum',
            'name': 'Platinum',
            'price': 4999,
            'duration': 6,
            'heartCoins': 100,
            'features': [
              '6 months validity',
              'View 100 contacts',
              '3X faster matches',
              'Profile boost top spot',
              'Priority support',
            ],
            'cardColor': const Color(0xFFFDF2F8),
            'borderColor': const Color(0xFFFBCFE8),
          },
        ]);
      });
    }
  }

  void _handleChoosePlan(Map<String, dynamic> plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Choose ${plan['name']} Plan'),
        content: Text(
          'You are about to purchase the ${plan['name']} plan for ₹${plan['price']}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement payment
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Payment integration coming soon'),
                ),
              );
            },
            child: const Text('Proceed'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Header Card
                    Container(
                      width: double.infinity,
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
                            'MEMBERSHIP',
                            style: theme.textTheme.bodySmall?.copyWith(
                              letterSpacing: 1.6,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Activate your plan',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Choose a plan that matches your family\'s expectations. Upgrade anytime — your preferences stay intact.',
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 16),
                          // Active Plan Status
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Active plan: ${_activePlan?['name'] ?? 'No active plan'}',
                                  style: const TextStyle(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (_activePlan == null)
                                  Text(
                                    'Choose a plan to get started',
                                    style: TextStyle(
                                      color: AppColors.success.withOpacity(0.8),
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Plans
                    ..._plans.map((plan) => _buildPlanCard(plan)),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    final theme = Theme.of(context);
    final isPlatinum = plan['id'] == 'platinum';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: plan['cardColor'] as Color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: plan['borderColor'] as Color),
        boxShadow: [
          BoxShadow(
            color: isPlatinum
                ? const Color(0xFFFBCFE8).withOpacity(0.5)
                : Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Plan Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PLAN',
                    style: theme.textTheme.bodySmall?.copyWith(
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    plan['name'],
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Text(
                '₹${plan['price']} / ${plan['duration']} ${plan['duration'] == 1 ? 'month' : 'months'}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${plan['heartCoins']} Heart Coins • ${plan['duration']} ${plan['duration'] == 1 ? 'month' : 'months'} validity',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          // Features
          ...(plan['features'] as List<String>).map((feature) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feature,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 24),
          // Choose Plan Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _handleChoosePlan(plan),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isPlatinum ? const Color(0xFF9333EA) : theme.cardColor,
                foregroundColor: isPlatinum
                    ? Colors.white
                    : theme.textTheme.bodyLarge?.color,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                  side: isPlatinum
                      ? BorderSide.none
                      : BorderSide(color: theme.dividerColor),
                ),
              ),
              child: const Text(
                'Choose plan',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
