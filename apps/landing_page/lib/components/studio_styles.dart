import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

class StudioStyles extends StatelessComponent {
  const StudioStyles();

  @override
  Component build(BuildContext context) {
    return Component.fragment([
      // Inter font from official source (not Google Fonts)
      RawText('<link rel="preconnect" href="https://rsms.me/">'
          '<link rel="stylesheet" href="https://rsms.me/inter/inter.css">'),
      Style(styles: [
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
              [FontFamily('InterVariable'), FontFamilies.sansSerif]),
          color: const Color('#0a0a0a'),
          backgroundColor: Colors.white,
          raw: {
            '-webkit-font-smoothing': 'antialiased',
            '-moz-osx-font-smoothing': 'grayscale',
            'font-feature-settings': '"cv02", "cv03", "cv04", "cv11"',
            'font-optical-sizing': 'auto',
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

        // Container — consistent across all sections
        css('.container').styles(
          width: 100.percent,
          maxWidth: 72.rem,
          margin: Margin.symmetric(horizontal: Unit.auto),
          padding: Padding.symmetric(horizontal: 1.5.rem),
        ),

        // ── Header ──
        css('.studio-header').styles(
          padding: Padding.symmetric(vertical: 1.rem),
          backgroundColor: const Color.rgba(255, 255, 255, 0.92),
          raw: {
            'position': 'sticky',
            'top': '0',
            'z-index': '50',
            'backdrop-filter': 'blur(16px)',
            '-webkit-backdrop-filter': 'blur(16px)',
            'border-bottom': '1px solid rgba(10, 10, 10, 0.06)',
          },
        ),
        css('.studio-header .container').styles(
          display: Display.flex,
          alignItems: AlignItems.center,
          raw: {'justify-content': 'space-between'},
        ),
        css('.studio-logo').styles(
          fontSize: 1.125.rem,
          fontWeight: FontWeight.w600,
          color: const Color('#0a0a0a'),
          textDecoration: TextDecoration.none,
          raw: {
            'letter-spacing': '-0.02em',
            'transition': 'opacity 0.15s ease',
          },
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
          raw: {'transition': 'color 0.15s ease'},
        ),
        css('.studio-nav a:hover').styles(
          color: const Color('#0a0a0a'),
        ),

        // ── Buttons ──
        // Primary CTA — compact padding per ui.sh guidelines
        css('a.cta-button').styles(
          display: Display.inlineBlock,
          padding: Padding.symmetric(horizontal: 1.rem, vertical: 0.5625.rem),
          backgroundColor: const Color('#0a0a0a'),
          color: Colors.white,
          fontSize: 0.875.rem,
          fontWeight: FontWeight.w500,
          textDecoration: TextDecoration.none,
          raw: {
            'border-radius': '8px',
            'transition': 'background-color 0.15s ease, box-shadow 0.15s ease',
            'position': 'relative',
          },
        ),
        css('a.cta-button:hover').styles(
          backgroundColor: const Color('#1a1a1a'),
          color: Colors.white,
        ),
        css('a.cta-button:focus-visible').styles(
          raw: {
            'outline': '2px solid #2563eb',
            'outline-offset': '2px',
          },
        ),
        // Secondary/inverted — uses ring instead of solid border
        css('a.cta-button.inverted').styles(
          backgroundColor: Colors.white,
          color: const Color('#0a0a0a'),
          raw: {
            'box-shadow': '0 0 0 1px rgba(10, 10, 10, 0.1)',
          },
        ),
        css('a.cta-button.inverted:hover').styles(
          backgroundColor: const Color('#fafafa'),
          color: const Color('#0a0a0a'),
          raw: {
            'box-shadow': '0 0 0 1px rgba(10, 10, 10, 0.15)',
          },
        ),

        // ── Hero section ──
        css('.hero-section').styles(
          padding: Padding.only(top: 7.rem, bottom: 5.rem),
        ),
        css('.hero-section h1').styles(
          fontSize: 3.25.rem,
          fontWeight: FontWeight.w500,
          color: const Color('#0a0a0a'),
          raw: {
            'letter-spacing': '-0.03em',
            'max-width': '20ch',
            'text-wrap': 'balance',
          },
        ),
        css('.hero-section p').styles(
          fontSize: 1.0625.rem,
          color: const Color('#525252'),
          raw: {
            'line-height': '1.75',
            'margin-top': '1.25rem',
            'max-width': '48ch',
            'text-wrap': 'pretty',
          },
        ),

        // ── Section intro — left-aligned heading groups ──
        // Note: max-width on individual text elements, not the wrapper
        css('.section-intro').styles(),
        css('.section-intro .eyebrow').styles(
          fontSize: 0.8125.rem,
          fontWeight: FontWeight.w500,
          color: const Color('#737373'),
          raw: {
            'margin-bottom': '0.75rem',
          },
        ),
        css('.section-intro h2').styles(
          fontSize: 2.rem,
          fontWeight: FontWeight.w500,
          color: const Color('#0a0a0a'),
          raw: {
            'letter-spacing': '-0.02em',
            'max-width': '35ch',
            'text-wrap': 'balance',
          },
        ),
        css('.section-intro p').styles(
          fontSize: 1.rem,
          color: const Color('#525252'),
          raw: {
            'line-height': '1.75',
            'margin-top': '0.75rem',
            'max-width': '56ch',
            'text-wrap': 'pretty',
          },
        ),

        // ── Services section ──
        css('.services-section').styles(
          padding: Padding.symmetric(vertical: 5.rem),
          raw: {'border-top': '1px solid rgba(10, 10, 10, 0.06)'},
        ),
        css('.services-grid').styles(
          display: Display.grid,
          raw: {
            'grid-template-columns': 'repeat(2, 1fr)',
            'gap': '1px',
            'margin-top': '2.5rem',
            'background': 'rgba(10, 10, 10, 0.06)',
            'border': '1px solid rgba(10, 10, 10, 0.06)',
            'border-radius': '16px',
            'overflow': 'hidden',
          },
        ),
        css('.service-item').styles(
          padding: Padding.all(1.75.rem),
          backgroundColor: Colors.white,
        ),
        css('.service-item h3').styles(
          fontSize: 1.rem,
          fontWeight: FontWeight.w600,
          color: const Color('#0a0a0a'),
          raw: {
            'margin-bottom': '0.625rem',
            'letter-spacing': '-0.01em',
          },
        ),
        css('.service-item p').styles(
          fontSize: 0.875.rem,
          color: const Color('#525252'),
          raw: {
            'line-height': '1.7',
            'text-wrap': 'pretty',
          },
        ),

        // ── Testimonial section ──
        css('.testimonial-section').styles(
          padding: Padding.symmetric(vertical: 5.rem),
          raw: {'border-top': '1px solid rgba(10, 10, 10, 0.06)'},
        ),
        // Hanging punctuation via relative positioning
        css('.testimonial-quote').styles(
          fontSize: 1.625.rem,
          fontWeight: FontWeight.w400,
          color: const Color('#0a0a0a'),
          raw: {
            'line-height': '1.5',
            'letter-spacing': '-0.01em',
            'max-width': '40ch',
            'font-style': 'italic',
            'position': 'relative',
          },
        ),
        css('.testimonial-quote::before').styles(
          raw: {
            'content': '"\\201C"',
            'position': 'absolute',
            'display': 'inline',
            'transform': 'translateX(-100%)',
          },
        ),
        css('.testimonial-quote::after').styles(
          raw: {
            'content': '"\\201D"',
            'display': 'inline',
          },
        ),
        css('.testimonial-author').styles(
          raw: {'margin-top': '1.25rem'},
          fontSize: 0.875.rem,
          color: const Color('#737373'),
        ),

        // ── Pricing section ──
        css('.pricing-section').styles(
          padding: Padding.symmetric(vertical: 5.rem),
          raw: {'border-top': '1px solid rgba(10, 10, 10, 0.06)'},
        ),
        // Left-aligned pricing header (not centered — follows the page flow)
        css('.pricing-header').styles(
          raw: {'margin-bottom': '2.5rem'},
        ),
        css('.pricing-header h2').styles(
          fontSize: 2.rem,
          fontWeight: FontWeight.w500,
          color: const Color('#0a0a0a'),
          raw: {
            'letter-spacing': '-0.02em',
            'max-width': '35ch',
            'text-wrap': 'balance',
          },
        ),
        css('.pricing-header p').styles(
          fontSize: 0.9375.rem,
          color: const Color('#525252'),
          raw: {
            'margin-top': '0.5rem',
            'line-height': '1.7',
            'max-width': '56ch',
            'text-wrap': 'pretty',
          },
        ),
        css('.pricing-grid').styles(
          display: Display.grid,
          raw: {
            'grid-template-columns': 'repeat(3, 1fr)',
            'gap': '1px',
            'background': 'rgba(10, 10, 10, 0.06)',
            'border': '1px solid rgba(10, 10, 10, 0.06)',
            'border-radius': '16px',
            'overflow': 'hidden',
          },
        ),
        css('.pricing-card').styles(
          padding: Padding.all(1.75.rem),
          backgroundColor: Colors.white,
          raw: {
            'display': 'flex',
            'flex-direction': 'column',
          },
        ),
        css('.pricing-card.featured').styles(
          backgroundColor: const Color('#fafafa'),
        ),
        css('.pricing-card h3').styles(
          fontSize: 1.rem,
          fontWeight: FontWeight.w600,
          color: const Color('#0a0a0a'),
          raw: {'letter-spacing': '-0.01em'},
        ),
        css('.pricing-card .price').styles(
          fontSize: 2.rem,
          fontWeight: FontWeight.w600,
          color: const Color('#0a0a0a'),
          raw: {
            'margin-top': '0.75rem',
            'letter-spacing': '-0.02em',
            // tabular-nums for price display
            'font-variant-numeric': 'tabular-nums',
          },
        ),
        css('.pricing-card .price-period').styles(
          fontSize: 0.8125.rem,
          fontWeight: FontWeight.w400,
          color: const Color('#737373'),
        ),
        css('.pricing-card .description').styles(
          fontSize: 0.875.rem,
          color: const Color('#525252'),
          raw: {
            'margin-top': '0.5rem',
            'line-height': '1.6',
            'text-wrap': 'pretty',
          },
        ),
        css('.pricing-card .features').styles(
          raw: {
            'list-style': 'none',
            'margin-top': '1.25rem',
            'flex': '1',
          },
          padding: Padding.zero,
        ),
        css('.pricing-card .features li').styles(
          padding: Padding.symmetric(vertical: 0.3125.rem),
          fontSize: 0.875.rem,
          color: const Color('#404040'),
          raw: {
            'display': 'flex',
            'align-items': 'baseline',
            'gap': '0.5rem',
          },
        ),
        css('.pricing-card .features li::before').styles(
          raw: {
            'content': '"✓"',
            'flex-shrink': '0',
          },
          color: const Color('#16a34a'),
          fontWeight: FontWeight.w500,
        ),
        css('.pricing-card .cta-button').styles(
          raw: {
            'margin-top': '1.25rem',
            'width': '100%',
            'text-align': 'center',
            'display': 'block',
          },
        ),
        css('.pricing-card.unavailable').styles(
          raw: {'opacity': '0.55'},
        ),
        css('.unavailable-badge').styles(
          display: Display.inlineBlock,
          fontSize: 0.6875.rem,
          fontWeight: FontWeight.w500,
          color: const Color('#525252'),
          backgroundColor: const Color('#f5f5f5'),
          raw: {
            'padding': '0.1875rem 0.625rem',
            'border-radius': '20px',
            'margin-bottom': '0.75rem',
          },
        ),
        css('.unavailable-note').styles(
          fontSize: 0.8125.rem,
          color: const Color('#737373'),
          raw: {
            'margin-top': '0.75rem',
            'font-style': 'italic',
            'line-height': '1.6',
            'text-wrap': 'pretty',
          },
        ),

        // ── Clients section ──
        css('.clients-section').styles(
          padding: Padding.symmetric(vertical: 5.rem),
          raw: {'border-top': '1px solid rgba(10, 10, 10, 0.06)'},
        ),
        css('.clients-section h2').styles(
          fontSize: 2.rem,
          fontWeight: FontWeight.w500,
          color: const Color('#0a0a0a'),
          raw: {
            'letter-spacing': '-0.02em',
            'max-width': '35ch',
            'text-wrap': 'balance',
          },
        ),
        css('.clients-section .section-intro p').styles(
          fontSize: 1.rem,
          color: const Color('#525252'),
          raw: {
            'max-width': '56ch',
            'line-height': '1.75',
            'text-wrap': 'pretty',
          },
        ),
        css('.clients-grid').styles(
          raw: {
            'display': 'grid',
            'grid-template-columns': 'repeat(2, 1fr)',
            'gap': '1px',
            'margin-top': '2.5rem',
            'background': 'rgba(10, 10, 10, 0.06)',
            'border': '1px solid rgba(10, 10, 10, 0.06)',
            'border-radius': '16px',
            'overflow': 'hidden',
          },
        ),
        css('.client-card').styles(
          padding: Padding.all(1.75.rem),
          backgroundColor: Colors.white,
          raw: {
            'transition': 'background-color 0.15s ease',
          },
        ),
        css('.client-card:hover').styles(
          backgroundColor: const Color('#fafafa'),
        ),
        css('.client-card.long-term').styles(
          raw: {'border-left': '3px solid #0a0a0a'},
        ),
        css('.client-badge').styles(
          display: Display.inlineBlock,
          fontSize: 0.6875.rem,
          fontWeight: FontWeight.w500,
          color: const Color('#525252'),
          backgroundColor: const Color('#f5f5f5'),
          raw: {
            'padding': '0.1875rem 0.625rem',
            'border-radius': '20px',
            'margin-bottom': '0.75rem',
          },
        ),
        css('.client-card h3').styles(
          fontSize: 1.rem,
          fontWeight: FontWeight.w600,
          color: const Color('#0a0a0a'),
          raw: {
            'margin-bottom': '0.5rem',
            'letter-spacing': '-0.01em',
          },
        ),
        css('.client-card p').styles(
          fontSize: 0.875.rem,
          color: const Color('#525252'),
          raw: {
            'line-height': '1.7',
            'text-wrap': 'pretty',
          },
        ),

        // ── Contact section ──
        css('.contact-section').styles(
          padding: Padding.symmetric(vertical: 5.rem),
          raw: {'border-top': '1px solid rgba(10, 10, 10, 0.06)'},
        ),
        css('.contact-inner').styles(
          padding: Padding.all(2.5.rem),
          raw: {
            // Concentric border radius: outer 16px, inner accounts for padding
            'border-radius': '16px',
            'background': '#fafafa',
            'border': '1px solid rgba(10, 10, 10, 0.06)',
          },
        ),
        css('.contact-inner h2').styles(
          fontSize: 1.75.rem,
          fontWeight: FontWeight.w500,
          color: const Color('#0a0a0a'),
          raw: {
            'letter-spacing': '-0.02em',
            'max-width': '30ch',
            'text-wrap': 'balance',
          },
        ),
        css('.contact-inner .cta-button').styles(
          raw: {'margin-top': '1.25rem'},
        ),
        css('.contact-offices').styles(
          raw: {
            'margin-top': '1.75rem',
            'padding-top': '1.75rem',
            'border-top': '1px solid rgba(10, 10, 10, 0.06)',
          },
        ),
        css('.contact-offices h3').styles(
          fontSize: 0.8125.rem,
          fontWeight: FontWeight.w600,
          color: const Color('#0a0a0a'),
          raw: {'margin-bottom': '0.625rem'},
        ),
        css('.contact-offices p').styles(
          fontSize: 0.8125.rem,
          color: const Color('#525252'),
          raw: {'line-height': '1.7'},
        ),

        // ── Footer ──
        css('.studio-footer').styles(
          padding: Padding.symmetric(vertical: 2.5.rem),
          raw: {'border-top': '1px solid rgba(10, 10, 10, 0.06)'},
        ),
        css('.footer-grid').styles(
          display: Display.grid,
          raw: {
            'grid-template-columns': 'repeat(auto-fit, minmax(160px, 1fr))',
            'gap': '2rem',
            'margin-bottom': '2.5rem',
          },
        ),
        css('.footer-column h4').styles(
          fontSize: 0.8125.rem,
          fontWeight: FontWeight.w500,
          color: const Color('#0a0a0a'),
          raw: {
            'margin-bottom': '0.875rem',
          },
        ),
        css('.footer-column ul').styles(
          raw: {'list-style': 'none'},
          padding: Padding.zero,
        ),
        css('.footer-column li').styles(
          raw: {'margin-bottom': '0.375rem'},
        ),
        css('.footer-column a').styles(
          color: const Color('#737373'),
          textDecoration: TextDecoration.none,
          fontSize: 0.875.rem,
          raw: {'transition': 'color 0.15s ease'},
        ),
        css('.footer-column a:hover').styles(
          color: const Color('#0a0a0a'),
        ),
        css('.footer-bottom').styles(
          display: Display.flex,
          raw: {
            'justify-content': 'space-between',
            'align-items': 'center',
            'padding-top': '1.75rem',
            'border-top': '1px solid rgba(10, 10, 10, 0.06)',
            'flex-wrap': 'wrap',
            'gap': '1rem',
          },
        ),
        css('.footer-bottom p').styles(
          fontSize: 0.8125.rem,
          color: const Color('#a3a3a3'),
        ),

        // ── About page ──
        css('.about-section').styles(
          padding: Padding.only(top: 7.rem, bottom: 3.5.rem),
        ),
        css('.about-eyebrow').styles(
          fontSize: 0.8125.rem,
          fontWeight: FontWeight.w500,
          color: const Color('#737373'),
          raw: {
            'margin-bottom': '0.75rem',
          },
        ),
        css('.about-section h1').styles(
          fontSize: 2.25.rem,
          fontWeight: FontWeight.w500,
          color: const Color('#0a0a0a'),
          raw: {
            'letter-spacing': '-0.02em',
            'margin-bottom': '0.75rem',
            'text-wrap': 'balance',
          },
        ),
        css('.about-section > .container > p').styles(
          fontSize: 1.0625.rem,
          color: const Color('#525252'),
          raw: {
            'line-height': '1.75',
            'max-width': '48ch',
            'text-wrap': 'pretty',
          },
        ),
        css('.about-body').styles(
          raw: {
            'margin-top': '2rem',
            'max-width': '42rem',
          },
        ),
        css('.about-body p').styles(
          fontSize: 1.rem,
          color: const Color('#404040'),
          raw: {
            'line-height': '1.85',
            'margin-bottom': '1.25rem',
            'text-wrap': 'pretty',
          },
        ),
        css('.about-body a').styles(
          color: const Color('#0a0a0a'),
          textDecoration: TextDecoration.none,
          raw: {
            'border-bottom': '1px solid rgba(10, 10, 10, 0.25)',
            'padding-bottom': '1px',
            'transition': 'border-color 0.15s ease',
          },
        ),
        css('.about-body a:hover').styles(
          raw: {'border-color': '#0a0a0a'},
        ),

        // Team section
        css('.team-section').styles(
          padding: Padding.symmetric(vertical: 3.5.rem),
          raw: {'border-top': '1px solid rgba(10, 10, 10, 0.06)'},
        ),
        css('.team-section h2').styles(
          fontSize: 1.125.rem,
          fontWeight: FontWeight.w600,
          color: const Color('#0a0a0a'),
          raw: {'margin-bottom': '1.5rem'},
        ),
        css('.team-card').styles(
          raw: {
            'border-radius': '16px',
            'overflow': 'hidden',
            'border': '1px solid rgba(10, 10, 10, 0.06)',
            'max-width': '300px',
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
          raw: {'margin-top': '0.125rem'},
        ),
      ]),
    ]);
  }

  static Component responsiveStyles() {
    return RawText('<style>'
        '@media (max-width: 768px) {'
        '  .hero-section h1 { font-size: 2.25rem; max-width: none; }'
        '  .hero-section { padding-top: 4.5rem; padding-bottom: 2.5rem; }'
        '  .section-intro h2 { font-size: 1.5rem; }'
        '  .testimonial-quote { font-size: 1.25rem; }'
        '  .testimonial-quote::before { position: static; transform: none; }'
        '  .pricing-grid { grid-template-columns: 1fr; }'
        '  .pricing-header h2 { font-size: 1.5rem; }'
        '  .services-grid { grid-template-columns: 1fr; }'
        '  .contact-inner { padding: 1.5rem; }'
        '  .contact-inner h2 { font-size: 1.375rem; }'
        '  .about-section { padding-top: 4.5rem; }'
        '  .about-section h1 { font-size: 1.75rem; }'
        '  .clients-section h2 { font-size: 1.5rem; }'
        '  .clients-grid { grid-template-columns: 1fr; }'
        '  .footer-bottom { flex-direction: column; align-items: flex-start; }'
        '}'
        '</style>');
  }
}
