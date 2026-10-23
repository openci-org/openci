import 'package:jaspr/server.dart';

import 'html.dart';

class Pricing extends StatelessComponent {
  const Pricing({super.key});

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
              Component.text('チームに合った、'),
              el('br'),
              Component.text('シンプルな料金。'),
            ],
          ),
          el(
            'p',
            text: 'Apple Siliconで動くGenuineCI Cloud。個人開発からチーム開発まで、必要な実行時間で選べます。',
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
              description: '個人開発や、小さく始めるチームに。',
            ),
            (
              name: 'Pro',
              price: '100',
              minutes: '6,000',
              description: '毎日のビルドを、チームでしっかり。',
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
                    el('span', cls: 'pricing-period', text: '/ 月・チーム'),
                  ],
                ),
                el(
                  'p',
                  cls: 'pricing-allowance',
                  children: [
                    icon('clock'),
                    el('strong', text: '${plan.minutes}分'),
                    el('span', text: '/ 月のCI実行時間'),
                  ],
                ),
                el(
                  'ul',
                  cls: 'check-list pricing-features',
                  children: [
                    for (final feature in [
                      'Apple SiliconのMacで実行',
                      'チーム全員で利用時間を共有',
                      'プランによる同時実行数制限なし',
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
                    'aria-label': '${plan.name}プランをダッシュボードで選ぶ',
                  },
                  children: [
                    el('span', text: 'ダッシュボードで選ぶ'),
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
        text: 'Webダッシュボードでチームを選び、「設定 → 課金を管理」からお申し込みください。初回から決済が発生します。',
      ),
      el(
        'ul',
        cls: 'pricing-notes',
        children: [
          el(
            'li',
            text: '利用枠は毎月の請求期間ごとに適用されます。各ジョブの実行時間を合算し、キューや依存ジョブの待ち時間は含みません。',
          ),
          el('li', text: 'プラン・チーム単位の同時実行数制限はありません。実際の開始時刻は、ワーカーの空き状況によります。'),
          el(
            'li',
            text: '利用枠を使い切ると新しいCIの開始を止めます。実行中のジョブは完了まで継続し、追加の従量料金は発生しません。',
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
              el('h3', text: '7日間返金保証'),
              el('p', text: 'まずは、いつものプロジェクトで。'),
            ],
          ),
          el(
            'div',
            children: [
              el('p', text: '初回決済の成功から168時間以内の申請で全額返金します。更新・再契約は対象外です。'),
              el(
                'details',
                children: [
                  el('summary', text: '返金時の取り扱い・申請先'),
                  el(
                    'p',
                    text:
                        '返金時は即時解約となり、新しいCIは開始できません。実行中のCIは完了まで継続します。チーム名を添えて、メールでご連絡ください。',
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
          el('p', text: '自分のマシンで動かすなら、セルフホストも。Cloudの料金は適用されません。'),
          link(
            'セルフホストのガイド',
            '/docs/self-hosting/',
            cls: 'text-link',
            arrow: 'arrow',
          ),
        ],
      ),
    ],
  );
}
