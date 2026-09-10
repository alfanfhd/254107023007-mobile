# 03-week-3-navigation-state-management

## Tujuan
Memahami konsep navigasi di Flutter menggunakan GoRouter sebagai router deklaratif yang direkomendasikan Flutter, serta memahami cara berpindah antar halaman menggunakan path parameter.

## Fitur Utama
- Multi-page navigation menggunakan GoRouter
- Dynamic path parameter (`/detail/:id`)
- Navigasi dari Home ke Detail page via `context.go()`
- Back navigation otomatis via AppBar back button

## Stack Teknologi
- Flutter 3.x
- Dart 3.x
- [go_router](https://pub.dev/packages/go_router) ^14.0.0
- Material 3

## Struktur Folder
```
lib/
├── main.dart          ← Router config & MyApp entry point
└── pages/
    ├── home_page.dart ← ListView 10 item
    └── detail_page.dart ← Halaman detail by id
```

## Cara Menjalankan
```bash
flutter pub get
flutter run
```

## Hasil yang Dicapai
- Aplikasi multi-halaman menggunakan GoRouter
- Navigasi deklaratif dengan route `/` dan `/detail/:id`
- `MaterialApp.router` dikonfigurasi via `routerConfig`

## Screenshot
*(Tambahkan screenshot di folder screenshots/)*

## Learning Outcomes
- Memahami perbedaan Navigator 1.0 vs GoRouter (Navigator 2.0)
- Menerapkan `GoRoute` dengan nested routes
- Menggunakan `context.go()` untuk berpindah route
- Membaca path parameter via `state.pathParameters`

---
**Status**: ✅ Selesai
