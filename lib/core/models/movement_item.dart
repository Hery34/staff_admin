import 'package:intl/intl.dart';
import 'package:staff_admin/core/models/move_in.dart';
import 'package:staff_admin/core/models/move_out.dart';

enum MovementTypeFilter {
  all,
  moveIn,
  moveOut,
}

class MovementItem {
  final String movementType;
  final int id;
  final DateTime createdAt;
  final int? siteId;
  final String? siteName;
  final String? siteCode;
  final String name;
  final String box;
  final String? startDate;
  final String? taille;
  final String? sizeCode;
  final String? idClient;
  final bool isEmpty;
  final bool isClean;
  final String? comments;
  final bool? posterOk;
  final String? leaveDate;
  final bool? hasLoxxOnDoor;
  final bool? hasLoxx;
  final Map<String, dynamic>? createdBy;

  MovementItem({
    required this.movementType,
    required this.id,
    required this.createdAt,
    this.siteId,
    this.siteName,
    this.siteCode,
    required this.name,
    required this.box,
    this.startDate,
    this.taille,
    this.sizeCode,
    this.idClient,
    required this.isEmpty,
    required this.isClean,
    this.comments,
    this.posterOk,
    this.leaveDate,
    this.hasLoxxOnDoor,
    this.hasLoxx,
    this.createdBy,
  });

  factory MovementItem.fromJson(Map<String, dynamic> json) {
    final siteInfo = json['site_info'] as Map<String, dynamic>?;
    return MovementItem(
      movementType: json['movement_type']?.toString() ?? '',
      id: int.parse(json['id'].toString()),
      createdAt: DateTime.parse(json['created_at'].toString()),
      siteId:
          json['site'] != null ? int.tryParse(json['site'].toString()) : null,
      siteName: siteInfo?['name']?.toString(),
      siteCode: siteInfo?['site_code']?.toString(),
      name: json['name']?.toString() ?? '',
      box: json['box']?.toString() ?? '',
      startDate: json['start_date']?.toString(),
      taille: json['taille']?.toString(),
      sizeCode: json['size_code']?.toString(),
      idClient: json['id_client']?.toString(),
      isEmpty: json['is_empty'] == true,
      isClean: json['is_clean'] == true,
      comments: json['comments']?.toString(),
      posterOk: json['poster_ok'] == null ? null : json['poster_ok'] == true,
      leaveDate: json['leave_date']?.toString(),
      hasLoxxOnDoor: json['has_loxx_on_door'] == null
          ? null
          : json['has_loxx_on_door'] == true,
      hasLoxx: json['has_loxx'] == null ? null : json['has_loxx'] == true,
      createdBy: json['created_by'] as Map<String, dynamic>?,
    );
  }

  bool get isMoveIn => movementType == 'move_in';

  String get typeLabel => isMoveIn ? 'Move-In' : 'Move-Out';

  String get formattedCreatedAt =>
      DateFormat('dd/MM/yyyy HH:mm').format(createdAt);

  String get siteDisplay {
    if (siteCode != null && siteName != null && siteName!.isNotEmpty) {
      return '$siteCode - $siteName';
    }
    return siteName ?? '-';
  }

  String get createdByName {
    if (createdBy == null) return 'Non spécifié';
    final firstname = createdBy!['firstname']?.toString() ?? '';
    final lastname = createdBy!['lastname']?.toString() ?? '';
    final fullName = '$firstname $lastname'.trim();
    return fullName.isEmpty ? 'Non spécifié' : fullName;
  }

  MoveIn toMoveIn() {
    return MoveIn.fromJson({
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'name': name,
      'box': box,
      'start_date': startDate,
      'taille': taille,
      'size_code': sizeCode,
      'id_client': idClient,
      'is_empty': isEmpty,
      'has_loxx_on_door': hasLoxxOnDoor ?? false,
      'is_clean': isClean,
      'comments': comments,
      'poster_ok': posterOk ?? true,
      'created_by': createdBy,
    });
  }

  MoveOut toMoveOut() {
    return MoveOut.fromJson({
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'name': name,
      'box': box,
      'start_date': startDate,
      'taille': taille,
      'size_code': sizeCode,
      'id_client': idClient,
      'is_empty': isEmpty,
      'has_loxx': hasLoxx ?? false,
      'is_clean': isClean,
      'comments': comments,
      'leave_date': leaveDate,
      'created_by': createdBy,
    });
  }
}
