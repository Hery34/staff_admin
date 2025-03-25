import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:staff_admin/features/admin/screens/reset_password_screen.dart';

class DeepLinkService {
  static final _appLinks = AppLinks();
  static GlobalKey<NavigatorState>? _navigatorKey;

  static void initialize({required GlobalKey<NavigatorState> navigatorKey}) async {
    _navigatorKey = navigatorKey;
    
    if (kIsWeb) {
      // Handle web deep linking
      final uri = Uri.base;
      if (uri.path == '/reset-password') {
        handleDeepLink(uri);
      }
    } else {
      try {
        // Get the initial link that opened the app
        final uri = await _appLinks.getInitialAppLink();
        if (uri != null) {
          handleDeepLink(uri);
        }

        // Listen to incoming deep links
        _appLinks.uriLinkStream.listen(
          (uri) {
            if (uri != null) {
              handleDeepLink(uri);
            }
          },
          onError: (err) {
            debugPrint('Deep link error: $err');
          },
        );
      } catch (e) {
        debugPrint('Failed to get initial deep link: $e');
      }
    }
  }

  static void handleDeepLink(Uri uri) {
    if (kIsWeb && uri.path == '/reset-password') {
      // Handle web reset password
      final accessToken = uri.queryParameters['access_token'];
      final refreshToken = uri.queryParameters['refresh_token'];
      final type = uri.queryParameters['type'];

      if (type == 'recovery' && accessToken != null && refreshToken != null) {
        _navigateToResetPassword(accessToken, refreshToken);
      } else {
        _showError('Liens de réinitialisation invalide');
      }
    } else if (!kIsWeb && uri.scheme == 'io.supabase.annexx' && uri.host == 'reset-callback') {
      // Handle mobile deep linking
      final type = uri.queryParameters['type'];
      
      if (type == 'recovery') {
        final accessToken = uri.queryParameters['access_token'];
        final refreshToken = uri.queryParameters['refresh_token'];
        
        if (accessToken != null && refreshToken != null) {
          _navigateToResetPassword(accessToken, refreshToken);
        } else {
          _showError('Liens de réinitialisation invalide');
        }
      }
    }
  }

  static void _navigateToResetPassword(String accessToken, String refreshToken) {
    if (_navigatorKey?.currentContext == null) {
      debugPrint('No valid context found for navigation');
      return;
    }

    Navigator.of(_navigatorKey!.currentContext!).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ResetPasswordScreen(
          accessToken: accessToken,
          refreshToken: refreshToken,
        ),
      ),
    );
  }

  static void _showError(String message) {
    if (_navigatorKey?.currentContext == null) return;

    ScaffoldMessenger.of(_navigatorKey!.currentContext!).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
} 