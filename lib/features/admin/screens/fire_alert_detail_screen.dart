import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import 'package:staff_admin/core/constants/colors.dart';
import 'package:staff_admin/core/models/fire_alert_report.dart';
import 'package:staff_admin/core/models/fire_alert_task.dart';
import 'package:staff_admin/core/services/fire_alert_service.dart';
import 'package:data_table_2/data_table_2.dart';

class FireAlertDetailScreen extends StatefulWidget {
  final int reportId;

  const FireAlertDetailScreen({
    super.key,
    required this.reportId,
  });

  @override
  State<FireAlertDetailScreen> createState() => _FireAlertDetailScreenState();
}

class _FireAlertDetailScreenState extends State<FireAlertDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<FireAlertService>().loadTasksForReport(widget.reportId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FireAlertService>(
      builder: (context, service, child) {
        final report = service.reports.firstWhereOrNull(
          (r) => r.id == widget.reportId,
        );
        final tasks = service.getTasksForReport(widget.reportId);

        if (report == null || tasks == null) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Rapport #${widget.reportId}'),
                if (report.siteName != null)
                  Text(
                    report.siteName!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.black,
                    ),
                  ),
              ],
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildReportInfo(report),
                const SizedBox(height: 24),
                Expanded(
                  child: _buildTasksTable(tasks, service),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReportInfo(FireAlertReport report) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations du rapport',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Date', report.formattedDate),
            _buildInfoRow('Type', report.alertTypeDisplay),
            _buildInfoRow('Étage', report.floor?.toString() ?? 'Non spécifié'),
            _buildInfoRow('Déclencheur', report.declencheur.toString().split('.').last),
            _buildInfoRow('État', report.isRunning ? 'En cours' : 'Terminé'),
            _buildInfoRow('Créé par', report.createdByName ?? 'Non spécifié'),
            if (!report.isRunning) ...[
              _buildInfoRow('Fermé le', report.formattedClosedAt),
              _buildInfoRow('Fermé par', report.closedByName ?? 'Non spécifié'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildTasksTable(List<FireAlertTask> tasks, FireAlertService service) {
    if (tasks.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Tâches',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text('Aucune tâche associée à ce rapport'),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tâches',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: DataTable2(
                columnSpacing: 12,
                horizontalMargin: 12,
                minWidth: 600,
                smRatio: 0.75,
                lmRatio: 1.5,
                columns: const [
                  DataColumn2(
                    label: Text('Tâche'),
                    size: ColumnSize.L,
                  ),
                  DataColumn2(
                    label: Text('État'),
                    size: ColumnSize.S,
                  ),
                  DataColumn2(
                    label: Text('Complété le'),
                    size: ColumnSize.M,
                  ),
                  DataColumn2(
                    label: Text('Notes'),
                    size: ColumnSize.L,
                  ),
                ],
                rows: tasks.map((task) {
                  return DataRow(
                    cells: [
                      DataCell(Text(task.displayName)),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: task.isDone ? Colors.green : Colors.orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            task.isDone ? 'Complété' : 'En attente',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      DataCell(Text(task.formattedCompletedAt)),
                      DataCell(
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 300),
                          child: Text(task.notes ?? '-'),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 