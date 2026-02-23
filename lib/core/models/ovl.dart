import 'package:intl/intl.dart';

class Ovl {
  final int id;
  final String? number;
  final int? code;
  final DateTime? dateTime;
  final String? customerId;
  final Map<String, dynamic>? operator;
  /// Date de retrait (pour OVL retirées du jour)
  final DateTime? removedDate;
  /// Opérateur ayant retiré l'OVL (pour OVL retirées du jour)
  final Map<String, dynamic>? removingOperator;

  Ovl({
    required this.id,
    this.number,
    this.code,
    this.dateTime,
    this.customerId,
    this.operator,
    this.removedDate,
    this.removingOperator,
  });

  factory Ovl.fromJson(Map<String, dynamic> json) {
    return Ovl(
      id: int.parse(json['id'].toString()),
      number: json['number'],
      code: json['code'] != null ? int.parse(json['code'].toString()) : null,
      dateTime: json['date_time'] != null ? DateTime.parse(json['date_time']) : null,
      customerId: json['customer_id'],
      operator: json['operator'] as Map<String, dynamic>?,
      removedDate: json['removed_date'] != null ? DateTime.parse(json['removed_date']) : null,
      removingOperator: json['removing_operator'] as Map<String, dynamic>?,
    );
  }

  String get formattedDateTime {
    if (dateTime == null) return 'Non spécifié';
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime!);
  }

  String get formattedRemovedDate {
    if (removedDate == null) return 'Non spécifié';
    return DateFormat('dd/MM/yyyy HH:mm').format(removedDate!);
  }

  String get operatorName {
    if (operator == null) return 'Non spécifié';
    final firstname = operator!['firstname'] ?? '';
    final lastname = operator!['lastname'] ?? '';
    return '$firstname $lastname'.trim();
  }

  String get removingOperatorName {
    if (removingOperator == null) return 'Non spécifié';
    final firstname = removingOperator!['firstname'] ?? '';
    final lastname = removingOperator!['lastname'] ?? '';
    return '$firstname $lastname'.trim();
  }
}
