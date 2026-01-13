import 'package:intl/intl.dart';

class Ovl {
  final int id;
  final String? number;
  final int? code;
  final DateTime? dateTime;
  final String? customerId;
  final Map<String, dynamic>? operator;

  Ovl({
    required this.id,
    this.number,
    this.code,
    this.dateTime,
    this.customerId,
    this.operator,
  });

  factory Ovl.fromJson(Map<String, dynamic> json) {
    return Ovl(
      id: int.parse(json['id'].toString()),
      number: json['number'],
      code: json['code'] != null ? int.parse(json['code'].toString()) : null,
      dateTime: json['date_time'] != null ? DateTime.parse(json['date_time']) : null,
      customerId: json['customer_id'],
      operator: json['operator'] as Map<String, dynamic>?,
    );
  }

  String get formattedDateTime {
    if (dateTime == null) return 'Non spécifié';
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime!);
  }
  
  String get operatorName {
    if (operator == null) return 'Non spécifié';
    final firstname = operator!['firstname'] ?? '';
    final lastname = operator!['lastname'] ?? '';
    return '$firstname $lastname'.trim();
  }
}
