import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'repositories/note_repository.dart';

final syncServiceProvider = Provider((ref) => SyncService());
final forceOfflineProvider = NotifierProvider<ForceOfflineNotifier, bool>(ForceOfflineNotifier.new);

class ForceOfflineNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  
  void toggle(bool value) {
    state = value;
  }
}

class SyncService {
  Future<int> syncNotes(NoteRepository repo, bool isOffline) async {
    if (isOffline) {
      throw Exception('Mode offline aktif! Tidak bisa sinkronisasi.');
    }

    final dirtyCount = await repo.countDirty();
    if (dirtyCount == 0) return 0;
    
    // Simulasi upload ke server: delay 1 detik
    await Future.delayed(const Duration(seconds: 1));
    
    // Jika "berhasil", tandai bersih
    await repo.markAllSynced();
    return dirtyCount;
  }
}
