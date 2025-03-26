import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:staff_admin/core/config/supabase_config.dart';
import 'package:staff_admin/core/services/auth_service.dart';
import 'package:staff_admin/core/services/deep_link_service.dart';
import 'package:staff_admin/core/services/fire_alert_service.dart';
import 'package:staff_admin/core/services/report_service.dart';
import 'package:staff_admin/core/services/task_site_service.dart';
import 'package:staff_admin/features/admin/screens/login_screen.dart';

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
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE31E24)),
          useMaterial3: true,
        ),
        home: const LoginScreen(),
      ),
    );
  }
}
