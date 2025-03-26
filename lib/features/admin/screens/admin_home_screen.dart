import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:staff_admin/core/services/auth_service.dart';
import 'package:staff_admin/features/admin/screens/fire_alert_list_screen.dart';
import 'package:staff_admin/features/admin/screens/report_list_screen.dart';
import 'package:staff_admin/features/admin/screens/site_tasks_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administration Annexx'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              try {
                final result = await context.read<AuthService>().logout();
                if (!context.mounted) return;

                if (result == "Déconnexion réussie") {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Déconnexion réussie"),
                      backgroundColor: Colors.green,
                    ),
                  );
                  
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login',
                    (route) => false,
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Erreur lors de la déconnexion: $e"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16.0),
        mainAxisSpacing: 16.0,
        crossAxisSpacing: 16.0,
        children: [
          _buildMenuCard(
            context,
            'Rapports Alerte Incendie',
            Icons.local_fire_department,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FireAlertListScreen(),
                ),
              );
            },
          ),
          _buildMenuCard(
            context,
            'Rapports de Tâches',
            Icons.assignment,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ReportListScreen(),
                ),
              );
            },
          ),
          _buildMenuCard(
            context,
            'Tâches par Site',
            Icons.task_alt,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SiteTasksScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
} 