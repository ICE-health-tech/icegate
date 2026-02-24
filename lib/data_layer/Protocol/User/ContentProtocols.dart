class BlogPostProtocol {
  final String blogPostID;
  final String authorID;
  final String title;
  final String slug;
  final String? excerpt;
  final String content;
  final String? featuredImageUrl;
  final String status;
  final bool isFeatured;
  final int viewCount;
  final int likeCount;
  final DateTime? publishedAt;
  final DateTime? scheduledFor;

  BlogPostProtocol({
    required this.blogPostID,
    required this.authorID,
    required this.title,
    required this.slug,
    this.excerpt,
    required this.content,
    this.featuredImageUrl,
    this.status = 'draft',
    this.isFeatured = false,
    this.viewCount = 0,
    this.likeCount = 0,
    this.publishedAt,
    this.scheduledFor,
  });
}
