import 'package:flutter/material.dart';
import 'package:staff_admin/core/models/move_in.dart';

class MoveInDetailScreen extends StatelessWidget {
  final MoveIn moveIn;

  const MoveInDetailScreen({
    super.key,
    required this.moveIn,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Move-In: ${moveIn.name}'),
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
                  'Informations du Move-In',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 24),
                _buildInfoRow('ID', moveIn.id.toString()),
                _buildInfoRow('Nom', moveIn.name),
                _buildInfoRow('Box', moveIn.box),
                _buildInfoRow('Date de création', moveIn.formattedCreatedAt),
                _buildInfoRow('Créé par', moveIn.createdByName),
                if (moveIn.startDate != null)
                  _buildInfoRow('Date de début', moveIn.startDate!),
                if (moveIn.taille != null)
                  _buildInfoRow('Taille', moveIn.taille!),
                if (moveIn.sizeCode != null)
                  _buildInfoRow('Code taille', moveIn.sizeCode!),
                if (moveIn.idClient != null)
                  _buildInfoRow('ID Client', moveIn.idClient!),
                _buildInfoRow('Vide', moveIn.isEmpty ? 'Oui' : 'Non'),
                _buildInfoRow('Loxx sur la porte', moveIn.hasLoxxOnDoor ? 'Oui' : 'Non'),
                _buildInfoRow('Propre', moveIn.isClean ? 'Oui' : 'Non'),
                _buildInfoRow('Poster OK', moveIn.posterOk ? 'Oui' : 'Non'),
                if (moveIn.comments != null && moveIn.comments!.isNotEmpty)
                  _buildInfoRow('Commentaires', moveIn.comments!),
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
