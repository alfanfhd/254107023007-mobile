# Dokumentasi Penggunaan AI (AI Challenge)

## 1. Prompt yang Digunakan
*   "buat lib/data/api_client.dart. Seluruh konfigurasi jaringan (base URL, timeout, logging) hidup di satu tempat:" (beserta gambar kode).
*   "Buat lib/data/models/post.dart dengan fromJson aman null" (beserta gambar kode).
*   "Buat lib/data/repositories/post_repository.dart" (beserta gambar kode).
*   "Praktikum 2: Provider dan error handling... Buat lib/data/providers.dart" (beserta gambar kode).
*   "Praktikum 3: Pagination dasar... Tambahkan method fetchPostsPage... Lanjutkan paged_posts.dart" (beserta gambar kode).
*   "Refactoring Challenge: Ekstrak widget, pindahkan friendlyErrorMessage, tambahkan halaman detail dengan GoRouter, dan buat testing."
*   "bantu saya mengerjakan tugas nya (README, docs, refleksi)"

## 2. Hasil AI
AI (Gemini) berhasil melakukan transkripsi kode dari gambar ke dalam file `.dart` dengan akurat. AI juga mampu menghubungkan file-file tersebut, memperbaiki pesan error dari `flutter test` (seperti menghapus `widget_test.dart` lama), menambahkan dependensi (seperti `dio`, `flutter_riverpod`, dan `go_router`), dan melakukan *refactoring* sesuai dengan instruksi yang diberikan pada Modul Praktikum.

## 3. Perbaikan yang Dilakukan (Human-in-the-Loop)
Meskipun AI menuliskan kodenya, saya sebagai *developer* melakukan verifikasi terhadap:
*   Mengecek apakah UI berjalan di browser/emulator dengan benar (menanyakan "hasilnya emang gini yaa" dan membandingkan *screenshot* dengan instruksi).
*   Memastikan tidak ada request HTTP sungguhan pada saat testing (`FakePostRepository`).
*   Secara berkala memantau hasil *run* dan *test* yang dijalankan oleh AI untuk memastikan semuanya *passed* (lulus).

## 4. Alasan Keputusan Teknis
*   **Kenapa memakai GoRouter?** Karena instruksi memintanya, dan `go_router` lebih mudah untuk manajemen *routing* deklaratif yang kompleks (seperti `/post/:id`).
*   **Kenapa memakai FakePostRepository?** Agar *Unit Testing* berjalan cepat dan tidak bergantung pada kestabilan internet/server JSONPlaceholder. Ini penting untuk praktik QA yang baik.
*   **Kenapa memisahkan PostTile?** Agar *ListView.builder* di UI utama (`paged_post_page.dart`) tidak membengkak panjang. Ini membuat kode UI jauh lebih mudah dibaca dan di- *maintain*.
