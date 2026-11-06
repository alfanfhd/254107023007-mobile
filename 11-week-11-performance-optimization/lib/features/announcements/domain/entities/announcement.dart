/// Entitas pengumuman yang dipakai fitur paginated announcement feed.
///
/// Domain layer tidak boleh mengimpor Flutter, Dio, atau package storage.
class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.author,
    required this.imageUrl,
    this.thumbnailUrl,
    this.page = 1,
  });

  final String id;
  final String title;
  final String author;
  final String imageUrl;
  final String? thumbnailUrl;
  final int page;

  /// URL kecil untuk list. Jangan pernah memakai gambar full-res di list:
  /// decode gambar besar di raster thread adalah salah satu penyebab jank.
  String get listImageUrl => thumbnailUrl ?? imageUrl;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'imageUrl': imageUrl,
      'thumbnailUrl': thumbnailUrl,
      'page': page,
    };
  }

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'].toString(),
      title: json['title']?.toString() ?? 'Pengumuman Kampus',
      author: json['author']?.toString() ?? 'Admin Kampus',
      imageUrl: json['imageUrl']?.toString() ?? '',
      thumbnailUrl: json['thumbnailUrl']?.toString(),
      page: (json['page'] as num?)?.toInt() ?? 1,
    );
  }
}
