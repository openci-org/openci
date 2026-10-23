import 'package:jaspr/server.dart';

import '../l10n/site_locale.dart';
import 'html.dart';

Component codeThemeToggle({
  required SiteLocale locale,
  required String initialTheme,
}) => el(
  'div',
  cls: 'd-code-theme-toggle',
  attrs: {
    'role': 'group',
    'aria-label': locale.text('コードサンプルの背景', 'Code sample background'),
  },
  children: [
    for (final theme in ['light', 'dark'])
      el(
        'button',
        attrs: {
          'type': 'button',
          'data-code-theme-choice': theme,
          'aria-pressed': '${theme == initialTheme}',
        },
        text: theme == 'light' ? 'Light' : 'Dark',
      ),
  ],
);
