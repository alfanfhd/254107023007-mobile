# Week 12 - Testing & Quality Assurance

## Deskripsi

Aplikasi daftar tugas sederhana yang dibangun dengan pemisahan tanggung jawab (repository pattern) agar mudah diuji. Project ini mencakup pengujian unit, widget, dan integrasi sesuai codelab Minggu 12.

## Struktur Project

```
lib/
├── main.dart                   # Entry point aplikasi
├── is_valid_task_title.dart     # Validasi judul tugas
├── task_repository.dart         # Kontrak abstrak repository
├── task_service.dart            # Business logic layer
├── in_memory_task_repository.dart # Implementasi repository in-memory
└── task_list_page.dart          # Widget UI daftar tugas

test/
├── fake_task_repository.dart    # Fake repository untuk pengujian
├── is_valid_task_title_test.dart # Unit test validasi
├── task_service_test.dart       # Unit test service + fake repo
└── task_list_page_test.dart     # Widget test

integration_test/
└── app_test.dart                # Integration test alur utama
```

## Skenario Pengujian

### 1. Unit Test - Validasi Judul (`isValidTaskTitle`)
| Skenario | Input | Hasil |
|----------|-------|-------|
| Judul berisi teks | `'Belajar Flutter'` | `true` |
| Judul dengan spasi di ujung | `'  Belajar  '` | `true` |
| String kosong | `''` | `false` |
| Hanya spasi | `'   '` | `false` |
| Satu karakter | `'A'` | `true` |

### 2. Unit Test - TaskService (dengan FakeTaskRepository)
| Skenario | Jenis | Hasil |
|----------|-------|-------|
| Meneruskan data dari repository | Sukses | Data sesuai |
| Daftar kosong jika tidak ada tugas | Sukses | `[]` |
| Exception jika repository gagal | Error | `throwsException` |
| Menambahkan tugas valid | Sukses | Tugas tersimpan |
| Trim spasi judul | Edge case | Spasi dihapus |
| Menolak judul kosong | Error | `throwsArgumentError` |
| Menolak judul hanya spasi | Error | `throwsArgumentError` |
| Menghapus tugas berdasarkan index | Sukses | Tugas terhapus |
| Index negatif | Error | `throwsRangeError` |
| Index di luar jangkauan | Error | `throwsRangeError` |

### 3. Widget Test - TaskListPage
| Skenario | Yang Diperiksa |
|----------|---------------|
| Menampilkan judul halaman | Teks "Daftar Tugas" muncul |
| Pesan kosong saat tidak ada tugas | Teks "Belum ada tugas" muncul |
| Menampilkan daftar tugas yang ada | Tugas dari repository ditampilkan |
| Menambahkan tugas baru | Input → Simpan → tugas muncul di daftar |
| Validasi judul kosong | Error "Judul tugas tidak boleh kosong" muncul |
| Menghapus tugas | Tekan delete → tugas hilang |
| Membersihkan field setelah simpan | TextField kosong setelah simpan berhasil |

### 4. Integration Test - Alur Utama
| Skenario | Langkah |
|----------|---------|
| Tambah dan hapus tugas | Buka app → tambah 2 tugas → hapus tugas pertama → verifikasi |
| Validasi judul kosong | Buka app → tekan Simpan tanpa isi → error muncul |

## Hasil Pengujian

### `flutter test`
```
00:04 +22: All tests passed!
```

### `flutter analyze`
```
Analyzing 12-week-12-testing-quality-assurance...
No issues found!
```

### `flutter test --coverage`
Coverage report dihasilkan di `coverage/lcov.info`.

### Integration Test
```
flutter test integration_test/app_test.dart -d <device_id>
```
**Kendala:** Tidak dapat dijalankan karena:
- Tidak ada emulator/perangkat Android yang terhubung
- Windows desktop build memerlukan Visual Studio toolchain yang belum terinstall
- Web device tidak mendukung integration test

Perintah yang digunakan:
```
flutter test integration_test/app_test.dart -d windows
flutter test integration_test/app_test.dart -d chrome
```
Keduanya gagal. Integration test perlu dijalankan di emulator Android atau perangkat fisik.

## Refleksi

1. **Bug yang mungkin terlewat tanpa pengujian:**
   - Validasi judul yang hanya berisi spasi bisa lolos tanpa unit test `isValidTaskTitle`.
   - Delete tugas dengan index di luar jangkauan bisa crash tanpa pengujian RangeError.
   - Field input tidak dibersihkan setelah simpan, membuat UX membingungkan.

2. **Fake repository dan konsistensi pengujian:**
   - `FakeTaskRepository` menggantikan akses data asli sehingga pengujian tidak bergantung pada jaringan atau database.
   - Bisa mensimulasikan error (`Exception`) untuk menguji penanganan kegagalan.
   - Pengujian menjadi cepat, deterministik, dan dapat diulang.

3. **Perbedaan pengujian widget vs integrasi:**
   - **Widget test:** menguji satu halaman secara terisolasi dengan fake data, cepat, cocok untuk interaksi UI spesifik.
   - **Integration test:** menguji alur lengkap dari `main()` pada perangkat/emulator, mencakup navigasi dan state management lintas komponen, lebih lambat tapi mencerminkan pengalaman pengguna sebenarnya.
