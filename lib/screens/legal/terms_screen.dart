import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

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
          'Terms & Conditions',
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
                'Terms and Conditions',
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
                title: '1. Acceptance of Terms',
                content:
                    'By accessing and using Connecting Hearts, you accept and agree to be bound by the terms and provision of this agreement.',
              ),
              _buildSection(
                theme,
                title: '2. User Registration',
                content:
                    'To use certain features of the Service, you must register for an account. You must provide accurate and complete information and keep your account information updated.',
              ),
              _buildSection(
                theme,
                title: '3. Privacy Policy',
                content:
                    'Your privacy is important to us. Please review our Privacy Policy, which also governs your use of the Service.',
              ),
              _buildSection(
                theme,
                title: '4. User Conduct',
                content:
                    'You agree not to use the Service for any unlawful purpose or in any way that interrupts, damages, or impairs the service.',
              ),
              _buildSection(
                theme,
                title: '5. Content',
                content:
                    'You are responsible for all content you post on the Service. You must not post any content that is illegal, harmful, or violates the rights of others.',
              ),
              _buildSection(
                theme,
                title: '6. Membership',
                content:
                    'Certain features require a paid membership. Membership fees are non-refundable except as required by law.',
              ),
              _buildSection(
                theme,
                title: '7. Termination',
                content:
                    'We may terminate or suspend your account at any time for violations of these terms.',
              ),
              _buildSection(
                theme,
                title: '8. Contact Us',
                content:
                    'If you have any questions about these Terms, please contact us at support@connectingheart.co.in',
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
