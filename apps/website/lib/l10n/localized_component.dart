import 'package:jaspr/server.dart';

import 'site_locale.dart';

abstract class LocalizedComponent extends StatelessComponent {
  const LocalizedComponent(this.locale, {super.key});

  final SiteLocale locale;

  String t(String japanese, String english) => locale.text(japanese, english);
  String localPath(String path) => locale.path(path);
}
