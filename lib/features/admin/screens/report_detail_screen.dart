import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import 'package:staff_admin/core/models/report.dart';
import 'package:staff_admin/core/models/report_detail.dart';
import 'package:staff_admin/core/services/report_service.dart';
import 'package:data_table_2/data_table_2.dart';

class ReportDetailScreen extends StatefulWidget {
  final int reportId;

  const ReportDetailScreen({
    super.key,
    required this.reportId,
  });

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<ReportService>().loadDetailsForReport(widget.reportId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rapport #${widget.reportId}'),
      ),
      body: Consumer<ReportService>(
        builder: (context, service, child) {
          final report = service.reports.firstWhereOrNull(
            (r) => r.id == widget.reportId,
          );
          final details = service.getDetailsForReport(widget.reportId);

          if (report == null || details == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildReportInfo(report),
                const SizedBox(height: 24),
                Expanded(
                  child: _buildDetailsTable(details),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildReportInfo(Report report) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations du rapport',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Date du clôture de rapport', report.formattedDateTime),
            _buildInfoRow('Date de génération du rapport', report.formattedToDoListDateTime),
            _buildInfoRow('Site', report.siteDisplay),
            _buildInfoRow('Signataire', report.responsableFullName),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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

  Widget _buildDetailsTable(List<ReportDetail> details) {
    if (details.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Détails',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text('Aucun détail associé à ce rapport'),
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
              'Détails',
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
                    label: Text('Commentaire'),
                    size: ColumnSize.L,
                  ),
                  DataColumn2(
                    label: Text('Photo'),
                    size: ColumnSize.S,
                  ),
                ],
                rows: details.map((detail) {
                  return DataRow(
                    cells: [
                      DataCell(Text(detail.taskName ?? 'Tâche ${detail.task}')),
                      DataCell(
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 300),
                          child: Text(detail.comment ?? '-'),
                        ),
                      ),
                      DataCell(
                        detail.photoUrl != null
                            ? IconButton(
                                icon: const Icon(Icons.photo),
                                onPressed: () {
                                  // TODO: Implement photo view
                                },
                              )
                            : const Text('-'),
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