# Performance Findings — Campus Notify

Dokumen ini mencatat proses **menemukan** masalah performa, bukan hanya daftar
optimasi yang sudah diterapkan. Setiap temuan berisi gejala, bukti, akar masalah,
dampak, dan tindakan yang diambil.

- **Aplikasi**: Campus Notify (hasil pengembangan Week 7 – Clean Architecture)
- **Target codelab**: Week 11 – Performance Optimization
- **Environment pengukuran**: Windows 11, Flutter 3.47.1 (stable), Dart 3.13.1,
  Chrome headless (web-server, SwiftShader), tanpa emulator Android
- **Tanggal pengukuran**: 6 November 2026

> Catatan kejujuran: angka frame timing bergantung pada perangkat, browser,
> mode build, dan beban sistem. Angka di dokumen ini adalah hasil pengukuran
> nyata pada environment di atas, bukan angka ideal dari dokumentasi. Data yang
> bersifat deterministik (jumlah item, jumlah request, jumlah test) dipisahkan
> dari data frame yang bersifat indikatif.

---

## 1. Metode Profiling

| Alat / cara | Digunakan untuk |
| --- | --- |
| `flutter run --profile` + Performance Overlay / DevTools Performance | Melihat frame build & raster, mencari jank saat scroll |
| `FrameMetricsController` (in-app, `SchedulerBinding.addTimingsCallback`) | Merekam `FrameTiming` nyata dan menampilkan avg/max build, avg/max raster, jumlah jank |
| Widget build counter di Performance Lab | Membuktikan `ref.watch` penuh vs `ref.watch(...select(...))` |
| Toggle baseline/optimized pada demo daftar | Membandingkan pembuatan 120 widget sekaligus vs pembuatan lazy |
| `flutter test` + `flutter analyze` | Regression gate dan bukti bahwa perilaku tidak berubah |
| Perbandingan kode Week 7 vs Week 11 | Menemukan pola yang berpotensi menyebabkan rebuild/repaint berlebih |

Langkah profiling yang dilakukan:

1. Menjalankan versi awal (Week 7) dan membuka Home, Notes, AI Chat.
2. Mengaktifkan Performance Overlay untuk melihat warna frame (hijau/kuning/merah).
3. Mencatat kandidat masalah dari struktur widget dan alur state.
4. Menerapkan satu teknik, lalu mengulang pengukuran dengan skenario yang sama.
5. Menyimpan bukti berupa screenshot Performance Lab dan output quality gate.

---

## 2. Ringkasan Temuan

| ID | Temuan | Kategori | Dampak | Prioritas |
| --- | --- | --- | --- | --- |
| F1 | Halaman ikut rebuild saat state yang tidak dipakai berubah | Rebuild berlebih | Build frame naik, UI tersendat saat mengetik/mengirim chat | Tinggi |
| F2 | Daftar besar membuat seluruh instance widget di awal | Alokasi & GC | Scroll pertama berat, memori naik | Tinggi |
| F3 | Gambar jaringan full-resolution tanpa cache | Raster & memori | Jank saat scroll, decode berulang, boros kuota | Tinggi |
| F4 | Setiap membuka layar harus menunggu jaringan | Waktu tunggu | Layar kosong/loading lama, gagal total saat offline | Tinggi |
| F5 | `MediaQuery.of` dipakai untuk satu nilai ukuran | Rebuild berlebih | Rebuild saat keyboard/inset berubah | Sedang |
| F6 | Controller/listener tidak selalu di-dispose dengan benar | Memory leak | Listener menumpuk, error setelah dispose | Sedang |
| F7 | Widget monolitik dan helper `_buildX` menghalangi `const` | Rebuild & alokasi | Subtree dibuat ulang walau data sama | Sedang |

---

## 3. Detail Temuan

### F1 — Rebuild berlebih karena `watch` seluruh state

**Gejala.** Pada AI Chat versi Week 7, `AiChatPage.build` melakukan
`ref.watch(chatMessagesProvider)` dan `ref.watch(aiLoadingProvider)`. Akibatnya
seluruh halaman (AppBar, privacy notice, daftar pesan, quick suggestions, dan
input bar) ikut dijadwalkan rebuild setiap kali status loading berubah atau
pesan baru masuk.

**Bukti kode (sebelum).**

```dart
// Week7 .../ai/presentation/pages/ai_chat_page.dart
final messages = ref.watch(chatMessagesProvider);
final isLoading = ref.watch(aiLoadingProvider);

return Scaffold(
  appBar: ...,
  body: Column(children: [
    _buildPrivacyNotice(),
    Expanded(child: ListView.builder(...)),
    _buildQuickSuggestions(),
    _buildInputBar(isLoading),
  ]),
);
```

**Bukti terukur.** Demo `Performance Lab` memiliki dua kartu yang memakai state
yang sama. Setelah menekan **“Ubah label saja”**:

- kartu `ref.watch(provider)` bertambah 1 build;
- kartu `ref.watch(provider.select(...))` **tidak** bertambah build.

Angka build counter diambil langsung dari `build()` masing-masing widget, jadi
tidak bergantung pada FPS perangkat. Screenshot:
`screenshots/lab-select-before.png` dan `screenshots/lab-select-after.png`.

**Akar masalah.** Provider yang di-`watch` terlalu luas. Perubahan kecil
(`label`) memaksa konsumen yang hanya butuh `counter` ikut rebuild.

**Perbaikan.**
- `AiChatPage` tidak lagi me-watch state chat. Daftar pesan dipindah ke
  `_ChatMessageList`, input bar ke `_ChatComposer`, dan `_ChatComposer`
  memakai `ref.watch(aiLoadingProvider.select((loading) => loading))`.
- `NotesPage` tidak lagi me-watch `searchQueryProvider`. Hanya
  `_NotesSearchField` yang memakai `select((q) => q.isNotEmpty)`.
- Halaman lain memakai `select` pada nilai yang benar-benar dipakai.

**Verifikasi.** Test widget AI Chat, Notes, dan pencarian tetap lulus
(`flutter test`: 30/30).

---

### F2 — Daftar besar tidak dibangun secara lazy

**Gejala.** Beberapa daftar dirender dengan `ListView(children: ...)` atau
`Column(children: ...)` yang membuat seluruh instance widget lebih dulu. Untuk
120 baris, semua objek `_DemoRow` dialokasikan pada frame pertama, walaupun
hanya ±6 baris yang terlihat.

**Bukti kode.** Demo di `Performance Lab` sengaja menyediakan dua mode:

```dart
// Baseline: 120 widget dibuat sekaligus.
ListView(children: List<Widget>.generate(120, (i) => _DemoRow(index: i)));

// Optimized: widget dibuat sesuai viewport + tinggi baris tetap.
ListView.builder(itemCount: 120, itemExtent: 56, itemBuilder: ...);
```

**Catatan teknis.** `ListView(children:)` tetap memakai sliver lazy untuk
membangun *element*, tetapi daftar 120 **objek widget** sudah dibuat di awal.
`ListView.builder` menunda pembuatan objek widget sampai item mendekati
viewport. Perbedaan ini yang diukur, bukan klaim bahwa semua 120 baris langsung
dirender.

**Perbaikan.**
- `NotesPage` memakai `ListView.builder` + `_NoteTile` terpisah,
  `addAutomaticKeepAlives: false`.
- Feed pengumuman memakai `ListView.builder` dengan pagination `pageSize = 10`.
- Chat memakai `ListView.builder` dengan `addAutomaticKeepAlives: false`.
- Demo optimized memakai `itemExtent: 56` agar engine tidak perlu mengukur
  ulang setiap baris.

**Verifikasi.** Screenshot `screenshots/lab-list-baseline.png` dan
`screenshots/lab-list-optimized.png`; jumlah item yang di-build dapat dilihat
dari isi viewport dan keterangan mode.

---

### F3 — Gambar jaringan full-resolution tanpa cache

**Gejala.** Pada aplikasi yang menampilkan banyak gambar, setiap scroll dapat
memicu decode ulang gambar besar. Di perangkat low-end ini terasa sebagai jank
raster dan kenaikan memori.

**Akar masalah.** `Image.network` tanpa `cacheWidth/cacheHeight` menyimpan
bitmap pada resolusi asli. URL Picsum `1200×800` untuk thumbnail `96×76`
menghabiskan memori jauh lebih besar dari yang dibutuhkan.

**Perbaikan.**
- Menambahkan `cached_network_image`.
- Thumbnail memakai `memCacheWidth: 288`, `memCacheHeight: 228` (≈3× ukuran
  logis untuk layar density tinggi), `fadeInDuration: 150 ms`.
- Gambar detail memakai `memCacheWidth: 900`.
- Placeholder dan `errorWidget` berupa `ColoredBox`/ikon, bukan widget berat.
- `RepaintBoundary` memisahkan gambar dari konten yang berubah.

**Bukti kode.**
`lib/features/announcements/presentation/widgets/announcement_card.dart`.

**Verifikasi.** Feed tetap dapat di-scroll saat gambar belum selesai dimuat;
placeholder tampil dan tidak ada error layout. Test repository/feed lulus.

---

### F4 — Setiap pembukaan layar menunggu jaringan

**Gejala.** Belum ada mekanisme cache. Saat sinyal buruk, layar hanya
menampilkan spinner lalu error. Membuka kembali layar yang sama tetap memanggil
jaringan dari awal.

**Perbaikan.** Feed pengumuman memakai alur **cache-first + stale-while-revalidate**:

1. `loadInitial()` membaca cache halaman 1 dan langsung menampilkannya.
2. Data segar diambil di belakang layar, lalu menggantikan cache.
3. Hasil jaringan ditulis kembali ke cache per halaman.
4. Jika jaringan gagal dan cache tersedia, cache dikembalikan sebagai fallback
   (`fromCache: true`) dan banner offline ditampilkan.
5. Pagination menambah halaman berikutnya; `loadMore()` tidak dipanggil lagi
   ketika `hasMore == false`.

**Bukti deterministik (unit test).**
- `announcement_repository_test.dart` — hasil jaringan ditulis ke cache;
  kegagalan jaringan mengembalikan cache; tanpa cache menghasilkan
  `NetworkFailure`.
- `announcement_feed_notifier_test.dart` — cache tampil lalu data segar;
  `loadMore` menambah 10 + 4 item dan berhenti di akhir (hanya 2 request);
  kegagalan jaringan mempertahankan 3 item cache dan menampilkan error.

**Dampak.** Tidak ada perubahan jumlah request pada skenario normal, tetapi
waktu tampil pertama berkurang karena cache dirender sebelum jaringan selesai.
Saat offline, layar tetap berisi data alih-alih kosong.

---

### F5 — `MediaQuery.of` untuk satu nilai

**Gejala.** `MediaQuery.of(context).size.width` membuat widget bergantung pada
seluruh `MediaQueryData`. Perubahan `viewInsets` (keyboard muncul) ikut
menjadwalkan rebuild bubble chat yang lebarnya tidak berubah.

**Perbaikan.**

```dart
// Sebelum
maxWidth: MediaQuery.of(context).size.width * 0.78,

// Sesudah
final maxWidth = MediaQuery.sizeOf(context).width * 0.78;
```

`MediaQuery.sizeOf` hanya rebuild ketika ukuran layar berubah. Diterapkan pada
`_MessageBubble` di AI Chat.

**Verifikasi.** Test widget chat (termasuk membuka dialog dan mengirim pesan)
lulus; tidak ada overflow pada viewport test 800×600.

---

### F6 — Siklus hidup controller dan listener

**Gejala 1.** Dialog API Key membuat `TextEditingController` di dalam
`_showApiKeyDialog`, lalu tidak pernah men-dispose. Ini leak kecil yang
berulang setiap dialog dibuka.

**Gejala 2 (regresi yang ditemukan saat test).** Perbaikan pertama mencoba
men-dispose controller tepat setelah `await showDialog(...)`. Ternyata
`showDialog` selesai sebelum animasi pop selesai; `TextField` masih dibangun
ulang dan mengakses controller yang sudah di-dispose:

```
A TextEditingController was used after being disposed.
Tried to build dirty widget in the wrong build scope.
```

Kegagalan ini juga merusak test berikutnya karena tree focus dalam keadaan
tidak konsisten. Ini contoh penting bahwa “dispose” yang salah waktu lebih
berbahaya daripada tidak dispose.

**Perbaikan final.** Controller dimiliki oleh `State` dari widget dialog
(`_ApiKeyDialog`, `_AddNoteDialog`) dan di-dispose di `dispose()` milik
`State`. Solusi ini mengikuti siklus hidup route dialog dan aman terhadap
animasi pop.

**Perbaikan lain.**
- `ScrollController` feed: `removeListener` sebelum `dispose`.
- `FrameMetricsController`: `stop()` + flag `_disposed` agar callback yang
  datang terlambat tidak memanggil `notifyListeners()` pada objek mati.
- `AiChatPage`: `TextEditingController` dan `ScrollController` di-dispose.

**Verifikasi.** `flutter test` 30/30 lulus, termasuk tiga test widget AI Chat
yang sebelumnya gagal.

---

### F7 — Widget monolitik dan helper `_buildX`

**Gejala.** Week 7 banyak memakai method `_buildAnnouncementCard`,
`_buildNotesCard`, `_buildAiChatCard`, `_buildMessageBubble`, dan sebagainya.
Method helper tetap membuat subtree baru setiap build dan tidak bisa diberi
`const`. Halaman juga sulit diuji/di-reuse.

**Perbaikan.**
- Home: `_AnnouncementCard` dan `_FeatureCard` menjadi class `StatelessWidget`
  dengan constructor `const`.
- AI Chat: `_PrivacyNotice`, `_LoadingBubble`, `_MessageBubble`,
  `_SenderLabel`, `_QuickSuggestions`, `_SuggestionChip`, `_ChatComposer`.
- Notes: `_NotesSearchField`, `_NotesEmptyState`, `_NotesErrorState`,
  `_NotesList`, `_NoteTile`.
- Feed: `_AnnouncementRow`, `_FeedFooter`, `_OfflineBanner`, `_FeedSkeleton`,
  `_FeedErrorState`.

**Dampak.** Subtree yang tidak berubah dapat dipakai ulang oleh Flutter,
`const` mengurangi alokasi, dan tanggung jawab tiap widget jelas.

---

## 4. Prioritas Perbaikan

Urutan pengerjaan dipilih berdasarkan rasio dampak terhadap risiko:

| Urutan | Temuan | Alasan |
| --- | --- | --- |
| 1 | F4 cache & pagination | Dampak paling terasa ke pengguna (waktu tunggu/offline) |
| 2 | F1 `select` | Perubahan kecil, dampak langsung ke jumlah rebuild |
| 3 | F2 lazy list | Mencegah biaya awal pada daftar besar |
| 4 | F3 image cache | Mengurangi raster jank dan memori |
| 5 | F6 lifecycle | Mencegah leak dan crash yang sulit dilacak |
| 6 | F5/F7 const & ekstraksi | Perbaikan struktural jangka panjang |

---

## 5. Yang Tidak Dioptimasi (dan Alasannya)

- **Isolate untuk JSON decoding.** Payload Picsum kecil (±10 item/halaman).
  Biaya spawn isolate lebih besar daripada manfaatnya. Akan relevan jika
  payload mencapai ratusan KB.
- **`compute()` untuk parsing.** Sama seperti di atas; belum menjadi bottleneck.
- **Shimmer/skeleton library.** Skeleton sederhana sudah cukup; menambah
  dependency hanya untuk animasi tidak sepadan.
- **Custom `SliverList` di feed.** `ListView.builder` sudah memenuhi kebutuhan;
  migrasi ke sliver menambah kompleksitas tanpa bukti bottleneck.
- **Cache gambar di memori tanpa batas.** `cached_network_image` sudah mengelola
  cache disk/memori; menambah cache manual berisiko double memory.

---

## 6. Kesimpulan Temuan

Masalah performa paling berdampak pada aplikasi ini bukan algoritma berat,
melainkan **pekerjaan UI yang berulang**: rebuild subtree yang tidak berubah,
membuat widget daftar lebih awal, decode gambar berulang, dan menunggu jaringan
tanpa cache. Perbaikan yang paling murah ( `select`, `const`, `ListView.builder`,
`MediaQuery.sizeOf`) menghasilkan perubahan struktur yang jelas dan dapat
diverifikasi dengan test deterministik. Perbaikan yang berorientasi pengguna
(cache-first, pagination, image cache) membutuhkan lebih banyak kode, tetapi
langsung menghilangkan layar kosong dan jank saat scroll.
