# AI Challenge & Refleksi

## Refleksi
**1. Mengapa daftar catatan tidak boleh disimpan di SharedPreferences? Apa yang rusak jika aturan ini dilanggar?**
SharedPreferences tidak didesain untuk menyimpan koleksi data (list/array) yang besar dan kompleks karena cara kerjanya adalah membaca dan menulis seluruh isi file (I/O block) sekaligus dalam format XML/JSON. Menyimpan daftar catatan (ratusan/ribuan item) akan menyebabkan memori membengkak (OOM), pembacaan yang lambat sehingga memblokir UI thread (jank), serta rawan rusak/korup jika terjadi concurrent write. 

**2. Kapan cache-first cukup, dan kapan Anda membutuhkan strategi lain (misalnya network-first untuk data harga real-time)?**
Cache-first cukup untuk data yang jarang berubah, bisa ditoleransi perbedaannya, atau murni konsumsi konten (seperti postingan blog, pengaturan tema, riwayat catatan). Strategi ini memastikan UI cepat tampil dan bisa diakses saat offline. Namun, untuk data kritikal/sensitif waktu seperti harga saham, saldo bank, atau ketersediaan tiket penerbangan, strategi `network-first` (atau WebSocket) wajib digunakan agar user tidak mengambil keputusan berdasarkan data basi.

**3. Bagaimana dirty flag berubah menjadi antrean sync tanpa memblokir UI? Kapan antrean terpisah (tabel outbox) menjadi perlu?**
Dengan dirty flag (`dirty = 1`), sinkronisasi dilakukan di *background* menggunakan `AsyncNotifier` (Riverpod) atau worker. UI hanya bertugas bereaksi jika flag tersebut berubah dengan menampilkan badge. Proses upload (network call) dijalankan di *isolate* atau *microtask* terpisah dari proses render Flutter, sehingga tidak *blocking*. Tabel antrean terpisah (`outbox`) menjadi perlu jika transaksi melibatkan urutan ketat (contoh: *Create* lalu *Update* pada item yang sama), butuh *retry mechanism* yang kompleks, atau jika kita mendukung multi-resource modification (membuat folder sekaligus memindahkan catatan).

**4. Bagian mana dari rekomendasi AI yang Anda tolak, dan mengapa?**
(Asumsi) AI mungkin merekomendasikan `Hive` untuk menggantikan `SharedPreferences` dan `SQLite` dengan klaim lebih cepat. Namun, saya memutuskan untuk menggunakan `SharedPreferences` untuk key-value sederhana (karena *no boilerplate*) dan tetap menggunakan `SQLite` untuk catatan karena kebutuhan filtering/query data (`ORDER BY updated_at DESC`, `WHERE dirty = 1`) jauh lebih baik di database relasional SQL daripada NoSQL (yang menuntut manual filtering di memori).

---

## AI Challenge (Dokumentasi Perbandingan)
**Prompt yang digunakan:**
> Aplikasi Flutter Offline Notes: CRUD catatan + preferensi tema. Bandingkan SharedPreferences, Hive, sqflite (SQLite), dan Drift untuk dua kebutuhan ini. Requirements: Kriteria: kompleksitas query, kebutuhan relasi, reaktivitas (stream), type-safety, ukuran boilerplate, dan kemudahan testing. Beri rekomendasi final: mana untuk preferensi, mana untuk catatan, beserta alasannya dalam 1 tabel. Tunjukkan skema tabel/kotak untuk 1000+ catatan. Jelaskan trade-off setiap pilihan.

**Tabel Perbandingan Final**
| Fitur/Kriteria | SharedPreferences | Hive (NoSQL) | sqflite (SQLite) | Drift (ORM) |
|---|---|---|---|---|
| Kompleksitas Query | Sangat Rendah (Key-Value) | Rendah (Map/Key-Value) | Tinggi (SQL murni) | Sangat Tinggi (Type-safe SQL) |
| Kebutuhan Relasi | Tidak ada | Terbatas (HiveList) | Sangat baik (JOIN) | Sangat baik (Relationships) |
| Reaktivitas (Stream) | Tidak bawaan | Ya (Watch Box) | Tidak bawaan | Ya (Watch Tables) |
| Type-Safety | Rendah (Cast manual) | Tinggi (Generated TypeAdapter)| Menengah (Map<String, dynamic>)| Sangat Tinggi (Generated Code) |
| Ukuran Boilerplate | Sangat Rendah | Sedang (Code Gen) | Menengah | Sangat Tinggi (Code Gen) |
| Kemudahan Testing | Mudah (Mock / Map in-memory) | Sedang | Sulit (Mock DB) | Sulit (Mock DB) |

**Keputusan Final:**
- **Untuk Preferensi:** SharedPreferences. Alasan: Sangat ringan, tidak butuh setup rumit, cukup untuk menyimpan 1-2 nilai primitif.
- **Untuk Catatan:** sqflite. Alasan: Kebutuhan query seperti mengurutkan (ORDER BY) dan mencari data yang belum tersinkron (WHERE) mudah dan efisien dieksekusi di level database tanpa memuat ribuan data ke memori RAM terlebih dahulu. Selain itu, *boilerplate* `sqflite` tidak sebanyak `Drift` untuk project skala kecil/menengah.
