# AI Challenge: Refactoring Clean Architecture

## 1. Usulan Struktur Feature-First (Auth & Announcements)

Berikut adalah usulan struktur folder `feature-first` untuk `auth` dan `announcements`:

```text
lib/
├── core/
│   ├── failures.dart               # Domain failure
│   └── format.dart                 # Murni fungsi format tanggal/rute
├── features/
│   ├── auth/
│   │   ├── domain/
│   │   │   ├── entities/user.dart
│   │   │   ├── repositories/auth_repository.dart
│   │   │   └── usecases/login_usecase.dart       # Opsional jika login kompleks
│   │   ├── data/
│   │   │   ├── models/user_model.dart
│   │   │   ├── repositories/auth_repository_impl.dart
│   │   │   └── datasources/auth_remote_ds.dart   # (Dio/SecureStorage)
│   │   └── presentation/
│   │       ├── providers/auth_providers.dart     # State + DI (AuthNotifier)
│   │       └── pages/login_page.dart
│   └── announcements/
│       ├── domain/
│       │   ├── entities/announcement.dart
│       │   └── repositories/announcement_repository.dart
│       ├── data/
│       │   ├── models/announcement_model.dart
│       │   └── repositories/announcement_repository_impl.dart
│       └── presentation/
│           ├── providers/announcement_providers.dart
│           ├── pages/home_page.dart
│           └── pages/announcement_page.dart
└── routes.dart
```

---

## 2. Pemetaan File Lama ke Tujuan Baru

| File Lama | Tujuan Baru (Setelah Refactor) | Keterangan |
| --- | --- | --- |
| `lib/data/auth_repository.dart` | `features/auth/domain/repositories/auth_repository.dart` (Interface) & `features/auth/data/repositories/auth_repository_impl.dart` (Implementasi) | Dipecah agar UI tidak bergantung langsung ke implementasi data. |
| `lib/providers/auth_provider.dart` | `features/auth/presentation/providers/auth_providers.dart` | Pindah ke dalam modul presentation khusus *auth*. Menghilangkan instansiasi `Repository()` manual. |
| `lib/pages/login_page.dart` | `features/auth/presentation/pages/login_page.dart` | Pindah ke modul *auth*. |
| `lib/pages/home_page.dart` | `features/announcements/presentation/pages/home_page.dart` | Pindah ke modul *announcements* karena menampilkan daftar pengumuman. |
| `lib/pages/announcement_page.dart`| `features/announcements/presentation/pages/announcement_page.dart` | Pindah ke modul *announcements*. |
| `lib/data/api_client.dart` | `core/network/api_client.dart` | Diubah menjadi infrastruktur core (disuntikkan via Riverpod). |
| `lib/data/token_store.dart` | `features/auth/data/datasources/token_store.dart` | Menjadi datasource lokal khusus auth. |

---

## 3. Analisa Over-Engineering vs Kebutuhan Usecase

**Kapan menggunakan Usecase?**
- **Dianjurkan:** Ketika operasi menggabungkan logika dari lebih dari satu repository, melakukan validasi bisnis yang kompleks sebelum mengirim data, atau memfilter data berdasarkan peran user.
- **Over-Engineering:** Jika fitur hanyalah **CRUD sederhana** atau operasi satu baris (seperti `getAnnouncements` yang hanya me-return daftar pengumuman). Dalam kasus ini, **memanggil Repository langsung dari Notifier/Provider adalah pendekatan yang lebih praktis (Pragmatic Clean Architecture)**.

**Trade-off:**
Memaksa pembuatan Usecase untuk setiap operasi satu-baris akan menghasilkan banyak file _boilerplate_ (_class_ yang hanya meneruskan panggilan metode) tanpa nilai tambah yang berarti, sehingga memperlambat _development_.

---

## 4. Wiring Dependency Injection (Riverpod)

Contoh Wiring DI terpusat tanpa bocor:

```dart
// Di features/auth/presentation/providers/auth_providers.dart

// 1. Data Source / Core (Instansiasi Dio disuntikkan)
final dioProvider = Provider<Dio>((ref) => Dio(BaseOptions(baseUrl: '...')));

// 2. Data Layer (Implementasi Repository membutuhkan Dio)
final authRepositoryImplProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(dio: ref.watch(dioProvider));
});

// 3. Domain Layer (Optional Usecase, menerima Interface)
final loginUsecaseProvider = Provider<LoginUsecase>((ref) {
  return LoginUsecase(ref.watch(authRepositoryImplProvider));
});

// 4. Presentation Layer (StateNotifier membutuhkan Usecase/Repository Interface)
final authStateProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  return AuthNotifier(ref.watch(loginUsecaseProvider)); // Atau langsung authRepositoryImplProvider
});
```

**Trade-off DI Riverpod:**
- **Pro:** Sangat reaktif, deklaratif, mudah di-mock saat _testing_, tidak butuh package DI tambahan seperti `get_it`.
- **Con:** Jika aplikasi sangat besar, _graph dependency_ tersebar di banyak file _provider_, sehingga pelacakan _wiring_ (mana bergantung pada mana) secara visual sedikit lebih sulit dibanding file _locator_ tunggal.

---

## 5. Hasil Verifikasi 3 Grep (Sterilitas)

Setelah disepakati, verifikasi sterilitas folder dapat dibuktikan dengan _grep_ berikut:

1. **Presentation bebas data mentah:**
   `rg "Dio\(|openDatabase|getDatabasesPath|FlutterSecureStorage|SharedPreferences\.getInstance|jsonDecode" lib/features/*/presentation lib/pages`
   **(Target: 0 hasil)**

2. **Domain bebas framework/package:**
   `rg "import 'package:flutter|import 'package:dio|import 'package:sqflite|import 'package:firebase" lib/features/*/domain lib/core`
   **(Target: 0 hasil)**

3. **Analysis & Test Bersih:**
   `flutter analyze` (Target: No issues) & `flutter test` (Target: All passing)
