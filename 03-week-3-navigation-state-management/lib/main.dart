import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'pages/shell_page.dart';
import 'pages/home_page.dart';
import 'pages/detail_page.dart';
import 'pages/todo_page.dart';
import 'pages/product_page.dart';
import 'pages/stats_page.dart';

// ProviderScope: wadah global semua Riverpod provider — wajib di root app
void main() => runApp(const ProviderScope(child: MyApp()));

final _router = GoRouter(
  initialLocation: '/home',
  routes: [
    // ShellRoute: halaman-halaman yang punya BottomNavigationBar
    ShellRoute(
      builder: (context, state, child) => ShellPage(child: child),
      routes: [
        // Tab 1: Navigasi GoRouter — demo push/go dengan path parameter
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomePage(),
        ),
        // Tab 2: ToDo — Riverpod NotifierProvider
        GoRoute(
          path: '/todo',
          builder: (context, state) => const TodoPage(),
        ),
        // Tab 3: Produk — AsyncNotifierProvider (simulasi network)
        GoRoute(
          path: '/products',
          builder: (context, state) => const ProductPage(),
        ),
        // Tab 4: Statistik — AsyncNotifierProvider dengan 30% failure
        GoRoute(
          path: '/stats',
          builder: (context, state) => const StatsPage(),
        ),
      ],
    ),
    // Detail page di luar ShellRoute: tidak punya bottom navigation bar
    GoRoute(
      path: '/detail/:id',
      builder: (context, state) => DetailPage(
        id: state.pathParameters['id']!,
      ),
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Week 3 — Navigation & State',
      routerConfig: _router,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
    );
  }
}
