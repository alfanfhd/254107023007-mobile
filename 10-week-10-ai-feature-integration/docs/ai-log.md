# AI Integration Log - Minggu 10: Integrasi Fitur AI

**Mata Kuliah:** Pemrograman Mobile  
**Nama Mahasiswa:** Mochammad Alfan Fadhilah  
**NIM:** 254107023007  
**Fitur AI:** Asisten Cerdas Kampus Polinema (Google Gemini 1.5 Flash)  
**Dokumen:** `docs/ai-log.md`

---

## 1. Konsep & Arsitektur Fitur AI

Fitur AI diintegrasikan ke dalam arsitektur *Clean Architecture* feature-first pada modul `Week7_Clean Architecture/campus_notify`:
- **Domain Layer:** Pure Dart entity (`ChatMessage`), abstract repository (`AiRepository`), dan usecase (`AskCampusAi`). Bebas dari dependensi Flutter/UI/Network.
- **Data Layer:** `AiRepositoryImpl` mengonsumsi `AiService` (client HTTP REST Gemini API) dengan penyimpanan secure token (`flutter_secure_storage`).
- **Presentation Layer:** Riverpod Notifier (`AiChatNotifier`), state management immutable, dan antarmuka chat responsif (`AiChatPage` & `ChatScreen`).

```
[Flutter UI: Chat Screen]
         │
         ▼
[Riverpod Notifier: aiChatNotifier]
         │
         ▼
[Domain UseCase: AskCampusAi]
         │
         ▼
[Data Repo: AiRepositoryImpl] ────► [Local Key: flutter_secure_storage]
         │
         ▼ (HTTP POST)
[Google Gemini 1.5 Flash Cloud API]
```

---

## 2. Prompt Engineering & Log Percakapan AI

### A. System Prompt (Persona, Batasan, dan Gaya Komunikasi)
System prompt diterapkan di `lib/ai/ai_service.dart` untuk memastikan model AI beroperasi sebagai asisten kampus yang ringkas, tepat sasaran, dan aman bagi pengguna mobile:

```text
Kamu adalah Asisten Cerdas Kampus Polinema yang ramah, informatif, dan membantu mahasiswa seputar jadwal kuliah, catatan akademik, dan kegiatan kampus. Jawablah secara ringkas (maksimal 3 kalimat), menggunakan Bahasa Indonesia yang sopan dan mudah dipahami di layar smartphone. Jangan pernah meminta informasi pribadi sensitif seperti NIK, password, atau nomor rekening.
```

### B. User Prompt (Pertanyaan Pengguna)
Contoh prompt pengguna saat menanyakan informasi kegiatan akademik di aplikasi:

```text
Kapan jadwal ujian tengah semester (UTS) dan bagaimana tips belajar efektif untuk menghadapi ujian pemrograman mobile?
```

### C. Output Awal AI (Raw Response dari Google Gemini 1.5 Flash)
Respons aktual yang diterima dari endpoint `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent`:

```json
{
  "candidates": [
    {
      "content": {
        "parts": [
          {
            "text": "Jadwal UTS biasanya diadakan pada minggu ke-8 atau ke-9 perkuliahan sesuai kalender akademik Polinema, silakan cek pengumuman resmi di Siakad. Untuk pemrograman mobile, seringlah berlatih membuat kode praktikum Clean Architecture secara mandiri dan pahami pemisahan domain layer dengan baik. Jangan lupa pelajari kembali konsep state management Riverpod dan siapkan pengujian unit test!"
          }
        ],
        "role": "model"
      },
      "finishReason": "STOP"
    }
  ],
  "usageMetadata": {
    "promptTokenCount": 78,
    "candidatesTokenCount": 72,
    "totalTokenCount": 150
  }
}
```

### D. Tampilan Hasil di Mobile Chat UI
Teks di atas diekstrak dan disajikan secara elegan ke dalam bubble chat asisten:
> **Asisten AI Kampus:**  
> *"Jadwal UTS biasanya diadakan pada minggu ke-8 atau ke-9 perkuliahan sesuai kalender akademik Polinema, silakan cek pengumuman resmi di Siakad. Untuk pemrograman mobile, seringlah berlatih membuat kode praktikum Clean Architecture secara mandiri dan pahami pemisahan domain layer dengan baik. Jangan lupa pelajari kembali konsep state management Riverpod dan siapkan pengujian unit test!"*

---

## 3. Fitur Tambahan: OCR, Speech-to-Text, dan Multimodal Design

Sesuai materi codelab bagian 4:
1. **OCR (Optical Character Recognition):**
   - Method: `AiService.recognizeText(dynamic imageFile)`
   - Kegunaan: Ekstraksi teks otomatis dari Kartu Tanda Mahasiswa (KTM), nota/receipt, surat keterangan, atau foto papan pengumuman jurusan.
2. **Speech-to-Text (Voice Prompt):**
   - Method: `AiService.speechToText(dynamic audioFile)`
   - Kegunaan: Memungkinkan mahasiswa merekam suara pertanyaan untuk ditranskripsi menjadi prompt teks secara instan demi aksesibilitas.
3. **Penyaringan Otomatis Data Sensitif (Privacy Sanitizer):**
   - Method: `AiService.sanitizePrompt(String input)`
   - Mendeteksi 16 digit angka (misalnya NIK KTP atau nomor dokumen rahasia) dan otomatis menggantinya menjadi `[NIK_DISAMARKAN]` sebelum dikirimkan ke cloud AI.

---

## 4. Verifikasi & Debugging Log

| No | Pengujian | Skenario | Hasil Verifikasi | Status |
|---|---|---|---|:---:|
| 1 | Unit Test API Key Guard | Storage kosong tanpa API key | Melempar `Exception('API key tidak tersedia. Silakan atur di pengaturan.')` | PASS |
| 2 | Unit Test Sanitasi NIK | Prompt berisi NIK 16 digit: `"NIK saya 3507112233440001"` | Menjadi: `"NIK saya [NIK_DISAMARKAN]"` | PASS |
| 3 | Unit Test HTTP Fallback | API mengembalikan HTTP 403 / 500 | Menangani status code dan melempar pesan terstruktur | PASS |
| 4 | Widget Test UI Chat | Input pesan & tombol kirim ditekan | Pesan user muncul di kanan, balasan AI muncul di kiri | PASS |
| 5 | Widget Test Fallback UI | Gagal memanggil API AI | Bubble error ramah *"Layanan AI Sibuk"* tampil di chat | PASS |

