# AI Challenge Documentation

## 1. Prompt yang Digunakan
```text
Aplikasi Flutter Campus Notification App.
Stack: firebase_messaging, flutter_local_notifications,
flutter_secure_storage, go_router, Riverpod.
Buatkan PushService dengan:
- requestPermission + getToken + onTokenRefresh (kirim ke POST /devices)
- onMessage (tampilkan local notification manual)
- onMessageOpenedApp + getInitialMessage (navigasi ke data.route)
- subscribe/unsubscribe topic pengumuman-kampus
- background handler top-level dengan @pragma('vm:entry-point')
Tandai bagian yang BERBEDA untuk Android 13+ vs iOS,
dan bagian yang tidak boleh mengakses BuildContext.
```

## 2. Output Awal AI (Draf)
AI (sebelumnya) menghasilkan kode yang hampir lengkap untuk `PushService`, termasuk semua requirement yang diminta. Namun, AI masih menggunakan *positional arguments* pada fungsi `_local.initialize()` dan `_local.show()` yang merupakan sintaks lama dari *package* `flutter_local_notifications`.

## 3. Perbaikan Manual (Manual Fixes)
Saya dan asisten AI harus memperbaiki cara pemanggilan metode `flutter_local_notifications` agar *error* `Too many positional arguments` bisa hilang. 

**Perbaikan pada `initialize`:**
```dart
// Sebelumnya (Draf AI/Modul lama):
await _local.initialize(
  const InitializationSettings(android: android, iOS: ios),
  onDidReceiveNotificationResponse: ...
);

// Setelah diperbaiki (Versi v22+):
await _local.initialize(
  settings: const InitializationSettings(android: android, iOS: ios),
  onDidReceiveNotificationResponse: ...
);
```

**Perbaikan pada `show`:**
```dart
// Sebelumnya (Draf AI/Modul lama):
await _local.show(
  message.hashCode,
  message.notification?.title ?? 'Pengumuman',
  message.notification?.body ?? '',
  const NotificationDetails(android: androidDetails),
  payload: route,
);

// Setelah diperbaiki (Versi v22+):
await _local.show(
  id: message.hashCode,
  title: message.notification?.title ?? 'Pengumuman',
  body: message.notification?.body ?? '',
  notificationDetails: const NotificationDetails(android: androidDetails),
  payload: route,
);
```

## 4. Alasan Teknis
Library `flutter_local_notifications` versi terbaru (22.x ke atas) telah menerapkan sistem **named parameters** secara wajib (required) untuk fungsi `initialize()` dan `show()` demi meningkatkan *code readability* (keterbacaan kode) dan keamanan *typing*. Oleh karena itu, *positional arguments* (mengandalkan urutan parameter saja) akan ditolak oleh kompilator Dart karena sudah tidak dikenali lagi pada *signature* fungsi tersebut. 
