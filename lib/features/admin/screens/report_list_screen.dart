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
  DateTime? _selectedDate;
  String? _selectedSite;
  String? _selectedResponsable;
  final TextEditingController _searchController = TextEditingController();
  
  // Pagination
  int _currentPage = 0;
  static const int _rowsPerPage = 25;

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
    final filtered = reports.where((report) {
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
    
    // Réinitialiser la page si nécessaire après filtrage
    final maxPage = (filtered.length / _rowsPerPage).ceil() - 1;
    if (_currentPage > maxPage && maxPage >= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _currentPage = 0);
        }
      });
    }
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

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
                  padding: EdgeInsets.all(isMobile ? 8.0 : 16.0),
                  child: isMobile
                      ? _buildMobileList(filteredReports)
                      : _buildDesktopTable(filteredReports, isTablet: isTablet),
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

    // Calculer les indices pour la pagination mobile
    final startIndex = _currentPage * _rowsPerPage;
    final endIndex = (startIndex + _rowsPerPage).clamp(0, reports.length);
    final paginatedReports = reports.sublist(
      startIndex,
      endIndex,
    );

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: paginatedReports.length,
            itemBuilder: (context, index) {
              final report = paginatedReports[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(
                    report.siteDisplay,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Date de clôture: ${report.formattedDateTime}'),
                      Text('Date de génération: ${report.formattedToDoListDateTime}'),
                      Text('Responsable: ${report.responsableFullName}'),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _navigateToDetail(report),
                ),
              );
            },
          ),
        ),
        // Pagination controls pour mobile
        if (reports.length > _rowsPerPage)
          _buildMobilePaginationControls(reports.length),
      ],
    );
  }

  Widget _buildMobilePaginationControls(int totalItems) {
    final totalPages = (totalItems / _rowsPerPage).ceil();
    final startIndex = _currentPage * _rowsPerPage;
    final endIndex = (startIndex + _rowsPerPage).clamp(0, totalItems);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${startIndex + 1}-$endIndex sur $totalItems',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.first_page),
                onPressed: _currentPage == 0
                    ? null
                    : () => setState(() => _currentPage = 0),
                tooltip: 'Première page',
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _currentPage == 0
                    ? null
                    : () => setState(() => _currentPage--),
                tooltip: 'Page précédente',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '${_currentPage + 1}/$totalPages',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _currentPage >= totalPages - 1
                    ? null
                    : () => setState(() => _currentPage++),
                tooltip: 'Page suivante',
              ),
              IconButton(
                icon: const Icon(Icons.last_page),
                onPressed: _currentPage >= totalPages - 1
                    ? null
                    : () => setState(() => _currentPage = totalPages - 1),
                tooltip: 'Dernière page',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTable(List<Report> reports, {bool isTablet = false}) {
    if (reports.isEmpty) {
      return const Center(
        child: Text('Aucun rapport ne correspond aux critères sélectionnés'),
      );
    }

    // Calculer les indices pour la pagination
    final startIndex = _currentPage * _rowsPerPage;
    final endIndex = (startIndex + _rowsPerPage).clamp(0, reports.length);
    final paginatedReports = reports.sublist(
      startIndex,
      endIndex,
    );

    return Column(
      children: [
        // Tableau avec scroll vertical et horizontal
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              child: DataTable2(
                columnSpacing: isTablet ? 8 : 12,
                horizontalMargin: isTablet ? 8 : 12,
                minWidth: isTablet ? 700 : 800,
                smRatio: 0.75,
                lmRatio: 1.5,
                headingRowHeight: isTablet ? 48 : 56,
                dataRowHeight: isTablet ? 48 : 56,
                columns: [
                  DataColumn2(
                    label: Text(
                      'Date clôture',
                      style: TextStyle(fontSize: isTablet ? 12 : 14),
                    ),
                    size: ColumnSize.M,
                  ),
                  DataColumn2(
                    label: Text(
                      'Date Génération',
                      style: TextStyle(fontSize: isTablet ? 12 : 14),
                    ),
                    size: ColumnSize.M,
                  ),
                  DataColumn2(
                    label: Text(
                      'Site',
                      style: TextStyle(fontSize: isTablet ? 12 : 14),
                    ),
                    size: ColumnSize.L,
                  ),
                  DataColumn2(
                    label: Text(
                      'Responsable',
                      style: TextStyle(fontSize: isTablet ? 12 : 14),
                    ),
                    size: ColumnSize.M,
                  ),
                  DataColumn2(
                    label: Text(
                      'Voir Rapport',
                      style: TextStyle(fontSize: isTablet ? 12 : 14),
                    ),
                    size: ColumnSize.S,
                  ),
                ],
                rows: paginatedReports.map((report) {
                  return DataRow2(
                    onSelectChanged: (_) => _navigateToDetail(report),
                    cells: [
                      DataCell(
                        Text(
                          report.formattedDateTime,
                          style: TextStyle(fontSize: isTablet ? 12 : 14),
                        ),
                      ),
                      DataCell(
                        Text(
                          report.formattedToDoListDateTime,
                          style: TextStyle(fontSize: isTablet ? 12 : 14),
                        ),
                      ),
                      DataCell(
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: isTablet ? 150 : 200,
                          ),
                          child: Text(
                            report.siteDisplay,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: isTablet ? 12 : 14),
                          ),
                        ),
                      ),
                      DataCell(
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: isTablet ? 120 : 150,
                          ),
                          child: Text(
                            report.responsableFullName,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: isTablet ? 12 : 14),
                          ),
                        ),
                      ),
                      DataCell(
                        IconButton(
                          icon: Icon(
                            Icons.visibility,
                            size: isTablet ? 20 : 24,
                          ),
                          onPressed: () => _navigateToDetail(report),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        // Pagination controls
        if (reports.length > _rowsPerPage)
          _buildPaginationControls(reports.length),
      ],
    );
  }

  Widget _buildPaginationControls(int totalItems) {
    final totalPages = (totalItems / _rowsPerPage).ceil();
    final startIndex = _currentPage * _rowsPerPage;
    final endIndex = (startIndex + _rowsPerPage).clamp(0, totalItems);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Affichage de ${startIndex + 1} à $endIndex sur $totalItems',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.first_page),
                onPressed: _currentPage == 0
                    ? null
                    : () => setState(() => _currentPage = 0),
                tooltip: 'Première page',
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _currentPage == 0
                    ? null
                    : () => setState(() => _currentPage--),
                tooltip: 'Page précédente',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Page ${_currentPage + 1} sur $totalPages',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _currentPage >= totalPages - 1
                    ? null
                    : () => setState(() => _currentPage++),
                tooltip: 'Page suivante',
              ),
              IconButton(
                icon: const Icon(Icons.last_page),
                onPressed: _currentPage >= totalPages - 1
                    ? null
                    : () => setState(() => _currentPage = totalPages - 1),
                tooltip: 'Dernière page',
              ),
            ],
          ),
        ],
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