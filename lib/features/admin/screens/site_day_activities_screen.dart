import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:staff_admin/core/models/move_in.dart';
import 'package:staff_admin/core/models/move_out.dart';
import 'package:staff_admin/core/models/ovl.dart';
import 'package:staff_admin/core/models/site_day_task.dart';
import 'package:staff_admin/core/services/agent_service.dart';
import 'package:staff_admin/core/services/agent_site_service.dart';
import 'package:staff_admin/core/services/report_service.dart';
import 'package:staff_admin/features/admin/screens/image_viewer_screen.dart';
import 'package:staff_admin/features/admin/screens/move_in_detail_screen.dart';
import 'package:staff_admin/features/admin/screens/move_out_detail_screen.dart';
import 'package:staff_admin/features/admin/screens/report_detail_screen.dart';
import 'package:data_table_2/data_table_2.dart';

class SiteDayActivitiesScreen extends StatefulWidget {
  const SiteDayActivitiesScreen({super.key});

  @override
  State<SiteDayActivitiesScreen> createState() => _SiteDayActivitiesScreenState();
}

class _SiteDayActivitiesScreenState extends State<SiteDayActivitiesScreen> {
  int? _selectedSiteId;
  DateTime? _selectedDate;
  List<Map<String, dynamic>> _sites = [];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    Future.microtask(() => _loadSites());
  }

  Future<void> _loadSites() async {
    if (!mounted) return;
    final agentSiteService = context.read<AgentSiteService>();
    var sites = await agentSiteService.loadSites();
    if (!mounted) return;
    final allowedIds = context.read<AgentService>().allowedSiteIds;
    if (allowedIds != null) {
      sites = sites.where((s) {
        final id = s['id'];
        return id != null && allowedIds.contains(id is int ? id : int.tryParse(id.toString()));
      }).toList();
    }
    setState(() => _sites = sites);
  }

  void _loadActivities() {
    if (_selectedSiteId == null || _selectedDate == null) return;
    context.read<ReportService>().loadActivitiesBySiteAndDate(
      _selectedSiteId!,
      _selectedDate!,
    );
  }

  double _tableHeight(int rowCount, {double minH = 200, double maxH = 600}) {
    return (56 + rowCount * 56.0).clamp(minH, maxH);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activités du jour par site'),
      ),
      body: Consumer3<ReportService, AgentSiteService, AgentService>(
        builder: (context, reportService, agentSiteService, agentService, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFilters(reportService),
                const SizedBox(height: 24),
                if (_selectedSiteId != null && _selectedDate != null) ...[
                  if (reportService.siteDayLoading)
                    const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
                  else
                    _buildContent(reportService),
                ] else
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'Sélectionnez un site et une date pour afficher les activités',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilters(ReportService reportService) {
    final siteOptions = _sites.map((s) => DropdownMenuItem<int>(
      value: s['id'] as int,
      child: Text(s['name']?.toString() ?? 'Site ${s['id']}'),
    )).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filtres', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: 240,
                  child: DropdownButtonFormField<int>(
                    value: _selectedSiteId,
                    decoration: const InputDecoration(
                      labelText: 'Site',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Choisir un site')),
                      ...siteOptions,
                    ],
                    onChanged: (v) {
                      setState(() => _selectedSiteId = v);
                      _loadActivities();
                    },
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label: Text(_selectedDate != null
                        ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                        : 'Date'),
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (d != null) {
                        setState(() => _selectedDate = d);
                        _loadActivities();
                      }
                    },
                  ),
                ),
                if (_selectedSiteId != null && _selectedDate != null)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Actualiser'),
                    onPressed: _loadActivities,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ReportService reportService) {
    final moveIns = reportService.siteDayMoveIns;
    final moveOuts = reportService.siteDayMoveOuts;
    final ovls = reportService.siteDayOvls;
    final tasks = reportService.siteDayTasks;
    final reports = reportService.siteDayReports;
    final hasReports = reports.isNotEmpty;
    final siteName = _sites.firstWhere(
      (s) => s['id'] == _selectedSiteId,
      orElse: () => {'name': 'Site'},
    )['name'] ?? 'Site';
    final dateStr = _selectedDate != null ? DateFormat('dd/MM/yyyy').format(_selectedDate!) : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!hasReports)
          _buildWarningBanner(),
        if (hasReports) _buildReportsSection(reports),
        const SizedBox(height: 24),
        _buildTasksSection(tasks),
        const SizedBox(height: 24),
        _buildMoveInsSection(moveIns),
        const SizedBox(height: 24),
        _buildMoveOutsSection(moveOuts),
        const SizedBox(height: 24),
        _buildOvlsSection(ovls),
      ],
    );
  }

  Widget _buildWarningBanner() {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Theme.of(context).colorScheme.error, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Aucune journée clôturée',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Les données affichées ci-dessous sont des activités enregistrées '
                    'mais non validées par signature PIN.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsSection(List<Map<String, dynamic>> reports) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 24),
                const SizedBox(width: 8),
                Text('Journée(s) clôturée(s)', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: reports.map((r) {
                final resp = r['responsable'] as Map<String, dynamic>?;
                final name = resp != null
                    ? '${resp['firstname'] ?? ''} ${resp['lastname'] ?? ''}'.trim()
                    : '?';
                final dt = r['date_time'];
                final dtStr = dt != null ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(dt.toString())) : '';
                return Padding(
                  padding: const EdgeInsets.only(right: 8, bottom: 8),
                  child: ActionChip(
                    avatar: const Icon(Icons.assignment, size: 18, color: Colors.white),
                    label: Text('Rapport #${r['id']} - $name ($dtStr)'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (c) => ReportDetailScreen(reportId: r['id'] as int),
                        ),
                      );
                    },
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTasksSection(List<SiteDayTask> tasks) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tâches effectuées (${tasks.length})', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (tasks.isEmpty)
              const Padding(padding: EdgeInsets.all(16), child: Center(child: Text('Aucune tâche pour ce jour')))
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: (MediaQuery.of(context).size.width - 32).clamp(500.0, double.infinity),
                  height: _tableHeight(tasks.length),
                  child: DataTable2(
                    columnSpacing: 12,
                    minWidth: 500,
                    columns: const [
                      DataColumn2(label: Text('Tâche'), size: ColumnSize.L),
                      DataColumn2(label: Text('Statut'), size: ColumnSize.S),
                      DataColumn2(label: Text('Commentaire'), size: ColumnSize.L),
                    ],
                    rows: tasks.map((t) => DataRow(
                      cells: [
                        DataCell(Text(t.taskName ?? 'Tâche ${t.id}')),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: t.isValidated ? Colors.green : Colors.orange,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              t.isValidated ? 'Validé' : 'Non validé',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ),
                        DataCell(Text(t.comment ?? '-')),
                      ],
                    )).toList(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoveInsSection(List<MoveIn> moveIns) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.move_to_inbox, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text('Move-In du jour (${moveIns.length})', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 16),
            if (moveIns.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(16), child: Text('Aucun move-in')))
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: (MediaQuery.of(context).size.width - 32).clamp(600.0, double.infinity),
                  height: _tableHeight(moveIns.length),
                  child: DataTable2(
                    columnSpacing: 12,
                    minWidth: 600,
                    columns: const [
                      DataColumn2(label: Text('Nom'), size: ColumnSize.M),
                      DataColumn2(label: Text('Box'), size: ColumnSize.S),
                      DataColumn2(label: Text('Date création'), size: ColumnSize.M),
                      DataColumn2(label: Text('Créé par'), size: ColumnSize.M),
                      DataColumn2(label: Text('Commentaires'), size: ColumnSize.L),
                    ],
                    rows: moveIns.map((m) => DataRow(
                      onSelectChanged: (_) => Navigator.push(context, MaterialPageRoute(
                        builder: (c) => MoveInDetailScreen(moveIn: m),
                      )),
                      cells: [
                        DataCell(Text(m.name)),
                        DataCell(Text(m.box)),
                        DataCell(Text(m.formattedCreatedAt)),
                        DataCell(Text(m.createdByName)),
                        DataCell(ConstrainedBox(constraints: const BoxConstraints(maxWidth: 200), child: Text(m.comments ?? '-'))),
                      ],
                    )).toList(),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.exit_to_app, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text('Move-Out du jour (${moveOuts.length})', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 16),
            if (moveOuts.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(16), child: Text('Aucun move-out')))
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: (MediaQuery.of(context).size.width - 32).clamp(600.0, double.infinity),
                  height: _tableHeight(moveOuts.length),
                  child: DataTable2(
                    columnSpacing: 12,
                    minWidth: 600,
                    columns: const [
                      DataColumn2(label: Text('Nom'), size: ColumnSize.M),
                      DataColumn2(label: Text('Box'), size: ColumnSize.S),
                      DataColumn2(label: Text('Date création'), size: ColumnSize.M),
                      DataColumn2(label: Text('Créé par'), size: ColumnSize.M),
                      DataColumn2(label: Text('Commentaires'), size: ColumnSize.L),
                    ],
                    rows: moveOuts.map((m) => DataRow(
                      onSelectChanged: (_) => Navigator.push(context, MaterialPageRoute(
                        builder: (c) => MoveOutDetailScreen(moveOut: m),
                      )),
                      cells: [
                        DataCell(Text(m.name)),
                        DataCell(Text(m.box)),
                        DataCell(Text(m.formattedCreatedAt)),
                        DataCell(Text(m.createdByName)),
                        DataCell(ConstrainedBox(constraints: const BoxConstraints(maxWidth: 200), child: Text(m.comments ?? '-'))),
                      ],
                    )).toList(),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lock, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text('OVL posées du jour (${ovls.length})', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 16),
            if (ovls.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(16), child: Text('Aucune OVL')))
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: (MediaQuery.of(context).size.width - 32).clamp(500.0, double.infinity),
                  height: _tableHeight(ovls.length),
                  child: DataTable2(
                    columnSpacing: 12,
                    minWidth: 500,
                    columns: const [
                      DataColumn2(label: Text('Numéro'), size: ColumnSize.M),
                      DataColumn2(label: Text('Code'), size: ColumnSize.S),
                      DataColumn2(label: Text('Date/Heure'), size: ColumnSize.M),
                      DataColumn2(label: Text('Client ID'), size: ColumnSize.M),
                      DataColumn2(label: Text('Opérateur'), size: ColumnSize.M),
                    ],
                    rows: ovls.map((o) => DataRow(
                      cells: [
                        DataCell(Text(o.number ?? '-')),
                        DataCell(Text(o.code?.toString() ?? '-')),
                        DataCell(Text(o.formattedDateTime)),
                        DataCell(Text(o.customerId ?? '-')),
                        DataCell(Text(o.operatorName)),
                      ],
                    )).toList(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
