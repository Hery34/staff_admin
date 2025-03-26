import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:staff_admin/core/models/fire_alert_report.dart';
import 'package:staff_admin/core/services/fire_alert_service.dart';
import 'package:staff_admin/features/admin/screens/fire_alert_detail_screen.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';

class FireAlertListScreen extends StatefulWidget {
  const FireAlertListScreen({super.key});

  @override
  State<FireAlertListScreen> createState() => _FireAlertListScreenState();
}

class _FireAlertListScreenState extends State<FireAlertListScreen> {
  String? selectedSite;
  DateTime? selectedDate;
  final dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if(mounted) {
        context.read<FireAlertService>().loadReports();
      }
    });
  }

  List<FireAlertReport> _filterReports(List<FireAlertReport> reports) {
    return reports.where((report) {
      bool matchesSite = selectedSite == null || report.siteName == selectedSite;
      bool matchesDate = selectedDate == null || 
        (report.date.year == selectedDate!.year && 
         report.date.month == selectedDate!.month && 
         report.date.day == selectedDate!.day);
      return matchesSite && matchesDate;
    }).toList();
  }

  List<String> _getUniqueSites(List<FireAlertReport> reports) {
    return reports
        .where((report) => report.siteName != null)
        .map((report) => report.siteName!)
        .toSet()
        .toList()
      ..sort();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Widget _buildFilters(List<FireAlertReport> allReports) {
    final sites = _getUniqueSites(allReports);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Wrap(
        spacing: 16.0,
        runSpacing: 8.0,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          DropdownButton<String>(
            value: selectedSite,
            hint: const Text('Filtrer par site'),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('Tous les sites'),
              ),
              ...sites.map((site) => DropdownMenuItem<String>(
                value: site,
                child: Text(site),
              )),
            ],
            onChanged: (value) {
              setState(() {
                selectedSite = value;
              });
            },
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.calendar_today),
            label: Text(selectedDate != null 
              ? 'Date: ${dateFormat.format(selectedDate!)}'
              : 'Filtrer par date'
            ),
            onPressed: () => _selectDate(context),
          ),
          if (selectedDate != null || selectedSite != null)
            TextButton.icon(
              icon: const Icon(Icons.clear),
              label: const Text('Effacer les filtres'),
              onPressed: () {
                setState(() {
                  selectedDate = null;
                  selectedSite = null;
                });
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rapports d\'Alerte Incendie'),
      ),
      body: Consumer<FireAlertService>(
        builder: (context, service, child) {
          if (service.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final filteredReports = _filterReports(service.reports);

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildFilters(service.reports),
                Expanded(
                  child: isMobile
                      ? _buildMobileList(filteredReports)
                      : _buildDesktopTable(filteredReports),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMobileList(List<FireAlertReport> reports) {
    return ListView.builder(
      itemCount: reports.length,
      itemBuilder: (context, index) {
        final report = reports[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8.0),
          child: ListTile(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '#${report.id}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: report.isRunning ? Colors.red : Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        report.isRunning ? 'En Cours' : 'Terminé',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                if (report.siteName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    FireAlertReport.capitalize(report.siteName!),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Date: ${report.formattedDate}'),
                Text('Type: ${report.alertTypeDisplay}'),
                if (report.declencheur != null)
                  Text('Déclencheur: ${report.declencheurDisplay}'),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.visibility),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FireAlertDetailScreen(
                      reportId: report.id,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopTable(List<FireAlertReport> reports) {
    return DataTable2(
      columns: const [
        DataColumn2(
          label: Text('N° Rapport'),
          size: ColumnSize.S,
        ),
        DataColumn2(
          label: Text('Site'),
          size: ColumnSize.L,
        ),
        DataColumn2(
          label: Text('Date'),
          size: ColumnSize.L,
        ),
        DataColumn2(
          label: Text('Type'),
          size: ColumnSize.M,
        ),
        DataColumn2(
          label: Text('État'),
          size: ColumnSize.M,
        ),
        DataColumn2(
          label: Text('Déclencheur'),
          size: ColumnSize.M,
        ),
        DataColumn2(
          label: Text('Voir rapport'),
          size: ColumnSize.S,
        ),
      ],
      rows: reports.map((report) {
        return DataRow(
          cells: [
            DataCell(Text('#${report.id}')),
            DataCell(Text(report.siteName != null 
              ? FireAlertReport.capitalize(report.siteName!)
              : '-')),
            DataCell(Text(report.formattedDate)),
            DataCell(Text(report.alertTypeDisplay)),
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: report.isRunning ? Colors.red : Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  report.isRunning ? 'En Cours' : 'Terminé',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            DataCell(Text(report.declencheurDisplay)),
            DataCell(
              IconButton(
                icon: const Icon(Icons.visibility),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FireAlertDetailScreen(
                        reportId: report.id,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
} 