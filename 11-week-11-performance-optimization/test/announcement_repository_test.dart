import 'package:flutter_test/flutter_test.dart';
import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/announcements/data/datasources/announcement_cache.dart';
import 'package:campus_notify/features/announcements/data/datasources/announcement_remote_datasource.dart';
import 'package:campus_notify/features/announcements/data/repositories/announcement_repository_impl.dart';
import 'package:campus_notify/features/announcements/domain/entities/announcement.dart';

class _StubRemote extends AnnouncementRemoteDataSource {
  _StubRemote({this.items = const [], this.error});

  final List<Announcement> items;
  final Object? error;
  int calls = 0;

  @override
  Future<List<Announcement>> fetchPage(int page, {int limit = 10}) async {
    calls++;
    if (error != null) throw error!;
    return items;
  }
}

Announcement _item(int id) {
  return Announcement(
    id: '$id',
    title: 'Pengumuman $id',
    author: 'Admin',
    imageUrl: 'https://example.test/$id.jpg',
    thumbnailUrl: 'https://example.test/thumb/$id.jpg',
    page: 1,
  );
}

void main() {
  group('AnnouncementRepositoryImpl', () {
    test('menyimpan hasil jaringan ke cache', () async {
      final cache = InMemoryAnnouncementCache();
      final remote = _StubRemote(items: [_item(1), _item(2)]);
      final repository = AnnouncementRepositoryImpl(
        remote: remote,
        cache: cache,
      );

      final result = await repository.fetchPage(1);

      expect(result.failure, isNull);
      expect(result.fromCache, isFalse);
      expect(result.items.length, 2);
      expect(await cache.readPage(1), isNotNull);
      expect(cache.hitCount, 1);
    });

    test(
      'mengembalikan cache saat jaringan gagal (offline fallback)',
      () async {
        final cache = InMemoryAnnouncementCache();
        await cache.writePage(1, [_item(9)]);

        final repository = AnnouncementRepositoryImpl(
          remote: _StubRemote(error: Exception('offline')),
          cache: cache,
        );

        final result = await repository.fetchPage(1);

        expect(result.failure, isNull);
        expect(result.fromCache, isTrue);
        expect(result.items.single.id, '9');
      },
    );

    test(
      'mengembalikan NetworkFailure saat jaringan gagal tanpa cache',
      () async {
        final repository = AnnouncementRepositoryImpl(
          remote: _StubRemote(error: Exception('offline')),
          cache: InMemoryAnnouncementCache(),
        );

        final result = await repository.fetchPage(1);

        expect(result.items, isEmpty);
        expect(result.fromCache, isFalse);
        expect(result.failure, isA<NetworkFailure>());
      },
    );
  });
}
