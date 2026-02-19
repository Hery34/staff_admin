import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:staff_admin/core/models/agent_site.dart';
import 'package:staff_admin/core/services/agent_site_service.dart';

/// Regroupe les associations par agent
class _AgentSitesGroup {
  final int agentId;
  final String agentName;
  final List<AgentSite> sites;

  _AgentSitesGroup({
    required this.agentId,
    required this.agentName,
    required this.sites,
  });
}

class AgentSitesScreen extends StatefulWidget {
  const AgentSitesScreen({super.key});

  @override
  State<AgentSitesScreen> createState() => _AgentSitesScreenState();
}

class _AgentSitesScreenState extends State<AgentSitesScreen> {
  final _searchController = TextEditingController();
  int? _selectedSiteFilterId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    Future.microtask(() {
      if (mounted) {
        context.read<AgentSiteService>().loadAgentSites();
      }
    });
  }

  Widget _buildFilterBar(
    BuildContext context,
    List<({int id, String name})> uniqueSites,
    bool isNarrow,
  ) {
    return isNarrow
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Rechercher par nom d\'agent ou de site…',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => _searchController.clear()),
                        )
                      : null,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
                value: _selectedSiteFilterId,
                decoration: const InputDecoration(
                  labelText: 'Filtrer par site',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('Tous les sites')),
                  ...uniqueSites.map((s) => DropdownMenuItem<int?>(
                        value: s.id,
                        child: Text(s.name),
                      )),
                ],
                onChanged: (v) => setState(() => _selectedSiteFilterId = v),
              ),
              if (_searchController.text.isNotEmpty || _selectedSiteFilterId != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _selectedSiteFilterId = null;
                      });
                    },
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text('Effacer les filtres'),
                  ),
                ),
            ],
          )
        : Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher par nom d\'agent ou de site…',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() => _searchController.clear()),
                          )
                        : null,
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 260,
                child: DropdownButtonFormField<int?>(
                  value: _selectedSiteFilterId,
                  decoration: const InputDecoration(
                    labelText: 'Filtrer par site',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('Tous les sites')),
                    ...uniqueSites.map((s) => DropdownMenuItem<int?>(
                          value: s.id,
                          child: Text(s.name),
                        )),
                  ],
                  onChanged: (v) => setState(() => _selectedSiteFilterId = v),
                ),
              ),
              if (_searchController.text.isNotEmpty || _selectedSiteFilterId != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _selectedSiteFilterId = null;
                      });
                    },
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text('Effacer'),
                  ),
                ),
            ],
          );
  }

  List<({int id, String name})> _getUniqueSites(List<_AgentSitesGroup> groups) {
    final seen = <int>{};
    final result = <({int id, String name})>[];
    for (final g in groups) {
      for (final s in g.sites) {
        if (seen.add(s.siteId)) {
          result.add((id: s.siteId, name: s.siteName));
        }
      }
    }
    result.sort((a, b) => a.name.compareTo(b.name));
    return result;
  }

  List<_AgentSitesGroup> _applyFilters(
    List<_AgentSitesGroup> groups,
    String query,
    int? siteId,
  ) {
    return groups.where((g) {
      final matchSearch = query.isEmpty ||
          g.agentName.toLowerCase().contains(query.toLowerCase()) ||
          g.sites.any((s) => s.siteName.toLowerCase().contains(query.toLowerCase()));
      final matchSite = siteId == null || g.sites.any((s) => s.siteId == siteId);
      return matchSearch && matchSite;
    }).toList();
  }

  List<_AgentSitesGroup> _groupByAgent(List<AgentSite> items) {
    final map = <int, _AgentSitesGroup>{};
    for (final a in items) {
      map.putIfAbsent(a.agentId, () => _AgentSitesGroup(
            agentId: a.agentId,
            agentName: a.agentName,
            sites: [],
          ));
      map[a.agentId]!.sites.add(a);
    }
    return map.values.toList()
      ..sort((a, b) => a.agentName.compareTo(b.agentName));
  }

  Future<void> _showAddDialog(BuildContext context, {int? preSelectedAgentId}) async {
    final service = context.read<AgentSiteService>();
    final messenger = ScaffoldMessenger.of(context);
    final agents = await service.loadAgents();
    final sites = await service.loadSites();

    if (!context.mounted) return;

    int? selectedAgentId = preSelectedAgentId;
    int? selectedSiteId;

    // Si on ouvre depuis une carte, filtrer les sites déjà assignés à cet agent
    final groups = _groupByAgent(service.agentSites);
    Set<int>? excludeSiteIds;
    if (preSelectedAgentId != null) {
      final g = groups.where((g) => g.agentId == preSelectedAgentId).firstOrNull;
      excludeSiteIds = g?.sites.map((s) => s.siteId).toSet();
    }

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          final siteItems = sites.where((s) {
            final sid = s['id'];
            final i = sid is int ? sid : int.tryParse(sid.toString());
            return i != null && (excludeSiteIds == null || !excludeSiteIds!.contains(i));
          }).toList();

          return AlertDialog(
            title: Text(preSelectedAgentId != null ? 'Ajouter un site' : 'Associer un agent à un site'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (preSelectedAgentId == null)
                    DropdownButtonFormField<int>(
                      value: selectedAgentId,
                      decoration: const InputDecoration(
                        labelText: 'Agent',
                        border: OutlineInputBorder(),
                      ),
                      items: agents.map((a) {
                        final id = a['id'];
                        final i = id is int ? id : int.tryParse(id.toString());
                        if (i == null) return null;
                        final name = '${a['firstname'] ?? ''} ${a['lastname'] ?? ''}'.trim();
                        return DropdownMenuItem<int>(
                          value: i,
                          child: Text(name.isNotEmpty ? name : 'Agent #$i'),
                        );
                      }).whereType<DropdownMenuItem<int>>().toList(),
                      onChanged: (v) => setDialogState(() => selectedAgentId = v),
                    ),
                  if (preSelectedAgentId == null) const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: selectedSiteId,
                    decoration: const InputDecoration(
                      labelText: 'Site',
                      border: OutlineInputBorder(),
                    ),
                    items: siteItems.map((s) {
                      final id = s['id'];
                      final i = id is int ? id : int.tryParse(id.toString());
                      if (i == null) return null;
                      return DropdownMenuItem<int>(
                        value: i,
                        child: Text((s['name'] ?? 'Site #$i').toString()),
                      );
                    }).whereType<DropdownMenuItem<int>>().toList(),
                    onChanged: siteItems.isEmpty ? null : (v) => setDialogState(() => selectedSiteId = v),
                  ),
                  if (siteItems.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Tous les sites sont déjà assignés à cet agent',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: siteItems.isEmpty
                    ? null
                    : () async {
                        final aid = selectedAgentId ?? preSelectedAgentId;
                        if (aid == null || selectedSiteId == null) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Veuillez sélectionner un agent et un site'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }
                        Navigator.of(context).pop();
                        try {
                          await service.addAgentSite(
                                agentId: aid,
                                siteId: selectedSiteId!,
                              );
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Association créée'),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        } catch (e) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Erreur : $e'),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                child: const Text('Ajouter'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showDeleteDialog(BuildContext context, AgentSite agentSite) async {
    final service = context.read<AgentSiteService>();
    final messenger = ScaffoldMessenger.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retirer le site'),
        content: Text(
          'Retirer "${agentSite.siteName}" de l\'agent "${agentSite.agentName}" ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await service.deleteAgentSite(agentSite.id);
      if (!context.mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Site retiré'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion agents / sites'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Associer un agent à un site',
            onPressed: () => _showAddDialog(context),
          ),
        ],
      ),
      body: Consumer<AgentSiteService>(
        builder: (context, service, child) {
          if (service.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final allGroups = _groupByAgent(service.agentSites);
          final filteredGroups = _applyFilters(
            allGroups,
            _searchController.text,
            _selectedSiteFilterId,
          );
          final uniqueSites = _getUniqueSites(allGroups);

          if (allGroups.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.link_off, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune association agent-site',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showAddDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Créer une association'),
                  ),
                ],
              ),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 600;
              final cardWidth = isNarrow ? constraints.maxWidth - 32 : 340.0;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: _buildFilterBar(context, uniqueSites, isNarrow),
                  ),
                  Expanded(
                    child: filteredGroups.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                Text(
                                  _searchController.text.isNotEmpty || _selectedSiteFilterId != null
                                      ? 'Aucun résultat pour ces critères'
                                      : 'Aucune carte à afficher',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        color: Colors.grey.shade600,
                                      ),
                                ),
                              ],
                            ),
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              alignment: WrapAlignment.start,
                              children: filteredGroups
                                  .map((g) => _buildAgentCard(context, g, cardWidth))
                                  .toList(),
                            ),
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAgentCard(BuildContext context, _AgentSitesGroup group, double cardWidth) {
    return SizedBox(
      width: cardWidth,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Text(
                      group.agentName.isNotEmpty ? group.agentName[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      group.agentName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...group.sites.map((as) => Chip(
                        deleteIcon: const Icon(Icons.close, size: 18),
                        onDeleted: () => _showDeleteDialog(context, as),
                        label: Text(as.siteName),
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      )),
                  ActionChip(
                    avatar: const Icon(Icons.add, size: 18, color: Colors.green),
                    label: const Text('Ajouter un site'),
                    onPressed: () => _showAddDialog(context, preSelectedAgentId: group.agentId),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
