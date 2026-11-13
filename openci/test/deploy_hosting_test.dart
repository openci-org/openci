import 'package:test/test.dart';

import '../tool/deploy_hosting.dart';

void main() {
  const mergeCommit =
      'tree aaaa\nparent bbbb\nparent cccc\n\nMerge cccc into bbbb';
  const refs = 'dddd\trefs/pull/39/merge\ncccc\trefs/pull/39/head\n';

  test('reuses the PR channel when only the base changed', () {
    expect(previewChannel('dddd', mergeCommit, refs), 'openci-ci-pr-39');
    expect(previewChannel('eeee', mergeCommit, refs), 'openci-ci-pr-39');
  });

  test('a stale checkout cannot fall through to a live release', () {
    expect(
      previewChannel('eeee', mergeCommit, 'cccc\trefs/pull/39/head'),
      isNull,
    );
    expect(
      previewChannel('eeee', mergeCommit, refs.replaceAll('cccc', 'ffff')),
      isNull,
    );
    expect(
      () => previewChannel('eeee', 'tree aaaa\nparent bbbb', refs),
      throwsStateError,
    );
  });

  test('only the exact merge can disambiguate two PRs with the same head', () {
    const shared = '${refs}eeee\trefs/pull/40/merge\ncccc\trefs/pull/40/head';
    expect(previewChannel('eeee', mergeCommit, shared), 'openci-ci-pr-40');
    expect(() => previewChannel('ffff', mergeCommit, shared), throwsStateError);
  });

  Map<String, String> channel(String id, [String? expiry]) => {
    'name': 'projects/test/sites/test/channels/$id',
    'expireTime': ?expiry,
  };
  final fullSite = [
    channel('live'),
    for (var i = 0; i < 18; i++) channel('manual-$i'),
    channel('openci-ci-pr-1', '2026-01-01T00:00:00.100Z'),
    channel('openci-ci-pr-2', '2026-01-01T00:00:00Z'),
  ];
  test(
    'an existing PR takes no new slot and the oldest owned preview makes room for a new PR',
    () {
      expect(channelsToRemove(fullSite, 'openci-ci-pr-1'), isEmpty);
      expect(channelsToRemove(fullSite, 'openci-ci-pr-3'), ['openci-ci-pr-2']);
    },
  );
  test(
    'the budget counts foreign previews and protects live and the current PR',
    () {
      expect(
        channelsToRemove([...fullSite, channel('other')], 'openci-ci-pr-2'),
        ['openci-ci-pr-1'],
      );
      expect(
        () => channelsToRemove([
          for (var i = 0; i < previewBudget; i++) channel('manual-$i'),
          channel('openci-ci-pr-custom'),
          channel('live'),
        ], 'openci-ci-pr-39'),
        throwsStateError,
      );
    },
  );
}
