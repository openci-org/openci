import 'package:jaspr/server.dart';

import '../l10n/localized_component.dart';
import 'html.dart';

class Pricing extends LocalizedComponent {
  const Pricing(super.locale, {super.key});

  @override
  Component build(BuildContext context) => el(
    'section',
    id: 'pricing',
    cls: 'section wrap pricing',
    attrs: {'aria-labelledby': 'pricing-title'},
    children: [
      label('03', 'PRICING'),
      el(
        'div',
        cls: 'section-heading',
        children: [
          el(
            'h2',
            id: 'pricing-title',
            children: [
              Component.text(t('チームに合った、', 'Simple pricing.')),
              el('br'),
              Component.text(t('シンプルな料金。', 'For your team.')),
            ],
          ),
          el(
            'p',
            text: t(
              'Apple Siliconで動くGenuineCI Cloud。個人開発からチーム開発まで、必要な実行時間で選べます。',
              'GenuineCI Cloud runs on Apple Silicon. Choose the build time you need, whether you work solo or with a team.',
            ),
          ),
        ],
      ),
      el(
        'div',
        cls: 'pricing-grid',
        children: [
          for (final plan in [
            (
              name: 'Light',
              price: '10',
              minutes: '600',
              description: t(
                '個人開発や、小さく始めるチームに。',
                'For solo developers and teams starting small.',
              ),
            ),
            (
              name: 'Pro',
              price: '100',
              minutes: '6,000',
              description: t(
                '毎日のビルドを、チームでしっかり。',
                'For teams building every day.',
              ),
            ),
          ])
            el(
              'article',
              cls: 'pricing-card ${plan.name == 'Pro' ? 'pricing-pro' : ''}',
              attrs: {'aria-labelledby': 'plan-${plan.name.toLowerCase()}'},
              children: [
                el(
                  'h3',
                  id: 'plan-${plan.name.toLowerCase()}',
                  text: plan.name,
                ),
                el('p', cls: 'pricing-description', text: plan.description),
                el(
                  'p',
                  cls: 'pricing-price',
                  children: [
                    el('span', cls: 'pricing-currency', text: 'US\$'),
                    el('strong', text: plan.price),
                    el(
                      'span',
                      cls: 'pricing-period',
                      text: t('/ 月・チーム', '/ month per team'),
                    ),
                  ],
                ),
                el(
                  'p',
                  cls: 'pricing-allowance',
                  children: [
                    icon('clock'),
                    el(
                      'strong',
                      text: t('${plan.minutes}分', '${plan.minutes} min'),
                    ),
                    el('span', text: t('/ 月のCI実行時間', '/ month of CI runtime')),
                  ],
                ),
                el(
                  'ul',
                  cls: 'check-list pricing-features',
                  children: [
                    for (final feature in [
                      t('Apple SiliconのMacで実行', 'Run on Apple Silicon Macs'),
                      t('チーム全員で利用時間を共有', 'Share runtime across your team'),
                      t('プランによる同時実行数制限なし', 'No plan-based concurrency limit'),
                    ])
                      el(
                        'li',
                        children: [icon('check'), Component.text(feature)],
                      ),
                  ],
                ),
                el(
                  'a',
                  cls: 'button button-dark',
                  attrs: {
                    'href': 'https://dashboard.openci.org/',
                    'aria-label': t(
                      '${plan.name}プランをダッシュボードで選ぶ',
                      'Choose ${plan.name} in the dashboard',
                    ),
                  },
                  children: [
                    el('span', text: t('ダッシュボードで選ぶ', 'Choose in dashboard')),
                    icon('external'),
                  ],
                ),
              ],
            ),
        ],
      ),
      el(
        'p',
        cls: 'pricing-signup',
        text: t(
          'Webダッシュボードでチームを選び、「設定 → 課金を管理」からお申し込みください。初回から決済が発生します。',
          'Select your team in the web dashboard, then open Settings → Manage billing to subscribe. Payment is taken when you subscribe.',
        ),
      ),
      el(
        'ul',
        cls: 'pricing-notes',
        children: [
          el(
            'li',
            text: t(
              '利用枠は毎月の請求期間ごとに適用されます。各ジョブの実行時間を合算し、キューや依存ジョブの待ち時間は含みません。',
              'The allowance applies to each monthly billing period. Usage is the sum of job runtime, excluding time spent in queues or waiting for dependencies.',
            ),
          ),
          el(
            'li',
            text: t(
              'プラン・チーム単位の同時実行数制限はありません。実際の開始時刻は、ワーカーの空き状況によります。',
              'There is no concurrency cap per plan or team. When jobs start depends on worker availability.',
            ),
          ),
          el(
            'li',
            text: t(
              '利用枠を使い切ると新しいCIの開始を止めます。実行中のジョブは完了まで継続し、追加の従量料金は発生しません。',
              'Once the allowance is used up, new CI runs are blocked. Running jobs can finish, and there are no overage charges.',
            ),
          ),
        ],
      ),
      el(
        'div',
        cls: 'pricing-guarantee',
        children: [
          el(
            'div',
            children: [
              el('h3', text: t('7日間返金保証', '7-day money-back guarantee')),
              el(
                'p',
                text: t('まずは、いつものプロジェクトで。', 'Try it with your own project.'),
              ),
            ],
          ),
          el(
            'div',
            children: [
              el(
                'p',
                text: t(
                  '初回決済の成功から168時間以内の申請で全額返金します。更新・再契約は対象外です。',
                  'Request a full refund within 168 hours of your first successful payment. Renewals and resubscriptions are excluded.',
                ),
              ),
              el(
                'details',
                children: [
                  el(
                    'summary',
                    text: t('返金時の取り扱い・申請先', 'Refund details and contact'),
                  ),
                  el(
                    'p',
                    text: t(
                      '返金時は即時解約となり、新しいCIは開始できません。実行中のCIは完了まで継続します。チーム名を添えて、メールでご連絡ください。',
                      'A refund cancels your subscription immediately and blocks new CI runs. Running jobs can finish. Email us with your team name to request a refund.',
                    ),
                  ),
                  link('m.aoki@openci.org', 'mailto:m.aoki@openci.org'),
                ],
              ),
            ],
          ),
        ],
      ),
      el(
        'div',
        cls: 'pricing-self-hosted',
        children: [
          el(
            'p',
            text: t(
              '自分のマシンで動かすなら、セルフホストも。Cloudの料金は適用されません。',
              'Prefer your own machines? You can self-host. Cloud pricing does not apply.',
            ),
          ),
          link(
            t('セルフホストのガイド', 'Self-hosting guide'),
            localPath('/docs/self-hosting/'),
            cls: 'text-link',
            arrow: 'arrow',
          ),
        ],
      ),
    ],
  );
}
