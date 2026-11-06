import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/announcements/domain/entities/announcement.dart';
import 'package:campus_notify/features/announcements/domain/repositories/announcement_repository.dart';
import 'package:campus_notify/features/announcements/presentation/providers/announcement_providers.dart';

typedef _PageResult = ({
  List<Announcement> items,
  Failure? failure,
  bool fromCache,
});

class _FakeAnnouncementRepository implements AnnouncementRepository {
  _FakeAnnouncementRepository({this.cachedPage, required this.responses});

  final List<Announcement>? cachedPage;
  final Map<int, _PageResult> responses;
  int fetchCalls = 0;

  @override
  Future<void> clearCache() async {}

  @override
  Future<List<Announcement>?> readCachedPage(int page) async {
    return page == 1 ? cachedPage : null;
  }

  @override
  Future<({List<Announcement> items, Failure? failure, bool fromCache})>
  fetchPage(int page, {int limit = 10}) async {
    fetchCalls++;
    final response =
        responses[page] ??
        (items: const <Announcement>[], failure: null, fromCache: false);
    return response;
  }
}

List<Announcement> _items(int start, int count) {
  return List<Announcement>.generate(
    count,
    (index) => Announcement(
      id: '${start + index}',
      title: 'Pengumuman ${start + index}',
      author: 'Admin',
      imageUrl: 'https://example.test/${start + index}.jpg',
      page: 1,
    ),
    growable: false,
  );
}

void main() {
  test('loadInitial menampilkan cache lalu data segar', () async {
    final repository = _FakeAnnouncementRepository(
      cachedPage: _items(1, 2),
      responses: {1: (items: _items(10, 10), failure: null, fromCache: false)},
    );

    final container = ProviderContainer(
      overrides: [announcementRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container.read(announcementFeedProvider.notifier).loadInitial();
    final state = container.read(announcementFeedProvider);

    expect(state.items.length, 10);
    expect(state.items.first.id, '10');
    expect(state.page, 1);
    expect(state.hasMore, isTrue);
    expect(state.isLoading, isFalse);
    expect(state.fromCache, isFalse);
    expect(repository.fetchCalls, 1);
  });

  test(
    'loadMore menambahkan halaman berikutnya dan berhenti di akhir',
    () async {
      final repository = _FakeAnnouncementRepository(
        responses: {
          1: (items: _items(1, 10), failure: null, fromCache: false),
          2: (items: _items(11, 4), failure: null, fromCache: false),
        },
      );

      final container = ProviderContainer(
        overrides: [
          announcementRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(announcementFeedProvider.notifier);
      await notifier.loadInitial();
      await notifier.loadMore();

      final state = container.read(announcementFeedProvider);
      expect(state.items.length, 14);
      expect(state.page, 2);
      expect(state.hasMore, isFalse);
      expect(state.isLoadingMore, isFalse);
      expect(repository.fetchCalls, 2);

      // Tidak ada request tambahan saat sudah di halaman terakhir.
      await notifier.loadMore();
      expect(repository.fetchCalls, 2);
    },
  );

  test(
    'kegagalan jaringan mempertahankan cache dan menampilkan error',
    () async {
      final repository = _FakeAnnouncementRepository(
        cachedPage: _items(1, 3),
        responses: {
          1: (
            items: const <Announcement>[],
            failure: const NetworkFailure('Tidak ada koneksi internet'),
            fromCache: false,
          ),
        },
      );

      final container = ProviderContainer(
        overrides: [
          announcementRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      await container.read(announcementFeedProvider.notifier).loadInitial();
      final state = container.read(announcementFeedProvider);

      expect(state.items.length, 3);
      expect(state.error, 'Tidak ada koneksi internet');
      expect(state.fromCache, isTrue);
      expect(state.hasMore, isFalse);
    },
  );
}
