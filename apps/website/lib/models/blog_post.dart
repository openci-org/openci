import 'package:jaspr_content/jaspr_content.dart';

import '../components/social_metadata.dart';
import '../l10n/site_locale.dart';

class BlogPost {
  const BlogPost(this.page);

  final Page page;

  Map<String, Object?> get data => page.data.page;
  String get category => data['category'] as String;
  String get title => data['title'] as String;
  String get plainTitle => title.replaceAll(RegExp(r'\s+'), ' ').trim();
  String get pageTitle => '$plainTitle — GenuineCI Blog';
  String get summary => data['description'] as String;
  String get publishedAt => data['date'] as String;
  String? get readTime => data['readTime'] as String?;
  String get author => data['author'] as String? ?? 'GenuineCI Team';
  String get coverLabel => data['coverLabel'] as String? ?? category;
  String get coverTitle => data['coverTitle'] as String? ?? plainTitle;
  SiteLocale get locale => SiteLocale.fromPath(page.url);
  String get url => locale.path(page.url);
  String get imagePath => data['image'] as String? ?? releaseImagePath;
  String get imageAlt => data['imageAlt'] as String? ?? releaseImageAlt(locale);
}

List<BlogPost> postsFromPages(List<Page> pages, SiteLocale locale) {
  final posts = pages
      .where((page) => page.url.startsWith(locale.path('/blog/')))
      .map(BlogPost.new)
      .toList();
  posts.sort((a, b) {
    final byDate = b.publishedAt.compareTo(a.publishedAt);
    return byDate != 0 ? byDate : a.url.compareTo(b.url);
  });
  return posts;
}
