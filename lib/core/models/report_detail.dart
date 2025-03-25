class ReportDetail {
  final int id;
  final int report;
  final int task;
  final String? comment;
  final String? photoUrl;
  final String? taskName;

  ReportDetail({
    required this.id,
    required this.report,
    required this.task,
    this.comment,
    this.photoUrl,
    this.taskName,
  });

  factory ReportDetail.fromJson(Map<String, dynamic> json) {
    return ReportDetail(
      id: int.parse(json['id'].toString()),
      report: int.parse(json['report'].toString()),
      task: int.parse(json['task'].toString()),
      comment: json['comment'],
      photoUrl: json['photo_url'],
      taskName: json['task_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'report': report,
      'task': task,
      'comment': comment,
      'photo_url': photoUrl,
    };
  }
} 