import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:staff_admin/core/config/supabase_config.dart';
import 'package:staff_admin/core/models/agent.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AgentService extends ChangeNotifier {
  final _supabase = SupabaseConfig.supabase;
  List<Agent> _agents = [];
  bool _isLoading = false;
  Agent? _currentAgent;
  Set<int>? _allowedSiteIds;

  List<Agent> get agents => _agents;
  bool get isLoading => _isLoading;
  Agent? get currentAgent => _currentAgent;
  /// Sites autorisés pour l'agent connecté (rôle "agent"). Null = pas de filtre (responsable, directeur).
  Set<int>? get allowedSiteIds => _allowedSiteIds;
  bool get isAgentRole => _currentAgent?.role == AgentRole.agent;

  /// Crée un nouvel agent dans Supabase Auth et dans la table agent
  /// Génère automatiquement un mot de passe fort
  Future<String> createAgent({
    required String firstname,
    required String lastname,
    required String email,
    required AgentRole role,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      // 1. Générer un mot de passe simple de 8 caractères (lettres et chiffres uniquement)
      final generatedPassword = generateStrongPassword();

      // 2. Créer l'utilisateur dans Supabase Auth
      // Stocker le mot de passe temporaire dans les métadonnées pour le webhook
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: generatedPassword,
        data: {
          'temporary_password': generatedPassword,
          'firstname': firstname,
          'lastname': lastname,
          'role': role.displayName,
        },
        emailRedirectTo: null, // Pas de redirection nécessaire
      );

      if (authResponse.user == null) {
        throw Exception('Échec de la création de l\'utilisateur dans Supabase Auth');
      }

      // 3. Insérer l'agent dans la table agent avec statut en_attente_confirmation
      final agentResponse = await _supabase
          .from('agent')
          .insert({
            'firstname': firstname,
            'lastname': lastname,
            'email': email,
            'pin_code': null, // L'agent devra le définir dans Staff_V2
            'role': role.databaseValue,
            'statut_compte': AgentStatus.en_attente_confirmation.databaseValue,
          })
          .select()
          .single();

      debugPrint('Agent créé: $agentResponse');

      // 4. Appeler le webhook n8n pour envoyer l'email de bienvenue
      await callValidationWebhook(
        email: email,
        nom: lastname,
        prenom: firstname,
        motDePasseTemp: generatedPassword,
        role: role.displayName,
      );

      // 5. Charger la liste des agents
      await loadAgents();

      return 'Agent créé avec succès. Un email de bienvenue a été envoyé.';
    } on AuthException catch (e) {
      debugPrint('Erreur Auth lors de la création: ${e.message}');
      return 'Erreur lors de la création de l\'agent: ${e.message}';
    } catch (e) {
      debugPrint('Erreur lors de la création de l\'agent: $e');
      return 'Erreur lors de la création de l\'agent: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Charge tous les agents
  Future<void> loadAgents() async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _supabase
          .from('agent')
          .select()
          .order('lastname');

      _agents = (response as List)
          .map((json) => Agent.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Erreur lors du chargement des agents: $e');
      _agents = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Récupère l'agent actuellement connecté
  Future<Agent?> getCurrentAgent() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from('agent')
          .select()
          .eq('email', user.email!)
          .maybeSingle();

      if (response == null) return null;

      return Agent.fromJson(response);
    } catch (e) {
      debugPrint('Erreur lors de la récupération de l\'agent actuel: $e');
      return null;
    }
  }

  /// Charge l'agent connecté et, si rôle "agent", la liste des sites autorisés (agent_sites).
  /// À appeler après connexion réussie.
  Future<void> loadCurrentAgentAndSites() async {
    _currentAgent = null;
    _allowedSiteIds = null;
    try {
      final agent = await getCurrentAgent();
      _currentAgent = agent;
      if (agent == null) return;
      if (agent.role == AgentRole.agent) {
        final rows = await _supabase
            .from('agent_sites')
            .select('site_id')
            .eq('agent_id', agent.id);
        final ids = <int>{};
        for (final row in rows as List) {
          final id = row['site_id'];
          if (id != null) ids.add(int.parse(id.toString()));
        }
        _allowedSiteIds = ids;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur loadCurrentAgentAndSites: $e');
      _currentAgent = null;
      _allowedSiteIds = null;
      notifyListeners();
    }
  }

  /// Réinitialise l'agent courant et les sites autorisés (à appeler à la déconnexion).
  void clearCurrentAgent() {
    _currentAgent = null;
    _allowedSiteIds = null;
    notifyListeners();
  }

  /// Appelle le webhook n8n pour envoyer l'email de bienvenue
  Future<void> callValidationWebhook({
    required String email,
    required String nom,
    required String prenom,
    required String motDePasseTemp,
    required String role,
  }) async {
    const webhookUrl = 'https://automation-annexx-n8n.zcbxvg.easypanel.host/webhook/validate_account';
    
    try {
      final response = await http.post(
        Uri.parse(webhookUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'nom': nom,
          'prenom': prenom,
          'mot_de_passe_temporaire': motDePasseTemp,
          'role': role,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('Webhook n8n appelé avec succès pour $email');
      } else {
        debugPrint('Erreur lors de l\'appel au webhook n8n: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'appel au webhook n8n: $e');
      // Ne pas faire échouer si le webhook échoue
    }
  }
}
