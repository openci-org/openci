const openciDirQuery = r'''
  query($owner: String!, $repo: String!, $expression: String!) {
    repository(owner: $owner, name: $repo) {
      object(expression: $expression) {
        ... on Tree {
          entries {
            name
            type
            object {
              ... on Blob { text }
            }
          }
        }
      }
    }
  }
''';

class OpenciDirEntry {
  final String name;
  final String type;
  final String? text;

  OpenciDirEntry({required this.name, required this.type, this.text});

  factory OpenciDirEntry.fromJson(Map<String, dynamic> json) {
    return OpenciDirEntry(
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      text: (json['object'] as Map<String, dynamic>?)?['text'] as String?,
    );
  }
}
