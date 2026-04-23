/// The entrypoint for the **server** environment.
library;

import 'package:jaspr/server.dart';
import 'package:jaspr_content/jaspr_content.dart';

import 'layouts/cicd_layout.dart';
import 'layouts/minimal_layout.dart';
import 'layouts/redirect_layout.dart';
import 'layouts/studio_about_layout.dart';
import 'layouts/studio_layout.dart';
import 'main.server.options.dart';

void main() {
  Jaspr.initializeApp(options: defaultServerOptions);

  runApp(
    ContentApp(
      parsers: [MarkdownParser()],
      layouts: [
        CicdLayout(),
        MinimalLayout(),
        RedirectLayout(),
        StudioAboutLayout(),
        StudioLayout(),
      ],
    ),
  );
}
