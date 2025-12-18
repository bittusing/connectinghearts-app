import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/colors.dart';
import '../../utils/profile_utils.dart';

class ProfileMatchCard extends StatelessWidget {
  final String id;
  final String name;
  final int age;
  final String height;
  final String location;
  final String? religion;
  final String? salary;
  final String? imageUrl;
  final String? gender;
  final VoidCallback? onSendInterest;
  final VoidCallback? onShortlist;
  final VoidCallback? onIgnore;
  final VoidCallback? onAcceptInterest;
  final VoidCallback? onDeclineInterest;
  final VoidCallback? onTap;
  final bool showCompatibilityTag;
  final Widget? customActions;

  const ProfileMatchCard({
    super.key,
    required this.id,
    required this.name,
    required this.age,
    required this.height,
    required this.location,
    this.religion,
    this.salary,
    this.imageUrl,
    this.gender,
    this.onSendInterest,
    this.onShortlist,
    this.onIgnore,
    this.onAcceptInterest,
    this.onDeclineInterest,
    this.onTap,
    this.showCompatibilityTag = false,
    this.customActions,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.78,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: GestureDetector(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Image
              imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Image.asset(
                        getGenderPlaceholder(gender),
                        fit: BoxFit.cover,
                      ),
                      errorWidget: (context, url, error) => Image.asset(
                        getGenderPlaceholder(gender),
                        fit: BoxFit.cover,
                      ),
                    )
                  : Image.asset(
                      getGenderPlaceholder(gender),
                      fit: BoxFit.cover,
                    ),
              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
                      Colors.black.withOpacity(0.8),
                    ],
                    stops: const [0.4, 0.7, 1.0],
                  ),
                ),
              ),
              // Compatibility Tag
              if (showCompatibilityTag)
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Best Match',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              // Profile Info
              Positioned(
                left: 20,
                right: 20,
                bottom: 100,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      height.isNotEmpty ? '$age years|$height' : '$age years',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (religion != null || salary != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        [religion, salary].where((e) => e != null).join(' • '),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Action Buttons
              Positioned(
                left: 20,
                right: 20,
                bottom: 20,
                child: customActions ??
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (onIgnore != null)
                          _buildActionButton(
                            icon: Icons.block,
                            label: 'Ignore',
                            color: Colors.grey,
                            onTap: onIgnore!,
                          ),
                        if (onDeclineInterest != null)
                          _buildActionButton(
                            icon: Icons.close,
                            label: 'Decline',
                            color: Colors.red,
                            onTap: onDeclineInterest!,
                          ),
                        if (onShortlist != null)
                          _buildActionButton(
                            icon: Icons.star,
                            label: 'Shortlist',
                            color: Colors.amber,
                            onTap: onShortlist!,
                          ),
                        if (onSendInterest != null)
                          _buildActionButton(
                            icon: Icons.send,
                            label: 'Interest',
                            color: AppColors.primary,
                            onTap: onSendInterest!,
                            isLarge: true,
                          ),
                        if (onAcceptInterest != null)
                          _buildActionButton(
                            icon: Icons.check,
                            label: 'Accept',
                            color: AppColors.success,
                            onTap: onAcceptInterest!,
                            isLarge: true,
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

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isLarge = false,
  }) {
    final size = isLarge ? 64.0 : 52.0;
    final iconSize = isLarge ? 32.0 : 24.0;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: color,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: color,
              size: iconSize,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
