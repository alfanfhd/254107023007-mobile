# Minggu 10: Integrasi Fitur AI (AI Feature Integration)

**Mata Kuliah:** Pemrograman Mobile  
**Nama Mahasiswa:** Mochammad Alfan Fadhilah  
**NIM:** 254107023007  
**Topik Pembelajaran:** #10 Integrasi Fitur AI (LLM API, Prompt Design, OCR & STT, Fallback Design)  
**Proyek Basis:** Campus Notify & Offline Notes (`Week7_Clean Architecture/campus_notify`)  
**Branch:** `develop`

---

## 📌 Ringkasan Modul & Hasil Kerja

Modul Minggu 10 berfokus pada integrasi model kecerdasan buatan (*Cloud LLM API*) ke dalam aplikasi mobile berbasis arsitektur bersih (*Clean Architecture*). Fitur yang diimplementasikan adalah **Asisten Cerdas Kampus Polinema** yang terhubung langsung dengan endpoint Google Gemini API (`gemini-1.5-flash`), dilengkapi penyimpanan kunci terenkripsi (*Secure Storage*), penyaringan otomatis data privasi (NIK guardrails), penanganan error terstruktur (*fallback design*), serta arsitektur multimodal untuk OCR dan Speech-to-Text.

Sesuai instruksi penugasan, seluruh artefak pada folder `10-week-10-ai-feature-integration/` memuat:
1. `lib/`: Salinan kode sumber lengkap aplikasi `campus_notify` termasuk modul AI.
2. `docs/`: Panduan integrasi serta `ai-log.md` (berisi prompt sistem, prompt pengguna, dan raw output AI).
3. `README.md`: Dokumentasi komprehensif, bukti mesin hijau, tabel risiko & mitigasi, serta refleksi.
4. `screenshots/`: Bukti visual antarmuka dan alur interaksi AI.

---

## 🏛️ Arsitektur Integrasi AI (Clean Architecture)

Mengikuti prinsip sterilitas arsitektur: domain layer murni Dart tanpa import framework atau API luar.

```
lib/
├── ai/
│   └── ai_service.dart                   # Service client Gemini API, sanitasi NIK, & Secure Storage
└── features/
    ├── ai/
    │   ├── domain/
    │   │   ├── entities/
    │   │   │   └── chat_message.dart      # Entitas pesan (User vs AI, timestamp, status)
    │   │   ├── repositories/
    │   │   │   └── ai_repository.dart     # Interface kontrak domain murni
    │   │   └── usecases/
    │   │       └── ask_campus_ai.dart     # Logika validasi input & pemanggilan AI
    │   ├── data/
    │   │   └── repositories/
    │   │       └── ai_repository_impl.dart # Implementasi repository & error mapping
    │   └── presentation/
    │       ├── providers/
    │       │   └── ai_providers.dart      # State management Riverpod (messages & loading)
    │       └── pages/
    │           └── ai_chat_page.dart      # Antarmuka chat interaktif & dialog input API Key
    └── chat_screen.dart                  # Layar alternatif integrasi cepat sesuai codelab
```

---

## 🛡️ Tabel Risiko & Mitigasi Privasi dan Biaya

| Kategori Risiko | Potensi Masalah / Dampak | Strategi Mitigasi Terapan di Kode |
|---|---|---|
| **Privasi Pengguna (Kebocoran NIK)** | Pengguna tidak sengaja memasukkan NIK atau nomor identitas rahasia ke dalam prompt yang dikirim ke cloud server. | **Client-side Sanitization (`sanitizePrompt`):** Regex otomatis mendeteksi pola 16 digit angka `\b\d{16}\b` dan menggantinya dengan `[NIK_DISAMARKAN]` sebelum HTTP payload dikirim ke API Gemini. |
| **Pencurian API Key (Security Leak)** | Kunci API terekspos jika ditaruh langsung di kode sumber (*hardcoded*) atau disimpan di SharedPreferences plaintext. | **Hardware-backed Storage:** Menggunakan `flutter_secure_storage` yang terenkripsi di *Android KeyStore* dan *iOS Keychain*. Kunci diinput pengguna langsung melalui dialog UI di dalam aplikasi. |
| **Pembengkakan Biaya (Token Quota)** | Prompt pengguna yang panjang atau respons model LLM yang bertele-tele menghabiskan kuota token dan menambah biaya/latensi. | **System Prompt Tuning:** System prompt membatasi model agar menjawab maksimal 3 kalimat padat to-the-point (`"maksimal 3 kalimat"`), menghemat hingga ~70% token per interaksi. |
| **Layanan Cloud Down / Rate Limit** | Kegagalan jaringan seluler, HTTP 429 (Too Many Requests), atau HTTP 403 (kuota habis) menyebabkan aplikasi *crash*. | **Graceful Fallback UI:** Try-catch di data repository menangkap semua HTTP/Network failure dan mengembalikan bubble chat informatif (*"Layanan AI Sibuk: Silakan coba lagi nanti atau gunakan mode offline"*). |
| **Input Kosong / Spam Request** | Menekan tombol kirim berulang kali saat prompt kosong atau koneksi lambat menyebabkan pemborosan kuota API. | **Domain Validation:** Use case `AskCampusAi` memvalidasi input `trim().isEmpty` dan melempar `ValidationFailure` sebelum panggilan HTTP dilakukan, serta tombol kirim di-*disable* saat loading. |

---

## 🧪 Bukti Mesin Hijau (Quality Gates: 100% Lulus)

Seluruh 3 gerbang kualitas mesin diverifikasi pada project `Week7_Clean Architecture/campus_notify`:

### 1. Analisis Statis Kode (`flutter analyze`)
```text
Analyzing campus_notify...
No issues found! (ran in 5.8s)
```
*Hasil: 0 warning, 0 error, 0 info.*

### 2. Format Standar Dart (`dart format --set-exit-if-changed .`)
```text
Formatted 39 files (0 changed) in 0.24 seconds.
```
*Hasil: Seluruh file Dart rapi dan konsisten.*

### 3. Pengujian Otomatis Unit & Widget (`flutter test`)
```text
00:00 +0: AiService Tests Melempar exception jika API key belum diatur di secure storage
00:00 +1: AiService Tests Berhasil mengembalikan respons teks saat API Gemini mengembalikan HTTP 200
00:00 +2: AiService Tests Melempar exception terstruktur saat API Key ditolak / kuota habis (HTTP 403)
00:00 +3: AiService Tests Menyaring NIK 16 digit otomatis dari prompt demi privasi data pengguna
00:00 +4: AiService Tests Dapat menyimpan dan membaca API key dari Secure Storage
00:00 +5: AiService Tests Mendukung fungsi simulasi OCR dan Speech-to-Text
00:01 +6: Menampilkan antarmuka chat AI, privacy notice, dan dialog API Key
00:02 +7: Mengirim pesan pengguna dan menampilkan bubble balasan asisten AI
00:03 +8: Menampilkan bubble Fallback Error ramah saat pemanggilan AI gagal
00:04 +24: All tests passed!
```
*Hasil: 24 dari 24 test LULUS.*

---

## 🧠 Jawaban Refleksi Pembelajaran

### 1. Fitur AI mana yang Anda integrasikan dan mengapa?
> **Jawaban:**  
> Saya mengintegrasikan fitur **Asisten Cerdas Kampus (Chat Interface dengan Google Gemini 1.5 Flash)**. Fitur ini dipilih karena sangat relevan dengan kebutuhan mahasiswa sehari-hari di aplikasi kampus, seperti menanyakan info jadwal kuliah, tips belajar, dan informasi akademik secara interaktif. Model `gemini-1.5-flash` dipilih karena memiliki kecepatan inferensi yang sangat tinggi (*low latency*) dan biaya token yang efisien untuk aplikasi mobile, serta dilengkapi rancangan antarmuka untuk pengembangan multimodal lanjutan (OCR dan Speech-to-Text).

### 2. Bagaimana Anda melindungi privasi pengguna saat menggunakan AI API?
> **Jawaban:**  
> Privasi dilindungi melalui tiga lapisan pertahanan:
> 1. **Client-side Masking:** Terdapat fungsi sanitasi otomatis (`sanitizePrompt()`) yang mendeteksi pola data pribadi sensitif (seperti 16 digit NIK/KTP) dan mengubahnya menjadi `[NIK_DISAMARKAN]` sebelum data dikirim ke cloud.
> 2. **Penyimpanan Kunci Terenkripsi:** API Key tidak di-*hardcode* di repository atau disimpan di `SharedPreferences` terbuka, melainkan disimpan menggunakan `FlutterSecureStorage` dengan enkripsi Android KeyStore / iOS Keychain.
> 3. **Instruksi Batasan pada System Prompt:** System prompt secara eksplisit melarang AI untuk meminta atau menyimpan kata sandi, NIK, maupun informasi finansial pengguna.

### 3. Fallback apa yang Anda sediakan jika layanan AI error?
> **Jawaban:**  
> Apabila terjadi kegagalan jaringan, API key belum disetel, kuota habis (HTTP 429/403), atau server cloud mengalami gangguan, sistem tidak membiarkan aplikasi mengalami *crash* atau *unhandled exception*. Sebaliknya, sistem menangkap error pada layer repository dan menampilkan **Fallback Bubble** ramah pengguna dengan pesan informatif: *"Layanan AI Sibuk: Silakan coba lagi nanti atau gunakan mode offline"*. Selain itu, pengguna diberikan panduan langsung melalui SnackBar untuk mengatur ulang API Key pada ikon kunci di AppBar.

### 4. Satu hal yang Anda pelajari tentang UI/UX AI di mobile?
> **Jawaban:**  
> Pelajaran terpenting adalah **latensi dan ekspektasi pengguna**. Pengguna mobile sangat sensitif terhadap respons yang lambat atau layar yang tampak beku (*frozen*). Oleh karena itu, penting untuk:
> 1. Menampilkan indikator loading / animasi *typing bubble* saat AI sedang memproses respons.
> 2. Membatasi panjang teks respons melalui System Prompt (maksimal 2-3 kalimat) agar jawaban tidak memenuhi seluruh layar smartphone dan mudah dibaca secara cepat.
> 3. Menyediakan tombol aksi cepat (*quick suggestion chips*) seperti topik bantuan yang sering ditanyakan agar pengguna tidak perlu mengetik panjang lebar.
