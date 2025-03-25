import 'package:flutter/material.dart';
import 'package:staff_admin/core/config/supabase_config.dart';
import 'package:staff_admin/core/models/report.dart';
import 'package:staff_admin/core/models/report_detail.dart';

class ReportService extends ChangeNotifier {
  final _supabase = SupabaseConfig.supabase;
  List<Report> _reports = [];
  Map<int, List<ReportDetail>> _detailsByReport = {};
  bool _isLoading = false;

  List<Report> get reports => _reports;
  List<ReportDetail>? getDetailsForReport(int reportId) => _detailsByReport[reportId];
  bool get isLoading => _isLoading;

  Future<void> loadReports() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase
          .from('report')
          .select('''
            *,
            responsable (
              firstname,
              lastname
            ),
            to_do_list (
              date_time,
              site:site_id (
                name,
                site_code
              )
            )
          ''')
          .order('date_time', ascending: false);

      debugPrint('Raw Supabase response: $response');

      if (response == null || response.isEmpty) {
        _reports = [];
        return;
      }

      _reports = response.map<Report>((json) {
        try {
          final reportJson = Map<String, dynamic>.from(json);
          
          // Handle to_do_list and site information
          if (json['to_do_list'] != null) {
            final toDoList = json['to_do_list'];
            reportJson['to_do_list_date_time'] = toDoList['date_time'];
            
            if (toDoList['site'] != null) {
              reportJson['site_name'] = toDoList['site']['name'];
              reportJson['site_code'] = toDoList['site']['site_code'];
            }
          }

          return Report.fromJson(reportJson);
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

  Future<void> loadDetailsForReport(int reportId) async {
    try {
      final response = await _supabase
          .from('report_detail')
          .select('''
            *,
            task_of_day!inner (
              task_site!inner (
                task!inner (
                  name
                )
              )
            )
          ''')
          .eq('report', reportId);

      debugPrint('Raw details response for report $reportId: $response');

      if (response == null || response.isEmpty) {
        _detailsByReport[reportId] = [];
        return;
      }

      _detailsByReport[reportId] = response.map<ReportDetail>((json) {
        try {
          final detailJson = Map<String, dynamic>.from(json);
          if (json['task_of_day'] != null && 
              json['task_of_day']['task_site'] != null &&
              json['task_of_day']['task_site']['task'] != null) {
            detailJson['task_name'] = json['task_of_day']['task_site']['task']['name'];
          }
          return ReportDetail.fromJson(detailJson);
        } catch (e) {
          debugPrint('Error parsing detail: $json');
          debugPrint('Error details: $e');
          rethrow;
        }
      }).toList();

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading details for report $reportId: $e');
      _detailsByReport[reportId] = [];
    }
  }
} 