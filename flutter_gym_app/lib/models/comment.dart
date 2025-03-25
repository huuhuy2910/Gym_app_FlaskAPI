class Comment {
  final String user;
  final String content;
  final int rating;
  final String createdAt;

  Comment({
    required this.user,
    required this.content,
    required this.rating,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      user: json['user'] ?? '',
      content: json['content'] ?? '',
      rating: json['rating'] ?? 0,
      createdAt: json['created_at'] ?? '',
    );
  }
}
