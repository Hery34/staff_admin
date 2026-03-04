import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:staff_admin/core/constants/colors.dart';
import 'package:staff_admin/core/models/agent.dart';
import 'package:staff_admin/core/services/agent_service.dart';
import 'package:staff_admin/features/admin/screens/create_agent_screen.dart';

class AgentManagementScreen extends StatefulWidget {
  const AgentManagementScreen({super.key});

  @override
  State<AgentManagementScreen> createState() => _AgentManagementScreenState();
}

class _AgentManagementScreenState extends State<AgentManagementScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        context.read<AgentService>().loadAgents();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showResetPasswordDialog(BuildContext context, Agent agent) async {
    final agentService = context.read<AgentService>();
    final messenger = ScaffoldMessenger.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Réinitialiser le mot de passe'),
        content: Text(
          'Un nouveau mot de passe sera généré et envoyé par email à ${agent.email}. Continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: redAnnexx),
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final result = await agentService.resetAgentPassword(agent);
    if (!context.mounted) return;
    if (result.contains('envoyé')) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(result),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(result),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  List<Agent> _filterAgents(List<Agent> agents, String query) {
    if (query.trim().isEmpty) return agents;
    final q = query.trim().toLowerCase();
    return agents.where((a) {
      return a.fullName.toLowerCase().contains(q) ||
          a.email.toLowerCase().contains(q) ||
          a.role.displayName.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des agents'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Créer un agent',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateAgentScreen(),
                ),
              );
              if (context.mounted) {
                context.read<AgentService>().loadAgents();
              }
            },
          ),
        ],
      ),
      body: Consumer<AgentService>(
        builder: (context, agentService, child) {
          if (agentService.isLoading && agentService.agents.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final filteredAgents = _filterAgents(
            agentService.agents,
            _searchController.text,
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher par nom, email ou rôle…',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              Expanded(
                child: filteredAgents.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              agentService.agents.isEmpty
                                  ? Icons.people_outline
                                  : Icons.search_off,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              agentService.agents.isEmpty
                                  ? 'Aucun agent'
                                  : 'Aucun résultat pour cette recherche',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                            ),
                            if (agentService.agents.isEmpty) ...[
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const CreateAgentScreen(),
                                    ),
                                  );
                                  if (context.mounted) {
                                    context.read<AgentService>().loadAgents();
                                  }
                                },
                                icon: const Icon(Icons.person_add),
                                label: const Text('Créer un agent'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: redAnnexx,
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredAgents.length,
                        itemBuilder: (context, index) {
                          final agent = filteredAgents[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                child: Text(
                                  agent.fullName.isNotEmpty
                                      ? agent.fullName[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(agent.fullName),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(agent.email, style: const TextStyle(fontSize: 12)),
                                  Row(
                                    children: [
                                      Chip(
                                        label: Text(
                                          agent.role.displayName,
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                        padding: EdgeInsets.zero,
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      const SizedBox(width: 8),
                                      Chip(
                                        label: Text(
                                          agent.statutCompte.displayName,
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                        padding: EdgeInsets.zero,
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.lock_reset),
                                tooltip: 'Réinitialiser le mot de passe',
                                onPressed: agentService.isLoading
                                    ? null
                                    : () => _showResetPasswordDialog(context, agent),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateAgentScreen(),
            ),
          );
          if (context.mounted) {
            context.read<AgentService>().loadAgents();
          }
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Créer un agent'),
        backgroundColor: redAnnexx,
      ),
    );
  }
}
