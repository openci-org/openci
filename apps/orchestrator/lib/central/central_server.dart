import 'dart:convert';

import 'package:relic/relic.dart';

import 'agent_registry.dart';

class CentralServer {
  final AgentRegistry registry;

  CentralServer(this.registry);

  void mount(RelicApp app) {
    app
      ..get('/health', _health)
      ..get('/agents', _listAgents)
      ..get('/vms', _listAllVMs)
      ..post('/vms', _createVM)
      ..get('/vms/:agentId/:vmId', _getVM)
      ..post('/vms/:agentId/:vmId/exec', _execCommand)
      ..delete('/vms/:agentId/:vmId', _deleteVM);
  }

  Future<Response> _health(Request request) async {
    await registry.refreshAll();
    final agents = registry.allAgents;
    final healthy = agents.where((a) => a.healthy).length;
    return _json({
      'status': 'ok',
      'agents_total': agents.length,
      'agents_healthy': healthy,
      'total_capacity': agents.fold<int>(0, (sum, a) => sum + a.maxVMs),
      'total_active': agents.fold<int>(0, (sum, a) => sum + a.activeVMs),
    });
  }

  Response _listAgents(Request request) {
    return _json({
      'agents': registry.allAgents.map((a) => a.toJson()).toList(),
    });
  }

  Future<Response> _listAllVMs(Request request) async {
    final allVMs = <Map<String, dynamic>>[];
    for (final agent in registry.allAgents) {
      if (!agent.healthy) continue;
      try {
        final vms = await agent.client.listVMs();
        for (final vm in vms) {
          vm['agent_id'] = agent.id;
        }
        allVMs.addAll(vms);
      } catch (_) {}
    }
    return _json({'vms': allVMs, 'total': allVMs.length});
  }

  Future<Response> _createVM(Request request) async {
    await registry.refreshAll();
    final agent = registry.selectBestAgent();
    if (agent == null) {
      return _json({
        'error': 'No agents available with capacity',
      }, statusCode: 503);
    }

    try {
      final vm = await agent.client.createVM();
      vm['agent_id'] = agent.id;
      agent.activeVMs++;
      return _json(vm, statusCode: 201);
    } catch (e) {
      return _json({'error': e.toString()}, statusCode: 500);
    }
  }

  Future<Response> _getVM(Request request) async {
    final agentId = request.rawPathParameters[#agentId] ?? '';
    final vmId = request.rawPathParameters[#vmId] ?? '';
    final agent = registry.getAgent(agentId);
    if (agent == null) {
      return _json({'error': 'Agent not found'}, statusCode: 404);
    }

    try {
      final vm = await agent.client.getVM(vmId);
      vm['agent_id'] = agentId;
      return _json(vm);
    } catch (e) {
      return _json({'error': e.toString()}, statusCode: 500);
    }
  }

  Future<Response> _execCommand(Request request) async {
    final agentId = request.rawPathParameters[#agentId] ?? '';
    final vmId = request.rawPathParameters[#vmId] ?? '';
    final agent = registry.getAgent(agentId);
    if (agent == null) {
      return _json({'error': 'Agent not found'}, statusCode: 404);
    }

    try {
      final bodyStr = await request.readAsString();
      final body = jsonDecode(bodyStr) as Map<String, dynamic>;
      final command = body['command'] as String?;
      if (command == null || command.isEmpty) {
        return _json({'error': 'Missing "command" field'}, statusCode: 400);
      }

      final result = await agent.client.execCommand(vmId, command);
      return _json(result);
    } catch (e) {
      return _json({'error': e.toString()}, statusCode: 500);
    }
  }

  Future<Response> _deleteVM(Request request) async {
    final agentId = request.rawPathParameters[#agentId] ?? '';
    final vmId = request.rawPathParameters[#vmId] ?? '';
    final agent = registry.getAgent(agentId);
    if (agent == null) {
      return _json({'error': 'Agent not found'}, statusCode: 404);
    }

    try {
      final result = await agent.client.deleteVM(vmId);
      agent.activeVMs = (agent.activeVMs - 1).clamp(0, agent.maxVMs);
      return _json(result);
    } catch (e) {
      return _json({'error': e.toString()}, statusCode: 500);
    }
  }

  Response _json(Object body, {int statusCode = 200}) {
    return Response(statusCode, body: Body.fromString(jsonEncode(body)));
  }
}
