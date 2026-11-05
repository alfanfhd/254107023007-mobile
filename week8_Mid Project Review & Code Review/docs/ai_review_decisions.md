# Dokumentasi AI Review & Keputusan Rekayasa (AI Review Decisions)

Dokumen ini mencatat seluruh interaksi prompt AI, tabel komparasi antara usulan AI versus keputusan final pengembang, serta alasan teknis penolakan maupun penerimaan rekomendasi AI demi menjaga kemurnian arsitektur dan efisiensi kode.

---

## 1. Riwayat Prompt AI yang Digunakan

### Prompt 1: Validasi Input dan Pembuatan Usecase
> *"Bantu saya membuat fitur validasi judul catatan agar tidak boleh kosong pada arsitektur Clean Architecture Flutter, sertakan dialog UI dan unit test-nya."*

### Prompt 2: Static Analysis dan Pembersihan Warning
> *"Terdapat 12 warning pada flutter analyze termasuk deprecated withOpacity, duplicate import, dan unused import. Tolong berikan solusi paling mutakhir yang kompatibel dengan Flutter 3.27+."*

### Prompt 3: Setup Otomasi CI GitHub Actions
> *"Buatkan file workflow GitHub Actions (.github/workflows/ci.yml) yang memverifikasi formatting, analisis statis, dan unit test untuk branch develop dan main."*

---

## 2. Tabel Komparasi: Usulan AI vs Keputusan Final

| Komponen / Topik | Usulan Draf AI | Keputusan Final Pengembang | Status Keputusan | Alasan Teknis & Verifikasi |
|---|---|---|---|---|
| **Lokasi Validasi Judul** | Memvalidasi langsung di dalam `TextFormField` via `validator: (v) => ...` di file UI saja. | Memisahkan logika validasi ke dalam *Domain Use Case* (`AddNote`), UI hanya menampilkan error dari `ValidationFailure`. | ⚠️ **Ditolak & Direvisi** | Jika validasi hanya di UI, logika tidak bisa diuji melalui unit test murni tanpa me-render widget (*widget test* lebih lambat dan rentan). Pemisahan ke domain menjamin validasi konsisten terlepas dari antarmuka apa pun yang memanggilnya. |
| **Pustaka Validasi Pihak Ketiga** | Menyarankan instalasi package eksternal `flutter_form_builder` atau library validasi validator regex besar. | Menggunakan *plain Dart validation* dengan method native `.trim().isEmpty` di domain layer. | ❌ **Ditolak Penuh** | *Over-engineering* yang tidak perlu. Menambah dependency eksternal ke domain layer melanggar *Clean Architecture Dependency Rule* (Domain harus murni Dart tanpa dependensi package eksternal). |
| **Penanganan Edge Case Spasi** | Awalnya AI hanya memeriksa `title.isEmpty`. | Ditambahkan pengecekan `.trim().isEmpty` pada usecase sebelum memanggil repository. | 🔄 **Disempurnakan** | Pengecekan `.isEmpty` murni akan meloloskan input spasi kosong `"    "`. Judul spasi tetap harus dianggap kosong demi integritas data. |
| **Struktur Failure** | Menyarankan melempar exception (`throw Exception('Judul kosong')`). | Menggunakan fungsional return type tuple `({Note? note, Failure? failure})` dengan subclass `ValidationFailure`. | ⚠️ **Ditolak & Direvisi** | Melempar exception untuk *expected business error* mengaburkan *control flow* dan memaksa blok `try-catch` di UI. Fungsional return pattern lebih ekspresif, terprediksi, dan aman dari runtime crash (*exhaustiveness*). |
| **Deprecated `withOpacity`** | Menyarankan membungkus widget dengan `Opacity` widget. | Menggunakan fungsi resmi Flutter terbaru `.withValues(alpha: ...)` pada objek `Color`. | ⚠️ **Ditolak & Direvisi** | Widget `Opacity` memaksa pembuatan *saveLayer* pada compositing tree engine yang mahal secara performa (GPU overhead). `.withValues` menyelesaikan deprecation warning tanpa penalty performa rendering. |
| **Workflow CI** | Mengusulkan pipeline kompleks dengan build APK lengkap di setiap PR. | Pipeline difokuskan pada *fast-feedback verification*: `dart format`, `flutter analyze`, dan `flutter test`. | 🔄 **Disederhanakan** | Build APK pada runner cloud memakan waktu 8-15 menit dan kuota GitHub Actions berbayar. *Quality gates* utama untuk PR paruh semester adalah kebenaran kode statis dan unit test yang selesai dalam < 1.5 menit. |

---

## 3. Bukti Verifikasi Arsitektur Pasca-Keputusan

Sebelum menerima kode hasil kolaborasi dengan AI, dilakukan verifikasi mandiri menggunakan pengujian perintah *grep*:

1. **Memastikan tidak ada impor library UI di domain usecase:**
   ```bash
   Select-String -Path "lib\features\notes\domain\usecases\*.dart" -Pattern "import 'package:flutter"
   ```
   *Hasil:* **0 temuan**. Domain tetap murni Dart.

2. **Memastikan analyzer dan formatter menerima keputusan:**
   ```bash
   flutter analyze
   dart format --set-exit-if-changed .
   ```
   *Hasil:* **0 issues, exit code 0**.
