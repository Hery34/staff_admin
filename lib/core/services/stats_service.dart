import 'package:flutter/material.dart';
import 'package:staff_admin/core/config/supabase_config.dart';
import 'package:staff_admin/core/models/site_closure_stat.dart';
import 'package:staff_admin/core/models/agent_report_stat.dart';

class StatsService extends ChangeNotifier {
  final _supabase = SupabaseConfig.supabase;

  List<SiteClosureStat> _closureBySite = [];
  List<AgentReportStat> _topAgents = [];
  int _expectedWorkingDays = 0;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;

  List<SiteClosureStat> get closureBySite => _closureBySite;
  List<AgentReportStat> get topAgents => _topAgents;
  int get expectedWorkingDays => _expectedWorkingDays;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  bool get isLoading => _isLoading;

  Future<void> loadReportStats(DateTime start, DateTime end) async {
    _isLoading = true;
    notifyListeners();

    try {
      final startStr = '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
      final endStr = '${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}';

      final response = await _supabase.rpc(
        'get_report_stats',
        params: {
          'start_date_param': startStr,
          'end_date_param': endStr,
        },
      );

      if (response == null) {
        _closureBySite = [];
        _topAgents = [];
        _expectedWorkingDays = 0;
        return;
      }

      final data = response as Map<String, dynamic>;
      _startDate = start;
      _endDate = end;
      _expectedWorkingDays = int.tryParse(data['expected_working_days']?.toString() ?? '0') ?? 0;

      final closureJson = data['closure_by_site'] as List<dynamic>? ?? [];
      _closureBySite = closureJson
          .map<SiteClosureStat>((j) => SiteClosureStat.fromJson(j as Map<String, dynamic>))
          .toList();

      final agentsJson = data['top_agents'] as List<dynamic>? ?? [];
      _topAgents = agentsJson
          .map<AgentReportStat>((j) => AgentReportStat.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error loading report stats: $e');
      _closureBySite = [];
      _topAgents = [];
      _expectedWorkingDays = 0;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
