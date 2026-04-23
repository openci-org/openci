import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_content/jaspr_content.dart';

class RedirectLayout extends PageLayoutBase {
  const RedirectLayout();

  @override
  Pattern get name => 'redirect';

  @override
  Iterable<Component> buildHead(Page page) sync* {
    yield* super.buildHead(page);
    yield link(rel: 'icon', href: '/favicon.png', type: 'image/png');
  }

  @override
  Component buildBody(Page page, Component child) {
    return div([
      RawText(
        '<script>'
        '(function(){'
        'var lang=navigator.language||navigator.userLanguage||"en";'
        'if(lang.toLowerCase().startsWith("ja")){'
        'window.location.replace("/ja/");'
        '}else{'
        'window.location.replace("/en/");'
        '}'
        '})();'
        '</script>',
      ),
      RawText(
        '<noscript>'
        '<p><a href="/en/">English</a> | <a href="/ja/">日本語</a></p>'
        '</noscript>',
      ),
    ]);
  }
}
