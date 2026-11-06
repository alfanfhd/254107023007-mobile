import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/announcement.dart';

/// Cache halaman pengumuman. Abstraksi ini membuat repository mudah diuji
/// tanpa menyentuh SharedPreferences atau jaringan.
abstract interface class AnnouncementCache {
  Future<List<Announcement>?> readPage(int page);

  Future<void> writePage(int page, List<Announcement> items);

  Future<void> clear();
}

/// Cache persisten berbasis SharedPreferences.
///
/// Setiap halaman disimpan sebagai satu string JSON sehingga hemat I/O dan
/// mudah dihapus per halaman saat data segar datang.
class SharedPreferencesAnnouncementCache implements AnnouncementCache {
  SharedPreferencesAnnouncementCache({SharedPreferences? preferences}) {
    _preferences = preferences;
  }

  static const _keyPrefix = 'announcement_page_';

  SharedPreferences? _preferences;

  Future<SharedPreferences> get _prefs async {
    return _preferences ??= await SharedPreferences.getInstance();
  }

  @override
  Future<List<Announcement>?> readPage(int page) async {
    final prefs = await _prefs;
    final raw = prefs.getString('$_keyPrefix$page');
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => Announcement.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    } catch (_) {
      // Data lama/korup tidak boleh membuat aplikasi crash.
      await prefs.remove('$_keyPrefix$page');
      return null;
    }
  }

  @override
  Future<void> writePage(int page, List<Announcement> items) async {
    final prefs = await _prefs;
    final encoded = jsonEncode(items.map((item) => item.toJson()).toList());
    await prefs.setString('$_keyPrefix$page', encoded);
  }

  @override
  Future<void> clear() async {
    final prefs = await _prefs;
    final keys = prefs.getKeys().where((key) => key.startsWith(_keyPrefix));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}

/// Cache in-memory untuk unit test dan mode demo.
class InMemoryAnnouncementCache implements AnnouncementCache {
  final Map<int, List<Announcement>> _pages = {};

  int get hitCount => _hitCount;
  int _hitCount = 0;

  @override
  Future<List<Announcement>?> readPage(int page) async {
    final items = _pages[page];
    if (items != null) _hitCount++;
    return items;
  }

  @override
  Future<void> writePage(int page, List<Announcement> items) async {
    _pages[page] = List<Announcement>.unmodifiable(items);
  }

  @override
  Future<void> clear() async {
    _pages.clear();
  }
}
