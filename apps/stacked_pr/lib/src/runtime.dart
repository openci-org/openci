import 'dart:io';
import 'package:path/path.dart' as p;
import 'config.dart';
import 'environment.dart';
import 'git.dart';
import 'github.dart';
import 'report.dart';
import 'service.dart';
import 'store.dart';
import 'webhook.dart';
import 'worker.dart';

class AppRuntime {
  AppRuntime._(this.store, this.api, this.worker, this.webhooks);
  final Store store;
  final GitHubApi api;
  final Worker worker;
  final WebhookReceiver webhooks;
  var _stopping = false;

  static Future<AppRuntime> create() async {
    final env = loadEnvironment();
    final config = AppConfig.fromEnvironment(env);
    await Directory(config.dataDir).create(recursive: true);
    final store = Store(p.join(config.dataDir, 'stacked-pr.sqlite'));
    try {
      final api = GitHubApi(config, client: createHttpClient(env));
      final service = Service(
        config: config,
        store: store,
        api: api,
        reporter: Reporter(api),
        gitFactory: (installation, repo) => GitRepository(
          directory: p.join(config.dataDir, 'git', '$installation-${repo.id}.git'),
          remote: '${config.githubUrl}/${repo.fullName}.git',
          token: () => api.token(installation),
          environment: env,
        ),
      );
      return AppRuntime._(
        store,
        api,
        Worker(store, service),
        WebhookReceiver(store, config.secret),
      );
    } catch (_) {
      store.close();
      rethrow;
    }
  }

  Future<void> close() async {
    if (_stopping) return;
    _stopping = true;
    await worker.stop();
    store.close();
    api.close();
  }
}
