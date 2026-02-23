class OvlDelayStat {
  final int siteId;
  final String siteName;
  final String? siteCode;
  final int removedCount;
  final double avgDelayDays;

  OvlDelayStat({
    required this.siteId,
    required this.siteName,
    this.siteCode,
    required this.removedCount,
    required this.avgDelayDays,
  });

  factory OvlDelayStat.fromJson(Map<String, dynamic> json) {
    return OvlDelayStat(
      siteId: int.parse(json['site_id'].toString()),
      siteName: json['site_name']?.toString() ?? '',
      siteCode: json['site_code']?.toString(),
      removedCount: int.tryParse(json['removed_count']?.toString() ?? '0') ?? 0,
      avgDelayDays:
          double.tryParse(json['avg_delay_days']?.toString() ?? '0') ?? 0,
    );
  }

  String get siteDisplay =>
      siteCode != null ? '$siteCode - $siteName' : siteName;
}
