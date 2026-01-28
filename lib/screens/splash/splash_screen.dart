import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Wait for auth check to complete
    while (authProvider.isCheckingAuth) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    // Navigate based on authentication status
    if (mounted && !_hasNavigated) {
      _hasNavigated = true;
      // Add a small delay to ensure smooth transition
      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        if (authProvider.isAuthenticated) {
          // Navigate based on screenName (only go to dashboard if screenName is "dashboard")
          final screenName = authProvider.user?.screenName
                  ?.toLowerCase()
                  .replaceAll(RegExp(r'\s+'), '') ??
              '';
          final routeMap = {
            'personaldetails': '/personal-details',
            'careerdetails': '/career-details',
            'socialdetails': '/social-details',
            'srcmdetails': '/srcm-details',
            'familydetails': '/family-details',
            'partnerpreferences': '/partner-preference',
            'aboutyou': '/about-you',
            'underverification': '/verification-pending',
            'dashboard': '/',
          };
          // Only go to dashboard if screenName is explicitly "dashboard"
          final redirectPath = routeMap[screenName] ?? '/personal-details';
          context.go(redirectPath);
        } else {
          context.go('/login');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: Stack(
          children: [
            // Background image - responsive and perfectly sized
            Positioned.fill(
              child: Image.asset(
                'assets/images/splash.jpeg',
                fit: BoxFit.cover,
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback to white container if image fails
                  return Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    color: Colors.white,
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        size: 64,
                        color: Colors.grey,
                      ),
                    ),
                  );
                },
              ),
            ),
            // Loading indicator overlay - positioned at bottom center with proper dimensions
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 56,
                  height: 56,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 12,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 3.0,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
