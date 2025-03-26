import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:staff_admin/core/config/supabase_config.dart';
import 'package:staff_admin/core/services/auth_service.dart';
import 'package:staff_admin/core/services/deep_link_service.dart';
import 'package:staff_admin/core/services/fire_alert_service.dart';
import 'package:staff_admin/core/services/report_service.dart';
import 'package:staff_admin/core/services/task_site_service.dart';
import 'package:staff_admin/features/admin/screens/login_screen.dart';
import 'package:staff_admin/features/admin/screens/admin_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => FireAlertService()),
        ChangeNotifierProvider(create: (_) => ReportService()),
        ChangeNotifierProvider(create: (_) => TaskSiteService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  static final navigatorKey = GlobalKey<NavigatorState>();
  
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize deep linking with navigator key
    DeepLinkService.initialize(navigatorKey: navigatorKey);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => FireAlertService()),
        ChangeNotifierProvider(create: (_) => ReportService()),
        ChangeNotifierProvider(create: (_) => TaskSiteService()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Staff Admin Annexx',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFE31E24), // Rouge Annexx
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          cardTheme: CardTheme(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFE31E24),
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
          ),
          textTheme: const TextTheme(
            titleLarge: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
            titleMedium: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE31E24),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        initialRoute: '/login',
        routes: {
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const AdminHomeScreen(),
        },
        home: const LoginScreen(),
      ),
    );
  }
}
