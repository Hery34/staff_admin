import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class Report {
  final int id;
  final DateTime dateTime;
  final Map<String, dynamic> toDoList;
  final Map<String, dynamic> responsable;

  Report({
    required this.id,
    required this.dateTime,
    required this.toDoList,
    required this.responsable,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: int.parse(json['id'].toString()),
      dateTime: DateTime.parse(json['date_time']),
      toDoList: json['to_do_list'] as Map<String, dynamic>,
      responsable: json['responsable'] as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date_time': dateTime.toIso8601String(),
      'to_do_list': toDoList,
      'responsable': responsable,
    };
  }

  String get formattedDateTime => DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  
  String get formattedToDoListDateTime {
    final todoDateTime = toDoList['date_time'];
    if (todoDateTime == null) return 'Non spécifié';
    
    DateTime dateTime;
    if (todoDateTime is DateTime) {
      dateTime = todoDateTime;
    } else if (todoDateTime is String) {
      try {
        dateTime = DateTime.parse(todoDateTime);
      } catch (e) {
        debugPrint('Error parsing date_time: $todoDateTime - $e');
        return 'Date invalide';
      }
    } else {
      debugPrint('Format de date non supporté: ${todoDateTime.runtimeType}');
      return 'Format de date non supporté';
    }
    
    // Log pour debug
    debugPrint('formattedToDoListDateTime - Date parsée: $dateTime');
    
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }
  
  String get siteDisplay {
    final site = toDoList['site'] as Map<String, dynamic>?;
    if (site == null) return 'Site non spécifié';
    
    final name = site['name'];
    final code = site['site_code'];
    
    if (code != null && name != null) {
      return '$code - $name';
    }
    return name ?? code ?? 'Site non spécifié';
  }

  String get responsableFullName {
    final firstname = responsable['firstname'] ?? '';
    final lastname = responsable['lastname'] ?? '';
    return '$firstname $lastname'.trim();
  }
} 