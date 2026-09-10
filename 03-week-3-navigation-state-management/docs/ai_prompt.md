# Dokumentasi AI Challenge — Week 3

## Prompt yang Digunakan

```
Buatkan halaman Flutter bernama StatsPage menggunakan flutter_riverpod.
Requirements:
- ConsumerWidget dengan satu AsyncNotifierProvider yang mensimulasikan
  pengambilan data statistik (delay 2 detik, kadang gagal 30%).
- UI harus menangani loading (spinner), error (pesan + tombol retry),
  dan success (ListView 3 item).
- Berikan unit test untuk notifier-nya.
Jelaskan setiap bagian kode dalam komentar.
```

## Output AI (Ringkasan)

AI menghasilkan:
- `StatsNotifier extends AsyncNotifier<List<Stat>>` dengan `Random().nextDouble() < 0.3` untuk 30% failure
- `AsyncValue.guard(() => _fetch())` di method `refresh()`
- `productsAsync.when(loading:, error:, data:)` untuk menangani ketiga state
- Unit test dengan `ProviderContainer`

## Verifikasi AI Checklist

| Item | Status | Catatan |
|------|--------|---------|
| State immutable? | ✅ | `state = [...state, Todo(title)]` — selalu buat list baru |
| `ref.watch` hanya di `build`? | ✅ | `ref.read` dipakai di semua callback/event handler |
| Ketiga state AsyncValue ditangani? | ✅ | `loading`, `error`, `data` semuanya ada di `.when()` |
| Provider tipe eksplisit, tidak duplikat? | ✅ | Setiap provider punya tipe berbeda: `List<Todo>`, `List<Stat>`, `List<String>` |
| Tidak pakai API lama? | ✅ | Menggunakan `Notifier`/`AsyncNotifier`, bukan `StateProvider`/`StateNotifierProvider` |
| `flutter analyze` lolos? | ✅ | No issues found |
| `flutter test` lolos? | ✅ | Semua test pass |

## Perbaikan yang Dilakukan

1. **Isolasi widget test** — Test menggunakan `MaterialApp(home: TodoPage())` langsung, bukan `MyApp()` dengan GoRouter, agar lebih fokus dan tidak bergantung routing.
2. **Unit test bersifat deterministik** — Test `stats_notifier_test.dart` menerima `hasValue || hasError` karena failure rate 30% membuat hasil tidak bisa diprediksi — yang diuji adalah *state machine* bukan *data*.
3. **`select()` di TodoTile** — Menambahkan `ref.watch(todoListProvider.select(...))` agar hanya item yang berubah yang di-rebuild, bukan seluruh list.

## Refleksi

**Mengapa menampilkan data lama (stale data) sambil refresh lebih baik?**

Ketika user tap refresh, menampilkan loading spinner penuh membuat seluruh layar kosong. Alternatif yang lebih baik: simpan data lama dan tampilkan indikator kecil (misalnya refresh indicator di AppBar), sehingga user tetap bisa melihat konten selama data baru dimuat. Pola ini penting di aplikasi dengan koneksi lambat (mobile data).
