import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

class StudioTestimonial extends StatelessComponent {
  const StudioTestimonial();

  @override
  Component build(BuildContext context) {
    return section(classes: 'testimonial-section', [
      div(classes: 'container', [
        Component.element(tag: 'figure', children: [
          Component.element(
              tag: 'blockquote',
              classes: 'testimonial-quote',
              children: [
                // No whitespace around quote content — required for hanging punctuation
                p([
                  Component.text(
                      'OpenCI Studioのサポートにより、停滞していたプロジェクトが劇的に改善しました。'
                      '技術的な課題の解決だけでなく、チーム全体のスキルアップを実現し、'
                      'メンバーのモチベーション向上にも大きく貢献していただきました。'),
                ]),
              ]),
          Component.element(
              tag: 'figcaption',
              classes: 'testimonial-author',
              children: [
                Component.text('— 非公開プロジェクト(大手外資系企業) · 技術顧問として参画'),
              ]),
        ]),
      ]),
    ]);
  }
}
