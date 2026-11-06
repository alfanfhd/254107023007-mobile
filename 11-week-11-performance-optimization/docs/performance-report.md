# Performance Report — Campus Notify Week 11

Laporan ini merangkum pekerjaan optimasi performa pada aplikasi Campus Notify,
beserta bukti sebelum/sesudah, trade-off, dan refleksi.

- **Nama**: Alfan Fahat Maulana
- **NIM**: 254107023007
- **Kelas**: Pemrograman Mobile — Semester 5
- **Minggu**: 11 — Performance Optimization
- **Tanggal**: 6 November 2026
- **Basis aplikasi**: `Week7_Clean Architecture/campus_notify`

---

## 1. Ringkasan Eksekutif

Aplikasi awal sudah memiliki arsitektur bersih, autentikasi aman, FCM, dan
fitur AI. Namun dari sisi performa terdapat empat masalah utama:

1. Banyak subtree UI ikut rebuild ketika state yang tidak dipakai berubah.
2. Daftar besar membuat seluruh objek widget di awal dan belum semua memakai
   `ListView.builder`.
3. Gambar jaringan belum di-cache dan di-decode pada ukuran tampil.
4. Feed pengumuman selalu menunggu jaringan; tidak ada cache offline.

Setelah optimasi:

- **Rebuild** berkurang: kartu dengan `ref.watch(...select(...))` tidak
  bertambah build ketika hanya label yang berubah, sedangkan kartu `watch`
  penuh bertambah. Angka ini deterministik dan dapat dilihat langsung di
  Performance Lab.
- **Alokasi widget** berkurang: demo daftar 120 item memakai
  `ListView.builder` + `itemExtent`, sehingga hanya item sekitar viewport yang
  dibuat.
- **Gambar** memakai cache disk/memori dan resize decode (`memCacheWidth`,
  `memCacheHeight`), mengurangi raster jank dan memori.
- **Waktu tunggu** berkurang dengan cache-first + stale-while-revalidate;
  aplikasi tetap menampilkan data saat offline.
- **Lifecycle** controller/listener diperbaiki, termasuk bug nyata
  “controller used after disposed” yang ditemukan lewat widget test.

`flutter analyze` bersih dan `flutter test` lulus **30/30**.

---

## 2. Lingkungan Pengukuran

| Item | Nilai |
| --- | --- |
| OS | Windows 11 |
| Flutter | 3.47.1 (stable) |
| Dart | 3.13.1 |
| DevTools | 2.60.0 |
| Build | Web (CanvasKit), mode `--profile`; debug untuk verifikasi UI |
| Browser | Google Chrome headless (CDP), SwiftShader (rasterizer software) |
| Perangkat Android | Tidak tersedia (emulator tidak terdeteksi) |

Keterbatasan environment dicatat secara eksplisit: pengukuran tidak dilakukan
di perangkat Android low-end. Karena itu, angka frame di laporan ini adalah
**indikatif** untuk sesi pengukuran tersebut. Klaim yang tidak bergantung pada
FPS (jumlah request, jumlah item, jumlah build widget, hasil test) tetap valid
dan dapat direproduksi.

---

## 3. Teknik Optimasi yang Diterapkan

| # | Teknik | Lokasi utama | Efek |
| --- | --- | --- | --- |
| 1 | `ListView.builder` + `itemExtent` | `notes_page.dart`, `announcement_feed_page.dart`, `performance_lab_page.dart` | Item dibuat lazy; `itemExtent` menghindari pengukuran ulang |
| 2 | `ref.watch(...select(...))` / pemisahan consumer | `ai_chat_page.dart`, `notes_page.dart` | Rebuild hanya pada nilai yang berubah |
| 3 | `const` widget + ekstraksi widget | `home_page.dart`, `ai_chat_page.dart`, `notes_page.dart` | Mengurangi alokasi dan memungkinkan reuse element |
| 4 | `RepaintBoundary` | `home_page.dart`, detail pengumuman | Mengisolasi repaint dari animasi/route transition |
| 5 | `MediaQuery.sizeOf` | `ai_chat_page.dart` | Tidak rebuild saat keyboard/inset berubah |
| 6 | `CachedNetworkImage` + resize memori | `announcement_card.dart` | Cache disk/memori, decode sesuai ukuran tampil |
| 7 | Cache-first + stale-while-revalidate + pagination | `announcement_repository_impl.dart`, `announcement_providers.dart` | Tampil instan dari cache, tetap jalan offline, request per halaman |
| 8 | Perbaikan lifecycle controller/listener | `ai_chat_page.dart`, `notes_page.dart`, `frame_metrics.dart` | Mencegah leak dan crash setelah dispose |

Jumlah teknik yang diterapkan melebihi syarat minimal tiga teknik.

---

## 4. Bukti Sebelum vs Sesudah

### 4.1 Perubahan struktur (deterministik)

| Aspek | Sebelum (Week 7) | Sesudah (Week 11) |
| --- | --- | --- |
| Home | Helper `_buildAnnouncementCard`, `_buildNotesCard`, `_buildAiChatCard` | `_AnnouncementCard` & `_FeatureCard` `StatelessWidget` dengan `const` |
| Home | Tanpa `RepaintBoundary` | `RepaintBoundary` pada body dan kartu konten |
| Notes | `ref.watch(searchQueryProvider)` di seluruh halaman | Hanya search field yang `select((q) => q.isNotEmpty)` |
| Notes | Dialog membuat controller tanpa dispose | `_AddNoteDialog` memiliki dan men-dispose controller di `dispose()` |
| AI Chat | Seluruh halaman `watch` pesan + loading | Daftar pesan & composer adalah consumer terpisah; composer `select` |
| AI Chat | `MediaQuery.of(context).size.width` | `MediaQuery.sizeOf(context).width` |
| AI Chat | Dialog API key tanpa dispose | `_ApiKeyDialog` memiliki controller dan men-dispose dengan benar |
| Gambar | Tidak ada (fitur feed baru) | `CachedNetworkImage` + `memCacheWidth/Height` |
| Feed | Tidak ada cache | Cache per halaman + fallback offline |
| Feed | Memuat semua data sekaligus (jika ada) | Pagination 10 item + infinite scroll |

### 4.2 Hasil pengukuran frame

Angka berikut dibaca langsung dari kartu **Frame Metrics** di Performance Lab
setelah menekan **Reset metrik** lalu melakukan scroll dengan gerakan yang sama.

| Sesi | Frame | Avg build | Avg raster | Jank | Max build | Max raster |
| --- | --- | --- | --- | --- | --- | --- |
| Scroll halaman + daftar (±8 detik) | 78 | 7,04 ms | 2,80 ms | 20 (25,6%) | 23,60 ms | 10,50 ms |
| Scroll diperpanjang (±20 detik) | 245 | 6,04 ms | 2,86 ms | 46 (18,8%) | 30,60 ms | 34,40 ms |

> **Catatan penting tentang angka “sebelum”.** Pengukuran FPS pada build Week 7
> tidak diambil sebelum kode diubah, sehingga tabel di atas adalah kondisi
> **sesudah** optimasi. Perbandingan sebelum/sesudah yang tersedia bersifat
> deterministik: perubahan struktur pada tabel 4.1, jumlah widget yang dibuat
> pada demo baseline vs optimized, dan build counter pada tabel 4.3. Laporan ini
> tidak mengklaim penurunan FPS karena klaim tersebut tidak didukung data.

> **Batas validitas.** Pengukuran berjalan di Chromium **headless** dengan
> **SwiftShader** (rasterizer software/CPU), bukan GPU perangkat nyata. Karena
> itu avg raster dan jank di sini lebih tinggi daripada yang akan terlihat di
> perangkat. Rata-rata build 6–7 ms masih di bawah budget 16,67 ms, tetapi nilai
> maksimum 23–31 ms menunjukkan masih ada frame yang melewati budget. Nilai
> maksimum harus dibaca bersama jumlah frame karena satu frame startup dapat
> mendominasi statistik. Angka ini dipakai sebagai indikator relatif dan bahan
> investigasi, bukan janji performa.

Sebagai pembanding, pada sesi verifikasi `select` dua frame pertama setelah
navigasi mencatat avg raster 79,60 ms dan max raster 157,60 ms. Frame startup
seperti ini yang membuat persentase jank terlihat tinggi; karena itu nilai
maksimum harus selalu dibaca bersama rata-rata dan jumlah frame.

### 4.3 Bukti build counter `select`

Di Performance Lab, tombol **“Ubah label saja”** mengubah `label` pada state
yang sama tanpa mengubah `counter`. Angka di bawah dibaca langsung dari kartu
`build: N×` pada build profile web (`lib/main_demo.dart`).

| Aksi | `ref.watch(provider)` | `watch(provider.select(...))` | Kesimpulan |
| --- | --- | --- | --- |
| Build pertama halaman | 1× | 1× | Keduanya build awal |
| Tekan **Ubah label saja** | 2× | 1× | `select` tidak ikut rebuild |
| Tekan **Ubah counter** | 3× | 2× | Keduanya rebuild karena nilai yang dipakai berubah |

Ini membuktikan bahwa `select` memotong rebuild yang tidak perlu. Sebelumnya,
seluruh halaman AI Chat ikut rebuild ketika status loading berubah karena
`ref.watch(aiLoadingProvider)` berada di `build` halaman.

### 4.4 Bukti unit & widget test

| Test | Jumlah | Status |
| --- | --- | --- |
| `announcement_repository_test.dart` | 3 | Lulus |
| `announcement_feed_notifier_test.dart` | 3 | Lulus |
| `ai_chat_widget_test.dart` | 3 | Lulus |
| Test lain (notes, auth, AI service, dll.) | 21 | Lulus |
| **Total** | **30** | **Lulus** |

Test yang relevan dengan performa:

- Repository: memastikan hasil jaringan ditulis ke cache dan cache dipakai saat
  offline (tidak ada request tambahan yang sia-sia).
- Feed notifier: memastikan `loadMore` berhenti di halaman terakhir dan tidak
  memanggil jaringan lagi.
- AI Chat widget: memastikan dialog, pengiriman pesan, dan fallback error tetap
  bekerja setelah refactor `select` dan pemisahan widget.

### 4.5 Screenshot

| File | Isi |
| --- | --- |
| `screenshots/home.png` | Dashboard setelah optimasi |
| `screenshots/performance-lab.png` | Ringkasan Performance Lab + frame metrics |
| `screenshots/lab-select-before.png` | Build counter sebelum label diubah |
| `screenshots/lab-select-after.png` | `watch` penuh naik, `select` tetap |
| `screenshots/lab-list-baseline.png` | Mode baseline `ListView(children: ...)` |
| `screenshots/lab-list-optimized.png` | Mode optimized `ListView.builder` |
| `screenshots/announcement-feed.png` | Feed dengan cache/pagination/gambar |
| `screenshots/notes.png` | Daftar catatan lazy |
| `screenshots/ai-chat.png` | Chat dengan pemisahan consumer |

---

## 5. Analisis Trade-off

| Keputusan | Keuntungan | Biaya / risiko |
| --- | --- | --- |
| Cache-first | Tampil instan, offline tetap jalan | Data bisa sesaat stale; perlu strategi invalidasi |
| Pagination 10 item | Frame awal ringan, memori terkendali | Butuh scroll untuk melihat data lama; error per halaman harus ditangani |
| `CachedNetworkImage` | Hemat memori & kuota | Menambah dependency dan storage gambar |
| `select` | Rebuild lebih sedikit | Selector harus stabil; objek baru setiap build dapat memicu rebuild palsu |
| `RepaintBoundary` | Isolasi repaint | Menambah layer GPU; jangan dipasang di semua tempat |
| `itemExtent` | Layout lebih cepat | Hanya cocok untuk tinggi item yang benar-benar seragam |
| Memisahkan widget | Rebuild terisolasi, mudah diuji | Jumlah class bertambah, perlu disiplin penamaan |

Prinsip yang dipakai: **optimasi harus dibuktikan**, bukan ditambahkan karena
“biasanya lebih cepat”. Contohnya, `itemExtent` hanya dipakai pada baris demo
yang tingginya memang tetap; pada kartu pengumuman yang tingginya dinamis,
tidak dipaksakan.

---

## 6. Refleksi

### 6.1 Mengapa profiling harus dilakukan sebelum optimasi?

Tanpa profiling, kita cenderung mengoptimasi bagian yang salah. Pada aplikasi
ini, dugaan awal bisa saja “AI service terlalu lambat”, padahal masalah utama
di UI adalah rebuild subtree yang tidak perlu dan daftar/gambar yang dibuat
berulang. Performance Overlay dan `FrameTiming` menunjukkan apakah beban ada di
build (UI thread) atau raster (GPU thread). Perbaikan yang tepat bergantung pada
jawaban itu: `const`/`select` mengurangi build, sedangkan image resize dan
`RepaintBoundary` mengurangi raster.

### 6.2 Kapan `const` benar-benar membantu?

`const` membantu ketika widget benar-benar tidak berubah dan dapat dipakai ulang
antar rebuild. `const` tidak akan menyelamatkan widget yang menerima data baru
setiap build. Karena itu, ekstraksi widget dan pemilihan provider yang tepat
lebih penting daripada menambahkan `const` secara sembarangan.

### 6.3 Mengapa `ListView.builder` lebih baik untuk daftar panjang?

`ListView(children:)` membuat seluruh objek widget di awal, walaupun elemen
yang benar-benar di-render tetap lazy. Untuk 120 item, selisih alokasinya sudah
terasa; untuk ribuan item, biayanya jauh lebih besar. `ListView.builder`
menunda pembuatan widget sampai item mendekati viewport, sehingga biaya awal
sebanding dengan jumlah item yang terlihat.

### 6.4 Apa risiko `RepaintBoundary` yang berlebihan?

Setiap `RepaintBoundary` membuat layer compositing tambahan. Jika dipasang pada
setiap widget kecil, biaya memori dan compositing bisa lebih besar daripada
manfaatnya. Pada proyek ini, `RepaintBoundary` hanya dipakai pada area besar
yang sering berubah atau pada batas animasi/route transition.

### 6.5 Mengapa cache offline penting untuk aplikasi kampus?

Mahasiswa sering membuka pengumuman di area dengan sinyal tidak stabil. Jika
aplikasi hanya mengandalkan jaringan, layar kosong saat offline membuat
informasi penting tidak terbaca. Dengan cache-first, data terakhir tetap
tersedia, dan banner offline memberi tahu pengguna bahwa data mungkin belum
yang terbaru.

### 6.6 Pelajaran dari bug “controller used after disposed”

Men-dispose resource adalah praktik yang benar, tetapi **waktu** dispose sama
pentingnya. `showDialog` selesai sebelum animasi pop berakhir, sehingga
controller yang di-dispose tepat setelah `await` masih dipakai `TextField`.
Solusi yang benar adalah memiliki controller di `State` widget dialog dan
men-dispose di `dispose()`. Bug ini ditemukan oleh test, bukan oleh review
manual — menegaskan nilai widget test untuk regresi lifecycle.

### 6.7 Apa yang akan dilakukan jika ada perangkat Android low-end?

Pengukuran akan diulang dalam mode `--profile` pada perangkat nyata, dengan
skenario yang sama: membuka feed, scroll 10 halaman, membuka detail gambar,
kembali, lalu membuka AI Chat. Targetnya adalah P90 frame build < 16 ms dan
P90 raster < 16 ms pada 60 Hz, serta jank < 5%. Jika masih ada jank, langkah
berikutnya adalah menganalisis DevTools timeline per frame, bukan menambah
optimasi secara acak.

---

## 7. Reproduksi

```bash
# 1. Dependensi
flutter pub get

# 2. Quality gate
dart format --set-exit-if-changed .
flutter analyze
flutter test

# 3. Demo tanpa Firebase/SQLite
flutter run -t lib/main_demo.dart

# 4. Pengukuran representatif (web)
flutter run --profile -d chrome -t lib/main_demo.dart

# 5. Aplikasi penuh (butuh konfigurasi Firebase)
flutter run
```

Langkah pengukuran di Performance Lab:

1. Buka menu **Performance Lab** dari Home.
2. Tekan **Reset metrik**, lalu scroll daftar demo.
3. Catat **Avg build**, **Avg raster**, **Jank**, dan **Max**.
4. Ubah mode **Baseline ↔ Optimized**, ulangi reset + scroll yang sama.
5. Tekan **Ubah label saja** untuk membandingkan build counter `watch` vs
   `select`.

---

## 8. Kesimpulan

Optimasi yang paling berdampak pada Campus Notify adalah pengurangan pekerjaan
UI yang berulang dan penghilangan waktu tunggu jaringan. Perubahan struktur
(`select`, `const`, ekstraksi widget, `ListView.builder`, `MediaQuery.sizeOf`)
memberi perbaikan yang dapat diverifikasi tanpa bergantung pada perangkat.
Perubahan fitur (cache-first, pagination, image cache) memberi perbaikan yang
langsung terasa oleh pengguna. Semua perubahan dijaga oleh 30 test yang lulus
dan `flutter analyze` yang bersih.
