import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/common/header_widget.dart';
import '../../widgets/common/sidebar_widget.dart';
import '../../widgets/common/bottom_navigation_widget.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const HeaderWidget(),
      drawer: const SidebarWidget(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: theme.dividerColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Privacy Policy',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.titleLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your privacy matters to us. This policy explains what we collect, how we use it, and the controls you have while using Connecting Hearts.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // What information does Connecting Hearts collect?
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What information does Connecting Hearts collect?',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.titleLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoItem(
                    theme,
                    description:
                        'Connecting Hearts, an advertising-led matchmaking platform, requests personal details so we can publish your profile and deliver tailored recommendations. By using the service you consent to the collection, processing, and sharing of this information in line with this policy.',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoItem(
                    theme,
                    title: 'Information you submit',
                    description:
                        'Profile data, preferences, photos, and communications you voluntarily provide.',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoItem(
                    theme,
                    title: 'Information not directly submitted by you',
                    description:
                        'App activity, device diagnostics, and technical identifiers captured automatically.',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoItem(
                    theme,
                    title: 'Information we receive from others',
                    description:
                        'Details shared by other members or third parties to keep our platform safe and compliant.',
                  ),
                ],
              ),
            ),

            // Information you provide to avail the service
            _buildBulletSection(
              theme,
              title: 'Information you provide to avail the service',
              bullets: const [
                'Personal details such as name, gender, date of birth, education, occupation, photos, marital status, and interests shared during registration.',
                'Payment information (debit/credit card or UPI) submitted directly or through our payment gateway while purchasing paid services.',
                'Testimonials, success stories, and photos voluntarily submitted for publication.',
                'Responses provided during surveys, contests, promotions, or community events.',
                'Details and recordings shared with our customer care team for quality assurance and support.',
                'Chats, messages, and user-generated content exchanged with other members on the platform.',
                'Reports of suspicious IDs; immediate legal action is taken if violations are confirmed.',
              ],
            ),

            // Information not directly submitted by you
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Information not directly submitted by you',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.titleLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoItem(
                    theme,
                    title: 'User activity',
                    description:
                        'Timestamps, feature usage, searches, clicks, visited pages, and interactions with other users (including exchanged messages).',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoItem(
                    theme,
                    title: 'Device information',
                    description:
                        'IP address, device IDs, device specifications, app/browser settings, crash logs, operating system details, and identifiers associated with cookies or similar technologies.',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoItem(
                    theme,
                    title: 'SMS permission',
                    description:
                        'Required solely to authenticate transactions via OTP issued by payment gateways.',
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'In addition, we may receive supporting details about you from external sources to comply with security, compliance, and fraud-prevention requirements.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.6,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),

            // How we use collected information
            _buildBulletSection(
              theme,
              title: 'How we use collected information',
              bullets: const [
                'Provide, personalize, and improve the core matchmaking services.',
                'Manage your account lifecycle and preferences.',
                'Deliver responsive customer support.',
                'Conduct research, reporting, and service quality analysis.',
                'Communicate about product updates, promotions, and relevant offers.',
                'Recommend compatible profiles and showcase your profile to other members.',
              ],
            ),

            // With whom we share your information
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'With whom we share your information',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.titleLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoItem(
                    theme,
                    title: 'With other users',
                    description:
                        'Your published profile information is visible to fellow members. Always review and limit what you share publicly.',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoItem(
                    theme,
                    title: 'With service providers and partners',
                    description:
                        'Trusted third parties assist with development, hosting, storage, analytics, and payments. They operate under strict contractual and confidentiality obligations.',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoItem(
                    theme,
                    title: 'With law enforcement',
                    description:
                        'Personal data may be disclosed to comply with applicable laws, court orders, or to protect the rights and safety of our members and platform.',
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'We do not sell or trade your personal data. Sharing occurs only as described above or when you are expressly informed and provide consent.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.6,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),

            // How to access or control your information
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How to access or control your information',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.titleLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Manage your information directly from your account dashboard. EU members and other applicable jurisdictions may exercise the following rights:',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.6,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoItem(
                    theme,
                    title: 'Reviewing your information',
                    description:
                        'Depending on your jurisdiction, you may have the right to access or port the personal data we hold.',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoItem(
                    theme,
                    title: 'Deletion',
                    description:
                        'You can delete your profile if you believe we no longer need your information. Certain records may be retained for legal or transactional reasons.',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoItem(
                    theme,
                    title: 'Information from other users',
                    description:
                        'Requests for another member\'s communications require that member\'s written consent before release.',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoItem(
                    theme,
                    title: 'Withdraw consent',
                    description:
                        'You may withdraw consent at any time. Doing so deletes your profile and limits our ability to provide further services.',
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'To protect all members, we may request proof of identity before honoring privacy requests.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.6,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),

            // How we secure your information
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How we secure your information',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.titleLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildBulletList(
                    theme,
                    bullets: const [
                      'Sensitive inputs, including payment card details, are encrypted during transmission and handled by PCI-compliant providers.',
                      'Access to personal data is restricted to employees who need it to perform their duties.',
                      'Industry-standard safeguards mitigate unauthorized access; however, no system is completely impenetrable given the nature of the internet.',
                    ],
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      final uri = Uri.parse(
                          'mailto:connectinghearts.helpdesk@gmail.com');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                    child: RichText(
                      text: TextSpan(
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.6,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                        children: [
                          const TextSpan(
                              text:
                                  'Have questions about security? Reach us at '),
                          TextSpan(
                            text: 'connectinghearts.helpdesk@gmail.com',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          const TextSpan(text: '.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // How long we keep your information
            _buildSection(
              theme,
              title: 'How long we keep your information',
              paragraphs: const [
                'We retain personal information only for as long as you maintain an account and as required by applicable laws. When you delete your profile, we delete or anonymize associated data unless retention is necessary to comply with legal obligations, prevent fraud, resolve disputes, enforce agreements, or support business operations.',
                'Aggregated insights may be used to improve our services, but they no longer identify you personally.',
              ],
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavigationWidget(),
    );
  }

  Widget _buildSection(
    ThemeData theme, {
    required String title,
    required List<String> paragraphs,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 16),
          ...paragraphs.map((paragraph) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  paragraph,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.6,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildBulletSection(
    ThemeData theme, {
    required String title,
    required List<String> bullets,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 16),
          _buildBulletList(theme, bullets: bullets),
        ],
      ),
    );
  }

  Widget _buildBulletList(ThemeData theme, {required List<String> bullets}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: bullets
          .map((bullet) => Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        bullet,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.6,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _buildInfoItem(
    ThemeData theme, {
    String? title,
    required String description,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 4),
        ],
        Text(
          description,
          style: theme.textTheme.bodyMedium?.copyWith(
            height: 1.6,
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }
}
