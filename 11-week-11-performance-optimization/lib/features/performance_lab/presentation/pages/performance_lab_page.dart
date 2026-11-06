import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/performance/frame_metrics.dart';
import '../providers/lab_providers.dart';

/// Halaman laboratorium performa.
///
/// Semua angka frame di halaman ini berasal dari `FrameTiming` engine melalui
/// [FrameMetricsController], bukan angka statis di dokumentasi.
class PerformanceLabPage extends ConsumerStatefulWidget {
  const PerformanceLabPage({super.key});

  @override
  ConsumerState<PerformanceLabPage> createState() => _PerformanceLabPageState();
}

class _PerformanceLabPageState extends ConsumerState<PerformanceLabPage> {
  late final FrameMetricsController _metrics;

  @override
  void initState() {
    super.initState();
    _metrics = FrameMetricsController()..start();
  }

  @override
  void dispose() {
    _metrics.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Lab'),
        actions: [
          IconButton(
            tooltip: 'Reset metrik',
            onPressed: _metrics.reset,
            icon: const Icon(Icons.restart_alt_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          const _LabIntro(),
          const SizedBox(height: 16),
          _FrameMetricsCard(controller: _metrics),
          const SizedBox(height: 16),
          const _RebuildIsolationDemo(),
          const SizedBox(height: 16),
          const _LazyListDemo(),
          const SizedBox(height: 16),
          const _AppliedOptimizationsCard(),
        ],
      ),
    );
  }
}

class _LabIntro extends StatelessWidget {
  const _LabIntro();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.speed_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Bukti Optimasi di Dalam Aplikasi',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Rekam frame saat scroll, bandingkan baseline vs optimized, dan '
            'lihat jumlah rebuild widget. Gunakan mode --profile untuk hasil '
            'yang paling representatif.',
            style: TextStyle(color: Colors.white70, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _FrameMetricsCard extends StatelessWidget {
  const _FrameMetricsCard({required this.controller});

  final FrameMetricsController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final metrics = controller.metrics;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Frame Metrics',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: controller.isRecording
                          ? controller.stop
                          : controller.start,
                      icon: Icon(
                        controller.isRecording
                            ? Icons.stop_circle_outlined
                            : Icons.fiber_manual_record,
                        size: 18,
                      ),
                      label: Text(controller.isRecording ? 'Stop' : 'Rekam'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Budget 60 FPS = 16,67 ms/frame. Jank = frame di atas budget.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetricTile(
                      label: 'Frame',
                      value: '${metrics.totalFrames}',
                      icon: Icons.movie_outlined,
                    ),
                    _MetricTile(
                      label: 'Avg build',
                      value: '${metrics.avgBuildMs.toStringAsFixed(2)} ms',
                      icon: Icons.build_outlined,
                      highlight: metrics.avgBuildMs > 8,
                    ),
                    _MetricTile(
                      label: 'Avg raster',
                      value: '${metrics.avgRasterMs.toStringAsFixed(2)} ms',
                      icon: Icons.gradient_outlined,
                      highlight: metrics.avgRasterMs > 8,
                    ),
                    _MetricTile(
                      label: 'Jank',
                      value:
                          '${metrics.jankFrames} '
                          '(${metrics.jankPercentage.toStringAsFixed(1)}%)',
                      icon: Icons.warning_amber_rounded,
                      highlight: metrics.jankFrames > 0,
                    ),
                    _MetricTile(
                      label: 'Max build',
                      value: '${metrics.maxBuildMs.toStringAsFixed(2)} ms',
                      icon: Icons.trending_up_rounded,
                    ),
                    _MetricTile(
                      label: 'Max raster',
                      value: '${metrics.maxRasterMs.toStringAsFixed(2)} ms',
                      icon: Icons.photo_size_select_large_outlined,
                    ),
                  ],
                ),
                if (metrics.totalFrames == 0) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Belum ada frame terekam. Scroll halaman ini atau tekan '
                    'tombol rekam.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    this.highlight = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final color = highlight ? Colors.red.shade700 : const Color(0xFF4A00E0);
    return Container(
      width: 130,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(fontSize: 11, color: color)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _RebuildIsolationDemo extends ConsumerWidget {
  const _RebuildIsolationDemo();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Riverpod select: kurangi rebuild',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Ubah label: kartu "watch penuh" rebuild, kartu "select" tidak. '
              'Ubah counter: keduanya rebuild.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _FullStateWatcher()),
                SizedBox(width: 8),
                Expanded(child: _SelectedCounterWatcher()),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed: () =>
                      ref.read(labCounterProvider.notifier).incrementCounter(),
                  child: const Text('Ubah counter'),
                ),
                OutlinedButton(
                  onPressed: () =>
                      ref.read(labCounterProvider.notifier).changeLabel(),
                  child: const Text('Ubah label saja'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FullStateWatcher extends ConsumerStatefulWidget {
  const _FullStateWatcher();

  @override
  ConsumerState<_FullStateWatcher> createState() => _FullStateWatcherState();
}

class _FullStateWatcherState extends ConsumerState<_FullStateWatcher> {
  int _buildCount = 0;

  @override
  Widget build(BuildContext context) {
    _buildCount++;
    final state = ref.watch(labCounterProvider);
    return _WatcherCard(
      title: 'ref.watch(provider)',
      subtitle: 'Counter: ${state.counter}\nLabel: ${state.label}',
      buildCount: _buildCount,
      color: Colors.red,
    );
  }
}

class _SelectedCounterWatcher extends ConsumerStatefulWidget {
  const _SelectedCounterWatcher();

  @override
  ConsumerState<_SelectedCounterWatcher> createState() =>
      _SelectedCounterWatcherState();
}

class _SelectedCounterWatcherState
    extends ConsumerState<_SelectedCounterWatcher> {
  int _buildCount = 0;

  @override
  Widget build(BuildContext context) {
    _buildCount++;
    final counter = ref.watch(
      labCounterProvider.select((state) => state.counter),
    );
    return _WatcherCard(
      title: 'watch(provider.select)',
      subtitle: 'Counter: $counter\nLabel: tidak dipakai',
      buildCount: _buildCount,
      color: Colors.green,
    );
  }
}

class _WatcherCard extends StatelessWidget {
  const _WatcherCard({
    required this.title,
    required this.subtitle,
    required this.buildCount,
    required this.color,
  });

  final String title;
  final String subtitle;
  final int buildCount;
  final MaterialColor color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color.shade700,
            ),
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(fontSize: 11)),
          const SizedBox(height: 6),
          Text(
            'build: $buildCount×',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LazyListDemo extends StatefulWidget {
  const _LazyListDemo();

  @override
  State<_LazyListDemo> createState() => _LazyListDemoState();
}

class _LazyListDemoState extends State<_LazyListDemo> {
  bool _optimized = true;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lazy list: ListView.builder',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              _optimized
                  ? 'Mode optimized: hanya item di sekitar viewport yang '
                        'di-build + itemExtent tetap.'
                  : 'Mode baseline: semua 120 item dibuat sekaligus oleh '
                        'ListView(children: ...).',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: false,
                  label: Text('Baseline'),
                  icon: Icon(Icons.warning_amber_rounded),
                ),
                ButtonSegment(
                  value: true,
                  label: Text('Optimized'),
                  icon: Icon(Icons.bolt_rounded),
                ),
              ],
              selected: {_optimized},
              onSelectionChanged: (selection) {
                setState(() => _optimized = selection.first);
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 260,
              child: _optimized ? _buildOptimizedList() : _buildBaselineList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptimizedList() {
    return ListView.builder(
      key: const ValueKey('optimized-demo-list'),
      itemCount: 120,
      itemExtent: 56,
      itemBuilder: (context, index) => _DemoRow(index: index),
    );
  }

  Widget _buildBaselineList() {
    return ListView(
      key: const ValueKey('baseline-demo-list'),
      children: List<Widget>.generate(
        120,
        (index) => _DemoRow(index: index),
        growable: false,
      ),
    );
  }
}

class _DemoRow extends StatelessWidget {
  const _DemoRow({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: index.isEven ? const Color(0xFFF3F0FF) : const Color(0xFFF8F8FC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: const Color(0xFF4A00E0),
            child: Text(
              '${index + 1}',
              style: const TextStyle(fontSize: 10, color: Colors.white),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Item pengumuman ${index + 1}',
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _AppliedOptimizationsCard extends StatelessWidget {
  const _AppliedOptimizationsCard();

  @override
  Widget build(BuildContext context) {
    const items = [
      'ListView.builder + itemExtent untuk lazy loading.',
      'const constructor & ekstraksi widget untuk menekan rebuild.',
      'Riverpod select agar widget hanya rebuild saat datanya berubah.',
      'RepaintBoundary pada area yang sering berubah (lihat HomePage).',
      'CachedNetworkImage + memCacheWidth/Height untuk gambar.',
      'Pagination + cache stale-while-revalidate di feed pengumuman.',
      'dispose() untuk controller, listener, dan frame callback.',
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Optimasi yang diterapkan',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 16,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(item, style: const TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
