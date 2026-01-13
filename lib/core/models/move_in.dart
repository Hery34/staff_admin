import 'package:intl/intl.dart';

class MoveIn {
  final int id;
  final DateTime createdAt;
  final String name;
  final String box;
  final String? startDate;
  final String? taille;
  final String? sizeCode;
  final String? idClient;
  final bool isEmpty;
  final bool hasLoxxOnDoor;
  final bool isClean;
  final String? comments;
  final bool posterOk;
  final Map<String, dynamic>? createdBy;

  MoveIn({
    required this.id,
    required this.createdAt,
    required this.name,
    required this.box,
    this.startDate,
    this.taille,
    this.sizeCode,
    this.idClient,
    required this.isEmpty,
    required this.hasLoxxOnDoor,
    required this.isClean,
    this.comments,
    required this.posterOk,
    this.createdBy,
  });

  factory MoveIn.fromJson(Map<String, dynamic> json) {
    return MoveIn(
      id: int.parse(json['id'].toString()),
      createdAt: DateTime.parse(json['created_at']),
      name: json['name'] ?? '',
      box: json['box'] ?? '',
      startDate: json['start_date'],
      taille: json['taille'],
      sizeCode: json['size_code'],
      idClient: json['id_client'],
      isEmpty: json['is_empty'] ?? false,
      hasLoxxOnDoor: json['has_loxx_on_door'] ?? false,
      isClean: json['is_clean'] ?? false,
      comments: json['comments'],
      posterOk: json['poster_ok'] ?? true,
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
