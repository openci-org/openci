import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_content/jaspr_content.dart';

import '../components/studio_header.dart';
import '../components/studio_footer.dart';
import '../components/studio_about_content.dart';
import '../components/studio_contact.dart';
import '../components/studio_styles.dart';

class StudioAboutLayout extends PageLayoutBase {
  const StudioAboutLayout();

  @override
  Pattern get name => 'studio-about';

  @override
  Iterable<Component> buildHead(Page page) sync* {
    yield* super.buildHead(page);
    yield link(
      rel: 'icon',
      href: '/favicon.png',
      type: 'image/png',
    );
    yield const StudioStyles();
    yield StudioStyles.responsiveStyles();
  }

  @override
  Component buildBody(Page page, Component child) {
    return div(classes: 'studio-page', [
      const StudioHeader(),
      main_([
        const StudioAboutContent(),
        const StudioContact(),
      ]),
      const StudioFooter(),
    ]);
  }
}
