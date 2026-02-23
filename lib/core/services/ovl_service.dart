import 'package:staff_admin/core/config/supabase_config.dart';
import 'package:staff_admin/core/models/ovl_site_item.dart';

enum OvlStatusFilter {
  all,
  active,
  removed,
}

class OvlPageResult {
  final List<OvlSiteItem> items;
  final bool hasNextPage;
  final int totalCount;

  OvlPageResult({
    required this.items,
    required this.hasNextPage,
    required this.totalCount,
  });
}

class OvlService {
  final _supabase = SupabaseConfig.supabase;

  Future<OvlPageResult> loadOvlsBySite({
    required int siteId,
    required int page,
    required int pageSize,
    String search = '',
    OvlStatusFilter status = OvlStatusFilter.all,
  }) async {
    final statusParam = switch (status) {
      OvlStatusFilter.all => 'all',
      OvlStatusFilter.active => 'active',
      OvlStatusFilter.removed => 'removed',
    };

    final response = await _supabase.rpc(
      'get_ovls_by_site_paginated',
      params: {
        'site_id_param': siteId,
        'status_param': statusParam,
        'search_param': search.trim(),
        'page_param': page,
        'page_size_param': pageSize,
      },
    );

    final data = Map<String, dynamic>.from(response as Map);
    final itemsJson = data['items'] as List<dynamic>? ?? [];
    final items = itemsJson
        .map((e) => OvlSiteItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final hasNextPage = data['has_next_page'] == true;
    final totalCount = int.tryParse(data['total_count']?.toString() ?? '0') ?? 0;

    return OvlPageResult(
      items: items,
      hasNextPage: hasNextPage,
      totalCount: totalCount,
    );
  }
}
