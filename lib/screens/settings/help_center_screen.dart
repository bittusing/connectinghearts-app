import 'package:flutter/material.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help Center'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
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
                      'Help Center',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Get help with your account and find answers to common questions.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    _buildHelpItem(
                      context,
                      icon: Icons.email_outlined,
                      title: 'Email Support',
                      subtitle: 'support@connectingheart.co.in',
                    ),
                    const Divider(),
                    _buildHelpItem(
                      context,
                      icon: Icons.phone_outlined,
                      title: 'Phone Support',
                      subtitle: '+91 1800 XXX XXXX',
                    ),
                    const Divider(),
                    _buildHelpItem(
                      context,
                      icon: Icons.chat_outlined,
                      title: 'Live Chat',
                      subtitle: 'Available 9 AM - 6 PM',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // FAQs
              Container(
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
                      'Frequently Asked Questions',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFaqItem(
                      context,
                      question: 'How do I update my profile?',
                      answer:
                          'Go to Settings > Edit Profile to update your information.',
                    ),
                    _buildFaqItem(
                      context,
                      question: 'How do I change my password?',
                      answer:
                          'Go to Settings > Change Password to update your password.',
                    ),
                    _buildFaqItem(
                      context,
                      question: 'How do I upgrade my membership?',
                      answer:
                          'Go to the Membership tab to view and upgrade your plan.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHelpItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {},
    );
  }

  Widget _buildFaqItem(
    BuildContext context, {
    required String question,
    required String answer,
  }) {
    return ExpansionTile(
      title: Text(
        question,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(answer),
        ),
      ],
    );
  }
}

