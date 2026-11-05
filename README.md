# Pemrograman Mobile - Portfolio Course

Repository ini berisi dokumentasi dan implementasi progres pembelajaran mata kuliah Pemrograman Mobile selama satu semester (16 minggu).

## Informasi Mahasiswa
- **Nama**: Alfan Fahat Maulana
- **NIM**: 254107023007
- **Email**: alfanfhd78@gmail.com
- **Mata Kuliah**: Pemrograman Mobile

## Struktur Repository
```
254107023007-mobile-course/
├── README.md
├── 01-week-1-mobile-development-ecosystem-flutter-refresh/
├── 02-week-2-declarative-ui-responsive-design/
├── 03-week-3-navigation-state-management/
├── week4_api/
├── week5_offline_notes/
├── Week6_Authentication, Security & FCM/
├── Week7_Clean Architecture/
├── week8_Mid Project Review & Code Review/
├── 09-week-9-ai-assisted-development/
├── 10-week-10-ai-feature-integration/
├── 11-week-11-performance-optimization/
├── 12-week-12-testing-quality-assurance/
├── 13-week-13-ci-cd-automation/
├── 14-week-14-deployment-monitoring/
├── 15-week-15-secure-mobile-development/
├── 16-week-16-final-project-expo/
└── notes/
```

## Progress
- [x] Week 1: Mobile Development Ecosystem & Flutter Refresh
- [x] Week 2: Declarative UI & Responsive Design
- [x] Week 3: Navigation & State Management
- [x] Week 4: Networking & REST API
- [x] Week 5: Local Storage & Offline First
- [x] Week 6: Authentication, Security & FCM
- [x] Week 7: Clean Architecture
- [x] Week 8: Mid Project Review & Code Review
- [x] Week 9: AI Assisted Development / Vibe Coding
- [ ] Week 10: AI Feature Integration
- [ ] Week 11: Performance Optimization
- [ ] Week 12: Testing & Quality Assurance
- [ ] Week 13: CI/CD Automation
- [ ] Week 14: Deployment & Monitoring
- [ ] Week 15: Secure Mobile Development
- [ ] Week 16: Final Project Expo

## Stack Teknologi Utama
- **Framework**: Flutter (Channel Stable)
- **Bahasa**: Dart
- **State Management**: Riverpod (Notifier, FutureProvider, Provider)
- **Networking**: Dio (dengan Auth & Token Refresh Interceptors)
- **Database & Storage**: SQLite (sqflite), FlutterSecureStorage
- **Cloud Messaging**: Firebase Core, Firebase Messaging, Flutter Local Notifications
- **Routing**: GoRouter (Declarative Routing & Deep Linking)
- **Otomasi**: GitHub Actions CI (`.github/workflows/ci.yml`)

## Panduan Pengujian Mesin
Jalankan di direktori proyek `Week7_Clean Architecture/campus_notify`:
```bash
flutter analyze
dart format --set-exit-if-changed .
flutter test
```

## Lisensi
Project ini dibuat untuk keperluan pembelajaran mata kuliah Pemrograman Mobile.
