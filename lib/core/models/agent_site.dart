/// Association agent ↔ site : définit les sites auxquels un agent a accès.
class AgentSite {
  final int id;
  final int agentId;
  final String agentName;
  final int siteId;
  final String siteName;

  AgentSite({
    required this.id,
    required this.agentId,
    required this.agentName,
    required this.siteId,
    required this.siteName,
  });

  factory AgentSite.fromJson(Map<String, dynamic> json) {
    final agentInfo = json['agent_info'] ?? json['agent'];
    final siteInfo = json['site_info'] ?? json['site'];

    String agentName = '';
    if (agentInfo != null) {
      final first = agentInfo['firstname'] ?? '';
      final last = agentInfo['lastname'] ?? '';
      agentName = '$first $last'.trim();
    }

    final siteName = siteInfo != null
        ? (siteInfo['name'] ?? siteInfo['site_code'] ?? '').toString()
        : '';

    return AgentSite(
      id: int.parse((json['id'] ?? 0).toString()),
      agentId: int.parse((json['agent_id'] ?? 0).toString()),
      agentName: agentName,
      siteId: int.parse((json['site_id'] ?? 0).toString()),
      siteName: siteName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'agent_id': agentId,
      'site_id': siteId,
    };
  }
}
