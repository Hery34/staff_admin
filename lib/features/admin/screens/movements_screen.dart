import 'dart:async';

import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:staff_admin/core/models/movement_item.dart';
import 'package:staff_admin/core/services/agent_service.dart';
import 'package:staff_admin/core/services/agent_site_service.dart';
import 'package:staff_admin/core/services/movement_service.dart';
import 'package:staff_admin/features/admin/screens/move_in_detail_screen.dart';
import 'package:staff_admin/features/admin/screens/move_out_detail_screen.dart';

class MovementsScreen extends StatefulWidget {
  const MovementsScreen({super.key});

  @override
  State<MovementsScreen> createState() => _MovementsScreenState();
}

class _MovementsScreenState extends State<MovementsScreen> {
  final MovementService _movementService = MovementService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _sites = [];
  List<MovementItem> _items = [];

  int? _selectedSiteId;
  MovementTypeFilter _selectedType = MovementTypeFilter.all;
  int _currentPage = 0;
  bool _hasNextPage = false;
  int _totalCount = 0;
  bool _isLoading = false;
  String? _error;
  Timer? _debounce;

  static const int _rowsPerPage = 25;

  @override
  void initState() {
    super.initState();
    final agentService = context.read<AgentService>();
    Future.microtask(() async {
      await agentService.loadCurrentAgentAndSites();
      if (!mounted) return;
      await _loadSites();
      await _loadPage();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSites() async {
    if (!mounted) return;

    final allowedIds = context.read<AgentService>().allowedSiteIds;
    var sites = await context.read<AgentSiteService>().loadSites();

    if (allowedIds != null) {
      sites = sites.where((s) {
        final id = s['id'];
        final parsed = id is int ? id : int.tryParse(id.toString());
        return parsed != null && allowedIds.contains(parsed);
      }).toList();
    }

    if (!mounted) return;
    setState(() {
      _sites = sites;
      if (allowedIds != null && allowedIds.length == 1 && sites.isNotEmpty) {
        _selectedSiteId = sites.first['id'] as int;
      }
    });
  }

  Future<void> _loadPage() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _movementService.loadMovements(
        page: _currentPage,
        pageSize: _rowsPerPage,
        type: _selectedType,
        search: _searchController.text,
        siteId: _selectedSiteId,
        allowedSiteIds: context.read<AgentService>().allowedSiteIds,
      );

      if (!mounted) return;

      setState(() {
        _items = result.items;
        _totalCount = result.totalCount;
        _hasNextPage = result.hasNextPage;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _items = [];
        _totalCount = 0;
        _hasNextPage = false;
        _error = 'Erreur de chargement des mouvements: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() => _currentPage = 0);
      _loadPage();
    });
  }

  Future<void> _goPreviousPage() async {
    if (_currentPage == 0 || _isLoading) return;
    setState(() => _currentPage--);
    await _loadPage();
  }

  Future<void> _goNextPage() async {
    if (!_hasNextPage || _isLoading) return;
    setState(() => _currentPage++);
    await _loadPage();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mouvements'),
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _buildContent(isMobile),
            ),
          ),
          _buildPaginationFooter(),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final siteItems = <DropdownMenuItem<int?>>[
      const DropdownMenuItem<int?>(
        value: null,
        child: Text('Tous les sites'),
      ),
      ..._sites.map((s) => DropdownMenuItem<int?>(
            value: s['id'] as int,
            child: Text(s['name']?.toString() ?? 'Site ${s['id']}'),
          )),
    ];

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
              width: 250,
              child: DropdownButtonFormField<int?>(
                initialValue: _selectedSiteId,
                decoration: const InputDecoration(
                  labelText: 'Site',
                  border: OutlineInputBorder(),
                ),
                items: siteItems,
                onChanged: (value) {
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
              child: DropdownButtonFormField<MovementTypeFilter>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: MovementTypeFilter.all,
                    child: Text('Tous'),
                  ),
                  DropdownMenuItem(
                    value: MovementTypeFilter.moveIn,
                    child: Text('Move-In'),
                  ),
                  DropdownMenuItem(
                    value: MovementTypeFilter.moveOut,
                    child: Text('Move-Out'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedType = value;
                    _currentPage = 0;
                  });
                  _loadPage();
                },
              ),
            ),
            SizedBox(
              width: 340,
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  labelText: 'Recherche (nom ou numéro de box)',
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

    if (_items.isEmpty) {
      return const Center(
        child: Text('Aucun mouvement trouvé avec ces critères.'),
      );
    }

    return isMobile ? _buildMobileList() : _buildDesktopTable();
  }

  Widget _buildMobileList() {
    return ListView.builder(
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        final isIn = item.isMoveIn;
        final color = isIn ? Colors.green : Colors.deepOrange;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: color.withValues(alpha: 0.5), width: 1.2),
          ),
          child: ListTile(
            title: Text('${item.typeLabel} - ${item.name}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Box: ${item.box}'),
                Text('Date: ${item.formattedCreatedAt}'),
                Text('Site: ${item.siteDisplay}'),
                Text('Créé par: ${item.createdByName}'),
              ],
            ),
            trailing: Icon(Icons.chevron_right, color: color),
            onTap: () => _openMovementDetail(item),
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
          minWidth: 980,
          columnSpacing: 12,
          columns: const [
            DataColumn2(label: Text('Type'), size: ColumnSize.S),
            DataColumn2(label: Text('Date'), size: ColumnSize.M),
            DataColumn2(label: Text('Site'), size: ColumnSize.M),
            DataColumn2(label: Text('Nom'), size: ColumnSize.M),
            DataColumn2(label: Text('Box'), size: ColumnSize.S),
            DataColumn2(label: Text('Créé par'), size: ColumnSize.M),
            DataColumn2(label: Text('Ouvrir'), size: ColumnSize.S),
          ],
          rows: _items
              .map(
                (item) => DataRow2(
                  onSelectChanged: (_) => _openMovementDetail(item),
                  cells: [
                    DataCell(_buildTypeChip(item)),
                    DataCell(Text(item.formattedCreatedAt)),
                    DataCell(Text(item.siteDisplay,
                        overflow: TextOverflow.ellipsis)),
                    DataCell(Text(item.name, overflow: TextOverflow.ellipsis)),
                    DataCell(Text(item.box)),
                    DataCell(Text(item.createdByName,
                        overflow: TextOverflow.ellipsis)),
                    DataCell(
                      IconButton(
                        icon: const Icon(Icons.visibility),
                        onPressed: () => _openMovementDetail(item),
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildTypeChip(MovementItem item) {
    final isIn = item.isMoveIn;
    final color = isIn ? Colors.green : Colors.deepOrange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        item.typeLabel,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildPaginationFooter() {
    final start = _items.isEmpty ? 0 : (_currentPage * _rowsPerPage) + 1;
    final end = _currentPage * _rowsPerPage + _items.length;

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
            _items.isEmpty
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
                    _currentPage == 0 || _isLoading ? null : _goPreviousPage,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('Page ${_currentPage + 1}'),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Page suivante',
                onPressed: !_hasNextPage || _isLoading ? null : _goNextPage,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openMovementDetail(MovementItem item) {
    if (item.isMoveIn) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MoveInDetailScreen(moveIn: item.toMoveIn()),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MoveOutDetailScreen(moveOut: item.toMoveOut()),
        ),
      );
    }
  }
}
