import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Model data statistik
class Stat {
  const Stat({required this.label, required this.value});
  final String label;
  final String value;
}

/// AsyncNotifier: mensimulasikan pengambilan data statistik dari server.
/// - Delay 2 detik (simulasi network request)
/// - 30% kemungkinan gagal (simulasi error jaringan)
class StatsNotifier extends AsyncNotifier<List<Stat>> {
  @override
  Future<List<Stat>> build() async {
    // Dipanggil pertama kali saat provider dibuat
    return _fetchStats();
  }

  /// Refresh: reset ke AsyncLoading, lalu fetch ulang.
  /// AsyncValue.guard() otomatis menangkap exception → AsyncError
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchStats);
  }

  /// Simulasi network call: delay 2 detik, 30% chance throw Exception
  Future<List<Stat>> _fetchStats() async {
    await Future.delayed(const Duration(seconds: 2));

    // 30% kemungkinan gagal
    if (Random().nextDouble() < 0.3) {
      throw Exception('Gagal terhubung ke server statistik');
    }

    return const [
      Stat(label: 'Total Pengguna', value: '1.234'),
      Stat(label: 'Tugas Selesai', value: '89'),
      Stat(label: 'Tingkat Keberhasilan', value: '94%'),
    ];
  }
}

/// Provider global untuk StatsNotifier.
/// Dideklarasikan dengan tipe eksplisit — tidak duplikat dengan provider lain.
final statsProvider =
    AsyncNotifierProvider<StatsNotifier, List<Stat>>(StatsNotifier.new);
