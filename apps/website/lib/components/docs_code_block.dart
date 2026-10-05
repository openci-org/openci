import 'dart:convert';

import 'package:jaspr/dom.dart' show RawText;
import 'package:jaspr/server.dart';
import 'package:jaspr_content/jaspr_content.dart';

import 'dart_code.dart';
import 'code_theme_toggle.dart';
import 'docs_icon.dart';
import 'html.dart';

class DocsCodeBlock extends CustomComponent {
  const DocsCodeBlock() : super.base();

  @override
  Component? create(Node node, NodesBuilder builder) {
    if (node case ElementNode(
      tag: 'pre',
      children: [ElementNode(tag: 'code', :final attributes)],
    )) {
      final isDart = attributes['class'] == 'language-dart';
      final source = node.innerText.trimRight();
      return el(
        'div',
        cls: 'code-block d-article-code d-code-surface',
        attrs: {'data-code-theme': 'light'},
        children: [
          el(
            'div',
            cls: 'd-doc-code-bar',
            children: [
              el(
                'span',
                children: [
                  docsIcon(isDart ? 'code' : 'terminal'),
                  Component.text(isDart ? 'Dart' : 'Terminal'),
                ],
              ),
              codeThemeToggle(initialTheme: 'light'),
              el(
                'button',
                attrs: {
                  'type': 'button',
                  'data-doc-copy': '',
                  'aria-label': 'コードをコピー',
                },
                children: [
                  docsIcon('copy'),
                  el('span', text: 'コピー'),
                ],
              ),
            ],
          ),
          el(
            'pre',
            children: [
              el(
                'code',
                children: [
                  RawText(
                    isDart
                        ? source.split('\n').map(highlightedDart).join('\n')
                        : htmlEscape.convert(source),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
    }
    return null;
  }
}
