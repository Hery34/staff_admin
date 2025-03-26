import 'package:flutter/foundation.dart';

enum Recurrence {
  daily,
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday,
  weekly,
  // ignore: constant_identifier_names
  twice_a_week,
}

class TaskSite {
  final int id;
  final int siteId;
  final String siteName;
  final int taskId;
  final String taskName;
  final String taskDescription;
  final Recurrence recurrence;

  TaskSite({
    required this.id,
    required this.siteId,
    required this.siteName,
    required this.taskId,
    required this.taskName,
    required this.taskDescription,
    required this.recurrence,
  });

  factory TaskSite.fromJson(Map<String, dynamic> json) {
    return TaskSite(
      id: int.parse(json['id'].toString()),
      siteId: int.parse(json['site'].toString()),
      siteName: json['site_info']['name'] ?? '',
      taskId: int.parse(json['task'].toString()),
      taskName: json['task_info']['name'] ?? '',
      taskDescription: json['task_info']['description'] ?? '',
      recurrence: _parseRecurrence(json['recurrence']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'site': siteId,
      'task': taskId,
      'recurrence': recurrence.toString().split('.').last,
    };
  }

  static Recurrence _parseRecurrence(String? value) {
    if (value == null) return Recurrence.daily;
    
    final normalizedValue = value.toLowerCase().trim();
    try {
      return Recurrence.values.firstWhere(
        (e) => e.toString().split('.').last == normalizedValue
      );
    } catch (e) {
      debugPrint('Error parsing recurrence: $value');
      return Recurrence.daily;
    }
  }

  String get recurrenceDisplay {
    switch (recurrence) {
      case Recurrence.daily:
        return 'Quotidien';
      case Recurrence.monday:
        return 'Lundi';
      case Recurrence.tuesday:
        return 'Mardi';
      case Recurrence.wednesday:
        return 'Mercredi';
      case Recurrence.thursday:
        return 'Jeudi';
      case Recurrence.friday:
        return 'Vendredi';
      case Recurrence.saturday:
        return 'Samedi';
      case Recurrence.sunday:
        return 'Dimanche';
      case Recurrence.weekly:
        return 'Hebdomadaire';
      case Recurrence.twice_a_week:
        return 'Deux fois par semaine';
    }
  }

  // Getters pour les noms formatés
  String get displayTaskName => taskName;
  String get displayTaskDescription => taskDescription;
} 