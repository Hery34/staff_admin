import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:staff_admin/core/constants/colors.dart';
import 'package:staff_admin/core/services/agent_service.dart';

/// Écran "Mon compte" : permet à l'agent connecté de gérer son code PIN.
/// Visible par tous les utilisateurs connectés (agent, responsable, directeur).
class MyAccountScreen extends StatefulWidget {
  const MyAccountScreen({super.key});

  @override
  State<MyAccountScreen> createState() => _MyAccountScreenState();
}

class _MyAccountScreenState extends State<MyAccountScreen> {
  final _pinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final agent = context.read<AgentService>().currentAgent;
    if (agent?.pinCode != null) {
      _pinController.text = agent!.pinCode.toString();
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _savePinCode() async {
    if (!_formKey.currentState!.validate()) return;

    final value = _pinController.text.trim();
    final pinCode = value.isEmpty ? null : int.tryParse(value);

    if (value.isNotEmpty && pinCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le code PIN doit être un nombre'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (value.isNotEmpty && (pinCode! < 0 || pinCode > 32767)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le code PIN doit être entre 0 et 32767'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final agentService = context.read<AgentService>();
    final result = await agentService.updateMyPinCode(pinCode);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result),
        backgroundColor: result.contains('Erreur') ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon compte'),
      ),
      body: Consumer<AgentService>(
        builder: (context, agentService, child) {
          final agent = agentService.currentAgent;
          if (agent == null) {
            return const Center(
              child: Text('Session expirée. Veuillez vous reconnecter.'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            agent.fullName,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(agent.email, style: TextStyle(color: Colors.grey.shade600)),
                          const SizedBox(height: 4),
                          Chip(
                            label: Text(agent.role.displayName),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Code PIN',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Code PIN personnel (optionnel). Laissez vide pour supprimer.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _pinController,
                    decoration: const InputDecoration(
                      labelText: 'Code PIN (4-5 chiffres)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.pin),
                      hintText: 'Ex: 1234',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(5),
                    ],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return null;
                      final n = int.tryParse(value);
                      if (n == null) return 'Entrez un nombre valide';
                      if (n < 0 || n > 32767) return 'Entre 0 et 32767';
                      if (value.length < 4) return 'Minimum 4 chiffres';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: agentService.isLoading ? null : _savePinCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: redAnnexx,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: agentService.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Enregistrer le code PIN'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
