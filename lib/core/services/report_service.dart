import 'package:flutter/material.dart';
import 'package:staff_admin/core/config/supabase_config.dart';
import 'package:staff_admin/core/models/report.dart';
import 'package:staff_admin/core/models/report_detail.dart';
import 'package:staff_admin/core/models/move_in.dart';
import 'package:staff_admin/core/models/move_out.dart';
import 'package:staff_admin/core/models/ovl.dart';

class ReportService extends ChangeNotifier {
  final _supabase = SupabaseConfig.supabase;
  List<Report> _reports = [];
  final Map<int, List<ReportDetail>> _detailsByReport = {};
  final Map<int, List<MoveIn>> _moveInsByReport = {};
  final Map<int, List<MoveOut>> _moveOutsByReport = {};
  final Map<int, List<Ovl>> _ovlsByReport = {};
  bool _isLoading = false;

  List<Report> get reports => _reports;
  List<ReportDetail>? getDetailsForReport(int reportId) => _detailsByReport[reportId];
  List<MoveIn>? getMoveInsForReport(int reportId) => _moveInsByReport[reportId];
  List<MoveOut>? getMoveOutsForReport(int reportId) => _moveOutsByReport[reportId];
  List<Ovl>? getOvlsForReport(int reportId) => _ovlsByReport[reportId];
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

      if (response.isEmpty) {
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
            
            // Debug: Log the date_time format
            debugPrint('to_do_list date_time type: ${toDoList['date_time'].runtimeType}');
            debugPrint('to_do_list date_time value: ${toDoList['date_time']}');
            
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

      if (response.isEmpty) {
        _detailsByReport[reportId] = [];
      } else {
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
      }

      // Load daily activities (move-in, move-out, OVL) via RPC
      await loadDailyActivitiesForReport(reportId);

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading details for report $reportId: $e');
      _detailsByReport[reportId] = [];
    }
  }

  Future<void> loadDailyActivitiesForReport(int reportId) async {
    try {
      final response = await _supabase.rpc(
        'get_daily_activities_for_report',
        params: {'report_id_param': reportId},
      );

      debugPrint('Raw daily activities response for report $reportId: $response');

      if (response == null) {
        _moveInsByReport[reportId] = [];
        _moveOutsByReport[reportId] = [];
        _ovlsByReport[reportId] = [];
        return;
      }

      final data = response as Map<String, dynamic>;

      // Parse move-ins
      final moveInsJson = data['move_ins'] as List<dynamic>? ?? [];
      _moveInsByReport[reportId] = moveInsJson.map<MoveIn>((json) {
        try {
          return MoveIn.fromJson(json as Map<String, dynamic>);
        } catch (e) {
          debugPrint('Error parsing move-in: $json');
          debugPrint('Error details: $e');
          rethrow;
        }
      }).toList();

      // Parse move-outs
      final moveOutsJson = data['move_outs'] as List<dynamic>? ?? [];
      _moveOutsByReport[reportId] = moveOutsJson.map<MoveOut>((json) {
        try {
          return MoveOut.fromJson(json as Map<String, dynamic>);
        } catch (e) {
          debugPrint('Error parsing move-out: $json');
          debugPrint('Error details: $e');
          rethrow;
        }
      }).toList();

      // Parse OVLs
      final ovlsJson = data['ovls'] as List<dynamic>? ?? [];
      _ovlsByReport[reportId] = ovlsJson.map<Ovl>((json) {
        try {
          return Ovl.fromJson(json as Map<String, dynamic>);
        } catch (e) {
          debugPrint('Error parsing OVL: $json');
          debugPrint('Error details: $e');
          rethrow;
        }
      }).toList();

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading daily activities for report $reportId: $e');
      _moveInsByReport[reportId] = [];
      _moveOutsByReport[reportId] = [];
      _ovlsByReport[reportId] = [];
    }
  }
} 