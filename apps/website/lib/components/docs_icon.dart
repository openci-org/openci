import 'package:jaspr/dom.dart' show RawText;
import 'package:jaspr/server.dart';

import 'html.dart';

Component docsIcon(String name) {
  const paths = {
    'book': '<path d="M12 6c-3-2-6-2-9-1v14c3-1 6-1 9 1 3-2 6-2 9-1V5c-3-1-6-1-9 1Zm0 0v14"/>',
    'spark': '<path d="m12 3 2.6 6.4L21 12l-6.4 2.6L12 21l-2.6-6.4L3 12l6.4-2.6L12 3Z"/>',
    'arrow': '<path d="M4 12h15m-6-6 6 6-6 6"/>',
    'external': '<path d="M14 4h6v6M20 4 10 14M10 4H4v16h16v-6"/>',
    'code': '<path d="m7 6-6 6 6 6m10-12 6 6-6 6M14 3l-4 18"/>',
    'terminal': '<rect x="2" y="4" width="20" height="16" rx="3"/><path d="m6 9 3 3-3 3m7 0h5"/>',
    'branch': '<circle cx="6" cy="5" r="2"/><circle cx="6" cy="19" r="2"/><circle cx="18" cy="6" r="2"/><path d="M6 7v10m0-3c8 0 12-1 12-6"/>',
    'box': '<path d="m12 3 9 5v9l-9 5-9-5V8l9-5Zm0 10v9M3 8l9 5 9-5M8 5l9 5"/>',
    'lock': '<rect x="4" y="10" width="16" height="11" rx="2"/><path d="M8 10V7a4 4 0 0 1 8 0v3m-4 5v2"/>',
    'server': '<rect x="3" y="3" width="18" height="7" rx="2"/><rect x="3" y="14" width="18" height="7" rx="2"/><path d="M7 6.5h.01M7 17.5h.01M16 6.5h2m-2 11h2"/>',
    'search': '<circle cx="10.5" cy="10.5" r="6.5"/><path d="m16 16 5 5"/>',
    'chevron': '<path d="m9 5 7 7-7 7"/>',
    'check': '<path d="m5 12 4 4L19 6"/>',
    'copy': '<rect x="8" y="8" width="12" height="13" rx="2"/><path d="M16 8V3H3v13h5"/>',
    'github': '<path d="M9 20c-5 1.5-5-2.5-7-3m14 5v-3.9c0-1.1-.4-1.9-1-2.4 3.3-.4 6.7-1.6 6.7-7.3 0-1.6-.6-2.9-1.5-4 .1-.4.6-1.9-.2-4-1.3-.4-4.2 1.5-4.2 1.5a14.2 14.2 0 0 0-7.6 0S5.3 0 4 1c-.8 2.1-.3 3.6-.2 4C2.9 6.1 2.3 7.4 2.3 9c0 5.7 3.4 6.9 6.7 7.3-.5.4-.9 1.1-1 2.1V22" transform="translate(1 1) scale(.9)"/>',
    'menu': '<path d="M4 6h16M4 12h16M4 18h16"/>',
    'close': '<path d="m6 6 12 12M6 18 18 6"/>',
    'list': '<path d="M9 5h12M9 12h12M9 19h12M3 5h.01M3 12h.01M3 19h.01"/>',
  };
  return el(
    'svg',
    cls: 'd-icon',
    attrs: {
      'viewBox': '0 0 24 24',
      'fill': 'none',
      'stroke': 'currentColor',
      'stroke-width': '1.6',
      'stroke-linecap': 'round',
      'stroke-linejoin': 'round',
      'aria-hidden': 'true',
    },
    children: [RawText(paths[name] ?? paths['book']!)],
  );
}

Component docLines(String tag, {String? cls, required String text}) {
  final lines = text.split('\n');
  return el(
    tag,
    cls: cls,
    children: [
      for (var i = 0; i < lines.length; i++) ...[
        if (i > 0) el('br'),
        Component.text(lines[i]),
      ],
    ],
  );
}
