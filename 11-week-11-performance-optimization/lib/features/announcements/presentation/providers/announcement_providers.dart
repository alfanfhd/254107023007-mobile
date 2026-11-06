import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/announcement_cache.dart';
import '../../data/datasources/announcement_remote_datasource.dart';
import '../../data/repositories/announcement_repository_impl.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';

final announcementCacheProvider = Provider<AnnouncementCache>((ref) {
  return SharedPreferencesAnnouncementCache();
});

final announcementRemoteProvider = Provider<AnnouncementRemoteDataSource>((
  ref,
) {
  return AnnouncementRemoteDataSource();
});

final announcementRepositoryProvider = Provider<AnnouncementRepository>((ref) {
  return AnnouncementRepositoryImpl(
    remote: ref.watch(announcementRemoteProvider),
    cache: ref.watch(announcementCacheProvider),
  );
});

/// State feed yang kecil dan immutable supaya perubahannya mudah dilacak.
class AnnouncementFeedState {
  const AnnouncementFeedState({
    this.items = const <Announcement>[],
    this.page = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.fromCache = false,
    this.error,
  });

  final List<Announcement> items;
  final int page;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final bool fromCache;
  final String? error;

  bool get isEmpty => items.isEmpty;

  AnnouncementFeedState copyWith({
    List<Announcement>? items,
    int? page,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    bool? fromCache,
    String? error,
    bool clearError = false,
  }) {
    return AnnouncementFeedState(
      items: items ?? this.items,
      page: page ?? this.page,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      fromCache: fromCache ?? this.fromCache,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Notifier halaman + infinite scroll.
///
/// `loadInitial` sengaja menampilkan cache lebih dulu (stale), lalu menggantinya
/// dengan data jaringan (revalidate). Ini yang membuat layar terasa instan
/// ketika dibuka kembali, termasuk saat offline.
class AnnouncementFeedNotifier extends Notifier<AnnouncementFeedState> {
  static const int pageSize = 10;

  @override
  AnnouncementFeedState build() => const AnnouncementFeedState();

  Future<void> loadInitial() async {
    if (state.isLoading) return;

    state = state.copyWith(
      isLoading: true,
      page: 0,
      hasMore: true,
      clearError: true,
    );

    final repository = ref.read(announcementRepositoryProvider);

    // 1. Tampilkan cache secepat mungkin (stale-while-revalidate).
    try {
      final cached = await repository.readCachedPage(1);
      if (cached != null && cached.isNotEmpty) {
        state = state.copyWith(
          items: cached,
          page: 1,
          isLoading: true,
          fromCache: true,
        );
      }
    } catch (_) {
      // Cache rusak tidak boleh menghalangi pengambilan data jaringan.
    }

    // 2. Revalidate dari jaringan.
    final result = await repository.fetchPage(1, limit: pageSize);
    if (result.failure != null) {
      state = state.copyWith(
        isLoading: false,
        error: result.failure!.message,
        hasMore: false,
      );
      return;
    }

    state = state.copyWith(
      items: result.items,
      page: 1,
      isLoading: false,
      hasMore: result.items.length == pageSize,
      fromCache: result.fromCache,
      clearError: true,
    );
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

    final nextPage = state.page + 1;
    state = state.copyWith(isLoadingMore: true, clearError: true);

    final repository = ref.read(announcementRepositoryProvider);
    final result = await repository.fetchPage(nextPage, limit: pageSize);

    if (result.failure != null) {
      state = state.copyWith(
        isLoadingMore: false,
        error: result.failure!.message,
      );
      return;
    }

    state = state.copyWith(
      items: <Announcement>[...state.items, ...result.items],
      page: nextPage,
      isLoadingMore: false,
      hasMore: result.items.length == pageSize,
      fromCache: result.fromCache,
      clearError: true,
    );
  }

  Future<void> refresh() => loadInitial();
}

final announcementFeedProvider =
    NotifierProvider<AnnouncementFeedNotifier, AnnouncementFeedState>(
      AnnouncementFeedNotifier.new,
    );
