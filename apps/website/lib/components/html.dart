import 'package:jaspr/dom.dart' show RawText;
import 'package:jaspr/server.dart';

Component el(
  String tag, {
  String? cls,
  String? id,
  String? text,
  Map<String, String>? attrs,
  List<Component> children = const [],
}) => Component.element(
  tag: tag,
  classes: cls,
  id: id,
  attributes: attrs,
  children: [if (text != null) Component.text(text), ...children],
);

Component icon(String name, {String? cls}) {
  const paths = {
    'arrow': '<path d="M5 12h14M13 6l6 6-6 6"/>',
    'external': '<path d="M7 17 17 7M7 7h10v10"/>',
    'check': '<path d="m5 12 4 4L19 6"/>',
    'branch': '<circle cx="6" cy="5" r="2"/><circle cx="6" cy="19" r="2"/><circle cx="18" cy="6" r="2"/><path d="M6 7v10m0-3c8 0 12-1 12-6"/>',
    'box': '<path d="m12 3 9 5v9l-9 5-9-5V8l9-5Zm0 10v9M3 8l9 5 9-5M8 5l9 5"/>',
    'terminal': '<path d="m5 7 5 5-5 5m8 0h6"/>',
    'grid': '<rect x="3" y="3" width="7" height="7" rx="1"/><rect x="14" y="3" width="7" height="7" rx="1"/><rect x="3" y="14" width="7" height="7" rx="1"/><rect x="14" y="14" width="7" height="7" rx="1"/>',
    'cpu': '<rect x="6" y="6" width="12" height="12" rx="2"/><path d="M9 3v3m6-3v3M9 18v3m6-3v3M3 9h3m-3 6h3m12-6h3m-3 6h3"/><rect x="9" y="9" width="6" height="6"/>',
    'layers':
        '<path d="m12 3 10 6-10 6L2 9l10-6ZM2 13l10 6 10-6M2 17l10 6 10-6"/>',
    'clock': '<circle cx="12" cy="12" r="9"/><path d="M12 6v6l4 2"/>',
    'play': '<path d="m9 5 11 7-11 7V5Z"/>',
  };
  return el(
    'svg',
    cls: 'icon ${cls ?? ''}',
    attrs: {
      'viewBox': '0 0 24 24',
      'fill': 'none',
      'stroke': 'currentColor',
      'stroke-width': '1.6',
      'stroke-linecap': 'round',
      'stroke-linejoin': 'round',
      'aria-hidden': 'true',
    },
    children: [RawText(paths[name] ?? paths['arrow']!)],
  );
}

Component link(String label, String href, {String cls = '', String? arrow}) =>
    el(
      'a',
      cls: cls,
      attrs: {'href': href},
      children: [
        el('span', text: label),
        if (arrow != null) icon(arrow),
      ],
    );

Component label(String number, String title) => el(
  'div',
  cls: 'section-label',
  children: [
    el('span', cls: 'section-number', text: number),
    el('span', text: title),
  ],
);
