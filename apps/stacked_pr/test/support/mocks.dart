import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:stacked_pr_app/src/git.dart';
import 'package:stacked_pr_app/src/github.dart';
import 'package:stacked_pr_app/src/report.dart';

@GenerateNiceMocks([
  MockSpec<GitHubApi>(),
  MockSpec<Reporter>(),
  MockSpec<GitRepository>(),
  MockSpec<http.Client>(),
])
void main() {}
