import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../theme/colors.dart';
import '../../providers/notification_count_provider.dart';
import '../../services/storage_service.dart';

class HeaderWidget extends StatefulWidget implements PreferredSizeWidget {
  final VoidCallback? onMenuTap;
  final int? notificationCount; // Optional override, otherwise uses provider

  const HeaderWidget({
    super.key,
    this.onMenuTap,
    this.notificationCount,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  State<HeaderWidget> createState() => _HeaderWidgetState();
}

class _HeaderWidgetState extends State<HeaderWidget> {
  final StorageService _storageService = StorageService();
  String? _profileName;

  @override
  void initState() {
    super.initState();
    _loadProfileName();
  }

  Future<void> _loadProfileName() async {
    final name = await _storageService.getProfileName();
    if (mounted && name != null) {
      setState(() {
        _profileName = name;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get notification count from provider if not overridden
    int? displayCount = widget.notificationCount;
    if (displayCount == null) {
      try {
        final provider =
            Provider.of<NotificationCountProvider>(context, listen: true);
        displayCount = provider.counts.total;
      } catch (_) {
        // Provider not available, use null
      }
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Menu Button
              IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: widget.onMenuTap ?? () => Scaffold.of(context).openDrawer(),
              ),
              // Title
              Expanded(
                child: Text(
                  'Heartfulness connecting Hearts',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                ),
              ),
              // Search Button
              IconButton(
                icon: const Icon(Icons.search, color: Colors.white),
                onPressed: () => context.push('/search'),
              ),
              // Notifications Button
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined,
                        color: Colors.white),
                    onPressed: () => context.push('/notifications'),
                  ),
                  if (displayCount != null && displayCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          displayCount > 9 ? '9+' : '$displayCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
