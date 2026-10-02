import 'package:genuineci_website/content/heading_ids_extension.dart';
import 'package:jaspr_content/jaspr_content.dart';
import 'package:test/test.dart';

void main() {
  test('Japanese and repeated headings get nonempty, unique anchors', () async {
    final page = _page('## 解析の設定\n\n## 解析の設定\n\n## Android builds');
    final nodes = await const HeadingIdsExtension().apply(
      page,
      const MarkdownParser().parsePage(page),
    );
    final ids = nodes
        .whereType<ElementNode>()
        .map((node) => node.attributes['id'])
        .toList();

    expect(ids, hasLength(3));
    expect(ids, everyElement(isNotEmpty));
    expect(ids.toSet(), hasLength(3));
    expect(ids.last, 'android-builds');
  });

  test('an explicitly written heading anchor is preserved', () async {
    final page = _page('<h2 id="existing-link">解析の設定</h2>');
    final nodes = await const HeadingIdsExtension().apply(
      page,
      const MarkdownParser().parsePage(page),
    );

    expect(
      nodes.whereType<ElementNode>().single.attributes['id'],
      'existing-link',
    );
  });
}

Page _page(String content) => Page(
  path: 'blog/test.md',
  url: '/blog/test',
  content: content,
  config: const PageConfig(),
  loader: MemoryLoader(pages: []),
);
