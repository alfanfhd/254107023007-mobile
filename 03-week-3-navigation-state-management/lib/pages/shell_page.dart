import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// ShellPage: wrapper dengan Material 3 NavigationBar untuk 4 tab utama.
/// Digunakan oleh ShellRoute di GoRouter.
class ShellPage extends StatelessWidget {
  const ShellPage({super.key, required this.child});
  final Widget child;

  /// Menentukan index tab aktif berdasarkan current route location
  static int _indexFromLocation(String location) {
    if (location.startsWith('/todo')) return 1;
    if (location.startsWith('/products')) return 2;
    if (location.startsWith('/stats')) return 3;
    return 0; // /home
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final selectedIndex = _indexFromLocation(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (i) {
          // context.go: navigasi via GoRouter (replace stack)
          switch (i) {
            case 0:
              context.go('/home');
            case 1:
              context.go('/todo');
            case 2:
              context.go('/products');
            case 3:
              context.go('/stats');
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Navigasi',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist),
            label: 'ToDo',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Produk',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Statistik',
          ),
        ],
      ),
    );
  }
}
