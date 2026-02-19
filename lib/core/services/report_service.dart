import 'package:flutter/material.dart';
import 'package:staff_admin/core/config/supabase_config.dart';
import 'package:staff_admin/core/models/report.dart';
import 'package:staff_admin/core/models/report_detail.dart';
import 'package:staff_admin/core/models/move_in.dart';
import 'package:staff_admin/core/models/move_out.dart';
import 'package:staff_admin/core/models/ovl.dart';

import 'package:staff_admin/core/models/site_day_task.dart';

class ReportService extends ChangeNotifier {
  final _supabase = SupabaseConfig.supabase;
  List<Report> _reports = [];
  final Map<int, List<ReportDetail>> _detailsByReport = {};
  final Map<int, List<MoveIn>> _moveInsByReport = {};
  final Map<int, List<MoveOut>> _moveOutsByReport = {};
  final Map<int, List<Ovl>> _ovlsByReport = {};
  bool _isLoading = false;

  // Activités par site + date (avec ou sans rapport clôturé)
  List<MoveIn> _siteDayMoveIns = [];
  List<MoveOut> _siteDayMoveOuts = [];
  List<Ovl> _siteDayOvls = [];
  List<SiteDayTask> _siteDayTasks = [];
  List<Map<String, dynamic>> _siteDayReports = [];
  bool _siteDayLoading = false;
  int? _siteDaySiteId;
  DateTime? _siteDayDate;

  List<Report> get reports => _reports;
  List<ReportDetail>? getDetailsForReport(int reportId) => _detailsByReport[reportId];
  List<MoveIn>? getMoveInsForReport(int reportId) => _moveInsByReport[reportId];
  List<MoveOut>? getMoveOutsForReport(int reportId) => _moveOutsByReport[reportId];
  List<Ovl>? getOvlsForReport(int reportId) => _ovlsByReport[reportId];
  bool get isLoading => _isLoading;

  List<MoveIn> get siteDayMoveIns => _siteDayMoveIns;
  List<MoveOut> get siteDayMoveOuts => _siteDayMoveOuts;
  List<Ovl> get siteDayOvls => _siteDayOvls;
  List<SiteDayTask> get siteDayTasks => _siteDayTasks;
  List<Map<String, dynamic>> get siteDayReports => _siteDayReports;
  bool get siteDayLoading => _siteDayLoading;
  int? get siteDaySiteId => _siteDaySiteId;
  DateTime? get siteDayDate => _siteDayDate;

  /// Charge un seul rapport par ID via RPC (bypass RLS).
  /// Utile quand on arrive depuis "Activités du jour par site" et que loadReports
  /// ne retourne pas le rapport (RLS en production).
  Future<Report?> loadReportById(int reportId) async {
    try {
      final response = await _supabase.rpc(
        'get_report_by_id',
        params: {'report_id_param': reportId},
      );
      if (response == null) return null;
      final json = response as Map<String, dynamic>;
      final report = Report.fromJson(json);
      if (!_reports.any((r) => r.id == reportId)) {
        _reports = [report, ..._reports];
        notifyListeners();
      }
      return report;
    } catch (e) {
      debugPrint('Error loading report by id $reportId: $e');
      return null;
    }
  }

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
              site_id,
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

  /// Charge toutes les activités d'un site pour une date donnée (avec ou sans journées clôturées).
  /// Permet de voir ce qui a été fait même si les agents n'ont pas clôturé leur journée par PIN.
  Future<void> loadActivitiesBySiteAndDate(int siteId, DateTime date) async {
    _siteDayLoading = true;
    _siteDaySiteId = siteId;
    _siteDayDate = date;
    notifyListeners();

    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final response = await _supabase.rpc(
        'get_activities_by_site_and_date',
        params: {
          'site_id_param': siteId,
          'date_param': dateStr,
        },
      );

      if (response == null) {
        _siteDayMoveIns = [];
        _siteDayMoveOuts = [];
        _siteDayOvls = [];
        _siteDayTasks = [];
        _siteDayReports = [];
        return;
      }

      final data = response as Map<String, dynamic>;

      final moveInsJson = data['move_ins'] as List<dynamic>? ?? [];
      _siteDayMoveIns = moveInsJson.map<MoveIn>((j) => MoveIn.fromJson(j as Map<String, dynamic>)).toList();

      final moveOutsJson = data['move_outs'] as List<dynamic>? ?? [];
      _siteDayMoveOuts = moveOutsJson.map<MoveOut>((j) => MoveOut.fromJson(j as Map<String, dynamic>)).toList();

      final ovlsJson = data['ovls'] as List<dynamic>? ?? [];
      _siteDayOvls = ovlsJson.map<Ovl>((j) => Ovl.fromJson(j as Map<String, dynamic>)).toList();

      final tasksJson = data['tasks'] as List<dynamic>? ?? [];
      _siteDayTasks = tasksJson.map<SiteDayTask>((j) => SiteDayTask.fromJson(j as Map<String, dynamic>)).toList();

      final reportsJson = data['reports'] as List<dynamic>? ?? [];
      _siteDayReports = reportsJson.map<Map<String, dynamic>>((j) => Map<String, dynamic>.from(j as Map)).toList();
    } catch (e) {
      debugPrint('Error loading activities by site/date: $e');
      _siteDayMoveIns = [];
      _siteDayMoveOuts = [];
      _siteDayOvls = [];
      _siteDayTasks = [];
      _siteDayReports = [];
    } finally {
      _siteDayLoading = false;
      notifyListeners();
    }
  }
} 