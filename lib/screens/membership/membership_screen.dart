import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../services/membership_service.dart';
import '../../widgets/common/bottom_navigation_widget.dart';
import '../../widgets/common/header_widget.dart';
import '../../widgets/common/sidebar_widget.dart';
import '../../models/profile_models.dart';

class MembershipScreen extends StatefulWidget {
  const MembershipScreen({super.key});

  @override
  State<MembershipScreen> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends State<MembershipScreen> {
  final MembershipService _membershipService = MembershipService();
  bool _isLoading = true;
  String? _error;
  final List<Map<String, dynamic>> _plans = [];
  Map<String, dynamic>? _activePlan;
  int _heartCoins = 0;

  @override
  void initState() {
    super.initState();
    _loadMembershipData();
  }

  Future<void> _loadMembershipData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _membershipService.getMembershipPlans(),
        _membershipService.getMyMembershipDetails(),
      ]);

      final plansResponse = results[0] as List<MembershipPlanApi>;
      final membershipResponse = results[1] as MembershipDetailsResponse;

      if (mounted) {
        setState(() {
          _plans.clear();
          for (var plan in plansResponse) {
            _plans.add({
              'id': plan.id,
              'name': plan.planName,
              'price': plan.membershipAmount,
              'duration': plan.duration,
              'heartCoins': plan.heartCoins,
              'features': plan.features ?? [],
              'currency': plan.currency,
            });
          }

          // Set active plan if membershipData exists and has valid data (like webapp)
          // Check if any field is not null to determine if membership exists
          if (membershipResponse.membershipData != null) {
            final membership = membershipResponse.membershipData!;
            // Check if membership has valid data (planName, expiryDate, or membership_id)
            if (membership.planName != null ||
                membership.memberShipExpiryDate != null ||
                membership.membership_id != null) {
              _activePlan = {
                'name': membership.planName ?? 'Active Plan',
                'expiryDate': membership.memberShipExpiryDate,
                'membership_id': membership.membership_id,
              };
              _heartCoins = membership.heartCoins;
            } else {
              _activePlan = null;
              _heartCoins = 0;
            }
          } else {
            _activePlan = null;
            _heartCoins = 0;
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleChoosePlan(Map<String, dynamic> plan) async {
    try {
      final orderResponse = await _membershipService.buyMembership(plan['id']);
      // TODO: Integrate Razorpay payment
      // For now, show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              orderResponse.message ?? 'Payment integration coming soon',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        // Reload membership data after purchase
        _loadMembershipData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('API ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const HeaderWidget(),
      drawer: const SidebarWidget(),
      bottomNavigationBar: const BottomNavigationWidget(),
      body: SafeArea(
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
                          onPressed: _loadMembershipData,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
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
                                  color: _activePlan != null
                                      ? AppColors.success.withOpacity(0.1)
                                      : AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _activePlan != null
                                          ? 'Active plan: ${_activePlan!['name']}'
                                          : 'No active membership',
                                      style: TextStyle(
                                        color: _activePlan != null
                                            ? AppColors.success
                                            : AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    if (_activePlan != null) ...[
                                      if (_activePlan!['expiryDate'] !=
                                          null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Expires on ${_formatDate(_activePlan!['expiryDate'])}',
                                          style: TextStyle(
                                            color: AppColors.success
                                                .withOpacity(0.8),
                                            fontSize: 12,
                                            fontWeight: FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 4),
                                      Text(
                                        '$_heartCoins Heart Coins remaining',
                                        style: TextStyle(
                                          color: AppColors.success
                                              .withOpacity(0.8),
                                          fontSize: 12,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                    if (_activePlan == null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Unlock premium filters, heart coins, and faster matches.',
                                        style: TextStyle(
                                          color: AppColors.primary
                                              .withOpacity(0.8),
                                          fontSize: 12,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                    ],
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
    final planName = (plan['name'] as String? ?? '').toLowerCase();
    final isPlatinum = planName.contains('platinum');

    // Determine card colors based on plan
    final cardColor = theme.cardColor;
    final borderColor = theme.dividerColor;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
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
                '${_getCurrencySymbol(plan['currency'] ?? 'INR')}${_formatPrice(plan['price'])} / ${plan['duration']} ${plan['duration'] == 1 ? 'month' : 'months'}',
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
          ...((plan['features'] as List<dynamic>?) ?? []).map((feature) {
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
                backgroundColor: theme.cardColor,
                foregroundColor: theme.textTheme.bodyLarge?.color,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                  side: BorderSide(color: theme.dividerColor),
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

  String _getCurrencySymbol(String currency) {
    if (currency == 'INR') return '₹';
    return '$currency ';
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';
    try {
      final date = DateTime.parse(dateString);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return '${months[date.month - 1]} ${date.day.toString().padLeft(2, '0')}, ${date.year}';
    } catch (_) {
      return dateString;
    }
  }

  String _formatPrice(dynamic price) {
    if (price == null) return '0';
    if (price is int) {
      return price.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
    }
    if (price is num) {
      return price.toInt().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
    }
    return price.toString();
  }
}
