import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (Navigator.canPop(context)) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        title: const Text(
          'Privacy Policy',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
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
                'Privacy Policy',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Last updated: December 2024',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              _buildSection(
                theme,
                title: 'Information We Collect',
                content:
                    'We collect information you provide directly to us, such as when you create an account, fill in your profile, or contact us for support.',
              ),
              _buildSection(
                theme,
                title: 'How We Use Your Information',
                content:
                    'We use the information we collect to provide, maintain, and improve our services, to process transactions, and to communicate with you.',
              ),
              _buildSection(
                theme,
                title: 'Information Sharing',
                content:
                    'We do not share your personal information with third parties except as described in this policy or with your consent.',
              ),
              _buildSection(
                theme,
                title: 'Data Security',
                content:
                    'We take reasonable measures to help protect your personal information from loss, theft, misuse, and unauthorized access.',
              ),
              _buildSection(
                theme,
                title: 'Your Rights',
                content:
                    'You have the right to access, update, or delete your personal information at any time through your account settings.',
              ),
              _buildSection(
                theme,
                title: 'Cookies',
                content:
                    'We use cookies and similar technologies to collect information about your browsing activities and to personalize your experience.',
              ),
              _buildSection(
                theme,
                title: 'Contact Us',
                content:
                    'If you have any questions about this Privacy Policy, please contact us at privacy@connectingheart.co.in',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(ThemeData theme,
      {required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
