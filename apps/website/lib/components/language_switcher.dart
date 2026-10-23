import 'package:jaspr/server.dart';

import '../l10n/site_locale.dart';
import 'html.dart';

Component languageSwitcher(
  SiteLocale locale,
  Map<SiteLocale, String> translations,
) => el(
  'nav',
  cls: 'language-switcher',
  attrs: {'aria-label': locale.text('言語を選択', 'Select language')},
  children: [
    for (final language in SiteLocale.values)
      if (translations[language] case final path?)
        el(
          'a',
          text: language.label,
          attrs: {
            'href': path,
            'lang': language.name,
            'hreflang': language.name,
            'data-language-link': '',
            if (language == locale) 'aria-current': 'page',
          },
        )
      else
        el(
          'span',
          text: language.label,
          attrs: {
            'lang': language.name,
            'aria-disabled': 'true',
            'title': locale.text(
              'このページの翻訳は準備中です',
              'This translation is not available yet',
            ),
          },
        ),
  ],
);
