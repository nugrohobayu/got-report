# Form Tugas Custom — Mobile Teknisi (PIC: Bayu)

Repo `form-tugas-mobile` adalah salah satu dari 3 repo proyek **Form Tugas Custom** (Hackathon Tim Milenials, Newtronic). File ini punya dua bagian: **Bersama** (sama di semua repo) dan **Khusus repo ini**.

---

# Bagian Bersama
## Produk dalam satu kalimat
Admin menyusun template form tugas lapangan, menugaskan teknisi/satpam ke lokasi, teknisi mengerjakan di HP dengan bukti yang sulit dipalsukan (GPS, foto kamera ber-watermark server, QR opsional, TTD klien), lalu sistem membuat laporan PDF/BAST dan menampilkan monitoring dinas luar di peta.

## Konteks hackathon
- Tujuan hackathon: **mengeksplor sejauh mana AI bisa dipakai untuk membuat aplikasi.** Utamakan kode yang dihasilkan AI, manusia mereview dan memutuskan.
- Durasi 7 hari: 17–23 Nov 2026. Demo final 23 Nov.
  - Hari 3–4 (19–20 Nov): build fitur inti
  - Hari 5 (21 Nov): integrasi, peta, code freeze malam
  - Hari 6 (22 Nov): rangkum temuan AI, deck, video
- Setiap pemakaian AI yang berarti dicatat di sheet tab **Log AI** (tool, tugas, hasil, waktu, % kode dari AI, pelajaran). Ingatkan user di akhir sesi kerja yang besar.

## Tim
| Nama | Peran | Repo |
|---|---|---|
| Rofik | Backend (Java Spring Boot) | `form-tugas-backend` |
| Cky | Frontend web admin (React TS) | `form-tugas-web` |
| Bayu | Frontend mobile teknisi (Flutter) | `form-tugas-mobile` |

## Repo (terpisah)
| Repo | PIC | Isi |
|---|---|---|
| `form-tugas-backend` | Rofik | Spring Boot + `docker-compose.yml` (PostGIS, MinIO) + `docs/openapi.json` |
| `form-tugas-web` | Cky | React TS web admin |
| `form-tugas-mobile` | Bayu | Flutter aplikasi teknisi |

Bagian **"Bersama"** di file ini sama persis di ketiga repo. Jika aturan bersama berubah, ubah di ketiga repo sekaligus.

## Fitur MVP (jangan melebar)
1. Template builder (web) + **buat template dari kalimat dengan AI**
2. Penugasan: template, teknisi, lokasi, tenggat
3. Kerjakan di HP: mulai tugas (GPS, QR opsional), form dinamis langkah berurutan, foto kamera, TTD klien
4. Laporan PDF/BAST otomatis + dashboard status
5. Monitoring dinas luar: peta pin tugas, posisi terakhir teknisi, rute aktual per tanggal, ringkasan harian AI

**Nice to have, kerjakan hanya jika MVP selesai:** replay pergerakan, rute optimal (VROOM), mode offline, notifikasi tugas terlewat.

## Aturan bisnis (sumber kebenaran untuk semua platform)
- **Bukti hadir = GPS dalam radius lokasi** (`lokasi.radius_m`). Scan QR **opsional**: hanya diminta jika `template.wajib_qr = true`.
- Foto hanya dari kamera, tidak dari galeri. Watermark (jam server + koordinat) **dibuat server**, bukan HP.
- Semua waktu bukti memakai **jam server** (`server_time`), bukan jam HP.
- Langkah form **terkunci berurutan**: langkah berikutnya terbuka setelah field wajib langkah sebelumnya terisi.
- Status tugas: `BELUM` → `BERJALAN` (saat mulai valid) → `SELESAI` (setelah TTD). `TERLAMBAT` diset penjadwal jika tenggat lewat dan belum selesai.
- GPS berkala hanya dikirim **selama tugas berstatus BERJALAN**, tidak di luar jam tugas (privasi).
- Template berversi. Tugas menyimpan `template_versi` agar perubahan template tidak merusak tugas lama.

## Bentuk template (JSON)
```json
{
  "langkah": [
    {
      "key": "pasang_mesin",
      "judul": "Pasang mesin",
      "field": [
        { "key": "foto_before", "tipe": "foto", "label": "Foto sebelum", "wajib": true },
        { "key": "cek", "tipe": "checklist", "label": "Checklist", "opsi": ["Mesin terpasang", "Kabel rapi"], "wajib": true },
        { "key": "foto_after", "tipe": "foto", "label": "Foto sesudah", "wajib": true }
      ]
    }
  ]
}
```
`tipe`: `foto` | `checklist` | `angka` | `pilihan` | `catatan` | `qr` | `ttd`. `opsi` hanya untuk `checklist` dan `pilihan`.

## Model data
| Entitas | Field utama |
|---|---|
| User | id, nama, email, password_hash, role (`ADMIN`/`TEKNISI`) |
| Template | id, nama, versi, wajib_qr, schema (jsonb), dibuat_oleh |
| Lokasi | id, nama, alamat, lat, lng, radius_m, qr_token (nullable) |
| Tugas | id, template_id, template_versi, teknisi_id, lokasi_id, tenggat, status, mulai_at, selesai_at |
| Jawaban | id, tugas_id, field_key, nilai (jsonb), server_time |
| Foto | id, tugas_id, field_key, url, lat, lng, server_time, jenis (`BEFORE`/`AFTER`) |
| TandaTangan | id, tugas_id, nama_penandatangan, url, server_time |
| JejakGPS | id, teknisi_id, tugas_id, lat, lng, waktu |
| Laporan | id, tugas_id, pdf_url, dibuat_at |

## Kontrak API
Base path `/api`. Auth: header `Authorization: Bearer <jwt>`.

| Method | Endpoint | Pemakai | Fungsi |
|---|---|---|---|
| POST | /auth/login | Web, HP | Login → token & role |
| GET, POST | /templates | Web | Daftar & buat template |
| GET, PUT | /templates/{id} | Web | Detail & ubah (versi naik) |
| POST | /templates/generate | Web | AI: kalimat → draf template |
| GET, POST | /lokasi | Web | Daftar & buat lokasi |
| GET | /lokasi/{id}/qr | Web | Gambar QR (jika dipakai) |
| GET, POST | /tugas | Web | Daftar (filter) & buat penugasan |
| GET | /tugas/{id} | Web, HP | Detail + template + jawaban + foto |
| GET | /me/tugas?tanggal= | HP | Tugas teknisi hari ini |
| POST | /tugas/{id}/mulai | HP | GPS (+ token QR jika wajib) |
| POST | /tugas/{id}/jawaban | HP | Simpan jawaban per langkah |
| POST | /tugas/{id}/foto | HP | Upload foto + GPS (multipart) |
| POST | /tugas/{id}/ttd | HP | Upload TTD → selesai + PDF |
| GET | /tugas/{id}/laporan.pdf | Web | Unduh PDF/BAST |
| POST | /lokasi-teknisi | HP | Titik GPS berkala |
| GET | /peta?tanggal= | Web | Pin tugas + posisi terakhir teknisi |
| GET | /teknisi/{id}/rute?tanggal= | Web | Jejak & rute aktual |
| GET | /ringkasan-harian?tanggal= | Web | AI: ringkasan dinas harian |

Format error seragam:
```json
{ "code": "GPS_OUT_OF_RADIUS", "message": "Anda 240 m dari lokasi (maks 100 m)" }
```
Kode error yang disepakati: `UNAUTHORIZED`, `FORBIDDEN`, `NOT_FOUND`, `VALIDATION_ERROR`, `GPS_OUT_OF_RADIUS`, `QR_REQUIRED`, `QR_MISMATCH`, `STEP_LOCKED`, `TASK_NOT_STARTED`, `TASK_ALREADY_DONE`.

**Sumber kontrak bersama:** `docs/openapi.json` di repo backend, diperbarui Rofik setiap kontrak berubah (sertakan di commit yang sama). Web & mobile generate client dari file itu atau dari Swagger server dev.

**Mengubah kontrak API = diskusi tim dulu.** Jangan mengganti nama endpoint/field diam-diam. Jika perlu, tambahkan field baru (non-breaking) dan beri tahu user untuk mengabari tim.

## Cara kerja dengan Claude
- Kerjakan per fitur kecil, jalankan/compile setelah tiap perubahan.
- Sebelum membuat file baru, cek apakah sudah ada yang serupa.
- Jangan commit secret (API key LLM, password DB). Pakai `.env` yang ada di `.gitignore`.
- Bahasa UI: **Bahasa Indonesia**. Kode, nama variabel, dan commit: bahasa Inggris, kecuali nama entitas domain di atas.
- Commit kecil dengan pesan jelas, prefix `feat:`, `fix:`, `chore:`.

## Referensi tim
- Whiteboard (wireframe, flowchart): https://claude.ai/artifact/4XpMuSAZPgeV67SAR7XiXh
- Sheet (Tugas, Scope MVP, Skema Data, API, Tech Stack, Log AI): https://claude.ai/artifact/Ank7jSmqcdLd7i4a2t8GrB

---

# Bagian Khusus Repo Ini
## Stack
- Flutter (Dart, null safety), target Android dulu (demo), iOS jika sempat
- bloc untuk state, go_router untuk navigasi
- dio untuk HTTP (+ interceptor JWT dan error `{code, message}`); model & client boleh di-generate dari `openapi.json` repo backend (salin ke `openapi/`)
- mobile_scanner (QR), camera (foto, **tanpa galeri**), geolocator (GPS), signature (TTD)
- flutter_secure_storage untuk token

## Struktur
```
lib/
  core/        api client (dio), auth, theme, error
  features/
    login/
    tugas_hari_ini/
    mulai_tugas/      GPS + QR opsional
    form_dinamis/     render dari JSON template
    kamera/
    ttd/
  widgets/     komponen bersama
```

## Layar MVP (lihat wireframe di whiteboard)
1. **Login** teknisi
2. **Tugas hari ini**: kartu per tugas (nama, lokasi, jam, status) + tombol Navigasi (buka Google Maps via URL)
3. **Mulai tugas**: ambil GPS → kirim ke `/tugas/{id}/mulai`.
   - Jika `template.wajib_qr = true`: tampilkan scanner, kirim token QR bersama GPS.
   - Jika tidak: **jangan tampilkan scanner**, cukup GPS.
   - Error `GPS_OUT_OF_RADIUS` → tampilkan jarak dari message + tombol coba lagi.
4. **Form dinamis**: header "Langkah N dari M", progres, render field sesuai `tipe`. Tombol Lanjut aktif hanya jika field wajib terisi. Langkah terkunci berurutan.
5. **Kamera bukti**: buka kamera langsung (`camera` package), tidak ada pilihan galeri. Upload multipart + lat/lng ke `/tugas/{id}/foto`. Tampilkan hasil ber-watermark dari server.
6. **Tanda tangan klien**: kanvas TTD + nama penandatangan, tombol Hapus & Selesai → `/tugas/{id}/ttd`.

## Render field dari template
| tipe | Widget |
|---|---|
| foto | tombol "Ambil foto" → layar kamera, thumbnail hasil |
| checklist | daftar CheckboxListTile dari `opsi` |
| angka | TextField numerik |
| pilihan | Radio / Dropdown dari `opsi` |
| catatan | TextField multiline |
| qr | tombol scan (di dalam langkah) |
| ttd | layar tanda tangan |

Field tidak dikenal → tampilkan teks "Field tidak didukung" (jangan crash).

## GPS berkala
- Mulai kirim titik ke `/lokasi-teknisi` tiap 1–2 menit **hanya setelah tugas BERJALAN**, berhenti saat tugas SELESAI atau aplikasi logout.
- Untuk MVP cukup saat aplikasi di foreground. Background tracking = nice to have.
- Minta izin lokasi dengan penjelasan Bahasa Indonesia ("Lokasi dipakai sebagai bukti hadir selama tugas berjalan").

## Aturan UI
- Bahasa Indonesia, tombol besar (dipakai di lapangan), satu tombol utama biru per layar.
- Warna status sama dengan web: Belum abu, Berjalan biru, Selesai hijau, Terlambat merah.
- Setiap request: loading state, pesan error dari backend apa adanya.

## Izin (AndroidManifest)
`CAMERA`, `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, `INTERNET`.

## Selama backend belum siap
Buat `FakeApi` yang membaca JSON contoh (template "Instalasi mesin antrean" dari bagian Bersama di atas) dan pilih lewat `--dart-define=USE_FAKE=true`.

## Perintah
```bash
flutter pub get
flutter run --dart-define=API_URL=http://10.0.2.2:8080/api   # emulator Android
flutter analyze && flutter test
```
Di HP fisik, ganti `API_URL` dengan IP laptop di jaringan yang sama.

## Jangan
- Memakai `image_picker` dari galeri atau menulis watermark di HP.
- Memakai jam HP sebagai bukti waktu.
- Mengirim GPS di luar tugas yang berjalan.
