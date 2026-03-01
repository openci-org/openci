import 'agent_client.dart';

class AgentInfo {
  final String id;
  final String url;
  final AgentClient client;
  int activeVMs;
  int maxVMs;
  DateTime lastHeartbeat;
  bool healthy;

  AgentInfo({
    required this.id,
    required this.url,
    required this.client,
    this.activeVMs = 0,
    this.maxVMs = 4,
  }) : lastHeartbeat = DateTime.now(),
       healthy = true;

  Map<String, dynamic> toJson() => {
    'id': id,
    'url': url,
    'active_vms': activeVMs,
    'max_vms': maxVMs,
    'healthy': healthy,
    'last_heartbeat': lastHeartbeat.toIso8601String(),
  };
}

class AgentRegistry {
  final Map<String, AgentInfo> _agents = {};

  List<AgentInfo> get allAgents => _agents.values.toList();

  void register(String id, String url, {int maxVMs = 4}) {
    _agents[id] = AgentInfo(
      id: id,
      url: url,
      client: AgentClient(agentId: id, baseUrl: url),
      maxVMs: maxVMs,
    );
  }

  AgentInfo? getAgent(String id) => _agents[id];

  AgentInfo? selectBestAgent() {
    final available = _agents.values
        .where((a) => a.healthy && a.activeVMs < a.maxVMs)
        .toList();
    if (available.isEmpty) return null;
    available.sort((a, b) => a.activeVMs.compareTo(b.activeVMs));
    return available.first;
  }

  Future<void> refreshAll() async {
    for (final agent in _agents.values) {
      try {
        final health = await agent.client.health();
        agent.activeVMs = health['vms_active'] as int? ?? 0;
        agent.lastHeartbeat = DateTime.now();
        agent.healthy = true;
      } catch (_) {
        agent.healthy = false;
      }
    }
  }

  String? findAgentForVM(String vmId) {
    for (final agent in _agents.values) {
      if (vmId.contains(agent.id)) return agent.id;
    }
    return null;
  }

  void dispose() {
    for (final agent in _agents.values) {
      agent.client.dispose();
    }
  }
}
