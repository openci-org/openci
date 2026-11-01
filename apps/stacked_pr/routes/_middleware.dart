import 'package:dart_frog/dart_frog.dart';
import 'package:stacked_pr_app/src/runtime.dart';
import 'package:stacked_pr_app/src/webhook.dart';

Handler middleware(Handler handler) =>
    handler.use(provider<WebhookReceiver>((context) => context.read<AppRuntime>().webhooks));
