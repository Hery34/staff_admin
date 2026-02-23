import 'package:staff_admin/core/config/supabase_config.dart';
import 'package:staff_admin/core/models/movement_item.dart';

class MovementPageResult {
  final List<MovementItem> items;
  final int totalCount;
  final bool hasNextPage;

  MovementPageResult({
    required this.items,
    required this.totalCount,
    required this.hasNextPage,
  });
}

class MovementService {
  final _supabase = SupabaseConfig.supabase;

  Future<MovementPageResult> loadMovements({
    required int page,
    required int pageSize,
    required MovementTypeFilter type,
    required String search,
    int? siteId,
    Set<int>? allowedSiteIds,
  }) async {
    try {
      return await _loadFromRpc(
        page: page,
        pageSize: pageSize,
        type: type,
        search: search,
        siteId: siteId,
        allowedSiteIds: allowedSiteIds,
      );
    } catch (_) {
      return _loadFallback(
        page: page,
        pageSize: pageSize,
        type: type,
        search: search,
        siteId: siteId,
        allowedSiteIds: allowedSiteIds,
      );
    }
  }

  Future<MovementPageResult> _loadFromRpc({
    required int page,
    required int pageSize,
    required MovementTypeFilter type,
    required String search,
    int? siteId,
    Set<int>? allowedSiteIds,
  }) async {
    final typeParam = switch (type) {
      MovementTypeFilter.all => 'all',
      MovementTypeFilter.moveIn => 'move_in',
      MovementTypeFilter.moveOut => 'move_out',
    };

    final response = await _supabase.rpc(
      'get_movements_paginated',
      params: {
        'site_id_param': siteId,
        'allowed_site_ids_param': allowedSiteIds?.toList(),
        'movement_type_param': typeParam,
        'search_param': search.trim(),
        'page_param': page,
        'page_size_param': pageSize,
      },
    );

    final data = Map<String, dynamic>.from(response as Map);
    final itemsJson = data['items'] as List<dynamic>? ?? [];
    final items = itemsJson
        .map((e) => MovementItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    return MovementPageResult(
      items: items,
      totalCount: int.tryParse(data['total_count']?.toString() ?? '0') ?? 0,
      hasNextPage: data['has_next_page'] == true,
    );
  }

  Future<MovementPageResult> _loadFallback({
    required int page,
    required int pageSize,
    required MovementTypeFilter type,
    required String search,
    int? siteId,
    Set<int>? allowedSiteIds,
  }) async {
    if (allowedSiteIds != null && allowedSiteIds.isEmpty) {
      return MovementPageResult(
          items: const [], totalCount: 0, hasNextPage: false);
    }

    final searchValue = search.trim();
    final escapedSearch = searchValue.replaceAll(',', r'\,');

    Future<List<Map<String, dynamic>>> loadMoveIns() async {
      var query = _supabase.from('move_in').select('''
        id,
        created_at,
        site,
        name,
        box,
        start_date,
        taille,
        size_code,
        id_client,
        is_empty,
        has_loxx_on_door,
        is_clean,
        comments,
        poster_ok,
        created_by:created_by (
          id,
          firstname,
          lastname
        ),
        site_info:site (
          id,
          name,
          site_code
        )
      ''');

      if (siteId != null) {
        query = query.eq('site', siteId);
      } else if (allowedSiteIds != null) {
        query = query.inFilter('site', allowedSiteIds.toList());
      }

      if (searchValue.isNotEmpty) {
        query = query.or(
          'name.ilike.%$escapedSearch%,box.ilike.%$escapedSearch%',
        );
      }

      final rows = await query.order('created_at', ascending: false);
      return (rows as List<dynamic>)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }

    Future<List<Map<String, dynamic>>> loadMoveOuts() async {
      var query = _supabase.from('move_out').select('''
        id,
        created_at,
        site,
        name,
        box,
        start_date,
        taille,
        size_code,
        id_client,
        is_empty,
        has_loxx,
        is_clean,
        comments,
        leave_date,
        created_by:created_by (
          id,
          firstname,
          lastname
        ),
        site_info:site (
          id,
          name,
          site_code
        )
      ''');

      if (siteId != null) {
        query = query.eq('site', siteId);
      } else if (allowedSiteIds != null) {
        query = query.inFilter('site', allowedSiteIds.toList());
      }

      if (searchValue.isNotEmpty) {
        query = query.or(
          'name.ilike.%$escapedSearch%,box.ilike.%$escapedSearch%',
        );
      }

      final rows = await query.order('created_at', ascending: false);
      return (rows as List<dynamic>)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }

    List<Map<String, dynamic>> moveIns = [];
    List<Map<String, dynamic>> moveOuts = [];

    if (type != MovementTypeFilter.moveOut) {
      moveIns = await loadMoveIns();
    }

    if (type != MovementTypeFilter.moveIn) {
      moveOuts = await loadMoveOuts();
    }

    final allItems = <MovementItem>[
      ...moveIns.map(
          (j) => MovementItem.fromJson({...j, 'movement_type': 'move_in'})),
      ...moveOuts.map(
          (j) => MovementItem.fromJson({...j, 'movement_type': 'move_out'})),
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final total = allItems.length;
    final start = page * pageSize;
    final end = (start + pageSize).clamp(0, total);

    if (start >= total) {
      return MovementPageResult(
          items: const [], totalCount: total, hasNextPage: false);
    }

    return MovementPageResult(
      items: allItems.sublist(start, end),
      totalCount: total,
      hasNextPage: end < total,
    );
  }
}
