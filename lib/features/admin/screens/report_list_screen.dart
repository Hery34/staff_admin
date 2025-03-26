import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:staff_admin/core/models/report.dart';
import 'package:staff_admin/core/services/report_service.dart';
import 'package:staff_admin/features/admin/screens/report_detail_screen.dart';

class ReportListScreen extends StatefulWidget {
  const ReportListScreen({super.key});

  @override
  State<ReportListScreen> createState() => _ReportListScreenState();
}

class _ReportListScreenState extends State<ReportListScreen> {
  DateTime? _selectedDate;
  String? _selectedSite;
  String? _selectedResponsable;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if(mounted) {
        context.read<ReportService>().loadReports();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Report> _filterReports(List<Report> reports) {
    return reports.where((report) {
      final matchesDate = _selectedDate == null || 
        (report.dateTime.year == _selectedDate!.year &&
         report.dateTime.month == _selectedDate!.month &&
         report.dateTime.day == _selectedDate!.day);

      final matchesSite = _selectedSite == null || 
        report.siteDisplay.toLowerCase() == _selectedSite!.toLowerCase();

      final matchesResponsable = _selectedResponsable == null || 
        report.responsableFullName.toLowerCase() == _selectedResponsable!.toLowerCase();

      return matchesDate && matchesSite && matchesResponsable;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rapports Quotidiens'),
      ),
      body: Consumer<ReportService>(
        builder: (context, service, child) {
          if (service.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final reports = service.reports;
          final filteredReports = _filterReports(reports);

          // Extraire les listes uniques pour les filtres
          final sites = reports.map((r) => r.siteDisplay).toSet().toList()..sort();
          final responsables = reports.map((r) => r.responsableFullName).toSet().toList()..sort();

          return Column(
            children: [
              _buildFilters(sites, responsables),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: isMobile
                      ? _buildMobileList(filteredReports)
                      : _buildDesktopTable(filteredReports),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilters(List<String> sites, List<String> responsables) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final screenWidth = MediaQuery.of(context).size.width;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.filter_list,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Filtres',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (isMobile)
              _buildMobileFilters(sites, responsables)
            else
              _buildDesktopFilters(sites, responsables, screenWidth),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileFilters(List<String> sites, List<String> responsables) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildDatePicker(),
        const SizedBox(height: 16),
        _buildSiteDropdown(sites),
        const SizedBox(height: 16),
        _buildResponsableDropdown(responsables),
        const SizedBox(height: 16),
        if (_hasActiveFilters())
          _buildResetButton(),
      ],
    );
  }

  Widget _buildDesktopFilters(List<String> sites, List<String> responsables, double screenWidth) {
    // Calculer la largeur optimale pour les filtres
    final availableWidth = screenWidth - 64; // Soustraire les marges
    final itemWidth = (availableWidth / 4).clamp(200.0, 300.0);

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.start,
      children: [
        SizedBox(
          width: itemWidth,
          child: _buildDatePicker(),
        ),
        SizedBox(
          width: itemWidth,
          child: _buildSiteDropdown(sites),
        ),
        SizedBox(
          width: itemWidth,
          child: _buildResponsableDropdown(responsables),
        ),
        if (_hasActiveFilters())
          SizedBox(
            width: itemWidth,
            child: _buildResetButton(),
          ),
      ],
    );
  }

  bool _hasActiveFilters() {
    return _selectedDate != null || _selectedSite != null || _selectedResponsable != null;
  }

  Widget _buildDatePicker() {
    return SizedBox(
      height: 56, // Même hauteur que les DropdownButtonFormField
      child: OutlinedButton.icon(
        icon: const Icon(Icons.calendar_today),
        label: Text(
          _selectedDate == null 
            ? 'Date de clôture'
            : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
          overflow: TextOverflow.ellipsis,
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          alignment: Alignment.centerLeft,
          side: BorderSide(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        onPressed: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: _selectedDate ?? DateTime.now(),
            firstDate: DateTime(2020),
            lastDate: DateTime.now(),
          );
          if (date != null) {
            setState(() => _selectedDate = date);
          }
        },
      ),
    );
  }

  Widget _buildSiteDropdown(List<String> sites) {
    return DropdownButtonFormField<String>(
      value: _selectedSite,
      decoration: InputDecoration(
        labelText: 'Site',
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ),
      isExpanded: true,
      items: [
        const DropdownMenuItem(
          value: null,
          child: Text('Tous les sites', overflow: TextOverflow.ellipsis),
        ),
        ...sites.map((site) => DropdownMenuItem(
          value: site,
          child: Text(site, overflow: TextOverflow.ellipsis),
        )),
      ],
      onChanged: (value) => setState(() => _selectedSite = value),
    );
  }

  Widget _buildResponsableDropdown(List<String> responsables) {
    return DropdownButtonFormField<String>(
      value: _selectedResponsable,
      decoration: InputDecoration(
        labelText: 'Responsable',
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ),
      isExpanded: true,
      items: [
        const DropdownMenuItem(
          value: null,
          child: Text('Tous les responsables', overflow: TextOverflow.ellipsis),
        ),
        ...responsables.map((resp) => DropdownMenuItem(
          value: resp,
          child: Text(resp, overflow: TextOverflow.ellipsis),
        )),
      ],
      onChanged: (value) => setState(() => _selectedResponsable = value),
    );
  }

  Widget _buildResetButton() {
    return ElevatedButton.icon(
      icon: const Icon(Icons.clear),
      label: const Text('Réinitialiser'),
      onPressed: () => setState(() {
        _selectedDate = null;
        _selectedSite = null;
        _selectedResponsable = null;
      }),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
      ),
    );
  }

  Widget _buildMobileList(List<Report> reports) {
    if (reports.isEmpty) {
      return const Center(
        child: Text('Aucun rapport ne correspond aux critères sélectionnés'),
      );
    }

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
                Text('Date de clôture: ${report.formattedDateTime}'),
                Text('Date de génération: ${report.formattedToDoListDateTime}'),
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
    if (reports.isEmpty) {
      return const Center(
        child: Text('Aucun rapport ne correspond aux critères sélectionnés'),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Date clôture')),
          DataColumn(label: Text('Date Génération')),
          DataColumn(label: Text('Site')),
          DataColumn(label: Text('Responsable')),
          DataColumn(label: Text('Voir Rapport')),
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