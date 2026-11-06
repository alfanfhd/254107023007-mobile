import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/ai/presentation/pages/ai_chat_page.dart';
import 'features/announcements/presentation/pages/announcement_feed_page.dart';
import 'features/notes/domain/entities/note.dart';
import 'features/notes/presentation/pages/notes_page.dart';
import 'features/notes/presentation/providers/notes_providers.dart';
import 'features/performance_lab/presentation/pages/performance_lab_page.dart';
import 'pages/announcement_page.dart';
import 'pages/home_page.dart';
import 'routes.dart';

/// Entry point demo tanpa Firebase / SQLite.
///
/// Jalankan dengan:
///   flutter run -t lib/main_demo.dart
///
/// Berguna untuk mengambil screenshot UI dan mencoba Performance Lab di
/// desktop/web tanpa menyiapkan emulator Android.
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final demoNotes = <Note>[
    Note(
      id: 1,
      title: 'Tugas Besar Pemrograman Mobile',
      body: 'Optimasi performa & dokumentasi profiling.',
      updatedAt: DateTime(2026, 11, 6),
    ),
    Note(
      id: 2,
      title: 'Jadwal Kuliah Pengganti',
      body: 'Senin, 08.00 WIB di Ruang A2.',
      updatedAt: DateTime(2026, 11, 5),
    ),
    Note(
      id: 3,
      title: 'Belanja Bulanan',
      body: 'Beli susu, roti, dan telur.',
      updatedAt: DateTime(2026, 11, 4),
    ),
  ];

  runApp(
    ProviderScope(
      overrides: [notesProvider.overrideWith((ref) async => demoNotes)],
      child: const _DemoApp(),
    ),
  );
}

class _DemoApp extends StatelessWidget {
  const _DemoApp();

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation: AppRoutes.home,
      routes: [
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: AppRoutes.announcementFeed,
          builder: (context, state) => const AnnouncementFeedPage(),
        ),
        GoRoute(
          path: AppRoutes.announcement,
          builder: (context, state) =>
              AnnouncementPage(id: state.pathParameters['id'] ?? ''),
        ),
        GoRoute(
          path: AppRoutes.notes,
          builder: (context, state) => const NotesPage(),
        ),
        GoRoute(
          path: AppRoutes.aiChat,
          builder: (context, state) => const AiChatPage(),
        ),
        GoRoute(
          path: AppRoutes.performanceLab,
          builder: (context, state) => const PerformanceLabPage(),
        ),
      ],
    );

    return MaterialApp.router(
      title: 'Campus Notify — Performance Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4A00E0)),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
