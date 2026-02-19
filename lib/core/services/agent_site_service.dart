import 'package:flutter/material.dart';
import 'package:staff_admin/core/config/supabase_config.dart';
import 'package:staff_admin/core/models/agent_site.dart';

class AgentSiteService extends ChangeNotifier {
  final _supabase = SupabaseConfig.supabase;
  List<AgentSite> _agentSites = [];
  bool _isLoading = false;

  List<AgentSite> get agentSites => _agentSites;
  bool get isLoading => _isLoading;

  /// Charge toutes les associations agent-site avec les noms
  Future<void> loadAgentSites() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase
          .from('agent_sites')
          .select('''
            id,
            agent_id,
            site_id,
            agent(firstname, lastname),
            site(name)
          ''');

      if (response.isEmpty) {
        _agentSites = [];
        return;
      }

      _agentSites = (response as List).map<AgentSite>((json) {
        // PostgREST retourne agent et site comme objets imbriqués
        final agentData = json['agent'];
        final siteData = json['site'];

        String agentName = '';
        if (agentData != null) {
          final first = agentData['firstname'] ?? '';
          final last = agentData['lastname'] ?? '';
          agentName = '$first $last'.trim();
        }

        final siteName = siteData != null
            ? (siteData['name'] ?? '').toString()
            : '';

        return AgentSite(
          id: int.parse((json['id'] ?? 0).toString()),
          agentId: int.parse((json['agent_id'] ?? 0).toString()),
          agentName: agentName,
          siteId: int.parse((json['site_id'] ?? 0).toString()),
          siteName: siteName,
        );
      }).toList();
    } catch (e) {
      debugPrint('Erreur chargement agent_sites: $e');
      _agentSites = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Ajoute une association agent-site
  Future<void> addAgentSite({required int agentId, required int siteId}) async {
    try {
      await _supabase.from('agent_sites').insert({
        'agent_id': agentId,
        'site_id': siteId,
      });
      await loadAgentSites();
    } catch (e) {
      debugPrint('Erreur ajout agent_site: $e');
      rethrow;
    }
  }

  /// Supprime une association agent-site
  Future<void> deleteAgentSite(int id) async {
    try {
      await _supabase.from('agent_sites').delete().eq('id', id);
      await loadAgentSites();
    } catch (e) {
      debugPrint('Erreur suppression agent_site: $e');
      rethrow;
    }
  }

  /// Charge la liste des agents (id, firstname, lastname)
  Future<List<Map<String, dynamic>>> loadAgents() async {
    try {
      final response = await _supabase
          .from('agent')
          .select('id, firstname, lastname')
          .order('lastname');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Erreur chargement agents: $e');
      return [];
    }
  }

  /// Charge la liste des sites (id, name)
  Future<List<Map<String, dynamic>>> loadSites() async {
    try {
      final response = await _supabase
          .from('site')
          .select('id, name')
          .order('name');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Erreur chargement sites: $e');
      return [];
    }
  }
}
