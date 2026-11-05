# Panduan Arsitektur & Integrasi Fitur AI Mobile (docs/ai_integration_guide.md)

Dokumen ini memuat arsitektur integrasi Cloud LLM (Google Gemini API), rancangan prompt mobile, strategi pengamanan kunci API melalui Secure Storage, mitigasi privasi data pengguna, serta mekanisme fallback design saat layanan eksternal mengalami kendala.

---

## 1. Konsep & Arsitektur Integrasi AI

Fitur AI pada aplikasi mobile memungkinkan interaksi cerdas secara real-time langsung di perangkat pengguna dengan memanfaatkan model bahasa besar (*Large Language Model*):

```
+------------------+         HTTPS / JSON          +---------------------+
|    Flutter UI    | <---------------------------> | Google Gemini API   |
| (AiChatPage, UI) |       (AiService / http)      | (gemini-1.5-flash)  |
+------------------+                               +---------------------+
         |                                                    |
  API Key| (Secure Storage)                                   | AI Response
         v                                                    v
+------------------+                               +---------------------+
|  Secure Storage  |                               | Domain & UI Layer   |
| (Encrypted Vault)|                               | (Riverpod Notifier) |
+------------------+                               +---------------------+
```

### Prinsip Utama Keamanan Kunci:
1. **Dilarang Keras *Hardcode* Kunci:** Kunci API Google Gemini tidak boleh disimpan di source code (`.dart`), file repository publik, maupun `.env` yang tidak terenkripsi.
2. **Penyimpanan Terenkripsi:** Menggunakan `flutter_secure_storage` yang memanfaatkan *Keychain* (iOS) dan *EncryptedSharedPreferences / KeyStore* (Android).
3. **Pengaturan Dinamis:** Pengguna atau pengembang dapat memasukkan / memperbarui API key kapan saja via dialog modal pengaturan di aplikasi tanpa perlu *re-compile*.

---

## 2. Prompt Engineering Khusus Perangkat Mobile

Layar mobile memiliki keterbatasan ukuran (*viewport*) dan pengguna membutuhkan jawaban yang instan, to-the-point, serta hemat bandwidth data.

### 2.1 Formula Desain Prompt Mobile:
- **System Prompt (Persona & Batas):**
  > *"Kamu asisten kampus ramah untuk mahasiswa Polinema. Jawab dalam Bahasa Indonesia dengan singkat, solutif, dan informatif (maksimal 3 kalimat). Hindari penjelasan bertele-tele."*
- **User Prompt (Pertanyaan Pengguna):** Input teks dinamis dari TextField, misalnya: *"Kapan batas akhir pengisian KRS semester genap?"*
- **Konteks:** Nama kampus (Polinema), modul akademik, dan pengumuman terkait.
- **Batas (Guardrails Privasi):** Dilarang membocorkan data sensitif, NIK mahasiswa, atau kredensial sistem.

---

## 3. Matriks Risiko, Privasi & Mitigasi

| Risiko Potensial | Dampak bagi Pengguna / Tim | Strategi Mitigasi yang Diimplementasikan |
|---|---|---|
| **Kebocoran Data Pribadi** | Data sensitif mahasiswa (NIK, no. HP, alamat) terekspos ke log server pihak ketiga AI. | Fungsi `sanitizePrompt()` otomatis mendeteksi dan menyamarkan 16 digit angka (regex NIK) menjadi `[NIK_DISAMARKAN]` sebelum dikirim ke API. |
| **Lonjakan Biaya & Rate Limit** | Biaya token per request membengkak atau kuota API habis mendadak. | Membatasi prompt pengguna, menggunakan model hemat `gemini-1.5-flash`, dan memvalidasi string kosong di domain layer sebelum request jaringan dikirim. |
| **API Error / Server Down** | Aplikasi crash atau layar macet saat endpoint Gemini mengembalikan HTTP 500 atau 403. | Error ditangkap dan dipetakan ke `NetworkFailure`. Tampilan chat merender **Fallback Bubble** ramah pengguna (*"Layanan AI Sibuk: Coba lagi nanti atau gunakan mode offline"*). |
| **Respons Halusinasi / Tak Relevan** | Pengguna menerima informasi tanggal ujian atau jadwal palsu dari AI. | Menyertakan peringatan visual pada UI (*"Jawaban asisten AI bersifat informatif, verifikasi ke portal resmi kampus"*). |

---

## 4. Fitur Ekstra: OCR, Speech-to-Text, dan Multimodal

Selain percakapan teks cerdas, arsitektur `AiService` dirancang modular untuk mengakomodasi kebutuhan fitur multimodal:
- **Optical Character Recognition (OCR):** Fungsi `recognizeText()` untuk mengekstraksi teks jadwal dari foto papan pengumuman kampus atau kartu tanda mahasiswa (KTM).
- **Speech-to-Text (STT):** Fungsi `speechToText()` untuk memfasilitasi input suara cepat (*voice query*) bagi mahasiswa yang sedang berjalan kaki di area kampus.
