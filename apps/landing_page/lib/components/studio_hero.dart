import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

class StudioHero extends StatelessComponent {
  const StudioHero();

  @override
  Component build(BuildContext context) {
    return section(classes: 'hero-section', [
      div(classes: 'container', [
        h1([
          Component.text('ビジネスを'),
          const br(),
          Component.text('成功に導くアプリを創る。'),
        ]),
        p([
          Component.text(
              'OpenCI Studioは、弊社代表青木の長年の経験・技術を活かして、ビジネスを成功に導くアプリを開発します。'),
          const br(),
          Component.text(
              'アプリ開発において、最も大切なのは技術ではなく、ビジネスが成功するかどうか。ここに重点を置き、開発、技術支援、コンサルティングを行います。'),
        ]),
        // Primary CTA — only one primary button per page
        a([Component.text('お問い合わせ')],
            href: 'https://form.typeform.com/to/XIdO4iES',
            target: Target.blank,
            classes: 'cta-button',
            attributes: {'style': 'margin-top: 1.75rem'}),
      ]),
    ]);
  }
}
