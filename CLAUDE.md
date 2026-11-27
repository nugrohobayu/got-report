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
## Bahasa respons Claude
Semua balasan, penjelasan, ringkasan, pertanyaan, dan feedback dari Claude ke user **wajib dalam Bahasa Indonesia**. Istilah teknis, nama file, kode, dan perintah tetap apa adanya. Aturan bahasa kode/commit di bagian "Cara kerja dengan Claude" tetap berlaku.

## Sumber kontrak API (baca sebelum memakai endpoint)
**Spesifikasi API yang berlaku ada di tab `API` pada Sheet tim**, bukan di tabel "Kontrak API" di atas (itu draf awal; path asli memakai prefix `/api/v1/...`, mis. login HP `/api/v1/auth/staff-app/login`, tugas HP `/api/v1/field/tasks`).

- Link: https://claude.ai/cowork/cse_01Wim4d1nR6hg2XLvhy9M1kx?artifact=4f4549ef-68f2-4aee-b013-e5a7804811e8#sheet-sht_p7tes3vajw.0 (artifact id `4f4549ef-68f2-4aee-b013-e5a7804811e8`, sama dengan Sheet di Referensi tim)
- Cara baca: Sheet ini adalah artifact tipe Sheets. Baca lewat konektor **Claude Docs** (`guide` topic.sheets → `read` project untuk node workbook → `readCells` sheet `API`, mulai `A1`, sesuai `filledRange` dari `readSheets`). Jangan WebFetch link-nya.
- Kolom: Method, Endpoint, Dipakai oleh, Fungsi, Status (`Sudah`/`Belum`), Izin / catatan, **FU FE & Mobile** (catatan khusus untuk mobile), Contoh request, Contoh response (JSON nyata dari backend). Baris catatan di bawah tabel menjelaskan envelope respons, paginasi, dan prefix akses (`/field` = petugas di HP).
- Selalu baca ulang sebelum membuat/mengubah pemanggilan API: isinya diperbarui Rofik dan bisa berubah. Pakai hanya endpoint dengan Status `Sudah`; jika `Belum`, jangan dipanggil dulu (kabari user; `FakeApi` belum dibuat, lihat "Selama backend belum siap").
- Jangan menebak path/field. Jika endpoint yang dibutuhkan tidak ada di tab API, tanyakan ke user (kabari Rofik), jangan mengarang.
- Sheet hanya dibaca. Jangan menulis ke Sheet kecuali user memintanya.
- `GET /api/v1/field/tasks` untuk daftar tugas: kirim `dueFrom`/`dueTo` saja, **tanpa parameter `status`** (dikonfirmasi backend). Pengecualian: pelacak GPS (`ping_tracker.dart`) tetap mengirim `status=DIKERJAKAN`.

## Stack
- Flutter (Dart, null safety), target Android dulu (demo), iOS jika sempat
- bloc untuk state, go_router untuk navigasi
- dio untuk HTTP (+ interceptor JWT dan error `{code, message}`); model & client boleh di-generate dari `openapi.json` repo backend (salin ke `openapi/`)
- mobile_scanner (QR), camera (foto, **tanpa galeri**), geolocator (GPS), signature (TTD)
- flutter_secure_storage untuk token

## Package yang dipakai (`pubspec.yaml`)
Cek tabel ini sebelum menambah package baru; pakai yang sudah ada jika fungsinya sama. Jika menambah/menghapus package, perbarui tabel ini.

| Package | Versi | Dipakai untuk | Lokasi utama |
|---|---|---|---|
| `flutter_bloc`, `bloc`, `equatable` | ^8.1.6, ^8.1.4, ^2.0.5 | State management (Cubit/Bloc), state yang bisa dibandingkan | `features/*/presentation/` , `core/theme/theme_cubit.dart` |
| `go_router` | ^14.6.2 | Navigasi & deep link dari notifikasi | `core/router/` |
| `dio` | ^5.7.0 | HTTP client + interceptor JWT & error `{code, message}` | `core/network/api_client.dart`, `core/auth/auth_interceptor.dart` |
| `path_provider` | ^2.1.5 | Folder lokal untuk unduhan (mis. PDF laporan) | `core/network/download_service.dart` |
| `flutter_dotenv` | ^5.2.1 | Baca `BASE_URL` dari `.env` (di-bundle sebagai asset) | `core/config/env_config.dart`, `main.dart` |
| `shared_preferences` | ^2.3.3 | Preferensi non-rahasia: override `BASE_URL` per perangkat, tema, status notifikasi | `core/config/`, `core/theme/`, `core/push/` (key di `core/utils/preference_keys.dart`) |
| `flutter_secure_storage` | ^9.2.2 | Simpan token JWT (jangan di `shared_preferences`) | `core/auth/` |
| `intl` + `flutter_localizations` | ^0.19.0 | Format tanggal/jam Bahasa Indonesia (`id_ID`) | `core/utils/date_formatter.dart`, `main.dart` |
| `google_fonts` | ^6.2.1 | Font aplikasi (file font di-bundle di `assets/google_fonts/`, tidak unduh saat runtime) | `core/theme/app_theme.dart` |
| `flutter_svg` | ^2.0.17 | Ilustrasi/logo SVG | `features/login/` |
| `cupertino_icons` | ^1.0.8 | Ikon iOS bawaan | — |
| `table_calendar` | ^3.1.3 | Kalender tugas | `features/kalender_tugas/` |
| `url_launcher` | ^6.3.2 | Tombol Navigasi → buka Google Maps via URL | `features/tugas_hari_ini/presentation/widgets/open_navigation.dart` |
| `geolocator` | ^13.0.4 | GPS untuk mulai tugas & ping berkala (hanya saat tugas berjalan) | `core/location/location_service.dart` (dipakai `core/tracking/ping_tracker.dart`) |
| `mobile_scanner` | ^5.2.3 | Scan QR (hanya jika `wajib_qr`, atau field `qr`) | `features/mulai_tugas/presentation/pages/qr_scan_page.dart` (dipakai juga oleh `form_dinamis`) |
| `camera` | ^0.11.2 | Foto bukti langsung dari kamera, **tanpa galeri** | `features/kamera/` |
| `image` | ^4.13.1 | Perbaiki orientasi EXIF & perkecil foto (JPEG q85) sebelum upload. **Bukan untuk watermark** (watermark dibuat server) | `features/kamera/presentation/pages/camera_capture_page.dart` |
| `signature` | ^5.5.0 | Kanvas tanda tangan klien | `features/ttd/` |
| `firebase_core`, `firebase_messaging` | ^5.1.0, ^17.0.1 | Push notification (FCM) tugas baru/berubah | `core/push/` |
| `firebase_app_installations` | ^0.5.1 | ID instalasi perangkat untuk registrasi push | `core/push/push_service.dart` |
| `flutter_local_notifications` | ^19.5.0 | Tampilkan notifikasi saat aplikasi di foreground | `core/push/push_notifications.dart` |
| `app_settings` | ^6.1.1 | Buka pengaturan notifikasi sistem dari halaman Profil | `features/profil/presentation/pages/profile_page.dart` |

Dev: `flutter_lints` ^5.0.0 (lint), `flutter_launcher_icons` ^0.14.3 (ikon app, jalankan `dart run flutter_launcher_icons`; sumber di `assets/icon/`).

Tidak dipakai dan **jangan ditambahkan**: `image_picker` (galeri dilarang).

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
- Status backend (`/field/tasks`): `DITUGASKAN` (Belum mulai), `DIKERJAKAN`, `MENUNGGU_TTD`, `PERLU_REVISI` (Berjalan), `SELESAI`, `DIBATALKAN`.
- Tugas `DIBATALKAN` **tetap ditampilkan** di daftar (hari ini, kalender, riwayat): label "Dibatalkan", abu, ikon larangan, tanpa tombol aksi, tidak dihitung terlambat dan tidak dipilih sebagai tugas terdekat. Jangan disaring.
- Setiap request: loading state, pesan error dari backend apa adanya.

## Izin (AndroidManifest)
`CAMERA`, `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, `INTERNET`.

## Selama backend belum siap
`FakeApi` **belum dibuat** (tidak ada `FakeApi` maupun flag `USE_FAKE` di kode); semua request saat ini langsung ke server `BASE_URL`. Jika nanti dibutuhkan: baca JSON contoh (template "Instalasi mesin antrean" dari bagian Bersama di atas) dan pilih lewat variabel di `.env` (mis. `USE_FAKE=true`, tambahkan juga ke `.env.example`), konsisten dengan konfigurasi `BASE_URL`.

## Perintah
```bash
cp .env.example .env          # sekali saja, lalu isi BASE_URL
flutter pub get
flutter run
flutter analyze && flutter test
dart run flutter_launcher_icons   # hanya jika ikon di assets/icon/ berubah
```

Konfigurasi server (`lib/core/config/env_config.dart`):
- `BASE_URL` dibaca dari `.env` (di-bundle sebagai asset lewat `flutter_dotenv`, dimuat di `main.dart`). Tidak memakai `--dart-define`.
- `BASE_URL` berisi host saja, **tanpa** `/api`; path endpoint sudah memuat prefix `/api/v1/...` (lihat `core/constants/app_constants.dart`). Contoh: emulator Android `BASE_URL=http://10.0.2.2:8080`, HP fisik `BASE_URL=http://<IP-laptop>:8080` (jaringan yang sama).
- `.env` ada di `.gitignore`; `.env.example` adalah templatenya. Jika menambah variabel baru, tambahkan juga ke `.env.example` (tanpa nilai rahasia).
- Mengubah `.env` perlu build/run ulang (bukan hot reload), karena file ikut di-bundle.
- Ganti server tanpa build ulang: di aplikasi, **Profil → ketuk versi aplikasi 3×** → form env. Nilainya disimpan per perangkat di `shared_preferences` (`PreferenceKeys.baseUrlOverride`); mengisi nilai yang sama dengan `.env` mengembalikan ke default.

## Jangan
- Memakai `image_picker` dari galeri atau menulis watermark di HP.
- Memakai jam HP sebagai bukti waktu.
- Mengirim GPS di luar tugas yang berjalan.
