import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

class _PricingTier {
  final String id;
  final String name;
  final String price;
  final String? period;
  final String description;
  final List<String> features;
  final bool featured;
  final String cta;
  final bool unavailable;
  final String? unavailableNote;

  const _PricingTier({
    required this.id,
    required this.name,
    required this.price,
    this.period,
    required this.description,
    required this.features,
    this.featured = false,
    required this.cta,
    this.unavailable = false,
    this.unavailableNote,
  });
}

const _tiers = [
  _PricingTier(
    id: 'flutter-app-development',
    name: 'アプリ開発 (Flutter)',
    price: '800,000円〜',
    period: '/月',
    description: 'Flutterを使用したアプリ開発を行います。',
    features: [
      '定例参加',
      '週1-2回のオフィスでの作業',
      'Flutterの開発',
      'コードレビュー',
    ],
    cta: '申し込む',
    unavailable: true,
    unavailableNote: '現在新規募集を停止しています。今後のご相談はお気軽にお問い合わせください。',
  ),
  _PricingTier(
    id: 'flutter-development-consulting',
    name: 'Flutter開発の技術支援 (技術顧問)',
    price: '300,000円〜',
    period: '/月',
    description: 'Flutter開発の技術支援を行います。',
    features: [
      '定例参加 (現地参加可)',
      '無制限の質問 (チャットおよび通話)',
      'コードレビュー',
    ],
    cta: '申し込む',
  ),
  _PricingTier(
    id: 'other',
    name: 'オーダーメイド',
    price: 'カスタム',
    description: '上記プランに当てはまらないご要望がありましたら、お気軽にお問い合わせください。',
    features: [
      '柔軟にご要望にお応え可能',
      'アプリ以外の開発',
      'AI開発の技術支援',
      'CI/CDの導入支援',
      'テストコードの追加',
    ],
    featured: true,
    cta: 'お問い合わせ',
  ),
];

class StudioPricing extends StatelessComponent {
  const StudioPricing();

  @override
  Component build(BuildContext context) {
    return section(classes: 'pricing-section', [
      div(classes: 'container', [
        // Left-aligned pricing header — consistent with page flow
        div(classes: 'pricing-header', [
          h2([Component.text('料金表')]),
          p([
            Component.text('価格は全て税抜きです。最低契約期間は3ヶ月、毎月最低稼動時間は100時間です。'),
          ]),
        ]),
        div(classes: 'pricing-grid', [
          for (final tier in _tiers) _buildPricingCard(tier),
        ]),
      ]),
    ]);
  }

  static Component _buildPricingCard(_PricingTier tier) {
    return div(
      classes:
          'pricing-card${tier.featured ? ' featured' : ''}${tier.unavailable ? ' unavailable' : ''}',
      [
        if (tier.unavailable)
          div(classes: 'unavailable-badge', [
            Component.text('現在募集停止中'),
          ]),
        h3([Component.text(tier.name)]),
        p(classes: 'description', [Component.text(tier.description)]),
        div(classes: 'price', [
          Component.text(tier.price),
          if (tier.period != null)
            span(classes: 'price-period', [Component.text(tier.period!)]),
        ]),
        Component.element(
          tag: 'ul',
          classes: 'features',
          attributes: {'role': 'list'},
          children: [
            for (final feature in tier.features)
              Component.element(
                tag: 'li',
                children: [Component.text(feature)],
              ),
          ],
        ),
        if (tier.unavailableNote != null)
          p(classes: 'unavailable-note', [
            Component.text(tier.unavailableNote!),
          ]),
        a(
          [Component.text(tier.unavailable ? 'ご相談はこちら' : tier.cta)],
          href: 'https://form.typeform.com/to/XIdO4iES',
          target: Target.blank,
          // All secondary buttons — primary is in the hero
          classes: 'cta-button inverted',
        ),
      ],
    );
  }
}
