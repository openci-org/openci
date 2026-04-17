import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

class StudioAboutContent extends StatelessComponent {
  const StudioAboutContent();

  @override
  Component build(BuildContext context) {
    return Component.fragment([
      section(classes: 'about-section', [
        div(classes: 'container', [
          div(classes: 'about-eyebrow', [Component.text('会社概要')]),
          h1([Component.text('代表挨拶')]),
          p([Component.text('アプリ開発を通じて、よりよい世界を創る。')]),
          div(classes: 'about-body', [
            p([
              Component.text(
                  '初めまして。OpenCI（オープンシーアイ）株式会社の代表取締役社長、青木正浩です。'),
              const br(),
              Component.text('この度は弊社のサイトをご覧いただき、ありがとうございます。'),
            ]),
            p([
              Component.text(
                  '国際基督教大学（ICU）を卒業後、2019年8月にゲーマー向けマッチングアプリの共同創業者兼CTOとして'
                  'アプリ開発のキャリアをスタートしました。VCからの資金調達を経て約3年間プロダクト開発に携わった後、'
                  'いくつかのプロジェクトを経験し、日本IBMに入社。大手銀行や大手海運企業のアプリ開発に従事しました。'),
            ]),
            p([
              Component.text(
                  'これらの経験と並行して、Flutterコミュニティでも積極的に活動してきました。'
                  'FlutterCon（ドイツ・ベルリン）、Flutter Connection（フランス・パリ）、'
                  'FlutterFormosa（台湾・台北）、State of Open Con（イギリス・ロンドン）での登壇のほか、'
                  'Google公認のFlutterミートアップ「Flutter Tokyo」のオーガナイザー、'
                  '日本最大級のFlutterカンファレンス「FlutterKaigi」の運営メンバーとしても活動しています。'),
            ]),
            p([
              Component.text(
                  'こうした開発の現場での経験を通じて、既存のCI/CDサービスに大きな課題があることを実感しました。'
                  '使いづらさと高額な料金により、多くのプロジェクトがCI/CDを十分に活用できていません。'
                  '誰もが使いやすいCI/CDを届けたい——その想いからIBMを退職し、OpenCI株式会社を設立しました。'),
            ]),
            p([
              Component.text(
                  'OpenCIでは、OSSとしてCI/CDプラットフォームを開発しています。'
                  'すべての開発者が効率的に開発できる環境を提供することが私たちの目標です。'),
              const br(),
              Component.text('ご興味のある方は、'),
              a([Component.text('OpenCIのGitHub')],
                  href: 'https://github.com/open-ci-io/openci',
                  target: Target.blank,
                  attributes: {'rel': 'noopener noreferrer'}),
              Component.text('をご覧ください。'),
            ]),
            p([
              Component.text(
                  'また、OpenCI Studio（以下Studio）では、これまで培ってきたFlutter開発の技術と経験を活かし、'
                  '技術支援サービスを提供しています。'
                  '小規模なプロジェクトから大規模なエンタープライズアプリまで幅広くサポートいたします。'),
            ]),
            p([
              Component.text(
                  'Studioでは単なる技術支援にとどまらず、CTOとしての経験、スタートアップでの事業立ち上げ、'
                  '大企業でのプロジェクト推進の知見を総合的に活かし、お客様のビジネスをサポートします。'
                  '技術的な課題解決はもちろん、チーム体制の構築や開発プロセスの改善まで、'
                  'ビジネスの成功に必要なあらゆる面でお手伝いいたします。'),
            ]),
          ]),
        ]),
      ]),

      // Team section
      section(classes: 'team-section', [
        div(classes: 'container', [
          h2([Component.text('代表者')]),
          div(classes: 'team-card', [
            img(
              src: '/images/team/masahiro-aoki.jpg',
              alt: 'Masahiro Aoki - OpenCI Studio 代表取締役',
              classes: 'team-card-image',
            ),
            div(classes: 'team-card-info', [
              h3([Component.text('Masahiro Aoki (青木 正浩)')]),
              p([Component.text('Founder / CEO')]),
            ]),
          ]),
        ]),
      ]),
    ]);
  }
}
