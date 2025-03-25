import 'package:flutter/material.dart';
import 'package:staff_admin/core/config/supabase_config.dart';
import 'package:staff_admin/core/models/fire_alert_report.dart';
import 'package:staff_admin/core/models/fire_alert_task.dart';

class FireAlertService extends ChangeNotifier {
  final _supabase = SupabaseConfig.supabase;
  List<FireAlertReport> _reports = [];
  Map<int, List<FireAlertTask>> _tasksByReport = {};
  bool _isLoading = false;

  List<FireAlertReport> get reports => _reports;
  List<FireAlertTask>? getTasksForReport(int reportId) => _tasksByReport[reportId];
  bool get isLoading => _isLoading;

  Future<void> loadReports() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase
          .from('fire_alert_report')
          .select('''
            *,
            created_by_agent:agent!created_by (
              firstname,
              lastname
            ),
            closed_by_agent:agent!closed_by (
              firstname,
              lastname
            ),
            site_info:site (
              name
            )
          ''')
          .order('date', ascending: false);

      debugPrint('Raw Supabase response: $response');

      if (response == null || response.isEmpty) {
        _reports = [];
        return;
      }

      _reports = response.map<FireAlertReport>((json) {
        try {
          final reportJson = Map<String, dynamic>.from(json);
          
          // Debug log for alert type
          debugPrint('Report ${json['id']} - Alert type: ${json['alert_type']}');
          
          // Add agent names
          if (json['created_by_agent'] != null) {
            final firstname = json['created_by_agent']['firstname'];
            final lastname = json['created_by_agent']['lastname'];
            reportJson['created_by_name'] = '$firstname $lastname';
          }

          if (json['closed_by_agent'] != null) {
            final firstname = json['closed_by_agent']['firstname'];
            final lastname = json['closed_by_agent']['lastname'];
            reportJson['closed_by_name'] = '$firstname $lastname';
          }

          // Add site information
          if (json['site_info'] != null) {
            reportJson['site_name'] = json['site_info']['name'];
          }

          return FireAlertReport.fromJson(reportJson);
        } catch (e) {
          debugPrint('Error parsing report: $json');
          debugPrint('Error details: $e');
          rethrow;
        }
      }).toList();

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading reports: $e');
      _reports = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTasksForReport(int reportId) async {
    try {
      final response = await _supabase
          .from('fire_alert_tasks')
          .select('''
            *,
            alerte_incendie_tasks!task_id (
              name,
              description
            )
          ''')
          .eq('fire_alert_report_id', reportId);

      debugPrint('Raw tasks response for report $reportId: $response');

      if (response == null || response.isEmpty) {
        _tasksByReport[reportId] = [];
        return;
      }

      _tasksByReport[reportId] = response.map<FireAlertTask>((json) {
        try {
          final taskJson = Map<String, dynamic>.from(json);
          
          // Add task name from the task relation
          if (json['alerte_incendie_tasks'] != null) {
            taskJson['task_name'] = json['alerte_incendie_tasks']['name'];
            taskJson['task_description'] = json['alerte_incendie_tasks']['description'];
          }

          return FireAlertTask.fromJson(taskJson);
        } catch (e) {
          debugPrint('Error parsing task: $json');
          debugPrint('Error details: $e');
          rethrow;
        }
      }).toList();

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading tasks for report $reportId: $e');
      _tasksByReport[reportId] = [];
    }
  }

  Future<void> updateTask(FireAlertTask task) async {
    try {
      await _supabase
          .from('fire_alert_tasks')
          .update(task.toJson())
          .eq('id', task.id);

      await loadTasksForReport(task.fireAlertReportId);
    } catch (e) {
      debugPrint('Error updating task: $e');
      rethrow;
    }
  }

  Future<void> closeReport(int reportId, int closedBy) async {
    try {
      await _supabase
          .from('fire_alert_report')
          .update({
            'is_running': false,
            'closed_at': DateTime.now().toIso8601String(),
            'closed_by': closedBy,
          })
          .eq('id', reportId);

      await loadReports();
    } catch (e) {
      debugPrint('Error closing report: $e');
      rethrow;
    }
  }
} 