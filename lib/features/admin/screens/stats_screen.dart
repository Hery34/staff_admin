import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:staff_admin/core/models/agent_report_stat.dart';
import 'package:staff_admin/core/models/site_closure_stat.dart';
import 'package:staff_admin/core/services/agent_service.dart';
import 'package:staff_admin/core/services/stats_service.dart';
import 'package:data_table_2/data_table_2.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 29));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadStats());
  }

  void _loadStats() {
    context.read<StatsService>().loadReportStats(_startDate, _endDate);
  }

  void _setPreset(int days) {
    setState(() {
      _endDate = DateTime.now();
      _startDate = _endDate.subtract(Duration(days: days - 1));
    });
    _loadStats();
  }

  double _tableHeight(int rowCount, {double minH = 200, double maxH = 600}) {
    return (56 + rowCount * 56.0).clamp(minH, maxH);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques de clôture'),
      ),
      body: Consumer2<StatsService, AgentService>(
        builder: (context, statsService, agentService, _) {
          if (statsService.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          var sites = statsService.closureBySite;
          final allowedIds = agentService.allowedSiteIds;
          if (allowedIds != null) {
            sites = sites.where((s) => allowedIds.contains(s.siteId)).toList();
          }

          final agents = statsService.topAgents;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPeriodSelector(statsService),
                const SizedBox(height: 24),
                _buildClosureBySite(sites, statsService.expectedWorkingDays),
                const SizedBox(height: 24),
                _buildTopAgents(agents),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPeriodSelector(StatsService statsService) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Période', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed: () => _setPreset(7),
                  child: const Text('7 derniers jours'),
                ),
                FilledButton.tonal(
                  onPressed: () => _setPreset(30),
                  child: const Text('30 derniers jours'),
                ),
                FilledButton.tonal(
                  onPressed: () async {
                    final range = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
                    );
                    if (range != null) {
                      setState(() {
                        _startDate = range.start;
                        _endDate = range.end;
                      });
                      _loadStats();
                    }
                  },
                  child: const Text('Personnalisé'),
                ),
                const SizedBox(width: 16),
                Text(
                  '${DateFormat('dd/MM/yyyy').format(_startDate)} – ${DateFormat('dd/MM/yyyy').format(_endDate)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(width: 8),
                Text(
                  '(${statsService.expectedWorkingDays} jours ouvrés attendus)',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClosureBySite(List<SiteClosureStat> sites, int expectedDays) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text('Taux de clôture par site', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Sites ouverts 5 jours/semaine. Triés du plus faible au plus élevé.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            if (sites.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('Aucun site avec agents assignés')),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: (MediaQuery.of(context).size.width - 32).clamp(500.0, double.infinity),
                  height: _tableHeight(sites.length),
                  child: DataTable2(
                    columnSpacing: 12,
                    minWidth: 450,
                    columns: const [
                      DataColumn2(label: Text('Site'), size: ColumnSize.L),
                      DataColumn2(label: Text('Rapports'), size: ColumnSize.S),
                      DataColumn2(label: Text('Attendus'), size: ColumnSize.S),
                      DataColumn2(label: Text('Taux'), size: ColumnSize.M),
                    ],
                    rows: sites.map((s) {
                      final color = s.ratePct >= 80
                          ? Colors.green
                          : s.ratePct >= 50
                              ? Colors.orange
                              : Colors.red;
                      return DataRow(
                        cells: [
                          DataCell(Text(s.siteDisplay, overflow: TextOverflow.ellipsis)),
                          DataCell(Text('${s.reportsCount}')),
                          DataCell(Text('${s.expectedDays}')),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${s.ratePct.toStringAsFixed(1)} %',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
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

  Widget _buildTopAgents(List<AgentReportStat> agents) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text('Top agents clôturants', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Agents ayant clôturé le plus de rapports sur la période.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            if (agents.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('Aucun rapport sur la période')),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: agents.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final a = agents[index];
                  final rank = index + 1;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: rank <= 3
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Text(
                        '$rank',
                        style: TextStyle(
                          color: rank <= 3
                              ? Colors.white
                              : Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(a.fullName),
                    trailing: Text(
                      '${a.reportsCount} rapport${a.reportsCount > 1 ? 's' : ''}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
