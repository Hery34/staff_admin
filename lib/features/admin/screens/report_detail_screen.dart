import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import 'package:staff_admin/core/models/report.dart';
import 'package:staff_admin/core/models/report_detail.dart';
import 'package:staff_admin/core/models/move_in.dart';
import 'package:staff_admin/core/models/move_out.dart';
import 'package:staff_admin/core/models/ovl.dart';
import 'package:staff_admin/core/services/report_service.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:staff_admin/features/admin/screens/image_viewer_screen.dart';
import 'package:staff_admin/features/admin/screens/move_in_detail_screen.dart';
import 'package:staff_admin/features/admin/screens/move_out_detail_screen.dart';

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
      if(mounted) {
        context.read<ReportService>().loadDetailsForReport(widget.reportId);
      }
    });
  }

  /// Calcule la hauteur dynamique d'un DataTable2 en fonction du nombre de lignes
  /// 
  /// [rowCount] : Nombre de lignes de données dans le tableau
  /// [headerHeight] : Hauteur de l'en-tête du tableau (défaut: 56px)
  /// [rowHeight] : Hauteur d'une ligne de données (défaut: 56px)
  /// [minHeight] : Hauteur minimale du tableau (défaut: 200px)
  /// [maxHeight] : Hauteur maximale du tableau (défaut: 600px)
  /// 
  /// Retourne la hauteur calculée contrainte entre minHeight et maxHeight
  double _calculateTableHeight(
    int rowCount, {
    double headerHeight = 56.0,
    double rowHeight = 56.0,
    double minHeight = 200.0,
    double maxHeight = 600.0,
  }) {
    // Calcul de base : en-tête + lignes
    final calculatedHeight = headerHeight + (rowCount * rowHeight);
    
    // Application des contraintes min/max
    return calculatedHeight.clamp(minHeight, maxHeight);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rapport n° ${widget.reportId}'),
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

          final moveIns = service.getMoveInsForReport(widget.reportId) ?? [];
          final moveOuts = service.getMoveOutsForReport(widget.reportId) ?? [];
          final ovls = service.getOvlsForReport(widget.reportId) ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildReportInfo(report),
                const SizedBox(height: 24),
                _buildDetailsTable(details),
                const SizedBox(height: 24),
                _buildMoveInsSection(moveIns),
                const SizedBox(height: 24),
                _buildMoveOutsSection(moveOuts),
                const SizedBox(height: 24),
                _buildOvlsSection(ovls),
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
            _buildInfoRow('Date de clôture', report.formattedDateTime),
            _buildInfoRow('Date de génération', report.formattedToDoListDateTime),
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

  /// Regroupe les détails par tâche (une ligne par tâche, plusieurs photos possibles).
  List<({int task, String? taskName, String? comment, List<ReportDetail> details})> _groupDetailsByTask(
      List<ReportDetail> details) {
    final grouped = groupBy<ReportDetail, int>(details, (d) => d.task);
    return grouped.entries.map((e) {
      final list = e.value;
      final first = list.first;
      final comment = list.map((d) => d.comment).firstWhere(
            (c) => c != null && c.toString().trim().isNotEmpty,
            orElse: () => null,
          ) ?? first.comment;
      return (
        task: e.key,
        taskName: first.taskName,
        comment: comment,
        details: list,
      );
    }).toList();
  }

  Widget _buildDetailsTable(List<ReportDetail> details) {
    final taskRows = _groupDetailsByTask(details);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tâches du jour',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (details.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Aucune tâche associée à ce rapport'),
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: (MediaQuery.of(context).size.width - 32).clamp(600.0, double.infinity),
                  height: _calculateTableHeight(taskRows.length),
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
                        label: Text('Commentaire'),
                        size: ColumnSize.L,
                      ),
                      DataColumn2(
                        label: Text('Photo'),
                        size: ColumnSize.S,
                      ),
                    ],
                    rows: taskRows.map((row) {
                      return DataRow(
                        cells: [
                          DataCell(Text(row.taskName ?? 'Tâche ${row.task}')),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Complété',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                          DataCell(
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 300),
                              child: Text(row.comment ?? '-'),
                            ),
                          ),
                          DataCell(_buildPhotoCell(row.details)),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static const double _thumbnailSize = 48.0;

  Widget _buildPhotoCell(List<ReportDetail> detailsWithPhotos) {
    final withUrl = detailsWithPhotos.where((d) => d.photoUrl != null && d.photoUrl!.trim().isNotEmpty).toList();
    if (withUrl.isEmpty) return const Text('-');
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: withUrl.asMap().entries.map((e) {
        final url = e.value.photoUrl!;
        final index = e.key + 1;
        return Tooltip(
          message: 'Photo $index - cliquer pour agrandir',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _openPhotoViewer(url, index),
              borderRadius: BorderRadius.circular(8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: _thumbnailSize,
                  height: _thumbnailSize,
                  child: Image.network(
                    url,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => Container(
                      color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
                      child: const Icon(Icons.broken_image_outlined, size: 28),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _openPhotoViewer(String url, int index) {
    try {
      final uri = Uri.parse(url);
      if (uri.hasAbsolutePath) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImageViewerScreen(
              imageUrl: url,
              title: 'Photo $index du rapport',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("L'URL de l'image n'est pas valide"),
          ),
        );
      }
    } catch (err) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Erreur lors de l'accès à l'image"),
        ),
      );
    }
  }

  Widget _buildMoveInsSection(List<MoveIn> moveIns) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.move_to_inbox, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Move-In du jour (${moveIns.length})',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (moveIns.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Aucun move-in pour ce jour'),
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: (MediaQuery.of(context).size.width - 32).clamp(600.0, double.infinity),
                  height: _calculateTableHeight(moveIns.length),
                  child: DataTable2(
                    columnSpacing: 12,
                    horizontalMargin: 12,
                    minWidth: 600,
                    columns: const [
                      DataColumn2(label: Text('Nom'), size: ColumnSize.M),
                      DataColumn2(label: Text('Box'), size: ColumnSize.S),
                      DataColumn2(label: Text('Date création'), size: ColumnSize.M),
                      DataColumn2(label: Text('Créé par'), size: ColumnSize.M),
                      DataColumn2(label: Text('Commentaires'), size: ColumnSize.L),
                    ],
                    rows: moveIns.map((moveIn) {
                      return DataRow(
                        onSelectChanged: (_) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MoveInDetailScreen(
                                moveIn: moveIn,
                              ),
                            ),
                          );
                        },
                        cells: [
                          DataCell(Text(moveIn.name)),
                          DataCell(Text(moveIn.box)),
                          DataCell(Text(moveIn.formattedCreatedAt)),
                          DataCell(Text(moveIn.createdByName)),
                          DataCell(
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 300),
                              child: Text(moveIn.comments ?? '-'),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoveOutsSection(List<MoveOut> moveOuts) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.exit_to_app, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Move-Out du jour (${moveOuts.length})',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (moveOuts.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Aucun move-out pour ce jour'),
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: (MediaQuery.of(context).size.width - 32).clamp(600.0, double.infinity),
                  height: _calculateTableHeight(moveOuts.length),
                  child: DataTable2(
                    columnSpacing: 12,
                    horizontalMargin: 12,
                    minWidth: 600,
                    columns: const [
                      DataColumn2(label: Text('Nom'), size: ColumnSize.M),
                      DataColumn2(label: Text('Box'), size: ColumnSize.S),
                      DataColumn2(label: Text('Date création'), size: ColumnSize.M),
                      DataColumn2(label: Text('Créé par'), size: ColumnSize.M),
                      DataColumn2(label: Text('Commentaires'), size: ColumnSize.L),
                    ],
                    rows: moveOuts.map((moveOut) {
                      return DataRow(
                        onSelectChanged: (_) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MoveOutDetailScreen(
                                moveOut: moveOut,
                              ),
                            ),
                          );
                        },
                        cells: [
                          DataCell(Text(moveOut.name)),
                          DataCell(Text(moveOut.box)),
                          DataCell(Text(moveOut.formattedCreatedAt)),
                          DataCell(Text(moveOut.createdByName)),
                          DataCell(
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 300),
                              child: Text(moveOut.comments ?? '-'),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOvlsSection(List<Ovl> ovls) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lock, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'OVL posées du jour (${ovls.length})',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (ovls.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Aucune OVL posée pour ce jour'),
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: (MediaQuery.of(context).size.width - 32).clamp(600.0, double.infinity),
                  height: _calculateTableHeight(ovls.length),
                  child: DataTable2(
                    columnSpacing: 12,
                    horizontalMargin: 12,
                    minWidth: 600,
                    columns: const [
                      DataColumn2(label: Text('Numéro'), size: ColumnSize.M),
                      DataColumn2(label: Text('Code'), size: ColumnSize.S),
                      DataColumn2(label: Text('Date/Heure'), size: ColumnSize.M),
                      DataColumn2(label: Text('Client ID'), size: ColumnSize.M),
                      DataColumn2(label: Text('Opérateur'), size: ColumnSize.M),
                    ],
                    rows: ovls.map((ovl) {
                      return DataRow(
                        cells: [
                          DataCell(Text(ovl.number ?? '-')),
                          DataCell(Text(ovl.code?.toString() ?? '-')),
                          DataCell(Text(ovl.formattedDateTime)),
                          DataCell(Text(ovl.customerId ?? '-')),
                          DataCell(Text(ovl.operatorName)),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}