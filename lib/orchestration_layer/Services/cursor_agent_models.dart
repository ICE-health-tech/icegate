/// Summary of a Cursor Cloud Agent (from GET/POST /v1/agents).
class CursorAgentSummary {
  const CursorAgentSummary({
    required this.id,
    required this.name,
    required this.status,
    this.url,
    this.envType,
    this.envName,
  });

  final String id;
  final String name;
  final String status;
  final String? url;
  final String? envType;
  final String? envName;

  factory CursorAgentSummary.fromJson(Map<String, dynamic> json) {
    final env = json['env'];
    String? envType;
    String? envName;
    if (env is Map<String, dynamic>) {
      envType = env['type'] as String?;
      envName = env['name'] as String?;
    }
    return CursorAgentSummary(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Agent',
      status: json['status'] as String? ?? 'UNKNOWN',
      url: json['url'] as String?,
      envType: envType,
      envName: envName,
    );
  }
}

class CursorCreateAgentResult {
  const CursorCreateAgentResult({
    required this.ok,
    this.agent,
    this.agentUrl,
    this.message,
    this.statusCode,
  });

  final bool ok;
  final CursorAgentSummary? agent;
  final String? agentUrl;
  final String? message;
  final int? statusCode;
}

enum CursorAgentTarget {
  /// Routes to a My Machines worker (`agent worker start` on Mac).
  machine,

  /// Cursor-hosted cloud VM with optional GitHub repo.
  cloudRepo,
}
