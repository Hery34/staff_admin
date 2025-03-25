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
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  Future<String> login(Credential credential) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _supabase.auth.signInWithPassword(
        email: credential.email,
        password: credential.password,
      );
      _currentUser = response.user;
      return "Vous êtes connecté !";
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return "Une erreur est survenue lors de la connexion";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> resetPassword(String email) async {
    try {
      _isLoading = true;
      notifyListeners();

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
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> logout() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Vérifier si l'utilisateur est connecté
      final session = await _supabase.auth.currentSession;
      if (session == null) {
        return "Vous n'êtes pas connecté";
      }

      // Déconnexion de Supabase
      await _supabase.auth.signOut();
      
      // Réinitialisation de l'état
      _currentUser = null;
      
      return "Déconnexion réussie";
    } on AuthException catch (e) {
      debugPrint('Erreur AuthException lors de la déconnexion: ${e.message}');
      return e.message;
    } catch (e) {
      debugPrint('Erreur lors de la déconnexion: $e');
      return "Une erreur est survenue lors de la déconnexion";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updatePassword(
    String newPassword,
    String accessToken,
    String refreshToken,
  ) async {
    try {
      _isLoading = true;
      notifyListeners();

      final session = await _supabase.auth.recoverSession(refreshToken);
      await _supabase.auth.updateUser(
        UserAttributes(
          password: newPassword,
        ),
      );
    } catch (e) {
      throw "Erreur lors de la mise à jour du mot de passe: ${e.toString()}";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
} 