import 'package:flutter/material.dart';
import 'package:staff_admin/core/config/supabase_config.dart';
import 'package:staff_admin/core/models/task_site.dart';

class TaskSiteService extends ChangeNotifier {
  final _supabase = SupabaseConfig.supabase;
  List<TaskSite> _tasks = [];
  bool _isLoading = false;
  int? _selectedSiteId;

  List<TaskSite> get tasks => _tasks;
  bool get isLoading => _isLoading;
  int? get selectedSiteId => _selectedSiteId;

  void selectSite(int siteId) {
    _selectedSiteId = siteId;
    loadTasksForSite(siteId);
  }

  Future<void> loadTasksForSite(int siteId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase
          .from('task_site')
          .select('''
            *,
            site_info:site (
              name
            ),
            task_info:task (
              name,
              description
            )
          ''')
          .eq('site', siteId);

      debugPrint('Raw task_site response: $response');

      if (response.isEmpty) {
        _tasks = [];
        return;
      }

      _tasks = response.map<TaskSite>((json) {
        try {
          return TaskSite.fromJson(json);
        } catch (e) {
          debugPrint('Error parsing task_site: $json');
          debugPrint('Error details: $e');
          rethrow;
        }
      }).toList();

    } catch (e) {
      debugPrint('Error loading tasks for site $siteId: $e');
      _tasks = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateTaskSite(TaskSite taskSite) async {
    try {
      // Si on modifie le nom ou la description de la tâche,
      // il faut mettre à jour la table task
      await _supabase
          .from('task')
          .update({
            'name': taskSite.taskName,
            'description': taskSite.taskDescription,
          })
          .eq('id', taskSite.taskId);

      // Mise à jour de la récurrence dans task_site
      await _supabase
          .from('task_site')
          .update(taskSite.toJson())
          .eq('id', taskSite.id);

      await loadTasksForSite(taskSite.siteId);
    } catch (e) {
      debugPrint('Error updating task_site: $e');
      rethrow;
    }
  }

  Future<void> deleteTaskSite(int taskSiteId) async {
    try {
      await _supabase
          .from('task_site')
          .delete()
          .eq('id', taskSiteId);

      if (_selectedSiteId != null) {
        await loadTasksForSite(_selectedSiteId!);
      }
    } catch (e) {
      debugPrint('Error deleting task_site: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> loadSites() async {
    try {
      final response = await _supabase
          .from('site')
          .select('id, name')
          .order('name');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error loading sites: $e');
      return [];
    }
  }
} 