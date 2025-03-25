import 'package:flutter/material.dart';
import 'package:staff_admin/core/config/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class Credential {
  final String email;
  final String password;

  Credential({required this.email, required this.password});
}

class AuthService extends ChangeNotifier {
  final _supabase = SupabaseConfig.supabase;
  User? _currentUser;

  User? get currentUser => _currentUser;

  Future<String> login(Credential credential) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: credential.email,
        password: credential.password,
      );
      _currentUser = response.user;
      notifyListeners();
      return "Vous êtes connecté !";
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return "Une erreur est survenue lors de la connexion";
    }
  }

  Future<String> resetPassword(String email) async {
    try {
      final redirectUrl = kIsWeb 
          ? 'http://localhost:3000/reset-password'  // URL de développement web
          : 'io.supabase.annexx://reset-callback/';
          
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: redirectUrl,
      );
      return "Un email de réinitialisation vous a été envoyé";
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return "Une erreur est survenue lors de l'envoi de l'email";
    }
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
    _currentUser = null;
    notifyListeners();
  }

  Future<void> updatePassword(
    String newPassword,
    String accessToken,
    String refreshToken,
  ) async {
    try {
      final session = await _supabase.auth.recoverSession(refreshToken);
      await _supabase.auth.updateUser(
        UserAttributes(
          password: newPassword,
        ),
      );
    } catch (e) {
      throw "Erreur lors de la mise à jour du mot de passe: ${e.toString()}";
    }
  }
} 