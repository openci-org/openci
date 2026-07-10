import 'package:chopper/chopper.dart';

import '../models/team.dart';
import '../models/user_device.dart';

part 'openci_api_service.chopper.dart';

@ChopperApi()
abstract class OpenCiApiService extends ChopperService {
  static OpenCiApiService create([ChopperClient? client]) =>
      _$OpenCiApiService(client);

  static const _timeout = Duration(seconds: 10);

  @GET(path: '/teams', timeout: _timeout)
  Future<Response<List<Team>>> getTeams();

  @POST(path: '/teams', timeout: _timeout)
  Future<Response<Map<String, dynamic>>> createTeam(
    @Body() Map<String, dynamic> body,
  );

  @PATCH(path: '/teams/{id}', timeout: _timeout)
  Future<Response<void>> updateTeam(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @DELETE(path: '/teams/{id}', timeout: _timeout)
  Future<Response<void>> deleteTeam(@Path('id') String id);

  @POST(path: '/teams/{id}/members', timeout: _timeout)
  Future<Response<void>> inviteMember(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @GET(path: '/devices', timeout: _timeout)
  Future<Response<List<UserDevice>>> getDevices();

  @GET(path: '/workers', timeout: _timeout)
  Future<Response<Map<String, dynamic>>> getWorkers();

  @POST(path: '/builds/claim', timeout: _timeout)
  Future<Response<Map<String, dynamic>>> claimNextJob(
    @Body() Map<String, dynamic> body,
  );

  @POST(path: '/builds/{id}/runs', timeout: _timeout)
  Future<Response<void>> createRun(
    @Path('id') String buildJobId,
    @Body() Map<String, dynamic> body,
  );

  @PATCH(path: '/builds/{id}', timeout: _timeout)
  Future<Response<void>> completeJob(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @PATCH(
    path: '/builds/{buildJobId}/runs/{runId}',
    timeout: _timeout,
  )
  Future<Response<void>> updateRunStatus(
    @Path('buildJobId') String buildJobId,
    @Path('runId') String runId,
    @Body() Map<String, dynamic> body,
  );

  @GET(path: '/builds/{id}', timeout: _timeout)
  Future<Response<Map<String, dynamic>>> getBuildJob(
    @Path('id') String id,
  );

  @POST(path: '/builds/{id}/check-run', timeout: _timeout)
  Future<Response<void>> updateCheckRun(
    @Path('id') String buildJobId,
    @Body() Map<String, dynamic> body,
  );

  @POST(path: '/builds/{id}/status-change', timeout: _timeout)
  Future<Response<void>> handleBuildJobStatusChange(
    @Path('id') String buildJobId,
    @Body() Map<String, dynamic> body,
  );

  @GET(path: '/builds/{id}/token', timeout: _timeout)
  Future<Response<Map<String, dynamic>>> resolveInstallationToken(
    @Path('id') String buildJobId,
  );

  @POST(path: '/teams/{teamId}/secrets', timeout: _timeout)
  Future<Response<void>> saveSecret(
    @Path('teamId') String teamId,
    @Body() Map<String, dynamic> body,
  );

  @GET(path: '/teams/{teamId}/secrets', timeout: _timeout)
  Future<Response<Map<String, dynamic>>> getSecrets(
    @Path('teamId') String teamId,
  );

  @GET(path: '/teams/{teamId}/secrets/{name}', timeout: _timeout)
  Future<Response<Map<String, dynamic>>> getSecretValue(
    @Path('teamId') String teamId,
    @Path('name') String name,
  );

  @POST(path: '/workers/heartbeat', timeout: _timeout)
  Future<Response<void>> sendHeartbeat(
    @Body() Map<String, dynamic> body,
  );

  @GET(path: '/builds/{id}/runs/{runId}/logs', timeout: _timeout)
  Future<Response<String>> getBuildJobLogs(
    @Path('id') String buildJobId,
    @Path('runId') String runId,
    @Query('limit') String? limit,
  );
}
