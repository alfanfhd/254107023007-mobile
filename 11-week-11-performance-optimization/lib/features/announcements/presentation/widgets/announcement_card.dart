import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/announcement.dart';

/// Kartu pengumuman yang dipisah dari halaman agar hanya item yang terlihat
/// yang di-build oleh [ListView.builder].
class AnnouncementCard extends StatelessWidget {
  const AnnouncementCard({super.key, required this.announcement});

  final Announcement announcement;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AnnouncementThumbnail(url: announcement.listImageUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      announcement.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      announcement.author,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.public_rounded,
                          size: 14,
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Halaman ${announcement.page}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.9,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  announcement.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  announcement.author,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: CachedNetworkImage(
                  imageUrl: announcement.imageUrl,
                  fit: BoxFit.cover,
                  memCacheWidth: 900,
                  placeholder: (context, url) =>
                      const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Gambar diambil dari Picsum Photos untuk mensimulasikan '
                  'pengumuman dengan gambar besar. Cache disk & resize memory '
                  'membuat scroll tetap halus.',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Thumbnail di-decode pada ukuran tampil (bukan full-res) berkat
/// [CachedNetworkImage.memCacheWidth] dan [CachedNetworkImage.memCacheHeight].
class _AnnouncementThumbnail extends StatelessWidget {
  const _AnnouncementThumbnail({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 96,
        height: 76,
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          memCacheWidth: 288,
          memCacheHeight: 228,
          fadeInDuration: const Duration(milliseconds: 150),
          placeholder: (context, url) =>
              const ColoredBox(color: Color(0xFFE9E9F2)),
          errorWidget: (context, url, error) => ColoredBox(
            color: const Color(0xFFF2F2F7),
            child: Icon(
              Icons.image_not_supported_outlined,
              color: Colors.grey.shade400,
            ),
          ),
        ),
      ),
    );
  }
}
