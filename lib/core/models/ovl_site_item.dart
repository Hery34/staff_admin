import 'package:intl/intl.dart';

class OvlSiteItem {
  final int id;
  final int? siteId;
  final String? siteName;
  final String? siteCode;
  final String? number;
  final int? code;
  final DateTime? dateTime;
  final String? customerId;
  final bool isRemoved;
  final DateTime? removedDate;
  final Map<String, dynamic>? operatorData;
  final Map<String, dynamic>? removingOperatorData;

  OvlSiteItem({
    required this.id,
    this.siteId,
    this.siteName,
    this.siteCode,
    this.number,
    this.code,
    this.dateTime,
    this.customerId,
    required this.isRemoved,
    this.removedDate,
    this.operatorData,
    this.removingOperatorData,
  });

  factory OvlSiteItem.fromJson(Map<String, dynamic> json) {
    final site = json['site_info'] as Map<String, dynamic>?;
    return OvlSiteItem(
      id: int.parse(json['id'].toString()),
      siteId: json['site'] != null && json['site'] is int
          ? json['site'] as int
          : (site?['id'] != null ? int.tryParse(site!['id'].toString()) : null),
      siteName: site?['name']?.toString(),
      siteCode: site?['site_code']?.toString(),
      number: json['number']?.toString(),
      code: json['code'] != null ? int.tryParse(json['code'].toString()) : null,
      dateTime: json['date_time'] != null
          ? DateTime.tryParse(json['date_time'].toString())
          : null,
      customerId: json['customer_id']?.toString(),
      isRemoved: json['ovl_removed'] == true,
      removedDate: json['removed_date'] != null
          ? DateTime.tryParse(json['removed_date'].toString())
          : null,
      operatorData: json['operator'] as Map<String, dynamic>?,
      removingOperatorData: json['removing_operator'] as Map<String, dynamic>?,
    );
  }

  String get statusLabel => isRemoved ? 'Enlevée' : 'Active';

  String get formattedDateTime {
    if (dateTime == null) return '-';
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime!);
  }

  String get formattedRemovedDate {
    if (removedDate == null) return '-';
    return DateFormat('dd/MM/yyyy HH:mm').format(removedDate!);
  }

  int? get poseDurationDays {
    if (dateTime == null) return null;
    final end = removedDate ?? DateTime.now();
    final diff = end.difference(dateTime!);
    if (diff.isNegative) return 0;
    return diff.inDays;
  }

  String get operatorName {
    if (operatorData == null) return '-';
    final firstname = operatorData!['firstname']?.toString() ?? '';
    final lastname = operatorData!['lastname']?.toString() ?? '';
    final fullName = '$firstname $lastname'.trim();
    return fullName.isEmpty ? '-' : fullName;
  }

  String get removingOperatorName {
    if (removingOperatorData == null) return '-';
    final firstname = removingOperatorData!['firstname']?.toString() ?? '';
    final lastname = removingOperatorData!['lastname']?.toString() ?? '';
    final fullName = '$firstname $lastname'.trim();
    return fullName.isEmpty ? '-' : fullName;
  }
}
