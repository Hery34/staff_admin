import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:staff_admin/core/models/task_site.dart';
import 'package:staff_admin/core/services/task_site_service.dart';

class SiteTasksScreen extends StatefulWidget {
  const SiteTasksScreen({super.key});

  @override
  State<SiteTasksScreen> createState() => _SiteTasksScreenState();
}

class _SiteTasksScreenState extends State<SiteTasksScreen> {
  int? _selectedSiteId;
  // ignore: unused_field
  String? _selectedSiteName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des tâches par site'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildSiteSelector(),
          ),
          Expanded(
            child: _selectedSiteId == null
                ? const Center(
                    child: Text('Veuillez sélectionner un site'),
                  )
                : _buildTasksList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSiteSelector() {
    return Consumer<TaskSiteService>(
      builder: (context, service, child) {
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: service.loadSites(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }

            if (snapshot.hasError) {
              return Text('Erreur: ${snapshot.error}');
            }

            final sites = snapshot.data ?? [];

            return DropdownButtonFormField<int>(
              value: _selectedSiteId,
              decoration: const InputDecoration(
                labelText: 'Sélectionner un site',
                border: OutlineInputBorder(),
              ),
              items: sites.map<DropdownMenuItem<int>>((site) {
                return DropdownMenuItem<int>(
                  value: site['id'],
                  child: Text(site['name']),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedSiteId = value;
                    _selectedSiteName = sites
                        .firstWhere((site) => site['id'] == value)['name'];
                  });
                  context.read<TaskSiteService>().selectSite(value);
                }
              },
            );
          },
        );
      },
    );
  }

  Widget _buildTasksList() {
    return Consumer<TaskSiteService>(
      builder: (context, service, child) {
        if (service.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final tasks = service.tasks;
        if (tasks.isEmpty) {
          return const Center(
            child: Text('Aucune tâche trouvée pour ce site'),
          );
        }

        return ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: ListTile(
                title: Text(task.taskName),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task.taskDescription),
                    Text('Récurrence: ${task.recurrenceDisplay}'),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showEditDialog(context, task),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _showDeleteDialog(context, task),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showEditDialog(BuildContext context, TaskSite task) async {
    final nameController = TextEditingController(text: task.taskName);
    final descriptionController = TextEditingController(text: task.taskDescription);
    Recurrence selectedRecurrence = task.recurrence;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier la tâche'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom de la tâche',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Recurrence>(
                value: selectedRecurrence,
                decoration: const InputDecoration(
                  labelText: 'Récurrence',
                ),
                items: Recurrence.values.map((recurrence) {
                  final taskSite = TaskSite(
                    id: 0,
                    siteId: 0,
                    siteName: '',
                    taskId: 0,
                    taskName: '',
                    taskDescription: '',
                    recurrence: recurrence,
                  );
                  return DropdownMenuItem(
                    value: recurrence,
                    child: Text(taskSite.recurrenceDisplay),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    selectedRecurrence = value;
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              final updatedTask = TaskSite(
                id: task.id,
                siteId: task.siteId,
                siteName: task.siteName,
                taskId: task.taskId,
                taskName: nameController.text,
                taskDescription: descriptionController.text,
                recurrence: selectedRecurrence,
              );
              
              context.read<TaskSiteService>().updateTaskSite(updatedTask);
              Navigator.of(context).pop();
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteDialog(BuildContext context, TaskSite task) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la tâche'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer la tâche "${task.taskName}" ?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              context.read<TaskSiteService>().deleteTaskSite(task.id);
              Navigator.of(context).pop();
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
} 