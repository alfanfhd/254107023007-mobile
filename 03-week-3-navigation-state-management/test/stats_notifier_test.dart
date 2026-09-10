import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week3_navigation/providers/stats_provider.dart';

void main() {
  group('StatsNotifier', () {
    test('berhasil memuat data atau gagal (30% chance)', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Listen agar provider tetap hidup
      final sub = container.listen(statsProvider, (_, __) {});

      // Tunggu delay 2 detik dari _fetchStats
      await Future.delayed(const Duration(seconds: 3));

      final state = sub.read();

      // State harus salah satu dari: data atau error (bukan loading)
      expect(state.hasValue || state.hasError, isTrue);
      expect(state.isLoading, isFalse);
    });

    test('refresh mereset state ke loading', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final sub = container.listen(statsProvider, (_, __) {});

      // Tunggu state awal selesai
      await Future.delayed(const Duration(seconds: 3));

      // Panggil refresh
      container.read(statsProvider.notifier).refresh();

      // Tepat setelah refresh() dipanggil, state harus AsyncLoading
      expect(sub.read().isLoading, isTrue);
    });
  });
}
