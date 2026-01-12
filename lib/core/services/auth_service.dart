import 'package:flutter/material.dart';
import 'package:staff_admin/core/config/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    } on AuthException {
      return "Veuillez vérifier vos identifiants";
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
          
      await _supabase.auth.resetPasswordForEmail(
        email,
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
      await _supabase.auth.signOut();
      
      // Réinitialiser l'état du service
      _currentUser = null;
      notifyListeners();
      
      return "Déconnexion réussie";
    } catch (e) {
      debugPrint('Error during logout: $e');
      return "Erreur lors de la déconnexion: $e";
    }
  }

} 