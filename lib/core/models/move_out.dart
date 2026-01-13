import 'package:intl/intl.dart';

class MoveOut {
  final int id;
  final DateTime createdAt;
  final String name;
  final String box;
  final String? startDate;
  final String? taille;
  final String? sizeCode;
  final String? idClient;
  final bool isEmpty;
  final bool hasLoxx;
  final bool isClean;
  final String? comments;
  final String? leaveDate;
  final Map<String, dynamic>? createdBy;

  MoveOut({
    required this.id,
    required this.createdAt,
    required this.name,
    required this.box,
    this.startDate,
    this.taille,
    this.sizeCode,
    this.idClient,
    required this.isEmpty,
    required this.hasLoxx,
    required this.isClean,
    this.comments,
    this.leaveDate,
    this.createdBy,
  });

  factory MoveOut.fromJson(Map<String, dynamic> json) {
    return MoveOut(
      id: int.parse(json['id'].toString()),
      createdAt: DateTime.parse(json['created_at']),
      name: json['name'] ?? '',
      box: json['box'] ?? '',
      startDate: json['start_date'],
      taille: json['taille'],
      sizeCode: json['size_code'],
      idClient: json['id_client'],
      isEmpty: json['is_empty'] ?? false,
      hasLoxx: json['has_loxx'] ?? false,
      isClean: json['is_clean'] ?? false,
      comments: json['comments'],
      leaveDate: json['leave_date'],
      createdBy: json['created_by'] as Map<String, dynamic>?,
    );
  }

  String get formattedCreatedAt => DateFormat('dd/MM/yyyy HH:mm').format(createdAt);
  
  String get createdByName {
    if (createdBy == null) return 'Non spécifié';
    final firstname = createdBy!['firstname'] ?? '';
    final lastname = createdBy!['lastname'] ?? '';
    return '$firstname $lastname'.trim();
  }
}
