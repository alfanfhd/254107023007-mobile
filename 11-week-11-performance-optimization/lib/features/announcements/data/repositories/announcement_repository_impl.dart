import 'package:dio/dio.dart';

import '../../../../core/failures.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../datasources/announcement_cache.dart';
import '../datasources/announcement_remote_datasource.dart';

/// Implementasi cache-first + stale-while-revalidate.
///
/// Alur:
/// 1. UI membaca [readCachedPage] lalu langsung menampilkan cache.
/// 2. UI memanggil [fetchPage] untuk mendapatkan data segar di background.
/// 3. Hasil segar ditulis kembali ke cache.
/// 4. Jika jaringan gagal dan cache tersedia, cache dikembalikan sebagai
///    fallback (mode offline).
class AnnouncementRepositoryImpl implements AnnouncementRepository {
  AnnouncementRepositoryImpl({
    required AnnouncementRemoteDataSource remote,
    required AnnouncementCache cache,
  }) {
    _remote = remote;
    _cache = cache;
  }

  late final AnnouncementRemoteDataSource _remote;
  late final AnnouncementCache _cache;

  @override
  Future<List<Announcement>?> readCachedPage(int page) {
    return _cache.readPage(page);
  }

  @override
  Future<({List<Announcement> items, Failure? failure, bool fromCache})>
  fetchPage(int page, {int limit = 10}) async {
    try {
      final fresh = await _remote.fetchPage(page, limit: limit);
      await _cache.writePage(page, fresh);
      return (items: fresh, failure: null, fromCache: false);
    } catch (error) {
      final cached = await _cache.readPage(page);
      if (cached != null && cached.isNotEmpty) {
        return (items: cached, failure: null, fromCache: true);
      }

      return (
        items: const <Announcement>[],
        failure: NetworkFailure(_friendlyMessage(error)),
        fromCache: false,
      );
    }
  }

  @override
  Future<void> clearCache() => _cache.clear();

  String _friendlyMessage(Object error) {
    if (error is DioException) {
      if (error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.connectionTimeout) {
        return 'Koneksi timeout. Coba lagi saat sinyal membaik.';
      }
      if (error.type == DioExceptionType.connectionError) {
        return 'Tidak ada koneksi internet. Menampilkan data offline.';
      }
      final status = error.response?.statusCode;
      if (status != null) {
        return 'Server mengembalikan HTTP $status. Coba beberapa saat lagi.';
      }
    }
    return 'Gagal memuat pengumuman. Periksa koneksi internet Anda.';
  }
}
