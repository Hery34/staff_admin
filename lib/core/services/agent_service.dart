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

      // 1. Générer une passphrase (3 mots) sans caractères ambigus
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
        throw Exception(
            'Échec de la création de l\'utilisateur dans Supabase Auth');
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

      final response = await _supabase.from('agent').select().order('lastname');

      _agents = (response as List).map((json) => Agent.fromJson(json)).toList();
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
  /// À appeler après connexion réussie. Charge TOUS les sites rattachés à l'agent.
  Future<void> loadCurrentAgentAndSites() async {
    _currentAgent = null;
    _allowedSiteIds = null;
    try {
      final agent = await getCurrentAgent();
      _currentAgent = agent;
      if (agent == null) return;
      if (agent.role == AgentRole.agent) {
        final response = await _supabase
            .from('agent_sites')
            .select('site_id')
            .eq('agent_id', agent.id);

        // Supabase retourne toujours une List ; gérer les deux cas par sécurité
        final rows = response;
        final ids = <int>{};
        for (final item in rows) {
          final id = item['site_id'];
          if (id != null) {
            try {
              ids.add(int.parse(id.toString()));
            } catch (_) {
              debugPrint('Valeur site_id invalide: $id');
            }
          }
        }
        _allowedSiteIds = ids;
        debugPrint(
            'Agent ${agent.id}: ${ids.length} site(s) autorisé(s) -> $ids');
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

  /// Récupère un agent par son id
  Future<Agent?> getAgentById(int id) async {
    try {
      final response = await _supabase
          .from('agent')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return Agent.fromJson(response);
    } catch (e) {
      debugPrint('Erreur getAgentById: $e');
      return null;
    }
  }

  /// Réinitialise le mot de passe d'un agent : envoie l'email de réinitialisation Supabase.
  Future<String> resetAgentPassword(Agent agent) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _supabase.auth.resetPasswordForEmail(agent.email);

      return 'Un lien de réinitialisation a été envoyé par email à ${agent.email}.';
    } on AuthException catch (e) {
      debugPrint('Erreur resetAgentPassword: $e');
      return e.message;
    } catch (e) {
      debugPrint('Erreur resetAgentPassword: $e');
      return 'Erreur lors de la réinitialisation: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Appelle le webhook n8n pour envoyer l'email de bienvenue (création)
  Future<void> callValidationWebhook({
    required String email,
    required String nom,
    required String prenom,
    required String motDePasseTemp,
    required String role,
  }) async {
    const webhookUrl =
        'https://automation-annexx-n8n.zcbxvg.easypanel.host/webhook/validate_account';

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
        debugPrint(
            'Erreur lors de l\'appel au webhook n8n: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'appel au webhook n8n: $e');
      // Ne pas faire échouer si le webhook échoue
    }
  }

  /// Demande une réinitialisation de mot de passe par email (écran de connexion).
  /// Utilise l'email de réinitialisation natif de Supabase.
  Future<String> requestPasswordResetByEmail(String email) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _supabase.auth.resetPasswordForEmail(email);

      return "Un lien de réinitialisation a été envoyé à $email.";
    } on AuthException catch (e) {
      debugPrint('Erreur requestPasswordResetByEmail: $e');
      return e.message;
    } catch (e) {
      debugPrint('Erreur requestPasswordResetByEmail: $e');
      return "Erreur lors de l'envoi. Vérifiez votre email ou contactez l'administrateur.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Met à jour le code PIN de l'agent connecté (écran Mon compte).
  Future<String> updateMyPinCode(int? pinCode) async {
    try {
      final agent = _currentAgent;
      if (agent == null) {
        return "Session expirée. Veuillez vous reconnecter.";
      }

      await _supabase
          .from('agent')
          .update({'pin_code': pinCode})
          .eq('id', agent.id);

      _currentAgent = Agent(
        id: agent.id,
        firstname: agent.firstname,
        lastname: agent.lastname,
        email: agent.email,
        pinCode: pinCode,
        role: agent.role,
        statutCompte: agent.statutCompte,
      );
      notifyListeners();

      return "Code PIN mis à jour.";
    } catch (e) {
      debugPrint('Erreur updateMyPinCode: $e');
      return "Erreur lors de la mise à jour du code PIN.";
    }
  }

}
