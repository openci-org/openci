# Basic Usage

```dart
final builds = BuildsConnector.instance;
await builds.getBuildJobs(teamId: teamId).execute();
await builds.getBuildJob(id: jobId).execute();
await builds.retryBuildJob(id: jobId, expectedRetryCount: retryCount).execute();
```

## Find jobs by pull request or commit

Pass a pull request number, a full commit SHA, or both to `findBuildJobs` before calling `execute()`.

```dart
final search = BuildsConnector.instance.findBuildJobs(
  teamId: teamId,
  githubBaseUrl: 'https://github.com',
  owner: owner,
  repo: repo,
);
final result = await search.pullRequestNumber(BigInt.from(42)).execute();
```
