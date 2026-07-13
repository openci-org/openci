import 'package:chopper/chopper.dart';
import 'package:http/http.dart' as http;
import 'package:lume_dart/lume_dart.dart';
import 'package:openci_build_job_processor/openci_build_job_processor.dart';
import 'package:openci_build_job_processor/src/lume/lume_api_service.dart';
import 'package:test/test.dart';

class FakeLumeApiService extends LumeApiService {
  FakeLumeApiService(this.getVmsMock);

  final Future<Response<List<LumeVM>>> Function(String url) getVmsMock;

  @override
  Type get definitionType => LumeApiService;

  @override
  Future<Response<List<LumeVM>>> getVms(String url) => getVmsMock(url);
}

void main() {
  group('LumeService tests', () {
    test(
      'findAvailableLumeUrl returns first host with < 2 running VMs',
      () async {
        final fakeApi = FakeLumeApiService((url) async {
          if (url == 'http://host1:7777/lume/vms') {
            return Response(http.Response('[]', 200), const [
              LumeVM(name: 'vm1', status: 'running'),
              LumeVM(name: 'vm2', status: 'running'),
            ]);
          } else if (url == 'http://host2:7777/lume/vms') {
            return Response(http.Response('[]', 200), const [
              LumeVM(name: 'vm3', status: 'running'),
              LumeVM(name: 'vm4', status: 'stopped'),
            ]);
          }
          throw UnimplementedError();
        });

        final chopper = ChopperClient(services: [fakeApi]);

        final service = LumeService(client: chopper);

        final result = await service.findAvailableLumeUrl(const [
          'http://host1:7777',
          'http://host2:7777',
        ]);

        expect(result, equals('http://host2:7777'));
      },
    );

    test(
      'findAvailableLumeUrl returns null if all hosts have >= 2 running VMs',
      () async {
        final fakeApi = FakeLumeApiService((url) async {
          return Response(http.Response('[]', 200), const [
            LumeVM(name: 'vm1', status: 'running'),
            LumeVM(name: 'vm2', status: 'running'),
          ]);
        });

        final chopper = ChopperClient(services: [fakeApi]);

        final service = LumeService(client: chopper);

        final result = await service.findAvailableLumeUrl(const [
          'http://host1:7777',
          'http://host2:7777',
        ]);

        expect(result, isNull);
      },
    );

    test('findAvailableLumeUrl ignores hosts that fail to respond', () async {
      final fakeApi = FakeLumeApiService((url) async {
        if (url == 'http://host1:7777/lume/vms') {
          throw Exception('Connection timed out');
        } else {
          return Response(http.Response('[]', 200), const [
            LumeVM(name: 'vm1', status: 'running'),
          ]);
        }
      });

      final chopper = ChopperClient(services: [fakeApi]);

      final service = LumeService(client: chopper);

      final result = await service.findAvailableLumeUrl(const [
        'http://host1:7777',
        'http://host2:7777',
      ]);

      expect(result, equals('http://host2:7777'));
    });
  });
}
