/// Statistique de rapports clôturés par un agent.
class AgentReportStat {
  final int agentId;
  final String firstname;
  final String lastname;
  final int reportsCount;

  AgentReportStat({
    required this.agentId,
    required this.firstname,
    required this.lastname,
    required this.reportsCount,
  });

  factory AgentReportStat.fromJson(Map<String, dynamic> json) {
    return AgentReportStat(
      agentId: int.parse(json['agent_id'].toString()),
      firstname: json['firstname']?.toString() ?? '',
      lastname: json['lastname']?.toString() ?? '',
      reportsCount: int.tryParse(json['reports_count']?.toString() ?? '0') ?? 0,
    );
  }

  String get fullName => '$firstname $lastname'.trim();
}
