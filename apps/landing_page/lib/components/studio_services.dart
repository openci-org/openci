import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

class StudioServices extends StatelessComponent {
  const StudioServices();

  @override
  Component build(BuildContext context) {
    return section(classes: 'services-section', [
      div(classes: 'container', [
        div(classes: 'section-intro', [
          div(classes: 'eyebrow', [Component.text('提供サービス')]),
          h2([Component.text('個人開発規模から大規模なものまで、なんでもお任せください。')]),
          p([
            Component.text(
                'OpenCI Studioは、数人規模の会社から大手外資系企業まで、様々な規模のプロジェクトに参画し、結果を残してきました。'),
          ]),
        ]),
        div(classes: 'services-grid', [
          _serviceItem(
            'iOS+Androidアプリ開発 (Flutter)',
            'Googleが開発した世界で最も使用されているクロスプラットフォームフレームワークの1つである、Flutterを使用し、アプリ開発を行います。'
                '毎月の稼働時間を決め、その中で稼働時間に応じて時給で請求します。'
                '弊社代表青木が責任を持って開発をします。外部委託はいたしません。',
          ),
          _serviceItem(
            'Flutter開発の技術支援 (技術顧問)',
            '弊社代表青木が、Flutter開発の技術顧問として、お客様のプロジェクトに参画し、技術的な課題を解決します。'
                'チーム規模に応じて毎月一定額の請求を行います。質問はSlackやHuddleでお受けします。回数は無制限です。'
                'また毎週の定例に参加します。東京近辺であれば、現地参加も可能です。',
          ),
          _serviceItem(
            'CI/CDの導入支援',
            'お客様のプロジェクトに、CI/CDを導入し、ビルド、テスト、リリースを自動化します。'
                'また、各種テストコードの追加も必要に応じて行います。',
          ),
          _serviceItem(
            'AI開発の技術支援 (技術顧問)',
            '弊社代表青木が、AI開発の技術顧問として、お客様のプロジェクトに参画し、技術力・デリバリスピードの改善を行います。'
                'こちらもFlutter開発の技術支援と同様に、チーム規模に応じて毎月一定額の請求を行います。'
                '質問はSlackやHuddleでお受けします。回数は無制限です。',
          ),
        ]),
      ]),
    ]);
  }

  static Component _serviceItem(String title, String description) {
    return div(classes: 'service-item', [
      h3([Component.text(title)]),
      p([Component.text(description)]),
    ]);
  }
}
