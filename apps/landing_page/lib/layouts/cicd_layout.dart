import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_content/jaspr_content.dart';

class CicdLayout extends PageLayoutBase {
  const CicdLayout();

  @override
  Pattern get name => 'cicd';

  @override
  Iterable<Component> buildHead(Page page) sync* {
    yield* super.buildHead(page);
    // Inter font from official source
    yield RawText(
      '<link rel="preconnect" href="https://rsms.me/">'
      '<link rel="stylesheet" href="https://rsms.me/inter/inter.css">',
    );
    yield link(rel: 'icon', href: '/favicon.png', type: 'image/png');
    yield const _CicdStyles();
    yield _CicdStyles.responsiveStyles();
  }

  @override
  Component buildBody(Page page, Component child) {
    final isJapanese = page.data.page['lang'] == 'ja';
    return div(classes: 'cicd-page', [
      // Header
      header(classes: 'cicd-header', [
        div(classes: 'container', [
          a(
            [Component.text('OpenCI')],
            href: isJapanese ? '/ja/' : '/en/',
            classes: 'cicd-logo',
            attributes: {'aria-label': isJapanese ? 'ホームページ' : 'Home'},
          ),
          nav(classes: 'cicd-nav', [
            a([
              Component.text(isJapanese ? '料金' : 'Pricing'),
            ], href: '#pricing'),
            a(
              [Component.text('GitHub')],
              href: 'https://github.com/openci-org/openci',
              target: Target.blank,
              attributes: {'rel': 'noopener noreferrer'},
            ),
            a(
              [Component.text(isJapanese ? 'ダッシュボード' : 'Dashboard')],
              href: 'https://dashboard.openci.org/',
              target: Target.blank,
              attributes: {'rel': 'noopener noreferrer'},
              classes: 'cta-button inverted',
            ),
          ]),
        ]),
      ]),
      // Main content
      main_([
        // Hero
        section(classes: 'cicd-hero', [
          div(classes: 'container', [
            child,
            div(classes: 'hero-actions', [
              a(
                [Component.text(isJapanese ? '無料で始める' : 'Start for free')],
                href: 'https://dashboard.openci.org/',
                target: Target.blank,
                attributes: {'rel': 'noopener noreferrer'},
                classes: 'cta-button',
              ),
            ]),
          ]),
        ]),
        // Video
        section(classes: 'cicd-video', [
          div(classes: 'container', [
            div(classes: 'video-wrapper', [
              RawText(
                '<video autoplay muted loop playsinline preload="metadata" '
                'aria-label="${isJapanese ? "OpenCIのデモ動画" : "OpenCI demo video"}">'
                '<source src="/openci_demo.mp4" type="video/mp4">'
                '</video>',
              ),
            ]),
          ]),
        ]),
        // Pricing
        section(classes: 'cicd-pricing', id: 'pricing', [
          div(classes: 'container', [
            h2([Component.text(isJapanese ? 'シンプルな料金体系' : 'Simple pricing')]),
            p(classes: 'pricing-subtitle', [
              Component.text(
                isJapanese
                    ? '使った分だけ。隠れたコストなし。'
                    : 'Pay only for what you use. No hidden costs.',
              ),
            ]),
            div(classes: 'pricing-grid', [
              _pricingCard(
                icon: _svgGift(),
                name: 'Free',
                price: isJapanese ? '¥0' : '\$0',
                unit: '',
                description: isJapanese
                    ? '毎月100分の無料ビルド'
                    : '100 free build minutes / month',
                features: isJapanese
                    ? [
                        'Mac + Linux 両対応',
                        'GitHub Actions互換',
                        '無料セットアップ通話 (15分)',
                      ]
                    : [
                        'Mac + Linux runners',
                        'GitHub Actions compatible',
                        'Free setup call (15 min)',
                      ],
              ),
              _pricingCard(
                icon: _svgApple(),
                name: 'Mac',
                price: isJapanese ? '¥1' : '\$0.007',
                unit: isJapanese ? '/分' : '/min',
                description: isJapanese
                    ? 'Apple Silicon (M1/M2/M4) ランナー'
                    : 'Apple Silicon (M1/M2/M4) runner',
                features: isJapanese
                    ? [
                        '4 vCPU / 8GB RAM',
                        'iOS / macOS ネイティブビルド',
                        'GitHub Actionsより最大90%オフ',
                      ]
                    : [
                        '4 vCPU / 8GB RAM',
                        'Native iOS / macOS builds',
                        'Up to 90% cheaper than GitHub Actions',
                      ],
                featured: true,
              ),
              _pricingCard(
                icon: _svgLinux(),
                name: 'Linux',
                price: isJapanese ? '¥0.1' : '\$0.0007',
                unit: isJapanese ? '/分' : '/min',
                description: isJapanese
                    ? '高性能 Linux ランナー(Ubuntu)'
                    : 'High-performance Linux runner (Ubuntu)',
                features: isJapanese
                    ? [
                        '2 vCPU / 4GB RAM',
                        'Docker対応',
                        'GitHub Actionsより最大93%オフ',
                      ]
                    : [
                        '2 vCPU / 4GB RAM',
                        'Docker support',
                        'Up to 93% cheaper than GitHub Actions',
                      ],
              ),
            ]),
          ]),
        ]),
        // Free setup support
        section(classes: 'cicd-support', [
          div(classes: 'container', [
            div(classes: 'support-card', [
              div(classes: 'support-icon', [_svgVideoCall()]),
              h2([
                Component.text(
                  isJapanese ? '初回セットアップを無料でサポート' : 'Free setup support',
                ),
              ]),
              p(classes: 'support-description', [
                Component.text(
                  isJapanese
                      ? '15分のビデオ通話で、ワークフロー設定から最初のビルド成功まで一緒にお手伝いします。'
                      : 'We\'ll help you set up your workflows and get your first build running in a free 15-minute video call.',
                ),
              ]),
              a(
                [Component.text(isJapanese ? '無料通話を予約' : 'Book a free call')],
                href: 'https://cal.com/masahiro-aoki-r4rxdx/15min',
                target: Target.blank,
                classes: 'cta-button',
                attributes: {'rel': 'noopener noreferrer'},
              ),
            ]),
          ]),
        ]),
      ]),
      // Footer
      footer(classes: 'cicd-footer', [
        div(classes: 'container', [
          div(classes: 'footer-inner', [
            a(
              [Component.text('OpenCI')],
              href: isJapanese ? '/ja/' : '/en/',
              classes: 'cicd-logo',
            ),
            div(classes: 'footer-links', [
              a(
                [Component.text('GitHub')],
                href: 'https://github.com/openci-org/openci',
                target: Target.blank,
                attributes: {'rel': 'noopener noreferrer'},
              ),
              a([Component.text('OpenCI Studio')], href: '/studio/'),
              a(
                [Component.text('X / Twitter')],
                href: 'https://x.com/ma_freud',
                target: Target.blank,
                attributes: {'rel': 'noopener noreferrer'},
              ),
            ]),
          ]),
          p(classes: 'footer-copyright', [
            Component.text('© OpenCI, Inc. ${DateTime.now().year}'),
          ]),
        ]),
      ]),
    ]);
  }

  static Component _pricingCard({
    required Component icon,
    required String name,
    required String price,
    required String unit,
    required String description,
    required List<String> features,
    bool featured = false,
  }) {
    return div(classes: 'pricing-card', [
      div(classes: 'card-content', [
        div(classes: 'card-name', [
          span(classes: 'card-icon', [icon]),
          h3([Component.text(name)]),
        ]),
        div(classes: 'card-price', [
          span(classes: 'price-value', [Component.text(price)]),
          if (unit.isNotEmpty)
            span(classes: 'price-unit', [Component.text(unit)]),
        ]),
        p(classes: 'card-description', [Component.text(description)]),
        Component.element(
          tag: 'ul',
          classes: 'card-features',
          attributes: {'role': 'list'},
          children: [
            for (final feature in features)
              Component.element(
                tag: 'li',
                children: [
                  RawText(
                    '<svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor" aria-hidden="true">'
                    '<path fill-rule="evenodd" d="M12.416 3.376a.75.75 0 0 1 .208 1.04l-5 7.5a.75.75 0 0 1-1.154.114l-3-3a.75.75 0 0 1 1.06-1.06l2.353 2.353 4.493-6.74a.75.75 0 0 1 1.04-.207Z" clip-rule="evenodd"/>'
                    '</svg>',
                  ),
                  Component.text(feature),
                ],
              ),
          ],
        ),
      ]),
    ]);
  }

  // ── Heroicons (24/outline) ──

  static Component _svgGift() {
    return RawText(
      '<svg width="24" height="24" viewBox="0 0 24 24" fill="none" '
      'stroke-width="1.5" stroke="currentColor" aria-hidden="true">'
      '<path stroke-linecap="round" stroke-linejoin="round" '
      'd="M20.625 11.505v8.25a1.5 1.5 0 0 1-1.5 1.5H4.875a1.5 1.5 0 0 1-1.5-1.5v-8.25m8.25-6.375A2.625 2.625 0 1 0 9 7.755h2.625m0-2.625v2.625m0-2.625a2.625 2.625 0 1 1 2.625 2.625h-2.625m0 0v13.5M3 11.505h18c.621 0 1.125-.504 1.125-1.125v-1.5c0-.622-.504-1.125-1.125-1.125H3c-.621 0-1.125.503-1.125 1.125v1.5c0 .621.504 1.125 1.125 1.125Z"/>'
      '</svg>',
    );
  }

  static Component _svgApple() {
    return RawText(
      '<svg width="24" height="24" viewBox="0 0 24 24" fill="none" '
      'stroke-width="1.5" stroke="currentColor" aria-hidden="true">'
      '<path stroke-linecap="round" stroke-linejoin="round" '
      'd="M8.25 3v1.5M4.5 8.25H3m18 0h-1.5M4.5 12H3m18 0h-1.5m-15 3.75H3m18 0h-1.5M8.25 19.5V21M12 3v1.5m0 15V21m3.75-18v1.5m0 15V21m-9-1.5h10.5a2.25 2.25 0 0 0 2.25-2.25V6.75a2.25 2.25 0 0 0-2.25-2.25H6.75A2.25 2.25 0 0 0 4.5 6.75v10.5a2.25 2.25 0 0 0 2.25 2.25Zm.75-12h9v9h-9v-9Z"/>'
      '</svg>',
    );
  }

  static Component _svgLinux() {
    return RawText(
      '<svg width="24" height="24" viewBox="0 0 24 24" fill="none" '
      'stroke-width="1.5" stroke="currentColor" aria-hidden="true">'
      '<path stroke-linecap="round" stroke-linejoin="round" '
      'd="m6.75 7.5 3 2.25-3 2.25m4.5 0h3m-9 8.25h13.5A2.25 2.25 0 0 0 21 18V6a2.25 2.25 0 0 0-2.25-2.25H5.25A2.25 2.25 0 0 0 3 6v12a2.25 2.25 0 0 0 2.25 2.25Z"/>'
      '</svg>',
    );
  }

  static Component _svgVideoCall() {
    return RawText(
      '<svg width="28" height="28" viewBox="0 0 24 24" fill="none" '
      'stroke-width="1.5" stroke="currentColor" aria-hidden="true">'
      '<path stroke-linecap="round" stroke-linejoin="round" '
      'd="m15.75 10.5 4.72-4.72a.75.75 0 0 1 1.28.53v11.38a.75.75 0 0 1-1.28.53l-4.72-4.72M4.5 18.75h9a2.25 2.25 0 0 0 2.25-2.25v-9a2.25 2.25 0 0 0-2.25-2.25h-9A2.25 2.25 0 0 0 2.25 7.5v9a2.25 2.25 0 0 0 2.25 2.25Z"/>'
      '</svg>',
    );
  }
}

// ── Styles ──────────────────────────────────────────────

class _CicdStyles extends StatelessComponent {
  const _CicdStyles();

  @override
  Component build(BuildContext context) {
    return Style(
      styles: [
        // Reset & base
        css(
          '*, *::before, *::after',
        ).styles(boxSizing: .borderBox, margin: .zero, padding: .zero),
        css('html, body').styles(
          width: 100.percent,
          minHeight: 100.vh,
          fontFamily: const FontFamily.list([
            FontFamily('InterVariable'),
            FontFamilies.sansSerif,
          ]),
          color: const Color('#0a0a0a'),
          backgroundColor: Colors.white,
          raw: {
            '-webkit-font-smoothing': 'antialiased',
            '-moz-osx-font-smoothing': 'grayscale',
            'font-feature-settings': '"cv02", "cv03", "cv04", "cv11"',
            'font-optical-sizing': 'auto',
            'scroll-behavior': 'smooth',
          },
        ),
        css(
          '::selection',
        ).styles(backgroundColor: const Color('#0a0a0a'), color: Colors.white),

        // Page wrapper
        css('.cicd-page').styles(
          display: Display.flex,
          flexDirection: FlexDirection.column,
          minHeight: 100.vh,
        ),
        css('.cicd-page main').styles(raw: {'flex': '1'}),

        // Container
        css('.container').styles(
          width: 100.percent,
          maxWidth: 64.rem,
          margin: Margin.symmetric(horizontal: Unit.auto),
          padding: Padding.symmetric(horizontal: 1.5.rem),
        ),

        // ── Header ──
        css('.cicd-header').styles(
          padding: Padding.symmetric(vertical: 1.rem),
          raw: {
            'position': 'sticky',
            'top': '0',
            'z-index': '50',
            'background': 'rgba(255, 255, 255, 0.92)',
            'backdrop-filter': 'blur(16px)',
            '-webkit-backdrop-filter': 'blur(16px)',
            'border-bottom': '1px solid rgba(10, 10, 10, 0.06)',
          },
        ),
        css('.cicd-header .container').styles(
          display: Display.flex,
          alignItems: AlignItems.center,
          raw: {'justify-content': 'space-between'},
        ),
        css('.cicd-logo').styles(
          fontSize: 1.0625.rem,
          fontWeight: FontWeight.w600,
          color: const Color('#0a0a0a'),
          textDecoration: TextDecoration.none,
          raw: {
            'letter-spacing': '-0.02em',
            'transition': 'opacity 0.15s ease',
          },
        ),
        css('.cicd-logo:hover').styles(raw: {'opacity': '0.7'}),
        css('.cicd-nav').styles(
          display: Display.flex,
          raw: {'gap': '1.75rem'},
          alignItems: AlignItems.center,
        ),
        css('.cicd-nav a').styles(
          color: const Color('#525252'),
          textDecoration: TextDecoration.none,
          fontSize: 0.875.rem,
          fontWeight: FontWeight.w400,
          raw: {'transition': 'color 0.15s ease'},
        ),
        css('.cicd-nav a:hover').styles(color: const Color('#0a0a0a')),

        // ── Buttons ──
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
          },
        ),
        css(
          'a.cta-button:hover',
        ).styles(backgroundColor: const Color('#1a1a1a'), color: Colors.white),
        css('a.cta-button.inverted').styles(
          backgroundColor: Colors.white,
          color: const Color('#0a0a0a'),
          raw: {'box-shadow': '0 0 0 1px rgba(10, 10, 10, 0.15)'},
        ),
        css('a.cta-button.inverted:hover').styles(
          backgroundColor: const Color('#fafafa'),
          color: const Color('#0a0a0a'),
          raw: {'box-shadow': '0 0 0 1px rgba(10, 10, 10, 0.2)'},
        ),

        // ── Hero ──
        css('.cicd-hero').styles(
          padding: Padding.only(top: 6.rem, bottom: 3.rem),
          raw: {'text-align': 'center'},
        ),
        css('.cicd-hero h1').styles(
          fontSize: 1.75.rem,
          fontWeight: FontWeight.w500,
          color: const Color('#0a0a0a'),
          raw: {
            'letter-spacing': '-0.02em',
            'white-space': 'pre-line',
            'text-wrap': 'balance',
          },
        ),
        css('.hero-tagline').styles(
          fontSize: 3.5.rem,
          fontWeight: FontWeight.w600,
          color: const Color('#0a0a0a'),
          display: Display.block,
          raw: {
            'letter-spacing': '-0.04em',
            'margin-top': '0.25rem',
            'text-wrap': 'balance',
          },
        ),
        css('.cicd-hero p').styles(
          fontSize: 1.0625.rem,
          color: const Color('#525252'),
          raw: {
            'line-height': '1.75',
            'margin-top': '1rem',
            'max-width': '42ch',
            'margin-left': 'auto',
            'margin-right': 'auto',
            'text-wrap': 'pretty',
            'white-space': 'pre-line',
          },
        ),
        css('.hero-actions').styles(
          raw: {
            'margin-top': '2rem',
            'display': 'flex',
            'justify-content': 'center',
            'gap': '0.75rem',
          },
        ),

        // ── Video ──
        css('.cicd-video').styles(padding: Padding.symmetric(vertical: 2.rem)),
        css('.video-wrapper').styles(
          raw: {
            'border-radius': '12px',
            'overflow': 'hidden',
            'border': '1px solid rgba(10, 10, 10, 0.08)',
          },
        ),
        css(
          '.video-wrapper video',
        ).styles(width: 100.percent, display: Display.block),

        // ── Pricing ──
        css('.cicd-pricing').styles(
          padding: Padding.symmetric(vertical: 4.rem),
          raw: {'border-top': '1px solid rgba(10, 10, 10, 0.06)'},
        ),
        css('.cicd-pricing > .container > h2').styles(
          fontSize: 1.75.rem,
          fontWeight: FontWeight.w500,
          color: const Color('#0a0a0a'),
          raw: {'letter-spacing': '-0.02em', 'text-align': 'center'},
        ),
        css('.pricing-subtitle').styles(
          fontSize: 1.rem,
          color: const Color('#525252'),
          raw: {
            'text-align': 'center',
            'margin-top': '0.5rem',
            'margin-bottom': '2.5rem',
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
          raw: {'display': 'flex', 'flex-direction': 'column'},
        ),
        css('.card-name').styles(
          display: Display.flex,
          alignItems: AlignItems.center,
          raw: {'gap': '0.5rem', 'flex-wrap': 'wrap'},
        ),
        css('.card-icon').styles(
          display: Display.flex,
          alignItems: AlignItems.center,
          color: const Color('#525252'),
          raw: {'flex-shrink': '0'},
        ),
        css('.card-badge').styles(
          fontSize: 0.6875.rem,
          fontWeight: FontWeight.w500,
          color: const Color('#0a0a0a'),
          raw: {
            'padding': '0.125rem 0.5rem',
            'border': '1px solid rgba(10, 10, 10, 0.15)',
            'border-radius': '9999px',
            'letter-spacing': '0.01em',
          },
        ),
        css('.card-name h3').styles(
          fontSize: 1.rem,
          fontWeight: FontWeight.w600,
          color: const Color('#0a0a0a'),
          raw: {'letter-spacing': '-0.01em'},
        ),
        css('.card-price').styles(
          raw: {
            'margin-top': '0.75rem',
            'font-variant-numeric': 'tabular-nums',
          },
        ),
        css('.price-value').styles(
          fontSize: 2.rem,
          fontWeight: FontWeight.w600,
          color: const Color('#0a0a0a'),
          raw: {'letter-spacing': '-0.02em'},
        ),
        css('.price-unit').styles(
          fontSize: 0.8125.rem,
          fontWeight: FontWeight.w400,
          color: const Color('#737373'),
        ),
        css('.card-description').styles(
          fontSize: 0.875.rem,
          color: const Color('#525252'),
          raw: {'margin-top': '0.375rem', 'line-height': '1.6'},
        ),
        css('.card-features').styles(
          raw: {'list-style': 'none', 'margin-top': '1.25rem', 'flex': '1'},
          padding: Padding.zero,
        ),
        css('.card-features li').styles(
          padding: Padding.symmetric(vertical: 0.25.rem),
          fontSize: 0.875.rem,
          color: const Color('#404040'),
          raw: {'display': 'flex', 'align-items': 'baseline', 'gap': '0.5rem'},
        ),
        css('.card-features li svg').styles(
          color: const Color('#16a34a'),
          raw: {'flex-shrink': '0', 'position': 'relative', 'top': '0.125em'},
        ),

        // ── Support ──
        css(
          '.cicd-support',
        ).styles(padding: Padding.symmetric(vertical: 4.rem)),
        css('.support-card').styles(
          padding: Padding.all(3.rem),
          raw: {
            'text-align': 'center',
            'background': '#fafafa',
            'border': '1px solid rgba(10, 10, 10, 0.06)',
            'border-radius': '16px',
          },
        ),
        css('.support-icon').styles(
          display: Display.flex,
          raw: {'justify-content': 'center', 'margin-bottom': '1rem'},
          color: const Color('#0a0a0a'),
        ),
        css('.support-card h2').styles(
          fontSize: 1.5.rem,
          fontWeight: FontWeight.w500,
          color: const Color('#0a0a0a'),
          raw: {'letter-spacing': '-0.02em'},
        ),
        css('.support-description').styles(
          fontSize: 1.rem,
          color: const Color('#525252'),
          raw: {
            'margin-top': '0.75rem',
            'margin-bottom': '1.5rem',
            'max-width': '48ch',
            'margin-left': 'auto',
            'margin-right': 'auto',
            'line-height': '1.7',
          },
        ),

        // ── Footer ──
        css('.cicd-footer').styles(
          padding: Padding.symmetric(vertical: 2.rem),
          raw: {'border-top': '1px solid rgba(10, 10, 10, 0.06)'},
        ),
        css('.footer-inner').styles(
          display: Display.flex,
          alignItems: AlignItems.center,
          raw: {'justify-content': 'space-between'},
        ),
        css(
          '.footer-links',
        ).styles(display: Display.flex, raw: {'gap': '1.5rem'}),
        css('.footer-links a').styles(
          color: const Color('#737373'),
          textDecoration: TextDecoration.none,
          fontSize: 0.875.rem,
          raw: {'transition': 'color 0.15s ease'},
        ),
        css('.footer-links a:hover').styles(color: const Color('#0a0a0a')),
        css('.footer-copyright').styles(
          fontSize: 0.8125.rem,
          color: const Color('#a3a3a3'),
          raw: {'margin-top': '1.5rem', 'text-align': 'center'},
        ),
      ],
    );
  }

  static Component responsiveStyles() {
    return RawText(
      '<style>'
      '@media (max-width: 768px) {'
      '  .cicd-hero { padding-top: 4rem; }'
      '  .cicd-hero h1 { font-size: 1.375rem; }'
      '  .hero-tagline { font-size: 2.25rem !important; }'
      '  .pricing-grid { grid-template-columns: 1fr; }'
      '  .cicd-nav { gap: 1rem; }'
      '  .footer-inner { flex-direction: column; gap: 1rem; }'
      '}'
      '</style>',
    );
  }
}
