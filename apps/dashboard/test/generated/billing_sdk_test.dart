import 'package:dashboard/generated/billing/billing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('billing context supports teams without purchases or accounts', () {
    final data = GetBillingContextData.fromJson({
      'account': null,
      'customer': null,
      'stripe': null,
      'checkout': null,
    });
    expect(data.account, isNull);
    expect(data.customer, isNull);
    expect(data.stripe, isNull);
    expect(data.checkout, isNull);
  });

  test('period allowances and account revisions preserve bigint precision', () {
    final data = GetBillingPeriodData.fromJson({
      'period': {
        'id': 'period',
        'teamId': 'team',
        'planId': 'pro',
        'periodType': 'paid',
        'startsAt': '1000',
        'endsAt': '2000',
        'allowanceSeconds': '9007199254740993',
      },
    });
    expect(data.period!.allowanceSeconds, BigInt.parse('9007199254740993'));
    expect(data.period!.toJson()['allowanceSeconds'], '9007199254740993');
    final context = GetBillingContextData.fromJson({
      'account': {'usageRevision': '9007199254740994'},
    });
    expect(context.account!.usageRevision, BigInt.parse('9007199254740994'));
  });

  test('native SQL usage and recovery values retain strings and nulls', () {
    final usage = {
      'revision': '9007199254740993',
      'availableMillis': '9007199254740994000',
      'measurementIncomplete': false,
    };
    final data = GetBillingPeriodUsageData.fromJson({'usage': usage});
    expect(data.usage!.toJson(), usage);
    expect(GetBillingPeriodUsageData.fromJson({'usage': null}).usage, isNull);
    final recovery = GetExpiredBillingWorkData.fromJson({
      'billingExecutions': [],
      'admissions': [
        {'id': 'admission', 'teamId': 'team', 'runId': null},
      ],
    });
    expect(recovery.admissions!.single.toJson(), {
      'id': 'admission',
      'teamId': 'team',
      'runId': null,
    });
  });

  test('team deletion returns nullable OAuth references for cleanup', () {
    final data = DeleteBillingTeamData.fromJson({
      'receipt': {'teamId': 'team'},
      'billingAccount_upsert': {'teamId': 'team'},
      'team_delete': {'id': 'team'},
      'cleanup': {
        'secrets': [
          {
            'secretVersionPath':
                'projects/demo-openci/secrets/token/versions/1',
          },
        ],
        'requests': [],
        'sessions': [
          {'accessTokenSecretVersionPath': null},
        ],
      },
    });
    expect(data.team_delete!.id, 'team');
    expect(
      data.cleanup!.secrets.single.secretVersionPath,
      endsWith('/versions/1'),
    );
    expect(data.cleanup!.sessions.single.accessTokenSecretVersionPath, isNull);
  });
}
