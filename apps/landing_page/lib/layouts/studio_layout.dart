import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_content/jaspr_content.dart';

import '../components/studio_header.dart';
import '../components/studio_footer.dart';
import '../components/studio_hero.dart';
import '../components/studio_services.dart';
import '../components/studio_testimonial.dart';
import '../components/studio_clients.dart';
import '../components/studio_pricing.dart';
import '../components/studio_contact.dart';
import '../components/studio_styles.dart';

class StudioLayout extends PageLayoutBase {
  const StudioLayout();

  @override
  Pattern get name => 'studio';

  @override
  Iterable<Component> buildHead(Page page) sync* {
    yield* super.buildHead(page);
    yield link(
      rel: 'stylesheet',
      href:
          'https://fonts.googleapis.com/css2?family=Inter:wght@100;200;300;400;500;600;700;800;900&display=swap',
    );
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
        const StudioHero(),
        const StudioServices(),
        const StudioTestimonial(),
        const StudioClients(),
        const StudioPricing(),
        const StudioContact(),
      ]),
      const StudioFooter(),
    ]);
  }
}
