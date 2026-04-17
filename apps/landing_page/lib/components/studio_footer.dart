import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

class StudioFooter extends StatelessComponent {
  const StudioFooter();

  @override
  Component build(BuildContext context) {
    return footer(classes: 'studio-footer', [
      div(classes: 'container', [
        div(classes: 'footer-grid', [
          div(classes: 'footer-column', [
            // No uppercase — ui.sh says use font-normal for footer headings
            h4([Component.text('会社情報')]),
            Component.element(
              tag: 'ul',
              attributes: {'role': 'list'},
              children: [
                Component.element(
                  tag: 'li',
                  children: [
                    a([Component.text('会社概要')], href: '/studio/about/'),
                  ],
                ),
              ],
            ),
          ]),
          div(classes: 'footer-column', [
            h4([Component.text('SNS')]),
            Component.element(
              tag: 'ul',
              attributes: {'role': 'list'},
              children: [
                Component.element(
                  tag: 'li',
                  children: [
                    a(
                      [Component.text('X / Twitter')],
                      href: 'https://x.com/ma_freud',
                      target: Target.blank,
                      attributes: {'rel': 'noopener noreferrer'},
                    ),
                  ],
                ),
                Component.element(
                  tag: 'li',
                  children: [
                    a(
                      [Component.text('LinkedIn')],
                      href:
                          'https://www.linkedin.com/in/masahiro-aoki-b68905163/',
                      target: Target.blank,
                      attributes: {'rel': 'noopener noreferrer'},
                    ),
                  ],
                ),
                Component.element(
                  tag: 'li',
                  children: [
                    a(
                      [Component.text('GitHub')],
                      href: 'https://github.com/open-ci-io',
                      target: Target.blank,
                      attributes: {'rel': 'noopener noreferrer'},
                    ),
                  ],
                ),
              ],
            ),
          ]),
        ]),
        div(classes: 'footer-bottom', [
          a(
            [Component.text('OpenCI Studio')],
            href: '/studio/',
            classes: 'studio-logo',
            attributes: {'aria-label': 'ホームページ'},
          ),
          p([Component.text('© OpenCI株式会社 ${DateTime.now().year}')]),
        ]),
      ]),
    ]);
  }
}
