import 'dart:async';
import 'dart:convert';

import 'package:dart_mcp/server.dart';
import 'package:http/http.dart' as http;

import '../auth/firebase_auth_client.dart';
import '../credential_store/credential_config.dart';
import '../version.dart';
import 'build_api.dart';
import 'find_jobs.dart';
import 'job_logs.dart';

final class OpenCiMcpServer extends MCPServer with ToolsSupport {
  OpenCiMcpServer(super.channel, this._readProfile, this._client)
    : super.fromStreamChannel(
        implementation: Implementation(name: 'openci', version: openCIVersion),
      ) {
    registerTool(
      Tool(
        name: 'find_jobs',
        description:
            'Find OpenCI jobs for a GitHub PR URL (all its commits unless commit_sha is supplied), or for a repository and full commit SHA. Follow next_cursor with the same search for older matches, including after an empty page.',
        annotations: ToolAnnotations(readOnlyHint: true),
        inputSchema: Schema.object(
          properties: {
            'pr_url': Schema.string(maxLength: 2048),
            'repository': Schema.string(
              description:
                  'owner/repo for github.com or an HTTPS repository URL for GitHub Enterprise.',
              maxLength: 2048,
            ),
            'commit_sha': Schema.string(
              pattern: r'^(?:[a-fA-F0-9]{40}|[a-fA-F0-9]{64})$',
            ),
            'cursor': Schema.string(pattern: r'^(jobs|team):[0-9]{1,9}$'),
          },
          additionalProperties: false,
        ),
      ),
      (request) => _call(request, findJobs),
    );
    registerTool(
      Tool(
        name: 'get_job_logs',
        description:
            'Read a bounded excerpt of saved OpenCI build output. Omit run_id for the current attempt. Pass a stored run_id for an earlier attempt or with a log cursor.',
        annotations: ToolAnnotations(readOnlyHint: true),
        inputSchema: Schema.object(
          properties: {
            'job_id': Schema.string(minLength: 1, maxLength: 512),
            'run_id': Schema.string(minLength: 1, maxLength: 512),
            'cursor': Schema.string(pattern: r'^[1-9][0-9]{0,17}:[0-9]{1,5}$'),
          },
          required: ['job_id'],
          additionalProperties: false,
        ),
      ),
      (request) => _call(request, getJobLogs),
    );
  }

  final Future<AuthProfile?> Function() _readProfile;
  final http.Client _client;
  Future<AuthProfile?>? _pendingProfile;

  Future<CallToolResult> _call(
    CallToolRequest request,
    Future<Map<String, Object?>> Function(BuildApi, Map<String, Object?>) read,
  ) async {
    try {
      // Concurrent calls share one refresh; the next call sees any team switch.
      final profile = await (_pendingProfile ??= _readProfile().whenComplete(
        () => _pendingProfile = null,
      ));
      if (profile == null ||
          profile.authType != 'firebase' ||
          profile.token.isEmpty ||
          profile.teamId.isEmpty) {
        throw const BuildReadException(
          'Run openci login in your terminal and select a team.',
        );
      }
      final result = await read(
        BuildApi(profile, _client),
        request.arguments ?? {},
      );
      return CallToolResult(content: [TextContent(text: jsonEncode(result))]);
    } on BuildReadException catch (e) {
      return _error(e.message);
    } on FirebaseAuthException {
      return _error('Sign in again with openci login.');
    } on TimeoutException {
      return _error('The OpenCI request timed out. Retry the read.');
    } catch (_) {
      return _error(
        'Could not read OpenCI data. Check your connection and openci status.',
      );
    }
  }

  CallToolResult _error(String message) =>
      CallToolResult(isError: true, content: [TextContent(text: message)]);
}
