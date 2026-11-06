import 'package:dio/dio.dart';

import '../../domain/entities/announcement.dart';

/// Sumber data jaringan untuk feed pengumuman.
///
/// Picsum Photos dipakai karena menyediakan pagination + gambar nyata sehingga
/// teknik lazy loading, cached image, dan cache halaman bisa diuji end-to-end.
class AnnouncementRemoteDataSource {
  AnnouncementRemoteDataSource({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: 'https://picsum.photos',
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
              headers: const {'Accept': 'application/json'},
            ),
          );

  final Dio _dio;

  Future<List<Announcement>> fetchPage(int page, {int limit = 10}) async {
    final response = await _dio.get<List<dynamic>>(
      '/v2/list',
      queryParameters: {'page': page, 'limit': limit},
    );

    final data = response.data ?? const <dynamic>[];
    return data
        .map((raw) {
          final json = raw as Map<String, dynamic>;
          final id = json['id'].toString();
          return Announcement(
            id: id,
            title: 'Pengumuman Kampus #$id',
            author: json['author']?.toString() ?? 'Admin Kampus',
            imageUrl: 'https://picsum.photos/id/$id/1200/800',
            thumbnailUrl: 'https://picsum.photos/id/$id/400/240',
            page: page,
          );
        })
        .toList(growable: false);
  }
}
