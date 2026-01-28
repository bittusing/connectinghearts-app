import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/lookup_provider.dart';
import 'providers/notification_count_provider.dart';
import 'providers/dashboard_provider.dart';
import 'theme/app_theme.dart';
import 'navigation/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const ConnectingHeartApp());
}

class ConnectingHeartApp extends StatelessWidget {
  const ConnectingHeartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LookupProvider()),
        ChangeNotifierProvider(create: (_) => NotificationCountProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
      ],
      child: Consumer2<ThemeProvider, AuthProvider>(
        builder: (context, themeProvider, authProvider, child) {
          return MaterialApp.router(
            title: 'Connecting Hearts',
            debugShowCheckedModeBanner: false,
            // Only light theme is enabled for now
            theme: AppTheme.lightTheme,
            // Dark theme is commented out
            // darkTheme: AppTheme.darkTheme,
            // Force light mode only
            themeMode: ThemeMode.light, // themeProvider.themeMode,
            routerConfig: createAppRouter(authProvider),
          );
        },
      ),
    );
  }
}
