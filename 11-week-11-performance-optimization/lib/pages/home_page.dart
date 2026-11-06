import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/providers/auth_providers.dart';
import '../routes.dart';

/// Dashboard utama.
///
/// Optimasi yang terlihat di file ini:
/// - widget dipecah menjadi class `const` ([_AnnouncementCard], [_FeatureCard]);
/// - tidak ada helper `_buildX` yang membuat ulang subtree pada setiap build;
/// - [RepaintBoundary] mengisolasi area konten dari animasi/route transition.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Campus Notify',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            key: const Key('open_performance_lab'),
            icon: const Icon(Icons.speed_rounded),
            tooltip: 'Performance Lab',
            onPressed: () => context.go(AppRoutes.performanceLab),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: () {
              ref.read(authStateProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: RepaintBoundary(
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  const Text(
                    'Halo, Mahasiswa! 👋',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Selamat datang di portal pengumuman kampus Anda.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: RepaintBoundary(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.notifications_active_rounded,
                                    color: Color(0xFF4A00E0),
                                  ),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: Text(
                                      'Pengumuman Terbaru',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF333333),
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        context.go(AppRoutes.announcementFeed),
                                    child: const Text('Lihat Semua'),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              const _AnnouncementCard(
                                id: '123',
                                title: 'Jadwal Kuliah Pengganti',
                                date: 'Hari ini, 08:00 WIB',
                                icon: Icons.schedule_rounded,
                                color: Colors.orange,
                              ),
                              const SizedBox(height: 12),
                              const _AnnouncementCard(
                                id: '124',
                                title: 'Batas Pembayaran UKT',
                                date: 'Kemarin, 15:30 WIB',
                                icon: Icons.account_balance_wallet_rounded,
                                color: Colors.red,
                              ),
                              const SizedBox(height: 12),
                              const _FeatureCard(
                                route: AppRoutes.announcementFeed,
                                title: 'Feed Pengumuman',
                                subtitle: 'Pagination, cache offline, dan gambar hemat memori',
                                icon: Icons.dynamic_feed_rounded,
                                color: Colors.teal,
                              ),
                              const SizedBox(height: 12),
                              const _FeatureCard(
                                route: AppRoutes.notes,
                                title: 'Catatan Lokal (Praktikum)',
                                subtitle: 'Fitur dari modul Clean Architecture',
                                icon: Icons.note_alt_rounded,
                                color: Colors.blue,
                              ),
                              const SizedBox(height: 12),
                              const _FeatureCard(
                                key: Key('open_ai_chat_card'),
                                route: AppRoutes.aiChat,
                                title: 'Asisten AI Kampus',
                                subtitle: 'Chat cerdas & tanya jawab jadwal dengan Gemini AI',
                                icon: Icons.smart_toy_rounded,
                                color: Colors.purple,
                              ),
                              const SizedBox(height: 12),
                              const _FeatureCard(
                                route: AppRoutes.performanceLab,
                                title: 'Performance Lab',
                                subtitle: 'Ukur frame, rebuild, dan lazy loading secara nyata',
                                icon: Icons.speed_rounded,
                                color: Color(0xFF4A00E0),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({
    required this.id,
    required this.title,
    required this.date,
    required this.icon,
    required this.color,
  });

  final String id;
  final String title;
  final String date;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go('/pengumuman/$id'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    super.key,
    required this.route,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String route;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go(route),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: color)),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: color.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}
