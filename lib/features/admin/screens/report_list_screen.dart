import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:staff_admin/core/models/report.dart';
import 'package:staff_admin/core/services/report_service.dart';
import 'package:staff_admin/features/admin/screens/report_detail_screen.dart';
import 'package:data_table_2/data_table_2.dart';

class ReportListScreen extends StatefulWidget {
  const ReportListScreen({super.key});

  @override
  State<ReportListScreen> createState() => _ReportListScreenState();
}

class _ReportListScreenState extends State<ReportListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<ReportService>().loadReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rapports de Tâches'),
      ),
      body: Consumer<ReportService>(
        builder: (context, service, child) {
          if (service.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: isMobile
                ? _buildMobileList(service.reports)
                : _buildDesktopTable(service.reports),
          );
        },
      ),
    );
  }

  Widget _buildMobileList(List<Report> reports) {
    return ListView.builder(
      itemCount: reports.length,
      itemBuilder: (context, index) {
        final report = reports[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text(report.siteDisplay),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Date du rapport: ${report.formattedDateTime}'),
                Text('Date de la liste: ${report.formattedToDoListDateTime}'),
                Text('Responsable: ${report.responsableFullName}'),
              ],
            ),
            onTap: () => _navigateToDetail(report),
          ),
        );
      },
    );
  }

  Widget _buildDesktopTable(List<Report> reports) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Date Rapport')),
          DataColumn(label: Text('Date Liste')),
          DataColumn(label: Text('Site')),
          DataColumn(label: Text('Responsable')),
          DataColumn(label: Text('Actions')),
        ],
        rows: reports.map((report) {
          return DataRow(
            cells: [
              DataCell(Text(report.formattedDateTime)),
              DataCell(Text(report.formattedToDoListDateTime)),
              DataCell(Text(report.siteDisplay)),
              DataCell(Text(report.responsableFullName)),
              DataCell(
                IconButton(
                  icon: const Icon(Icons.visibility),
                  onPressed: () => _navigateToDetail(report),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _navigateToDetail(Report report) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportDetailScreen(
          reportId: report.id,
        ),
      ),
    );
  }
} 