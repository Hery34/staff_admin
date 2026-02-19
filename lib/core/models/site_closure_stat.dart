/// Statistique de clôture pour un site sur une période.
class SiteClosureStat {
  final int siteId;
  final String siteName;
  final String? siteCode;
  final int reportsCount;
  final int expectedDays;
  final double ratePct;

  SiteClosureStat({
    required this.siteId,
    required this.siteName,
    this.siteCode,
    required this.reportsCount,
    required this.expectedDays,
    required this.ratePct,
  });

  factory SiteClosureStat.fromJson(Map<String, dynamic> json) {
    return SiteClosureStat(
      siteId: int.parse(json['site_id'].toString()),
      siteName: json['site_name']?.toString() ?? '',
      siteCode: json['site_code']?.toString(),
      reportsCount: int.tryParse(json['reports_count']?.toString() ?? '0') ?? 0,
      expectedDays: int.tryParse(json['expected_days']?.toString() ?? '0') ?? 0,
      ratePct: (json['rate_pct'] != null)
          ? double.tryParse(json['rate_pct'].toString()) ?? 0.0
          : 0.0,
    );
  }

  String get siteDisplay => siteCode != null ? '$siteCode - $siteName' : siteName;
}
