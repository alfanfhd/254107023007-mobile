import '../../../../core/failures.dart';
import '../entities/announcement.dart';

/// Kontrak data layer untuk feed pengumuman.
///
/// [readCachedPage] dipakai lebih dulu agar UI bisa langsung menampilkan cache
/// (stale-while-revalidate), lalu [fetchPage] mengambil data segar.
abstract interface class AnnouncementRepository {
  Future<List<Announcement>?> readCachedPage(int page);

  Future<({List<Announcement> items, Failure? failure, bool fromCache})>
  fetchPage(int page, {int limit});

  Future<void> clearCache();
}
