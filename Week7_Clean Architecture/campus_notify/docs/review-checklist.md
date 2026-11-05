# Checklist Kesiapan Tengah Semester & Audit Riwayat (Mid-Project Review)

Dokumen ini memuat audit riwayat Git, pembuktian sterilitas arsitektur (Clean Architecture), status kelulusan pengujian mesin (CI/Static Analysis/Testing), serta checklist verifikasi mandiri sebelum rilis paruh semester.

---

## 1. Audit Riwayat Git & Hygiene Branch (Praktikum 1)

### 1.1 Hasil Pemeriksaan Awal
- **Perintah Audit:** `git log --oneline -15`, `git branch -a`, `git status`
- **Temuan Masalah:**
  1. **Commit Langsung ke `main`:** Seluruh riwayat pengerjaan sebelumnya di-commit langsung ke branch `main` tanpa melalui branch staging (`develop`) atau branch fitur terisolasi.
  2. **Format Pesan Commit Belum Baku:** Banyak commit menggunakan format non-standar / terlalu generik (contoh: *"Update course work"*, *"Update README with screenshots"*), menyulitkan penelusuran riwayat fungsional dan otomatisasi changelog.
  3. **File Tak Terlacak (Untracked Files):** Ditemukan file konfigurasi editor/alat (`devtools_options.yaml`) yang belum di-ignore melalui `.gitignore`.

### 1.2 Tabel Simulasi Perbaikan Pesan Commit Buruk
Sesuai panduan *Conventional Commits* (`<type>(<scope>): <deskripsi pendek>`):

| Hash / Pesan Awal | Format Konvensional Baru | Alasan Perubahan (Apa, Di mana, Buktinya) |
|---|---|---|
| `10f1d62 Update course work` | `feat(api): integrasi pagination dan rest api dummyjson + unit test` | Pesan lama sangat kabur. Format baru menjelaskan penambahan fitur API pada modul networking beserta bukti unit test. |
| `cd72f54 Add Week 6 Authentication, Security and FCM` | `feat(auth): implementasi jwt interceptor dan penerimaan push fcm` | Menjelaskan secara spesifik penambahan arsitektur login token secure storage dan integrasi FCM multi-state. |
| `1a38dab Update README with screenshots` | `docs(readme): lengkapi tabel pengujian tiga app state dan bukti visual` | Membedakan tipe dokumentasi (`docs`) dari perubahan kode logika, serta merinci bagian mana yang diperbarui. |
| `7569448 Menyelesaikan Tugas Week 3: GoRouter...` | `feat(nav): konfigurasi deklaratif gorouter dan riverpod todo state` | Mengganti gaya narasi kalimat panjang dengan tipe `feat`, scope `nav`, dan kata kerja imperatif yang jelas. |

---

## 2. Bukti Sterilitas Clean Architecture (Hasil Grep Minggu 7)

Pengujian ini memastikan tidak ada kebocoran dependensi antar-lapisan (*Dependency Rule*):

### 2.1 Domain Bebas Framework / Package Eksternal (Steril)
- **Tujuan:** Domain harus murni logika bisnis Dart (*Plain Dart Objects*), tanpa dependensi UI (`flutter`), network (`dio`), database (`sqflite`), maupun vendor (`firebase`).
- **Perintah Uji:**
  ```bash
  Select-String -Path "lib\features\*\domain\*.dart", "lib\features\*\domain\*\*.dart", "lib\core\*.dart" -Pattern "import 'package:flutter/|import 'package:dio|import 'package:sqflite|import 'package:firebase"
  ```
- **Hasil:** `0 Temuan` (**LULUS 100%**). Tidak ada kebocoran framework ke Domain Layer.

### 2.2 Presentation Bebas Akses Data Mentah Langsung
- **Tujuan:** UI/Presentation hanya boleh berkomunikasi lewat *Use Case* atau *Notifier Provider*, dilarang langsung menyentuh raw storage, driver Dio, atau raw SQL.
- **Perintah Uji:**
  ```bash
  Select-String -Path "lib\features\*\presentation\*.dart", "lib\pages\*.dart" -Pattern "openDatabase|getDatabasesPath|FlutterSecureStorage|SharedPreferences\.getInstance|jsonDecode"
  ```
- **Hasil Awal & Refactoring:**
  - Sebelumnya terdapat inisialisasi `openDatabase` di dalam `notes_providers.dart` yang berada di folder presentation.
  - **Refactoring:** Pembukaan koneksi diisolasi ke implementasi repositori data, dan pembuatan catatan dialihkan melalui use case `AddNote` sehingga UI tidak memanggil `NoteRepository` secara langsung.
  - Status: **TERSELESAIKAN (LULUS)**.

---

## 3. Hasil Pemeriksaan Mesin (Static Analysis, Formatting, Tests)

Semua pemeriksaan mesin dijalankan secara otomatis melalui runner CI (`.github/workflows/ci.yml`) dan lokal:

| Perintah Pemeriksaan | Target Standar | Status Aktual | Keterangan |
|---|---|---|---|
| `flutter analyze` | 0 error, 0 warning, 0 info | **HIJAU (0 Issues)** | Telah dibersihkan 12 issues (duplicate import, unused import, constructor formals, deprecated member). |
| `dart format --set-exit-if-changed .` | 0 file terformat ulang (exit code 0) | **HIJAU (Exit 0)** | 26 file Dart terformat seragam dan konsisten. |
| `flutter test` | Seluruh unit test lulus | **HIJAU (10/10 Passed)** | Mencakup pengujian otentikasi, push route, usecase get notes, dan usecase validasi note. |

---

## 4. Checklist Kesiapan Paruh Semester (Mid-Review)

- [x] **Struktur Feature-First Terbukti:** Modul aplikasi dipisahkan per fitur (`auth`, `notes`), masing-masing memiliki sub-layer `data/`, `domain/`, dan `presentation/`.
- [x] **Pemeriksaan Mesin Bersih:** `flutter analyze`, `dart format`, dan `flutter test` seluruhnya berstatus hijau.
- [x] **Hygiene Git & Branching:** Menggunakan alur kerja `develop` dan branch fitur `feat/*`, tidak ada pengerjaan langsung di `main`.
- [x] **Pull Request Kecil & Terfokus:** Satu PR menangani satu masalah terisolasi (`feat(notes): validasi judul kosong + test`) lengkap dengan deskripsi, solusi, dan cara uji.
- [x] **Peer Review Berkualitas:** Review sejawat menghasilkan temuan kebenaran, arsitektur, dan test dengan pola *observasi -> dampak -> usulan konkret*, ditindaklanjuti hingga *Approve*.
- [x] **Pencegahan Regresi Otomatis (CI):** File `.github/workflows/ci.yml` terkonfigurasi untuk memverifikasi formatting, analyzer, dan unit test pada setiap PR ke `develop` dan `main`.
- [x] **Dokumentasi Lengkap:** README memuat status paruh semester, peta issue/PR, arsitektur, panduan menjalankan, hasil capaian, dan refleksi mendalam.
