import 'package:jaspr_content/jaspr_content.dart';

class HeadingIdsExtension implements PageExtension {
  const HeadingIdsExtension();

  @override
  Future<List<Node>> apply(Page page, List<Node> nodes) async {
    final ids = <String>{};

    Node assignId(Node node) {
      if (node is! ElementNode) return node;

      final attributes = {...node.attributes};
      if (RegExp(r'^h[1-6]$').hasMatch(node.tag)) {
        var base = attributes['id'];
        if (base == null || base.isEmpty) {
          base = node.innerText.trim().replaceAll(RegExp(r'\s+'), '-');
        }
        if (base.isEmpty) base = 'heading';
        var id = base;
        var suffix = 2;
        while (!ids.add(id)) {
          id = '$base-${suffix++}';
        }
        attributes['id'] = id;
      }

      return ElementNode(
        node.tag,
        attributes,
        node.children?.map(assignId).toList(),
      );
    }

    return nodes.map(assignId).toList();
  }
}
