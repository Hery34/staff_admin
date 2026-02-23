import 'dart:async';

import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:staff_admin/core/models/ovl_site_item.dart';
import 'package:staff_admin/core/services/agent_service.dart';
import 'package:staff_admin/core/services/agent_site_service.dart';
import 'package:staff_admin/core/services/ovl_service.dart';

class OvlBySiteScreen extends StatefulWidget {
  const OvlBySiteScreen({super.key});

  @override
  State<OvlBySiteScreen> createState() => _OvlBySiteScreenState();
}

class _OvlBySiteScreenState extends State<OvlBySiteScreen> {
  final OvlService _ovlService = OvlService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _sites = [];
  List<OvlSiteItem> _ovls = [];

  int? _selectedSiteId;
  OvlStatusFilter _selectedStatus = OvlStatusFilter.all;
  int _currentPage = 0;
  bool _hasNextPage = false;
  int _totalCount = 0;
  bool _isLoading = false;
  String? _error;
  Timer? _searchDebounce;

  static const int _rowsPerPage = 25;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadSites());
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
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
        final parsedId = id is int ? id : int.tryParse(id.toString());
        return parsedId != null && allowedIds.contains(parsedId);
      }).toList();
    }

    setState(() {
      _sites = sites;
      if (_sites.isNotEmpty) {
        _selectedSiteId = _sites.first['id'] as int;
      }
    });

    if (_selectedSiteId != null) {
      await _loadPage();
    }
  }

  Future<void> _loadPage() async {
    if (_selectedSiteId == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _ovlService.loadOvlsBySite(
        siteId: _selectedSiteId!,
        page: _currentPage,
        pageSize: _rowsPerPage,
        search: _searchController.text,
        status: _selectedStatus,
      );

      if (!mounted) return;

      setState(() {
        _ovls = result.items;
        _hasNextPage = result.hasNextPage;
        _totalCount = result.totalCount;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Erreur de chargement des OVL: $e';
        _ovls = [];
        _hasNextPage = false;
        _totalCount = 0;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onSearchChanged(String _) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() => _currentPage = 0);
      _loadPage();
    });
  }

  Future<void> _goToPreviousPage() async {
    if (_currentPage == 0 || _isLoading) return;
    setState(() => _currentPage--);
    await _loadPage();
  }

  Future<void> _goToNextPage() async {
    if (!_hasNextPage || _isLoading) return;
    setState(() => _currentPage++);
    await _loadPage();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      appBar: AppBar(
        title: const Text('OVL par site'),
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  _buildTotalCountCard(),
                  const SizedBox(height: 12),
                  Expanded(child: _buildContent(isMobile)),
                ],
              ),
            ),
          ),
          _buildPaginationFooter(),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final siteItems = _sites
        .map((s) => DropdownMenuItem<int>(
              value: s['id'] as int,
              child: Text(s['name']?.toString() ?? 'Site ${s['id']}'),
            ))
        .toList();

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 260,
              child: DropdownButtonFormField<int>(
                initialValue: _selectedSiteId,
                decoration: const InputDecoration(
                  labelText: 'Site',
                  border: OutlineInputBorder(),
                ),
                items: siteItems,
                onChanged: _sites.isEmpty
                    ? null
                    : (value) {
                        if (value == null) return;
                        setState(() {
                          _selectedSiteId = value;
                          _currentPage = 0;
                        });
                        _loadPage();
                      },
              ),
            ),
            SizedBox(
              width: 220,
              child: DropdownButtonFormField<OvlStatusFilter>(
                initialValue: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Statut',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: OvlStatusFilter.all,
                    child: Text('Tous'),
                  ),
                  DropdownMenuItem(
                    value: OvlStatusFilter.active,
                    child: Text('Actives'),
                  ),
                  DropdownMenuItem(
                    value: OvlStatusFilter.removed,
                    child: Text('Enlevées'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedStatus = value;
                    _currentPage = 0;
                  });
                  _loadPage();
                },
              ),
            ),
            SizedBox(
              width: 320,
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  labelText: 'Recherche (numéro, box)',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _currentPage = 0;
                            });
                            _loadPage();
                          },
                        ),
                ),
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Actualiser'),
              onPressed: _isLoading ? null : _loadPage,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(bool isMobile) {
    if (_sites.isEmpty) {
      return const Center(
        child: Text('Aucun site disponible pour votre compte.'),
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadPage,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_ovls.isEmpty) {
      return const Center(
        child: Text('Aucune OVL trouvée avec ces critères.'),
      );
    }

    return isMobile ? _buildMobileList() : _buildDesktopTable();
  }

  Widget _buildTotalCountCard() {
    final label = switch (_selectedStatus) {
      OvlStatusFilter.all => 'Total OVL (tous statuts)',
      OvlStatusFilter.active => 'Total OVL actives',
      OvlStatusFilter.removed => 'Total OVL enlevées',
    };

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          '$label: $_totalCount',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }

  Widget _buildMobileList() {
    return ListView.builder(
      itemCount: _ovls.length,
      itemBuilder: (context, index) {
        final ovl = _ovls[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      ovl.number ?? 'OVL #${ovl.id}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    _buildStatusChip(ovl),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Code: ${ovl.code?.toString() ?? '-'}'),
                Text('Date pose: ${ovl.formattedDateTime}'),
                Text('Jours de pose: ${ovl.poseDurationDays?.toString() ?? '-'}'),
                Text('Posée par: ${ovl.operatorName}'),
                Text('Date retrait: ${ovl.formattedRemovedDate}'),
                Text('Retirée par: ${ovl.removingOperatorName}'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: DataTable2(
          minWidth: 1050,
          columnSpacing: 12,
          columns: const [
            DataColumn2(label: Text('Statut'), size: ColumnSize.S),
            DataColumn2(label: Text('Box'), size: ColumnSize.M),
            DataColumn2(label: Text('Code'), size: ColumnSize.S),
            DataColumn2(label: Text('Date pose'), size: ColumnSize.M),
            DataColumn2(label: Text('Jours de pose'), size: ColumnSize.S),
            DataColumn2(label: Text('Posée par'), size: ColumnSize.M),
            DataColumn2(label: Text('Date retrait'), size: ColumnSize.M),
            DataColumn2(label: Text('Retirée par'), size: ColumnSize.M),
          ],
          rows: _ovls
              .map(
                (ovl) => DataRow(
                  cells: [
                    DataCell(_buildStatusChip(ovl)),
                    DataCell(Text(ovl.number ?? '-')),
                    DataCell(Text(ovl.code?.toString() ?? '-')),
                    DataCell(Text(ovl.formattedDateTime)),
                    DataCell(Text(ovl.poseDurationDays?.toString() ?? '-')),
                    DataCell(Text(ovl.operatorName)),
                    DataCell(Text(ovl.formattedRemovedDate)),
                    DataCell(Text(ovl.removingOperatorName)),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildStatusChip(OvlSiteItem ovl) {
    final isRemoved = ovl.isRemoved;
    final color = isRemoved ? Colors.orange : Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        ovl.statusLabel,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildPaginationFooter() {
    final start = _ovls.isEmpty ? 0 : (_currentPage * _rowsPerPage) + 1;
    final end = _currentPage * _rowsPerPage + _ovls.length;

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
            _ovls.isEmpty
                ? 'Aucun résultat sur $_totalCount'
                : '$start à $end sur $_totalCount',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Page précédente',
                onPressed:
                    _currentPage == 0 || _isLoading ? null : _goToPreviousPage,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('Page ${_currentPage + 1}'),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Page suivante',
                onPressed: !_hasNextPage || _isLoading ? null : _goToNextPage,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
