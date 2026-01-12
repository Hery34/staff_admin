import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:staff_admin/core/services/auth_service.dart';
import 'package:staff_admin/features/admin/screens/fire_alert_list_screen.dart';
import 'package:staff_admin/features/admin/screens/report_list_screen.dart';
import 'package:staff_admin/features/admin/screens/site_tasks_screen.dart';
import 'package:staff_admin/features/admin/screens/create_agent_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administration Staff Annexx'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              try {
                final result = await context.read<AuthService>().logout();
                if (!context.mounted) return;

                if (result == "Déconnexion réussie") {
                  if (!context.mounted) return;
                  
                  await Navigator.of(context).pushReplacementNamed('/login');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Erreur lors de la déconnexion: $e"),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive layout
          final isWebOrDesktop = constraints.maxWidth > 600;
          final crossAxisCount = isWebOrDesktop ? 3 : 1;
          final padding = isWebOrDesktop ? 24.0 : 16.0;
          
          return Center(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: isWebOrDesktop ? 1200 : double.infinity,
              ),
              child: GridView.count(
                crossAxisCount: crossAxisCount,
                padding: EdgeInsets.all(padding),
                mainAxisSpacing: padding,
                crossAxisSpacing: padding,
                // Ajuster la taille des cartes sur le web
                childAspectRatio: isWebOrDesktop ? 1.5 : 1.3,
                shrinkWrap: isWebOrDesktop,
                physics: isWebOrDesktop 
                  ? const NeverScrollableScrollPhysics() 
                  : const AlwaysScrollableScrollPhysics(),
                children: [
                  _buildAnimatedMenuCard(
                    context,
                    'Rapports Alerte Incendie',
                    Icons.local_fire_department,
                    () => _navigateWithAnimation(
                      context,
                      const FireAlertListScreen(),
                    ),
                    0,
                  ),
                  _buildAnimatedMenuCard(
                    context,
                    'Rapports quotidiens',
                    Icons.assignment,
                    () => _navigateWithAnimation(
                      context,
                      const ReportListScreen(),
                    ),
                    1,
                  ),
                  _buildAnimatedMenuCard(
                    context,
                    'Tâches par Site',
                    Icons.task_alt,
                    () => _navigateWithAnimation(
                      context,
                      const SiteTasksScreen(),
                    ),
                    2,
                  ),
                  _buildAnimatedMenuCard(
                    context,
                    'Créer un agent',
                    Icons.person_add,
                    () => _navigateWithAnimation(
                      context,
                      const CreateAgentScreen(),
                    ),
                    3,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _navigateWithAnimation(BuildContext context, Widget screen) async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;
          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );
          var offsetAnimation = animation.drive(tween);
          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  Widget _buildAnimatedMenuCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
    int index,
  ) {
    final isWebOrDesktop = MediaQuery.of(context).size.width > 600;

    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, double value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Hero(
        tag: title,
        child: Card(
          elevation: 4,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary.withValues(alpha:0.8),
                    Theme.of(context).colorScheme.primary,
                  ],
                ),
              ),
              child: isWebOrDesktop
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        size: 32,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 16),
                      Flexible(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        size: 48,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
            ),
          ),
        ),
      ),
    );
  }
} 