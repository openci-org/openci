import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

class StudioHeader extends StatelessComponent {
  const StudioHeader();

  @override
  Component build(BuildContext context) {
    return header(classes: 'studio-header', [
      div(classes: 'container', [
        a([Component.text('OpenCI Studio')],
            href: '/studio/', classes: 'studio-logo'),
        nav(classes: 'studio-nav', [
          a([Component.text('会社概要')], href: '/studio/about/'),
          a([Component.text('お問い合わせ')],
              href: 'https://form.typeform.com/to/XIdO4iES',
              target: Target.blank,
              classes: 'cta-button'),
        ]),
      ]),
    ]);
  }
}
