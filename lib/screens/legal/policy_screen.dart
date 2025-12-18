import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/colors.dart';

class PolicyScreen extends StatelessWidget {
  const PolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final policies = [
      {
        'title': 'Data privacy',
        'body':
            'All personally identifiable information is encrypted at rest. Phone numbers, documents, and chat transcripts stay hidden until both parties consent to share.',
      },
      {
        'title': 'Profile verification',
        'body':
            'We follow a three-layer KYC process (ID proof, selfie video, and human review). Suspicious profiles are auto-flagged and escalated to the trust & safety pod.',
      },
      {
        'title': 'Payment & refunds',
        'body':
            'Membership charges (₹499 / ₹799 / ₹999) unlock platform-wide access for their duration. Direct course or feature purchases stay active for one year, aligned with monetization rules shared earlier.',
      },
      {
        'title': 'Community standards',
        'body':
            'Respectful, harassment-free communication is mandatory. Report buttons are embedded across the product and route directly to moderators within 6 hours.',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Policies & Trust'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Policies & trust',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Transparent, human-centered safeguards.',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'These summaries mirror the ConnectingHeart policy flow. Swap this static content with markdown pulled from your CMS/API after integration.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // Policy Cards
              ...policies.map((policy) => Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          policy['title'] as String,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          policy['body'] as String,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 24),
              // Contact Info
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Text.rich(
                  TextSpan(
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                    children: [
                      const TextSpan(
                        text:
                            'Need edits or legal copy approval? Drop a note to ',
                      ),
                      WidgetSpan(
                        child: GestureDetector(
                          onTap: () async {
                            final uri =
                                Uri.parse('mailto:legal@connectingheart.co');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          },
                          child: const Text(
                            'legal@connectingheart.co',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const TextSpan(
                        text:
                            '. We keep UI static until we fetch policy sections from the backend CMS via the shared API hook.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
