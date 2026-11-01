import 'dart:io';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:path/path.dart' as p;
import 'package:stacked_pr_app/src/config.dart';
import 'package:stacked_pr_app/src/models.dart';

const secret = 'a-long-random-webhook-secret-for-tests';
String get testKey => File(p.join('test', 'fixtures', 'test_key.txt')).readAsStringSync();
AppConfig config({String? dataDir, bool autoRestack = true}) => AppConfig(
  githubUrl: Uri.parse('https://git.example.com'),
  appId: '7',
  privateKey: RSAPrivateKey(testKey),
  secret: secret,
  dataDir: dataDir ?? '.',
  autoRestack: autoRestack,
);

List<PullRequest> chain() => [
  PullRequest(
    number: 1,
    title: 'DB',
    headRef: 'db',
    baseRef: 'main',
    head: 'a' * 40,
    base: '0' * 40,
  ),
  PullRequest(
    number: 2,
    title: 'API',
    headRef: 'api',
    baseRef: 'db',
    head: 'b' * 40,
    base: 'a' * 40,
    parent: 1,
    boundary: 'a' * 40,
  ),
  PullRequest(
    number: 3,
    title: 'UI',
    headRef: 'ui',
    baseRef: 'api',
    head: 'c' * 40,
    base: 'b' * 40,
    parent: 2,
    boundary: 'b' * 40,
  ),
];
PullRequest modify(PullRequest pr, Json changes) =>
    PullRequest.fromJson({...pr.toJson(), ...changes});
