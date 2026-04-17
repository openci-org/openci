import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

class StudioHeader extends StatelessComponent {
  const StudioHeader();

  @override
  Component build(BuildContext context) {
    return header(classes: 'studio-header', [
      div(classes: 'container', [
        // Logo wrapped in <a> with aria-label per ui.sh header guidelines
        a(
          [Component.text('OpenCI Studio')],
          href: '/studio/',
          classes: 'studio-logo',
          attributes: {'aria-label': 'ホームページ'},
        ),
        nav(classes: 'studio-nav', [
          a([Component.text('会社概要')], href: '/studio/about/'),
          // Navbar CTA is secondary to hero — uses smaller, secondary button style
          a([Component.text('お問い合わせ')],
              href: 'https://form.typeform.com/to/XIdO4iES',
              target: Target.blank,
              classes: 'cta-button inverted'),
        ]),
      ]),
    ]);
  }
}
