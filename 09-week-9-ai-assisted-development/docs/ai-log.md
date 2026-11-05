# AI Engineering Log & Verification Report (docs/ai-log.md)

Dokumen ini mencatat seluruh proses siklus *AI-Assisted Development*: formulasi prompt 5 slot, respons mentah AI, proses verifikasi 6 langkah, bukti test merah (bug reproduksi), isolasi ke Clean Architecture, serta penolakan halusinasi AI.

---

## 1. Praktikum 1: Prompt & Context Engineering

### 1.1 Formula 5 Slot
Sesuai formula prompt rekayasa konteks:
- **Peran:** Senior Flutter Architect & Mobile Developer.
- **Konteks:** Fitur catatan kampus dengan struktur *Feature-First Clean Architecture*, menggunakan state management `flutter_riverpod: ^3.4.3`, SQLite lokal, dan Dio.
- **Tugas:** Tambahkan fungsionalitas pencarian judul catatan (*search notes by title*) dan status tampilan kosong (*empty state*) ketika hasil tidak ditemukan.
- **Batas:** Jangan merusak arsitektur (dilarang memanggil database dari UI atau memasukkan library Flutter ke domain layer), panjang fungsi UI di bawah 40 baris, murni gunakan Clean Architecture.
- **Output:** Kode domain use case murni, notifier state Riverpod 3, widget pencarian dengan empty state, serta 3 test case unit/widget.

### 1.2 Perbandingan Prompt Buruk vs Prompt Baik
- **Prompt Buruk (Vibe Coding):**
  > *"Buatkan search notes yang keren dong dan ada empty state-nya."*  
  *(Dampak: AI membuat fungsi monolithic 150 baris yang langsung mengakses SQLite di dalam `onChanged` TextField widget, tidak bisa di-unit test, dan melanggar prinsip dependensi).*
- **Prompt Baik (Structured Context):**
  > *"Tambah search judul notes.  
  Arsitektur: presentation -> domain <- data.  
  Jangan panggil SQLite dari widget.  
  Sertakan usecase murni di domain, Notifier di presentation, dan widget test untuk empty state."*

### 1.3 Manajemen Privasi & Secret
- Seluruh kredensial sensitif seperti FCM token dan JWT Authorization disaring menggunakan placeholder: `TOKEN_PLACEHOLDER`.
- Konteks hanya memberikan potongan kontrak interface `NoteRepository` dan versi dependensi `pubspec.yaml` tanpa mengunggah seluruh repositori.

---

## 2. Praktikum 2: Output Mentah AI vs Hasil Verifikasi 6 Langkah

### 2.1 Draf Awal Kode yang Dihasilkan AI (Unverified)
```dart
// Draf Awal yang Diusulkan AI (Mengandung Halusinasi & Bug)
final searchQueryProvider = StateProvider<String>((ref) => ''); // Bug 1: StateProvider deprecated/removed di Riverpod 3

class NotesSearchWidget extends StatelessWidget {
  // Bug 2: Logika filter langsung di dalam widget UI
  List<Note> filter(List<Note> list, String query) {
    return list.where((n) => n.title.contains(query)).toList(); // Bug 3: Case-sensitive search!
  }
}
```

### 2.2 Verifikasi 6 Langkah
1. **Baca tiap baris kode:** Menemukan bahwa draf AI menaruh logika pemfilteran di dalam widget UI dan melakukan pencarian string case-sensitive.
2. **Cek impor (Dependency Rule):** Memastikan domain usecase `search_notes.dart` murni Dart tanpa `package:flutter`, `package:dio`, maupun `package:sqflite`.
3. **Cek API nyata & Versi Package:**
   - Memeriksa `pubspec.lock` dan menemukan `flutter_riverpod: ^3.4.3`.
   - **Halusinasi API Ditemukan:** `StateProvider` telah dihapus pada Riverpod v3! Solusi: menggantinya dengan `NotifierProvider` dan class `Notifier<String>`.
4. **Analisis Statis (`flutter analyze`):** Menjalankan analyzer hingga **0 issues found**.
5. **Penulisan Unit & Widget Test:** Menulis `test/search_filter_test.dart` dan `test/empty_state_widget_test.dart`.
6. **Uji Manual 3 Skenario:** Query kosong, query cocok, query tidak cocok (empty state).

### 2.3 Bukti Halusinasi & Bug yang Ditemukan (Wajib)
| Kategori | Temuan Halusinasi / Bug | Bukti Cara Membuktikan | Solusi & Refactoring |
|---|---|---|---|
| **Package Kadaluarsa** | AI menggunakan `StateProvider<String>((ref) => '')`. | Kompilator melempar error: `Error: Method not found: 'StateProvider'`. | Diganti menggunakan `Notifier<String>` resmi Riverpod 3.x (`SearchQueryNotifier`). |
| **Logika Yakin tapi Salah** | Filter awal AI `note.title.contains(query)` bersifat *case-sensitive*. | Test merah: mencari `"belanja"` menghasilkan 0 hasil padahal ada `"Belanja Bulanan"`. | Menggunakan `.trim().toLowerCase()` pada query dan judul catatan. |
| **Pelanggaran Arsitektur** | Logika pemfilteran ditaruh di dalam method widget UI. | Grep sterilitas menemukan logika bisnis di layer presentation. | Dipindahkan ke *Domain Use Case* murni `SearchNotes`. |

---

## 3. Praktikum 3: Debug & Refactor (Test Merah ke Hijau)

### 3.1 Siklus Test Merah (Red-Green-Refactor)
1. **Reproduksi Masalah:** Pengguna mencari kata `"belanja"` dengan huruf kecil, namun sistem mengembalikan daftar kosong karena data di database berjudul `"Belanja Bulanan"`.
2. **Test Merah:** Dibuat pengujian unit:
   ```dart
   test('filter abaikan huruf besar/kecil (case-insensitive search)', () {
     final results = searchNotes(notes: sampleNotes, query: 'belanja');
     expect(results.length, 2); // Awalnya GAGAL (merah) dengan draf mentah AI
   });
   ```
3. **Perbaikan (Hijau):** Implementasi usecase `SearchNotes`:
   ```dart
   class SearchNotes {
     const SearchNotes();

     List<Note> call({required List<Note> notes, required String query}) {
       final trimmedQuery = query.trim().toLowerCase();
       if (trimmedQuery.isEmpty) return notes;
       return notes.where((note) => note.title.toLowerCase().contains(trimmedQuery)).toList();
     }
   }
   ```
4. **Hasil:** Pengujian `flutter test test/search_filter_test.dart` langsung berstatus **LULUS (Hijau)**.

### 3.2 Refactor ke Layer yang Benar (Arsitektur Bersih)
- **Widget (UI Saja):** Menampilkan TextField pencarian, tombol clear, dan delegasi rendering ke ListView atau Empty State. Seluruh fungsi dipisah di bawah 40 baris.
- **Notifier (State Saja):** `SearchQueryNotifier` mengelola perubahan string query reaktif.
- **Use Case (Aturan Filter/Search):** `SearchNotes` mengisolasi logika pencarian murni Dart.
- **Repository (SQLite):** `NoteRepository` tetap fokus pada persistensi data.

---

## 4. Checklist Verifikasi Mandiri Minggu 9

- [x] **Prompt 5 slot terdefinisi jelas** dan didokumentasikan di `docs/ai-log.md`.
- [x] **`flutter analyze` bersih** (0 issues found).
- [x] **`flutter test` hijau** (15/15 tests passed, mencakup unit test dan widget test).
- [x] **1 temuan AI dibuktikan benar** (perancangan widget empty state yang interaktif).
- [x] **1 halusinasi AI ditolak beralasan** (penggunaan `StateProvider` yang kadaluarsa di Riverpod 3 dan filter case-sensitive).
- [x] **Mampu menjelaskan alur tanpa membuka AI** (siklus *Prompt -> Generate -> Verify -> Test -> Refactor -> Explain*).
