# Dokumentasi Pull Request & Peer Review (Praktikum 2 & Refactoring)

Dokumen ini mencatat artefak Issue, Pull Request, proses *Peer Review* (Review Sejawat), serta bukti tindak lanjut refactoring hingga disetujui (*Approved*) dan di-merge ke branch `develop`.

---

## 1. Peta Issue

### Issue #12: [Bug] Pengguna Dapat Menyimpan Catatan Tanpa Judul
- **Tipe:** Bug / Validation Defect
- **Prioritas:** High
- **Deskripsi:** Pada halaman Catatan (`NotesPage`), penekanan tombol tambah catatan dapat mengeksekusi penyimpanan langsung ke database lokal meskipun judul kosong atau hanya berisi spasi. Hal ini menyebabkan inkonsistensi data di database lokal dan tampilan UI menjadi rancu (*empty card*).
- **Kriteria Penerimaan:**
  1. Catatan dengan judul kosong (`""`) wajib ditolak dengan pesan error yang jelas.
  2. Catatan dengan judul hanya spasi (*whitespace* seperti `"   "`) harus ditolak.
  3. Validasi harus berada pada *Domain Use Case*, bukan dicampur di dalam *Widget* UI.
  4. Tersedia unit test otomatis untuk menjamin regresi.

---

## 2. Template Pull Request

- **Judul PR:** `feat(notes): validasi judul kosong + test`
- **Branch Sumber:** `feat/notes-validation`
- **Branch Target:** `develop`
- **Status:** Merged via Squash

### Deskripsi PR
- **Masalah:**
  Pengguna dapat menyimpan catatan tanpa judul atau hanya spasi, menyebabkan baris catatan kosong di database SQLite dan UI. Selain itu, UI sebelumnya mengakses repositori secara langsung tanpa melewati usecase domain.
- **Solusi:**
  1. Membuat usecase `AddNote` pada `features/notes/domain/usecases/add_note.dart` dengan aturan validasi `.trim().isEmpty`.
  2. Menambahkan `ValidationFailure` pada `core/failures.dart`.
  3. Menyediakan provider `addNoteProvider` di presentation layer.
  4. Menambahkan modal dialog form input dengan penanganan pesan error real-time via `errorText` dan `SnackBar`.
  5. Menambahkan unit test komprehensif pada `test/validate_note_test.dart`.
- **Cara Uji:**
  1. Buka aplikasi -> Masuk ke menu Catatan Kampus.
  2. Klik tombol `+ Catatan Baru`.
  3. Biarkan kolom Judul kosong atau isi dengan spasi saja -> Klik `Simpan`.
  4. *Ekspektasi:* Muncul pesan error `"Judul catatan tidak boleh kosong"` dan data tidak tersimpan.
  5. Isi judul yang valid (contoh: `"Tugas Mobile Minggu 8"`) -> Klik `Simpan`.
  6. *Ekspektasi:* Dialog tertutup, catatan muncul di list, dan pesan sukses muncul.
  7. Jalankan uji otomatis di terminal:
     ```bash
     flutter test test/validate_note_test.dart
     ```
- **Closes:** #12

---

## 3. Lembar Peer Review (Review Sejawat 15 Menit)

- **Reviewer:** Mochammad Alfan Fadhilah / Peer Partner
- **Metode:** Checklist temuan dengan pola standar: **Observasi $\rightarrow$ Dampak $\rightarrow$ Usulan Konkret**.

### Temuan Review:

#### A. Temuan Kebenaran (Correctness & Edge Cases)
1. **Temuan 1 (Edge Case Whitespace):**
   - *Observasi:* Pengecekan awal hanya menggunakan `title.isEmpty`.
   - *Dampak:* Bila pengguna memasukkan karakter spasi `"   "`, validasi lolos dan judul kosong tetap tersimpan di database.
   - *Usulan Konkret:* Gunakan `title.trim().isEmpty` pada `AddNote` usecase dan trim teks sebelum dikirim ke `noteRepository.addNote`.
2. **Temuan 2 (Error State Handling & Feedback):**
   - *Observasi:* Pada draf awal dialog UI, bila usecase mengembalikan error, dialog tetap tertutup dan pesan error hanya dicetak ke konsol.
   - *Dampak:* Pengguna bingung mengapa catatannya tidak muncul di daftar dan tidak tahu penyebab kegagalannya.
   - *Usulan Konkret:* Pertahankan dialog tetap terbuka saat error terjadi, perbarui state dialog untuk menampilkan `errorText` pada `TextField`, serta munculkan `SnackBar` merah dengan pesan dari failure.

#### B. Temuan Arsitektur (Clean Architecture & Layer Boundary)
3. **Temuan Arsitektur (Bypass Usecase di UI):**
   - *Observasi:* Pada implementasi lama di `notes_page.dart`, FloatingActionButton memanggil `ref.read(noteRepositoryProvider).addNote(...)` secara langsung.
   - *Dampak:* Layer Presentation melompati domain usecase, melanggar *Dependency Rule*, dan membuat aturan validasi bisnis tidak dapat diuji secara terisolasi tanpa database.
   - *Usulan Konkret:* Buat provider `addNoteProvider` yang membungkus `AddNote` usecase, lalu panggil usecase tersebut dari UI.

#### C. Temuan Testing & Saran Keterbacaan
4. **Temuan Testing (Kasus Uji Gagal Database Belum Ada):**
   - *Observasi:* Unit test awal hanya menguji skenario judul kosong dan judul berhasil.
   - *Dampak:* Ketahanan use case saat repository melempar failure database belum terverifikasi secara otomatis.
   - *Usulan Konkret:* Tambahkan skenario test `'Meneruskan kegagalan jika repository mengalami error database'` dengan mock repository yang disimulasikan gagal (`fail = true`).
5. **Saran Keterbacaan (Pattern Arrange-Act-Assert):**
   - *Observasi:* Komentar sekat pengujian masih belum rapi.
   - *Usulan Konkret:* Berikan sekat komentar `// Arrange`, `// Act`, dan `// Assert` di setiap blok `test()` agar mudah dibaca anggota tim lain.

### Keputusan Awal Review:
> **Status:** ⚠️ **REQUEST CHANGES**
> *"Mohon perbaiki edge case whitespace di usecase, pertahankan dialog terbuka saat validasi gagal, dan lengkapi pengujian kegagalan database pada unit test."*

---

## 4. Tindak Lanjut Perbaikan (Author Refactoring)

Author telah melakukan perbaikan menyeluruh:
1. Menambahkan `.trim()` pada validasi judul di `AddNote` usecase.
2. Memperbarui `_showAddNoteDialog` dengan `StatefulBuilder` untuk mengelola `errorMessage` lokal dan menampilkan notifikasi visual.
3. Menambahkan 2 test case baru pada `validate_note_test.dart` (uji edge-case spasi dan uji failure database).
4. Menjalankan `flutter analyze` dan `dart format .` hingga 0 issue.

### Keputusan Akhir Review:
> **Status:** ✅ **APPROVED**
> *"Seluruh temuan observasi telah diperbaiki dengan sangat rapi dan memenuhi prinsip Clean Architecture. Lulus verifikasi pengujian otomatis dan siap di-merge."*

---

## 5. Merge Record
- **Metode Merge:** Squash and Merge
- **Target Branch:** `develop`
- **Commit Summary:** `feat(notes): validasi judul kosong + test (#12)`
- **Branch Cleanup:** Branch fitur `feat/notes-validation` ditutup/dihapus secara higienis setelah proses merge selesai.
