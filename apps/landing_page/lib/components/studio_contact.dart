import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

class StudioContact extends StatelessComponent {
  const StudioContact();

  @override
  Component build(BuildContext context) {
    return section(classes: 'contact-section', [
      div(classes: 'container', [
        div(classes: 'contact-inner', [
          h2([
            Component.text('お気軽にご相談ください。'),
            const br(),
            Component.text('何度相談していただいても、'),
            const br(),
            Component.text('相談料は無料です。'),
          ]),
          a([Component.text('お問い合わせ')],
              href: 'https://form.typeform.com/to/XIdO4iES',
              target: Target.blank,
              classes: 'cta-button inverted'),
          div(classes: 'contact-offices', [
            h3([Component.text('会社情報')]),
            div([
              p([
                strong([Component.text('OpenCI株式会社')]),
              ]),
              p([
                Component.text(
                    '東京都渋谷区道玄坂1丁目10番8号渋谷道玄坂東急ビル2F-C'),
              ]),
              p([
                Component.text('法人番号: 8011001159197'),
              ]),
              p([
                Component.text('資本金: 100万円'),
              ]),
            ]),
          ]),
        ]),
      ]),
    ]);
  }
}
