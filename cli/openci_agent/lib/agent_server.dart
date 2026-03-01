import 'dart:convert';

import 'package:relic/relic.dart';

import 'vm_manager.dart';

class AgentServer {
  final VMManager vmManager;

  AgentServer(this.vmManager);

  void mount(RelicApp app) {
    app
      ..get('/health', _health)
      ..get('/vms', _listVMs)
      ..post('/vms', _createVM)
      ..get('/vms/:id', _getVM)
      ..post('/vms/:id/exec', _execCommand)
      ..delete('/vms/:id', _deleteVM);
  }

  Response _health(Request request) {
    return _json({'status': 'ok', 'vms_active': vmManager.allVMs.length});
  }

  Response _listVMs(Request request) {
    final vms = vmManager.allVMs.map((vm) => vm.toJson()).toList();
    return _json({'vms': vms, 'total': vms.length});
  }

  Future<Response> _createVM(Request request) async {
    try {
      final instance = await vmManager.createVM();
      return _json(instance.toJson(), statusCode: 201);
    } catch (e) {
      return _json({'error': e.toString()}, statusCode: 500);
    }
  }

  Response _getVM(Request request) {
    final id = request.rawPathParameters[#id];
    final instance = vmManager.getVM(id ?? '');
    if (instance == null) {
      return _json({'error': 'VM not found'}, statusCode: 404);
    }
    return _json(instance.toJson());
  }

  Future<Response> _execCommand(Request request) async {
    final id = request.rawPathParameters[#id];
    try {
      final bodyStr = await request.readAsString();
      final body = jsonDecode(bodyStr) as Map<String, dynamic>;
      final command = body['command'] as String?;
      if (command == null || command.isEmpty) {
        return _json({'error': 'Missing "command" field'}, statusCode: 400);
      }

      final result = await vmManager.execCommand(id ?? '', command);
      return _json(result.toJson());
    } catch (e) {
      return _json({'error': e.toString()}, statusCode: 500);
    }
  }

  Future<Response> _deleteVM(Request request) async {
    final id = request.rawPathParameters[#id];
    try {
      await vmManager.deleteVM(id ?? '');
      return _json({'status': 'deleted', 'id': id});
    } catch (e) {
      return _json({'error': e.toString()}, statusCode: 500);
    }
  }

  Response _json(Object body, {int statusCode = 200}) {
    return Response(statusCode, body: Body.fromString(jsonEncode(body)));
  }
}
