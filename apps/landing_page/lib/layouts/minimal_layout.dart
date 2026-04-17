import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_content/jaspr_content.dart';

class MinimalLayout extends PageLayoutBase {
  const MinimalLayout();

  @override
  Pattern get name => 'minimal';

  @override
  Iterable<Component> buildHead(Page page) sync* {
    yield* super.buildHead(page);
    yield link(
      rel: 'stylesheet',
      href:
          'https://fonts.googleapis.com/css2?family=Inter:wght@100;200;300;400;500;600;700;800;900&display=swap',
    );
    yield link(
      rel: 'icon',
      href: '/favicon.png',
      type: 'image/png',
    );
    yield Style(styles: [
      css('*, *::before, *::after').styles(
        boxSizing: .borderBox,
        margin: .zero,
        padding: .zero,
      ),
      css('html, body').styles(
        width: 100.percent,
        minHeight: 100.vh,
        fontFamily: const FontFamily.list(
            [FontFamily('Inter'), FontFamilies.sansSerif]),
        color: const Color('#1a1a1a'),
        backgroundColor: const Color('#fafafa'),
        raw: {
          '-webkit-font-smoothing': 'antialiased',
          '-moz-osx-font-smoothing': 'grayscale',
        },
      ),
      css('::selection').styles(
        backgroundColor: const Color('#1a1a1a'),
        color: const Color('#fafafa'),
      ),
      css('.minimal-layout').styles(
        display: Display.flex,
        alignItems: AlignItems.center,
        justifyContent: JustifyContent.center,
        minHeight: 100.vh,
      ),
      css('.minimal-content').styles(
        display: Display.flex,
        flexDirection: FlexDirection.column,
        alignItems: AlignItems.center,
        raw: {
          'gap': '0.4rem',
          'text-align': 'center',
        },
      ),
      css('.minimal-content h1').styles(
        color: const Color('#1a1a1a'),
        fontSize: 1.1.rem,
        fontWeight: FontWeight.w300,
        raw: {
          'letter-spacing': '0.08em',
        },
      ),
      css('.minimal-content p').styles(
        color: const Color('#888888'),
        fontSize: 0.85.rem,
        fontWeight: FontWeight.w300,
        raw: {
          'line-height': '2.2',
        },
      ),
      css('.minimal-content a').styles(
        color: const Color('#1a1a1a'),
        fontSize: 0.8.rem,
        fontWeight: FontWeight.w400,
        textDecoration: TextDecoration.none,
        raw: {
          'border-bottom': '1px solid #cccccc',
          'padding-bottom': '2px',
          'transition': 'border-color 0.2s ease',
        },
      ),
      css('.minimal-content a:hover').styles(
        raw: {
          'border-color': '#1a1a1a',
        },
      ),
    ]);
  }

  @override
  Component buildBody(Page page, Component child) {
    final isRedirect = page.data.page['redirect'] == true;

    if (isRedirect) {
      return RawText('''
<script>
(function() {
  var lang = navigator.language || navigator.userLanguage || '';
  if (lang.startsWith('ja')) {
    window.location.replace('/ja/');
  } else {
    window.location.replace('/en/');
  }
})();
</script>
''');
    }

    return div(classes: 'minimal-layout', [
      div(classes: 'minimal-content', [
        child,
      ]),
    ]);
  }
}
