import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/prefs.dart';

final prefsRepositoryProvider = Provider((ref) => PrefsRepository());

final darkModeProvider =
    AsyncNotifierProvider<DarkModeNotifier, bool>(DarkModeNotifier.new);

class DarkModeNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() =>
      ref.watch(prefsRepositoryProvider).getDarkMode();

  Future<void> toggle() async {
    final next = !(state.value ?? false);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(prefsRepositoryProvider).setDarkMode(next);
      return next;
    });
  }
}

/// Toggle forceOffline untuk simulasi offline deterministik.
/// Matikan Wi-Fi / aktifkan mode pesawat tidak diperlukan saat ini aktif.
final forceOfflineProvider = NotifierProvider<ForceOfflineNotifier, bool>(
  ForceOfflineNotifier.new,
);

class ForceOfflineNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    // TODO: isi dari praktikum
    return const Scaffold();
  }
}
