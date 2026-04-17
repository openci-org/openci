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
            h4([Component.text('会社情報')]),
            Component.element(
              tag: 'ul',
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
              children: [
                Component.element(
                  tag: 'li',
                  children: [
                    a(
                      [Component.text('X / Twitter')],
                      href: 'https://x.com/ma_freud',
                      target: Target.blank,
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
          ),
          p([Component.text('© OpenCI株式会社 ${DateTime.now().year}')]),
        ]),
      ]),
    ]);
  }
}
