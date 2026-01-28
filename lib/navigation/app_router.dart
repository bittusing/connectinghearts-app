import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/onboarding/verification_pending_screen.dart';
import '../screens/onboarding/personal_details_screen.dart';
import '../screens/onboarding/career_details_screen.dart';
import '../screens/onboarding/social_details_screen.dart';
import '../screens/onboarding/srcm_details_screen.dart';
import '../screens/onboarding/family_details_screen.dart';
import '../screens/onboarding/partner_preference_screen.dart';
import '../screens/settings/partner_preference_screen.dart' as settings;
import '../screens/edit_profile/edit_profile_basic_page.dart';
import '../screens/edit_profile/edit_about_page.dart';
import '../screens/edit_profile/edit_education_page.dart';
import '../screens/edit_profile/edit_career_page.dart';
import '../screens/edit_profile/edit_family_page.dart';
import '../screens/edit_profile/edit_contact_page.dart';
import '../screens/edit_profile/edit_horoscope_page.dart';
import '../screens/edit_profile/edit_lifestyle_page.dart';
import '../screens/onboarding/about_you_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/search/search_results_screen.dart';
import '../screens/profiles/profiles_screen.dart';
import '../screens/membership/membership_screen.dart';
import '../screens/daily_picks/daily_picks_screen.dart';
import '../screens/profile_visitors/profile_visitors_screen.dart';
import '../screens/interests/interests_received_screen.dart';
import '../screens/interests/interests_sent_screen.dart';
import '../screens/profile_actions/shortlisted_profiles_screen.dart';
import '../screens/profile_actions/blocked_profiles_screen.dart';
import '../screens/profile_actions/ignored_profiles_screen.dart';
import '../screens/settings/change_password_screen.dart';
import '../screens/settings/help_center_screen.dart';
import '../screens/settings/delete_profile_screen.dart';
import '../screens/profile_detail/profile_detail_screen.dart';
import '../screens/my_profile/my_profile_screen.dart';
import '../screens/profile_lists/profile_list_screen.dart';
import '../screens/profile_lists/interest_received_list_screen.dart';
import '../screens/acceptance/acceptance_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/notifications/unlocked_profiles_screen.dart';
import '../screens/notifications/i_declined_screen.dart';
import '../screens/notifications/they_declined_screen.dart';
import '../screens/feedback/feedback_screen.dart';
import '../screens/legal/terms_screen.dart';
import '../screens/legal/privacy_policy_screen.dart';
import '../screens/legal/policy_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../models/profile_models.dart';
import '../theme/colors.dart';
import '../widgets/common/header_widget.dart';
import '../widgets/common/sidebar_widget.dart';
import '../providers/auth_provider.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>();

GoRouter createAppRouter(AuthProvider authProvider) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash', // Start with splash screen
    refreshListenable: authProvider,
    redirect: (context, state) {
      final currentPath = state.uri.path;

      // Allow splash screen to handle its own navigation
      if (currentPath == '/splash') {
        return null;
      }

      // Wait for initial auth check to complete
      if (authProvider.isCheckingAuth) {
        return '/splash'; // Redirect to splash while checking
      }

      final isLoggedIn = authProvider.isAuthenticated;
      final isGoingToLogin =
          currentPath == '/login' || currentPath == '/register';
      final isGoingToForgotPassword = currentPath == '/forgot-password';

      // If logged in and trying to access login/register, redirect based on screenName
      if (isLoggedIn && isGoingToLogin) {
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
        return redirectPath;
      }

      // If not logged in and trying to access protected route, redirect to login
      if (!isLoggedIn && !isGoingToLogin && !isGoingToForgotPassword) {
        return '/login';
      }

      return null; // No redirect needed
    },
    routes: [
      // Splash Screen
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      // Auth Routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/policy',
        builder: (context, state) => const PolicyScreen(),
      ),
      GoRoute(
        path: '/verification-pending',
        builder: (context, state) => const VerificationPendingScreen(),
      ),
      // Onboarding Routes
      GoRoute(
        path: '/personal-details',
        builder: (context, state) => const PersonalDetailsScreen(),
      ),
      GoRoute(
        path: '/career-details',
        builder: (context, state) => const CareerDetailsScreen(),
      ),
      GoRoute(
        path: '/social-details',
        builder: (context, state) => const SocialDetailsScreen(),
      ),
      GoRoute(
        path: '/srcm-details',
        builder: (context, state) => const SRCMDetailsScreen(),
      ),
      GoRoute(
        path: '/family-details',
        builder: (context, state) => const FamilyDetailsScreen(),
      ),
      GoRoute(
        path: '/partner-preference',
        builder: (context, state) => const PartnerPreferenceScreen(),
      ),
      GoRoute(
        path: '/about-you',
        builder: (context, state) => const AboutYouScreen(),
      ),
      // Main Shell with Bottom Navigation
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainTabsScreen(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/search',
            builder: (context, state) => const SearchScreen(),
          ),
          GoRoute(
            path: '/daily-picks',
            builder: (context, state) => const DailyPicksScreen(),
          ),
          GoRoute(
            path: '/profile-visitors',
            builder: (context, state) => const ProfileVisitorsScreen(),
          ),
          GoRoute(
            path: '/profiles',
            builder: (context, state) => const ProfilesScreen(),
          ),
        ],
      ),
      // Membership route outside ShellRoute to avoid duplicate bottom nav
          GoRoute(
            path: '/membership',
            builder: (context, state) => const MembershipScreen(),
      ),
      // Profile Detail
      GoRoute(
        path: '/profile/:id',
        builder: (context, state) {
          final profileId = state.pathParameters['id']!;
          return ProfileDetailScreen(profileId: profileId);
        },
      ),
      // Search Results
      GoRoute(
        path: '/search-results',
        builder: (context, state) {
          final filters =
              state.extra as ProfileSearchPayload? ?? ProfileSearchPayload();
          return SearchResultsScreen(filters: filters);
        },
      ),
      // Profile Lists
      GoRoute(
        path: '/interest-received',
        builder: (context, state) => const InterestReceivedListScreen(),
      ),
      GoRoute(
        path: '/interests-received',
        builder: (context, state) => const InterestsReceivedScreen(),
      ),
      GoRoute(
        path: '/interests-sent',
        builder: (context, state) => const InterestsSentScreen(),
      ),
      GoRoute(
        path: '/shortlisted',
        builder: (context, state) => const ShortlistedProfilesScreen(),
      ),
      GoRoute(
        path: '/blocked',
        builder: (context, state) => const BlockedProfilesScreen(),
      ),
      GoRoute(
        path: '/ignored',
        builder: (context, state) => const IgnoredProfilesScreen(),
      ),
      GoRoute(
        path: '/acceptance',
        builder: (context, state) => const AcceptanceScreen(),
      ),
      GoRoute(
        path: '/just-joined',
        builder: (context, state) => const ProfileListScreen(
          listType: ProfileListType.justJoined,
        ),
      ),
      GoRoute(
        path: '/daily-recommendations',
        builder: (context, state) => const ProfileListScreen(
          listType: ProfileListType.dailyRecommendations,
        ),
      ),
      GoRoute(
        path: '/all-profiles',
        builder: (context, state) => const ProfileListScreen(
          listType: ProfileListType.allProfiles,
        ),
      ),
      // My Profile
      GoRoute(
        path: '/my-profile',
        builder: (context, state) => const MyProfileScreen(),
      ),
      // Settings
      GoRoute(
        path: '/settings-partner-preference',
        builder: (context, state) => const settings.PartnerPreferenceScreen(),
      ),
      GoRoute(
        path: '/change-password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: '/help',
        builder: (context, state) => const HelpCenterScreen(),
      ),
      GoRoute(
        path: '/delete-profile',
        builder: (context, state) => const DeleteProfileScreen(),
      ),
      // Notifications
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/unlocked-profiles',
        builder: (context, state) => const UnlockedProfilesScreen(),
      ),
      GoRoute(
        path: '/i-declined',
        builder: (context, state) => const IDeclinedScreen(),
      ),
      GoRoute(
        path: '/they-declined',
        builder: (context, state) => const TheyDeclinedScreen(),
      ),
      // Feedback
      GoRoute(
        path: '/feedback',
        builder: (context, state) => const FeedbackScreen(),
      ),
      // Legal
      GoRoute(
        path: '/terms',
        builder: (context, state) => const TermsScreen(),
      ),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      // Edit Profile Pages
      GoRoute(
        path: '/edit-profile-basic',
        builder: (context, state) => const EditProfileBasicPage(),
      ),
      GoRoute(
        path: '/edit-about',
        builder: (context, state) => const EditAboutPage(),
      ),
      GoRoute(
        path: '/edit-education',
        builder: (context, state) => const EditEducationPage(),
      ),
      GoRoute(
        path: '/edit-career',
        builder: (context, state) => const EditCareerPage(),
      ),
      GoRoute(
        path: '/edit-family',
        builder: (context, state) => const EditFamilyPage(),
      ),
      GoRoute(
        path: '/edit-contact',
        builder: (context, state) => const EditContactPage(),
      ),
      GoRoute(
        path: '/edit-horoscope',
        builder: (context, state) => const EditHoroscopePage(),
      ),
      GoRoute(
        path: '/edit-lifestyle',
        builder: (context, state) => const EditLifestylePage(),
      ),
    ],
  );
}

// Legacy Route Generator for compatibility
class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/register':
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case '/forgot-password':
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Page not found')),
          ),
        );
    }
  }
}

class MainTabsScreen extends StatefulWidget {
  final Widget child;

  const MainTabsScreen({
    super.key,
    required this.child,
  });

  @override
  State<MainTabsScreen> createState() => _MainTabsScreenState();
}

class _MainTabsScreenState extends State<MainTabsScreen> {
  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/search')) return 1;
    if (location.startsWith('/daily-picks')) return 2;
    if (location.startsWith('/profiles')) return 3;
    if (location.startsWith('/membership')) return 4;
    return 0;
  }

  void _onTap(int index) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/search');
        break;
      case 2:
        context.go('/daily-picks');
        break;
      case 3:
        context.go('/profiles');
        break;
      case 4:
        context.go('/membership');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const HeaderWidget(),
      drawer: const SidebarWidget(),
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          border: Border(
            top: BorderSide(color: theme.dividerColor),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _calculateSelectedIndex(context),
          onTap: _onTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: theme.cardColor,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: theme.textTheme.bodySmall?.color,
          selectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.star),
              label: 'Daily Picks',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: 'Profiles',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.card_membership),
              label: 'Membership',
            ),
          ],
        ),
      ),
    );
  }
}
