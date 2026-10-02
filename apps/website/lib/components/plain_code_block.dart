import 'package:jaspr/server.dart';
import 'package:jaspr_content/components/code_block.dart';
import 'package:jaspr_content/jaspr_content.dart';

class PlainCodeBlock extends CustomComponent {
  const PlainCodeBlock() : super.base();

  @override
  Component? create(Node node, NodesBuilder builder) {
    if (node
        case ElementNode(
          tag: 'pre',
          children: [
            ElementNode(
              tag: 'code',
              attributes: {'class': final String language},
            ),
          ],
        )
        when language != 'language-dart') {
      return CodeBlock.from(source: node.innerText);
    }
    return null;
  }
}
