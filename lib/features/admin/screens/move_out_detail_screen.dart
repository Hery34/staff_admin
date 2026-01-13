import 'package:flutter/material.dart';
import 'package:staff_admin/core/models/move_out.dart';

class MoveOutDetailScreen extends StatelessWidget {
  final MoveOut moveOut;

  const MoveOutDetailScreen({
    super.key,
    required this.moveOut,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Move-Out: ${moveOut.name}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Informations du Move-Out',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 24),
                _buildInfoRow('ID', moveOut.id.toString()),
                _buildInfoRow('Nom', moveOut.name),
                _buildInfoRow('Box', moveOut.box),
                _buildInfoRow('Date de création', moveOut.formattedCreatedAt),
                _buildInfoRow('Créé par', moveOut.createdByName),
                if (moveOut.startDate != null)
                  _buildInfoRow('Date de début', moveOut.startDate!),
                if (moveOut.leaveDate != null)
                  _buildInfoRow('Date de départ', moveOut.leaveDate!),
                if (moveOut.taille != null)
                  _buildInfoRow('Taille', moveOut.taille!),
                if (moveOut.sizeCode != null)
                  _buildInfoRow('Code taille', moveOut.sizeCode!),
                if (moveOut.idClient != null)
                  _buildInfoRow('ID Client', moveOut.idClient!),
                _buildInfoRow('Vide', moveOut.isEmpty ? 'Oui' : 'Non'),
                _buildInfoRow('Loxx', moveOut.hasLoxx ? 'Oui' : 'Non'),
                _buildInfoRow('Propre', moveOut.isClean ? 'Oui' : 'Non'),
                if (moveOut.comments != null && moveOut.comments!.isNotEmpty)
                  _buildInfoRow('Commentaires', moveOut.comments!),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
