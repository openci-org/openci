import 'package:jaspr/server.dart';

import 'html.dart';

Component codeThemeToggle({required String initialTheme}) => el(
  'div',
  cls: 'd-code-theme-toggle',
  attrs: {'role': 'group', 'aria-label': 'コードサンプルの背景'},
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
