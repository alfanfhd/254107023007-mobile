import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/announcement.dart';
import '../providers/announcement_providers.dart';
import '../widgets/announcement_card.dart';

/// Feed pengumuman dengan infinite scroll, pull-to-refresh, cache offline,
/// dan gambar yang di-cache + di-resize.
class AnnouncementFeedPage extends ConsumerStatefulWidget {
  const AnnouncementFeedPage({super.key});

  @override
  ConsumerState<AnnouncementFeedPage> createState() =>
      _AnnouncementFeedPageState();
}

class _AnnouncementFeedPageState extends ConsumerState<AnnouncementFeedPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Provider bisa sudah berisi data (mis. kembali dari halaman detail).
    final notifier = ref.read(announcementFeedProvider.notifier);
    if (ref.read(announcementFeedProvider).page == 0) {
      notifier.loadInitial();
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 320) {
      ref.read(announcementFeedProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(announcementFeedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengumuman Kampus'),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                ref.read(announcementFeedProvider.notifier).refresh(),
          ),
        ],
      ),
      body: Column(
        children: [
          if (feed.fromCache) const _OfflineBanner(),
          Expanded(child: _buildBody(feed)),
        ],
      ),
    );
  }

  Widget _buildBody(AnnouncementFeedState feed) {
    if (feed.isLoading && feed.isEmpty) {
      return const _FeedSkeleton();
    }

    if (feed.error != null && feed.isEmpty) {
      return _FeedErrorState(
        message: feed.error!,
        onRetry: () =>
            ref.read(announcementFeedProvider.notifier).loadInitial(),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(announcementFeedProvider.notifier).refresh(),
      child: ListView.builder(
        key: const Key('announcement_feed_list'),
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        // Lazy loading: hanya item yang mendekati viewport yang di-build.
        itemCount: feed.items.length + 1,
        itemBuilder: (context, index) {
          if (index == feed.items.length) {
            return _FeedFooter(feed: feed);
          }
          return _AnnouncementRow(announcement: feed.items[index]);
        },
      ),
    );
  }
}

/// Dipisah agar perubahan state footer (loading) tidak me-rebuild seluruh kartu.
class _AnnouncementRow extends StatelessWidget {
  const _AnnouncementRow({required this.announcement});

  final Announcement announcement;

  @override
  Widget build(BuildContext context) {
    return AnnouncementCard(announcement: announcement);
  }
}

class _FeedFooter extends ConsumerWidget {
  const _FeedFooter({required this.feed});

  final AnnouncementFeedState feed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (feed.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (feed.error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              feed.error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red.shade700),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () =>
                  ref.read(announcementFeedProvider.notifier).loadMore(),
              icon: const Icon(Icons.refresh),
              label: const Text('Coba lagi'),
            ),
          ],
        ),
      );
    }

    if (!feed.hasMore && feed.items.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            'Semua pengumuman sudah dimuat',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ),
      );
    }

    return const SizedBox(height: 24);
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.amber.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.cloud_off_rounded, size: 16, color: Colors.amber.shade900),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Mode offline: menampilkan data dari cache lokal.',
              style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedSkeleton extends StatelessWidget {
  const _FeedSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 96,
                  height: 76,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 14, color: Colors.grey.shade200),
                      const SizedBox(height: 8),
                      Container(
                        width: 120,
                        height: 12,
                        color: Colors.grey.shade200,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 80,
                        height: 10,
                        color: Colors.grey.shade100,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FeedErrorState extends StatelessWidget {
  const _FeedErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'Gagal memuat pengumuman',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
