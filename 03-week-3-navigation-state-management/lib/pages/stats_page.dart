import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/stats_provider.dart';

/// StatsPage: halaman statistik menggunakan AsyncNotifierProvider.
/// Menampilkan loading, error (+ retry), dan data (ListView 3 item).
class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref.watch di dalam build: subscribe ke provider, rebuild saat state berubah
    final statsAsync = ref.watch(statsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistik'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            // ref.read di callback: hanya memanggil method, tidak berlangganan
            onPressed: () => ref.read(statsProvider.notifier).refresh(),
          ),
        ],
      ),
      // AsyncValue.when() menangani ketiga state sekaligus
      body: statsAsync.when(
        // State loading: tampilkan CircularProgressIndicator
        loading: () => const Center(child: CircularProgressIndicator()),

        // State error: tampilkan pesan + tombol Coba lagi
        error: (err, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                '$err',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                // ref.invalidate: reset provider ke build() ulang dari awal
                onPressed: () => ref.invalidate(statsProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Coba lagi'),
              ),
            ],
          ),
        ),

        // State data (success): tampilkan ListView 3 item statistik
        data: (stats) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: stats.length,
          itemBuilder: (context, index) {
            final stat = stats[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(stat.label),
                trailing: Text(
                  stat.value,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
