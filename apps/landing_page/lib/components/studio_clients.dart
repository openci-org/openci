import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

class StudioClients extends StatelessComponent {
  const StudioClients();

  @override
  Component build(BuildContext context) {
    return section(classes: 'clients-section', [
      div(classes: 'container', [
        div(classes: 'section-intro', [
          // No uppercase eyebrow
          div(classes: 'eyebrow', [Component.text('実績')]),
          h2([Component.text('長期的なパートナーシップを大切にしています。')]),
          p([
            Component.text(
                'お客様との信頼関係を第一に考え、多くのプロジェクトで継続的にご支援しています。'
                '以下は現在進行中の案件の一部です。'),
          ]),
        ]),
        div(classes: 'clients-grid', [
          _clientCard(
            label: '技術顧問 · 継続2年以上',
            title: '大手外資系企業 / 東証プライム上場企業',
            description:
                'モバイルアプリケーションの技術顧問として、アーキテクチャ設計や開発チームの体制構築を支援。'
                '新技術のR&D・技術検証も担当し、プロダクトの技術的な意思決定をサポートしています。',
            isLongTerm: true,
          ),
          _clientCard(
            label: '技術顧問 · 継続2年以上',
            title: 'スポーツテック系スタートアップ',
            description:
                '甲子園常連の強豪校や大手企業をクライアントに持つスポーツテック企業の技術顧問。'
                'アスリート向けプラットフォームの設計支援および開発を行っています。',
            isLongTerm: true,
          ),
          _clientCard(
            label: '技術顧問',
            title: 'エンターテインメント系スタートアップ',
            description:
                '大手芸能プロダクションと連携し、著名アーティストのファン向けチケットシステムの技術顧問を担当。'
                '設計レビューに加え、一部開発にも携わっています。',
          ),
          _clientCard(
            label: '技術顧問',
            title: 'ヘルスケア系スタートアップ',
            description:
                'パーソナルコーチング領域のモバイルアプリケーション開発における技術顧問。'
                'アーキテクチャ設計やUI/UX改善のアドバイスを提供しています。',
          ),
        ]),
      ]),
    ]);
  }

  static Component _clientCard({
    String? label,
    required String title,
    required String description,
    bool isLongTerm = false,
  }) {
    return div(classes: 'client-card${isLongTerm ? ' long-term' : ''}', [
      if (label != null)
        div(classes: 'client-badge', [Component.text(label)]),
      h3([Component.text(title)]),
      p([Component.text(description)]),
    ]);
  }
}
