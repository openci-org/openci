import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

class StudioStyles extends StatelessComponent {
  const StudioStyles();

  @override
  Component build(BuildContext context) {
    return Style(styles: [
      // Reset & base
      css('*, *::before, *::after').styles(
        boxSizing: .borderBox,
        margin: .zero,
        padding: .zero,
      ),
      css('html, body').styles(
        width: 100.percent,
        minHeight: 100.vh,
        fontFamily: const FontFamily.list(
            [FontFamily('Inter'), FontFamilies.sansSerif]),
        color: const Color('#0a0a0a'),
        backgroundColor: Colors.white,
        raw: {
          '-webkit-font-smoothing': 'antialiased',
          '-moz-osx-font-smoothing': 'grayscale',
        },
      ),

      // Studio page wrapper
      css('.studio-page').styles(
        display: Display.flex,
        flexDirection: FlexDirection.column,
        minHeight: 100.vh,
        backgroundColor: Colors.white,
        color: const Color('#0a0a0a'),
      ),
      css('.studio-page main').styles(
        raw: {'flex': '1'},
      ),

      // Container
      css('.container').styles(
        width: 100.percent,
        maxWidth: 80.rem,
        margin: Margin.symmetric(horizontal: Unit.auto),
        padding: Padding.symmetric(horizontal: 1.5.rem),
      ),

      // Header
      css('.studio-header').styles(
        padding: Padding.symmetric(vertical: 1.5.rem),
        backgroundColor: const Color.rgba(255, 255, 255, 0.92),
        raw: {
          'position': 'sticky',
          'top': '0',
          'z-index': '50',
          'backdrop-filter': 'blur(12px)',
          '-webkit-backdrop-filter': 'blur(12px)',
          'border-bottom': '1px solid #e5e5e5',
        },
      ),
      css('.studio-header .container').styles(
        display: Display.flex,
        alignItems: AlignItems.center,
        raw: {'justify-content': 'space-between'},
      ),
      css('.studio-logo').styles(
        fontSize: 1.25.rem,
        fontWeight: FontWeight.w600,
        color: const Color('#0a0a0a'),
        textDecoration: TextDecoration.none,
        raw: {'letter-spacing': '-0.01em'},
      ),
      css('.studio-logo:hover').styles(
        raw: {'opacity': '0.7'},
      ),
      css('.studio-nav').styles(
        display: Display.flex,
        raw: {'gap': '2rem'},
        alignItems: AlignItems.center,
      ),
      css('.studio-nav a').styles(
        color: const Color('#525252'),
        textDecoration: TextDecoration.none,
        fontSize: 0.875.rem,
        fontWeight: FontWeight.w400,
        raw: {'transition': 'color 0.2s ease'},
      ),
      css('.studio-nav a:hover').styles(
        color: const Color('#0a0a0a'),
      ),
      css('a.cta-button').styles(
        display: Display.inlineBlock,
        padding: Padding.symmetric(horizontal: 1.25.rem, vertical: 0.625.rem),
        backgroundColor: const Color('#0a0a0a'),
        color: Colors.white,
        fontSize: 0.875.rem,
        fontWeight: FontWeight.w500,
        textDecoration: TextDecoration.none,
        raw: {
          'border-radius': '8px',
          'transition': 'background-color 0.2s ease',
        },
      ),
      css('a.cta-button:hover').styles(
        backgroundColor: const Color('#262626'),
        color: Colors.white,
      ),
      css('a.cta-button.inverted').styles(
        backgroundColor: Colors.white,
        color: const Color('#0a0a0a'),
        raw: {'border': '1px solid #d4d4d4'},
      ),
      css('a.cta-button.inverted:hover').styles(
        backgroundColor: const Color('#fafafa'),
        color: const Color('#0a0a0a'),
      ),

      // Hero section
      css('.hero-section').styles(
        padding: Padding.only(top: 8.rem, bottom: 6.rem),
      ),
      css('.hero-section h1').styles(
        fontSize: 3.5.rem,
        fontWeight: FontWeight.w500,
        color: const Color('#0a0a0a'),
        raw: {
          'line-height': '1.1',
          'letter-spacing': '-0.03em',
          'max-width': '48rem',
          'text-wrap': 'balance',
        },
      ),
      css('.hero-section p').styles(
        fontSize: 1.125.rem,
        color: const Color('#525252'),
        raw: {
          'line-height': '1.8',
          'margin-top': '1.5rem',
          'max-width': '42rem',
        },
      ),

      // Section intro
      css('.section-intro').styles(
        raw: {'max-width': '48rem'},
      ),
      css('.section-intro .eyebrow').styles(
        fontSize: 0.875.rem,
        fontWeight: FontWeight.w600,
        color: const Color('#737373'),
        raw: {
          'letter-spacing': '0.05em',
          'text-transform': 'uppercase',
          'margin-bottom': '0.75rem',
        },
      ),
      css('.section-intro h2').styles(
        fontSize: 2.25.rem,
        fontWeight: FontWeight.w500,
        color: const Color('#0a0a0a'),
        raw: {
          'line-height': '1.2',
          'letter-spacing': '-0.02em',
        },
      ),
      css('.section-intro p').styles(
        fontSize: 1.rem,
        color: const Color('#525252'),
        raw: {
          'line-height': '1.75',
          'margin-top': '1rem',
        },
      ),

      // Services section
      css('.services-section').styles(
        padding: Padding.symmetric(vertical: 6.rem),
        raw: {'border-top': '1px solid #e5e5e5'},
      ),
      css('.services-grid').styles(
        display: Display.grid,
        raw: {
          'grid-template-columns': 'repeat(auto-fit, minmax(280px, 1fr))',
          'gap': '1px',
          'margin-top': '3rem',
          'background': '#e5e5e5',
          'border': '1px solid #e5e5e5',
          'border-radius': '16px',
          'overflow': 'hidden',
        },
      ),
      css('.service-item').styles(
        padding: Padding.all(2.rem),
        backgroundColor: Colors.white,
      ),
      css('.service-item h3').styles(
        fontSize: 1.125.rem,
        fontWeight: FontWeight.w600,
        color: const Color('#0a0a0a'),
        raw: {
          'margin-bottom': '0.75rem',
          'letter-spacing': '-0.01em',
        },
      ),
      css('.service-item p').styles(
        fontSize: 0.875.rem,
        color: const Color('#525252'),
        raw: {'line-height': '1.7'},
      ),

      // Testimonial section
      css('.testimonial-section').styles(
        padding: Padding.symmetric(vertical: 6.rem),
        raw: {'border-top': '1px solid #e5e5e5'},
      ),
      css('.testimonial-quote').styles(
        fontSize: 1.75.rem,
        fontWeight: FontWeight.w400,
        color: const Color('#0a0a0a'),
        raw: {
          'line-height': '1.4',
          'letter-spacing': '-0.01em',
          'max-width': '48rem',
          'font-style': 'italic',
        },
      ),
      css('.testimonial-quote::before').styles(
        raw: {'content': '"\\201C"'},
      ),
      css('.testimonial-quote::after').styles(
        raw: {'content': '"\\201D"'},
      ),
      css('.testimonial-author').styles(
        raw: {'margin-top': '1.5rem'},
        fontSize: 0.9375.rem,
        color: const Color('#737373'),
      ),

      // Pricing section
      css('.pricing-section').styles(
        padding: Padding.symmetric(vertical: 6.rem),
        raw: {'border-top': '1px solid #e5e5e5'},
      ),
      css('.pricing-header').styles(
        raw: {'text-align': 'center', 'margin-bottom': '3rem'},
      ),
      css('.pricing-header h2').styles(
        fontSize: 1.75.rem,
        fontWeight: FontWeight.w600,
        color: const Color('#0a0a0a'),
        raw: {'letter-spacing': '-0.02em'},
      ),
      css('.pricing-header p').styles(
        fontSize: 0.9375.rem,
        color: const Color('#737373'),
        raw: {
          'margin-top': '0.75rem',
          'line-height': '1.7',
        },
      ),
      css('.pricing-grid').styles(
        display: Display.grid,
        raw: {
          'grid-template-columns': 'repeat(auto-fit, minmax(300px, 1fr))',
          'gap': '1px',
          'background': '#e5e5e5',
          'border': '1px solid #e5e5e5',
          'border-radius': '16px',
          'overflow': 'hidden',
        },
      ),
      css('.pricing-card').styles(
        padding: Padding.all(2.rem),
        backgroundColor: Colors.white,
      ),
      css('.pricing-card.featured').styles(
        backgroundColor: const Color('#fafafa'),
      ),
      css('.pricing-card h3').styles(
        fontSize: 1.125.rem,
        fontWeight: FontWeight.w600,
        color: const Color('#0a0a0a'),
        raw: {'letter-spacing': '-0.01em'},
      ),
      css('.pricing-card .price').styles(
        fontSize: 2.25.rem,
        fontWeight: FontWeight.w600,
        color: const Color('#0a0a0a'),
        raw: {
          'margin-top': '1rem',
          'letter-spacing': '-0.02em',
        },
      ),
      css('.pricing-card .price-period').styles(
        fontSize: 0.875.rem,
        fontWeight: FontWeight.w400,
        color: const Color('#737373'),
      ),
      css('.pricing-card .description').styles(
        fontSize: 0.875.rem,
        color: const Color('#525252'),
        raw: {
          'margin-top': '0.75rem',
          'line-height': '1.6',
        },
      ),
      css('.pricing-card .features').styles(
        raw: {
          'list-style': 'none',
          'margin-top': '1.5rem',
        },
        padding: Padding.zero,
      ),
      css('.pricing-card .features li').styles(
        padding: Padding.symmetric(vertical: 0.375.rem),
        fontSize: 0.875.rem,
        color: const Color('#404040'),
        raw: {
          'display': 'flex',
          'align-items': 'center',
          'gap': '0.5rem',
        },
      ),
      css('.pricing-card .features li::before').styles(
        raw: {'content': '"✓"'},
        color: const Color('#16a34a'),
        fontWeight: FontWeight.w600,
      ),
      css('.pricing-card .cta-button').styles(
        raw: {
          'margin-top': '1.5rem',
          'width': '100%',
          'text-align': 'center',
          'display': 'block',
        },
      ),

      css('.pricing-card.unavailable').styles(
        raw: {'opacity': '0.6'},
      ),
      css('.unavailable-badge').styles(
        display: Display.inlineBlock,
        fontSize: 0.7.rem,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        backgroundColor: const Color('#a3a3a3'),
        raw: {
          'padding': '0.25rem 0.75rem',
          'border-radius': '20px',
          'margin-bottom': '1rem',
        },
      ),
      css('.unavailable-note').styles(
        fontSize: 0.8.rem,
        color: const Color('#737373'),
        raw: {
          'margin-top': '0.75rem',
          'font-style': 'italic',
          'line-height': '1.5',
        },
      ),

      // Clients section
      css('.clients-section').styles(
        padding: Padding.symmetric(vertical: 5.rem),
        backgroundColor: const Color('#fafafa'),
      ),
      css('.clients-section h2').styles(
        fontSize: 1.75.rem,
        fontWeight: FontWeight.w700,
        color: const Color('#0a0a0a'),
        raw: {'margin-bottom': '0.75rem'},
      ),
      css('.clients-section .section-intro p').styles(
        fontSize: 1.rem,
        color: const Color('#525252'),
        raw: {'max-width': '600px', 'line-height': '1.7'},
      ),
      css('.clients-grid').styles(
        raw: {
          'display': 'grid',
          'grid-template-columns': 'repeat(2, 1fr)',
          'gap': '1.5rem',
          'margin-top': '3rem',
        },
      ),
      css('.client-card').styles(
        padding: Padding.all(2.rem),
        backgroundColor: Colors.white,
        raw: {
          'border': '1px solid #e5e5e5',
          'border-radius': '12px',
          'transition': 'border-color 0.2s ease, box-shadow 0.2s ease',
        },
      ),
      css('.client-card:hover').styles(
        raw: {
          'border-color': '#d4d4d4',
          'box-shadow': '0 4px 12px rgba(0,0,0,0.05)',
        },
      ),
      css('.client-card.long-term').styles(
        raw: {'border-left': '3px solid #0a0a0a'},
      ),
      css('.client-badge').styles(
        display: Display.inlineBlock,
        fontSize: 0.7.rem,
        fontWeight: FontWeight.w600,
        color: const Color('#0a0a0a'),
        backgroundColor: const Color('#f0f0f0'),
        raw: {
          'padding': '0.25rem 0.75rem',
          'border-radius': '20px',
          'margin-bottom': '1rem',
          'letter-spacing': '0.02em',
        },
      ),
      css('.client-card h3').styles(
        fontSize: 1.1.rem,
        fontWeight: FontWeight.w600,
        color: const Color('#0a0a0a'),
        raw: {'margin-bottom': '0.75rem'},
      ),
      css('.client-card p').styles(
        fontSize: 0.9.rem,
        color: const Color('#525252'),
        raw: {'line-height': '1.7'},
      ),

      // Contact section
      css('.contact-section').styles(
        padding: Padding.symmetric(vertical: 6.rem),
        raw: {'border-top': '1px solid #e5e5e5'},
      ),
      css('.contact-inner').styles(
        padding: Padding.all(3.rem),
        raw: {
          'border-radius': '20px',
          'background': '#fafafa',
          'border': '1px solid #e5e5e5',
        },
      ),
      css('.contact-inner h2').styles(
        fontSize: 2.rem,
        fontWeight: FontWeight.w500,
        color: const Color('#0a0a0a'),
        raw: {
          'line-height': '1.3',
          'letter-spacing': '-0.02em',
        },
      ),
      css('.contact-inner .cta-button').styles(
        raw: {'margin-top': '1.5rem'},
      ),
      css('.contact-offices').styles(
        raw: {
          'margin-top': '2rem',
          'padding-top': '2rem',
          'border-top': '1px solid #e5e5e5',
        },
      ),
      css('.contact-offices h3').styles(
        fontSize: 0.875.rem,
        fontWeight: FontWeight.w600,
        color: const Color('#0a0a0a'),
        raw: {'margin-bottom': '0.75rem'},
      ),
      css('.contact-offices p').styles(
        fontSize: 0.875.rem,
        color: const Color('#525252'),
        raw: {'line-height': '1.7'},
      ),

      // Footer
      css('.studio-footer').styles(
        padding: Padding.symmetric(vertical: 3.rem),
        raw: {'border-top': '1px solid #e5e5e5'},
      ),
      css('.footer-grid').styles(
        display: Display.grid,
        raw: {
          'grid-template-columns': 'repeat(auto-fit, minmax(160px, 1fr))',
          'gap': '2rem',
          'margin-bottom': '3rem',
        },
      ),
      css('.footer-column h4').styles(
        fontSize: 0.8125.rem,
        fontWeight: FontWeight.w600,
        color: const Color('#0a0a0a'),
        raw: {
          'letter-spacing': '0.05em',
          'text-transform': 'uppercase',
          'margin-bottom': '1rem',
        },
      ),
      css('.footer-column ul').styles(
        raw: {'list-style': 'none'},
        padding: Padding.zero,
      ),
      css('.footer-column li').styles(
        raw: {'margin-bottom': '0.5rem'},
      ),
      css('.footer-column a').styles(
        color: const Color('#737373'),
        textDecoration: TextDecoration.none,
        fontSize: 0.875.rem,
        raw: {'transition': 'color 0.2s ease'},
      ),
      css('.footer-column a:hover').styles(
        color: const Color('#0a0a0a'),
      ),
      css('.footer-bottom').styles(
        display: Display.flex,
        raw: {
          'justify-content': 'space-between',
          'align-items': 'center',
          'padding-top': '2rem',
          'border-top': '1px solid #e5e5e5',
          'flex-wrap': 'wrap',
          'gap': '1rem',
        },
      ),
      css('.footer-bottom p').styles(
        fontSize: 0.8125.rem,
        color: const Color('#a3a3a3'),
      ),

      // About page
      css('.about-section').styles(
        padding: Padding.only(top: 8.rem, bottom: 4.rem),
      ),
      css('.about-eyebrow').styles(
        fontSize: 0.875.rem,
        fontWeight: FontWeight.w600,
        color: const Color('#737373'),
        raw: {
          'letter-spacing': '0.05em',
          'text-transform': 'uppercase',
          'margin-bottom': '0.75rem',
        },
      ),
      css('.about-section h1').styles(
        fontSize: 2.5.rem,
        fontWeight: FontWeight.w500,
        color: const Color('#0a0a0a'),
        raw: {
          'letter-spacing': '-0.02em',
          'margin-bottom': '1rem',
        },
      ),
      css('.about-section > .container > p').styles(
        fontSize: 1.125.rem,
        color: const Color('#525252'),
        raw: {'line-height': '1.8'},
      ),
      css('.about-body').styles(
        raw: {
          'margin-top': '2.5rem',
          'max-width': '42rem',
        },
      ),
      css('.about-body p').styles(
        fontSize: 1.rem,
        color: const Color('#404040'),
        raw: {
          'line-height': '1.85',
          'margin-bottom': '1.5rem',
        },
      ),
      css('.about-body a').styles(
        color: const Color('#0a0a0a'),
        textDecoration: TextDecoration.none,
        raw: {
          'border-bottom': '1px solid #a3a3a3',
          'padding-bottom': '1px',
          'transition': 'border-color 0.2s ease',
        },
      ),
      css('.about-body a:hover').styles(
        raw: {'border-color': '#0a0a0a'},
      ),

      // Team section
      css('.team-section').styles(
        padding: Padding.symmetric(vertical: 4.rem),
        raw: {'border-top': '1px solid #e5e5e5'},
      ),
      css('.team-section h2').styles(
        fontSize: 1.25.rem,
        fontWeight: FontWeight.w600,
        color: const Color('#0a0a0a'),
        raw: {'margin-bottom': '2rem'},
      ),
      css('.team-card').styles(
        raw: {
          'border-radius': '16px',
          'overflow': 'hidden',
          'border': '1px solid #e5e5e5',
          'max-width': '320px',
        },
      ),
      css('.team-card-image').styles(
        width: 100.percent,
        raw: {
          'aspect-ratio': '1',
          'object-fit': 'cover',
          'filter': 'grayscale(100%)',
        },
      ),
      css('.team-card-info').styles(
        padding: Padding.all(1.25.rem),
      ),
      css('.team-card-info h3').styles(
        fontSize: 1.rem,
        fontWeight: FontWeight.w600,
        color: const Color('#0a0a0a'),
      ),
      css('.team-card-info p').styles(
        fontSize: 0.8125.rem,
        color: const Color('#737373'),
        raw: {'margin-top': '0.25rem'},
      ),
    ]);
  }

  static Component responsiveStyles() {
    return RawText('<style>'
        '@media (max-width: 768px) {'
        '  .hero-section h1 { font-size: 2.25rem; }'
        '  .hero-section { padding-top: 5rem; padding-bottom: 3rem; }'
        '  .testimonial-quote { font-size: 1.25rem; }'
        '  .pricing-grid { grid-template-columns: 1fr; }'
        '  .contact-inner { padding: 2rem; }'
        '  .about-section { padding-top: 5rem; }'
        '  .about-section h1 { font-size: 1.75rem; }'
        '  .clients-grid { grid-template-columns: 1fr; }'
        '  .footer-bottom { flex-direction: column; align-items: flex-start; }'
        '}'
        '</style>');
  }
}
