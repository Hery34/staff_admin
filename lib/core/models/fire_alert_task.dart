import 'package:intl/intl.dart';

class FireAlertTask {
  final int id;
  final int fireAlertReportId;
  final int taskId;
  final bool isDone;
  final bool isModified;
  final String? notes;
  final String? taskName;
  final String? taskDescription;
  final DateTime? completedAt;
  final int? completedBy;
  final int? createdBy;
  final String? createdByName;
  final String? completedByName;

  FireAlertTask({
    required this.id,
    required this.fireAlertReportId,
    required this.taskId,
    required this.isDone,
    required this.isModified,
    this.notes,
    this.taskName,
    this.taskDescription,
    this.completedAt,
    this.completedBy,
    this.createdBy,
    this.createdByName,
    this.completedByName,
  });

  factory FireAlertTask.fromJson(Map<String, dynamic> json) {
    return FireAlertTask(
      id: int.parse(json['id'].toString()),
      fireAlertReportId: int.parse(json['fire_alert_report_id'].toString()),
      taskId: int.parse(json['task_id'].toString()),
      isDone: json['is_done'] ?? false,
      isModified: json['is_modified'] ?? false,
      notes: json['notes'],
      taskName: json['task_name'],
      taskDescription: json['task_description'],
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      completedBy: json['completed_by'] != null
          ? int.parse(json['completed_by'].toString())
          : null,
      createdBy: json['created_by'] != null
          ? int.parse(json['created_by'].toString())
          : null,
      createdByName: json['created_by_name'],
      completedByName: json['completed_by_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fire_alert_report_id': fireAlertReportId,
      'task_id': taskId,
      'is_done': isDone,
      'is_modified': isModified,
      'notes': notes,
      'completed_at': completedAt?.toIso8601String(),
      'completed_by': completedBy,
      'created_by': createdBy,
    };
  }

  String get formattedCompletedAt {
    if (completedAt == null) return '-';
    return DateFormat('dd/MM/yyyy HH:mm').format(completedAt!);
  }

  String get displayName {
    if (taskName != null && taskDescription != null) {
      return '$taskName - $taskDescription';
    }
    return taskName ?? 'Tâche $taskId';
  }
} 