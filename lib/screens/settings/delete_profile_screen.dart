import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../theme/colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';

class DeleteProfileScreen extends StatefulWidget {
  const DeleteProfileScreen({super.key});

  @override
  State<DeleteProfileScreen> createState() => _DeleteProfileScreenState();
}

class _DeleteProfileScreenState extends State<DeleteProfileScreen> {
  final _reasonController = TextEditingController();
  final _commentController = TextEditingController();
  bool _isDeleting = false;
  int? _selectedReason;
  bool _confirmed = false;

  final List<Map<String, dynamic>> _reasons = [
    {'id': 1, 'label': 'I found my match on Connecting Hearts'},
    {'id': 2, 'label': 'I found my match elsewhere'},
    {'id': 3, 'label': 'I am unhappy with services'},
    {'id': 4, 'label': 'Marry later / create profile later'},
    {'id': 5, 'label': 'I have to do some changes in my profile'},
    {'id': 6, 'label': 'Privacy issues'},
    {'id': 7, 'label': 'Other reasons'},
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  Future<void> _deleteProfile() async {
    if (!_confirmed) {
      _showError('Please confirm that you want to delete your profile');
      return;
    }

    if (_selectedReason == null) {
      _showError('Please select a reason before continuing');
      return;
    }

    setState(() => _isDeleting = true);

    try {
      final authService = AuthService();
      await authService.deleteProfile(
        reasonForDeletion: _selectedReason!,
        deletionComment: _commentController.text.trim().isNotEmpty
            ? _commentController.text.trim()
            : 'No additional details provided.',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile deleted successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.logout();
        context.go('/login');
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

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
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/');
            }
          },
        ),
        title: const Text(
          'Delete Profile',
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
        child: Column(
          children: [
            // Warning Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 64,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Delete Your Profile?',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This action cannot be undone. All your data, matches, and conversations will be permanently deleted.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Form
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
                    'Why are you deleting your profile?',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._reasons.map((reason) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () =>
                            setState(() => _selectedReason = reason['id']),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _selectedReason == reason['id']
                                  ? AppColors.primary
                                  : theme.dividerColor,
                              width: _selectedReason == reason['id'] ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Radio<int>(
                                value: reason['id'],
                                groupValue: _selectedReason,
                                onChanged: (value) =>
                                    setState(() => _selectedReason = value),
                                activeColor: AppColors.primary,
                              ),
                              Expanded(
                                child: Text(
                                  reason['label'],
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                  Text(
                    'Additional comments (optional)',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _commentController,
                    maxLines: 3,
                    maxLength: 300,
                    decoration: const InputDecoration(
                      hintText:
                          'Share any feedback that could help us improve.',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Checkbox(
                        value: _confirmed,
                        onChanged: (value) =>
                            setState(() => _confirmed = value ?? false),
                        activeColor: AppColors.error,
                      ),
                      Expanded(
                        child: Text(
                          'I understand that this action is irreversible and all my data will be permanently deleted.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isDeleting ? null : _deleteProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                      ),
                      child: _isDeleting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Delete My Profile'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        if (Navigator.canPop(context)) {
                          context.pop();
                        } else {
                          context.go('/');
                        }
                      },
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
