import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Hasil agregasi frame timing dari [FrameMetricsController].
///
/// Semua durasi dalam milidetik agar mudah dibaca di UI maupun laporan.
@immutable
class FrameMetrics {
  const FrameMetrics({
    this.totalFrames = 0,
    this.jankFrames = 0,
    this.avgBuildMs = 0,
    this.avgRasterMs = 0,
    this.maxBuildMs = 0,
    this.maxRasterMs = 0,
  });

  final int totalFrames;
  final int jankFrames;
  final double avgBuildMs;
  final double avgRasterMs;
  final double maxBuildMs;
  final double maxRasterMs;

  double get jankPercentage =>
      totalFrames == 0 ? 0 : (jankFrames / totalFrames) * 100;

  /// Budget frame 60 FPS. Frame di atas nilai ini dianggap jank.
  static const double frameBudgetMs = 1000 / 60;

  FrameMetrics copyWith({
    int? totalFrames,
    int? jankFrames,
    double? avgBuildMs,
    double? avgRasterMs,
    double? maxBuildMs,
    double? maxRasterMs,
  }) {
    return FrameMetrics(
      totalFrames: totalFrames ?? this.totalFrames,
      jankFrames: jankFrames ?? this.jankFrames,
      avgBuildMs: avgBuildMs ?? this.avgBuildMs,
      avgRasterMs: avgRasterMs ?? this.avgRasterMs,
      maxBuildMs: maxBuildMs ?? this.maxBuildMs,
      maxRasterMs: maxRasterMs ?? this.maxRasterMs,
    );
  }
}

/// Mengumpulkan [FrameTiming] dari engine secara nyata (bukan data dummy).
///
/// Gunakan di mode `--profile` agar hasil representatif. Widget Performance Lab
/// memakai controller ini untuk menampilkan bukti before/after di dalam aplikasi.
class FrameMetricsController extends ChangeNotifier {
  final List<FrameTiming> _timings = [];

  bool _listening = false;
  bool _disposed = false;

  FrameMetrics get metrics {
    if (_timings.isEmpty) return const FrameMetrics();

    var totalBuildUs = 0;
    var totalRasterUs = 0;
    var maxBuildUs = 0;
    var maxRasterUs = 0;
    var jank = 0;

    for (final timing in _timings) {
      final buildUs = timing.buildDuration.inMicroseconds;
      final rasterUs = timing.rasterDuration.inMicroseconds;

      totalBuildUs += buildUs;
      totalRasterUs += rasterUs;
      if (buildUs > maxBuildUs) maxBuildUs = buildUs;
      if (rasterUs > maxRasterUs) maxRasterUs = rasterUs;

      if (timing.totalSpan.inMicroseconds > FrameMetrics.frameBudgetMs * 1000) {
        jank++;
      }
    }

    final count = _timings.length;
    return FrameMetrics(
      totalFrames: count,
      jankFrames: jank,
      avgBuildMs: totalBuildUs / count / 1000,
      avgRasterMs: totalRasterUs / count / 1000,
      maxBuildMs: maxBuildUs / 1000,
      maxRasterMs: maxRasterUs / 1000,
    );
  }

  void start() {
    if (_listening) return;
    _listening = true;
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
    _notify();
  }

  void stop() {
    if (!_listening) return;
    _listening = false;
    SchedulerBinding.instance.removeTimingsCallback(_onTimings);
    _notify();
  }

  void reset() {
    _timings.clear();
    _notify();
  }

  bool get isRecording => _listening;

  void _onTimings(List<FrameTiming> timings) {
    _timings.addAll(timings);
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    stop();
    _disposed = true;
    super.dispose();
  }
}
