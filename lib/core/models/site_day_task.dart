/// Tâche effectuée sur un site à une date donnée.
/// [isValidated] indique si la tâche a été incluse dans un rapport clôturé (signature PIN).
class SiteDayTask {
  final int id;
  final String? taskName;
  final String? comment;
  final String? photo;
  final bool isValidated;

  SiteDayTask({
    required this.id,
    this.taskName,
    this.comment,
    this.photo,
    required this.isValidated,
  });

  factory SiteDayTask.fromJson(Map<String, dynamic> json) {
    return SiteDayTask(
      id: int.parse(json['id'].toString()),
      taskName: json['task_name'],
      comment: json['comment'],
      photo: json['photo'],
      isValidated: json['is_validated'] == true,
    );
  }
}
