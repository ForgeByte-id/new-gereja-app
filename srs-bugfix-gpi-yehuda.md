# Spesifikasi Perbaikan — Aplikasi GPI Yehuda (PWA & Admin)

**Tanggal:** 30 Juni 2026
**Sumber:** Temuan klien via WhatsApp
**Status verifikasi:** Sudah dicek ke source code, ketiganya valid (lihat referensi file)

---

## 1. Logo PWA masih logo default Flutter

**Kondisi saat ini**
`web/manifest.json` dan `web/index.html` sudah mereferensikan path `icons/Icon-192.png`, `Icon-512.png`, `Icon-maskable-192.png`, `Icon-maskable-512.png`, dan `favicon.png` — tapi file gambar di `web/icons/` & `web/favicon.png` masih asset default Flutter, belum diganti logo gereja.

**Yang diharapkan**
- Ganti 5 file icon di atas dengan logo gereja (ukuran & nama file tetap sama agar tidak perlu ubah manifest).
- Pastikan versi maskable punya safe-zone padding (icon tidak terpotong saat jadi app icon Android).
- Setelah ganti, perlu rebuild PWA + hard refresh/clear cache agar service worker ambil asset baru.

**File terkait:** `web/manifest.json`, `web/index.html`, `web/icons/*`, `web/favicon.png`

---

## 2. Fitur tambah berita/rekap acara belum ada di Admin

**Kondisi saat ini**
- Di app jemaat, halaman "Berita" (`jemaat_berita_page.dart`) sudah ada UI-nya, tapi datanya **hardcode kosong** — belum terhubung ke endpoint API manapun (`_berita = []` permanen, hanya placeholder).
- Di sisi API (Laravel) maupun Admin, **tidak ada model/endpoint/menu** untuk CRUD berita sama sekali. Ini bukan bug kecil, tapi fitur yang belum dibangun.

**Yang diharapkan (scope minimum)**
- **API:** tabel `news`/`berita` (kolom: title, content/description, cover image opsional, created_by, published_at), endpoint:
  - `GET /news` — list untuk app jemaat (publik/login)
  - `POST /news`, `PUT /news/{id}`, `DELETE /news/{id}` — khusus admin
- **Admin:** menu baru "Berita" dengan form tambah/edit/hapus.
- **App Jemaat:** ganti `jemaat_berita_page.dart` agar fetch dari `GET /news` (bukan list kosong hardcode), tampilkan title, ringkasan, tanggal, dan detail saat di-tap.

**File terkait:** `lib/src/pages/jemaat_berita_page.dart`, `lib/src/core/api_client.dart`, `api/app/Http/Controllers/`, `api/app/Models/`, `api/routes/`

---

## 3. Link sosial media (TikTok, Instagram, dll) di Admin tidak muncul di app jemaat

**Kondisi saat ini**
- Admin bisa input Instagram & TikTok di form "Profil Gereja" dan data tersimpan ke API (`PUT /church/profile`, field `metadata.instagram`, `metadata.tiktok`).
- App jemaat memang sudah memanggil `GET /church/profile` (`jemaat_dashboard_page.dart`), **tapi hanya memakai `name`, `address`, dan `logo`** dari hasil response. Field `metadata.instagram` & `metadata.tiktok` diambil tapi tidak pernah dirender di UI.

**Yang diharapkan**
- Di halaman dashboard/profil jemaat, tambahkan section "Sosial Media" yang menampilkan instagram & tiktok (dan field sosial lain yang sudah ada di `metadata` jika ada), sebagai link yang bisa di-tap (buka browser/app terkait).
- Sembunyikan section ini jika field kosong.

**File terkait:** `lib/src/pages/jemaat_dashboard_page.dart`, `lib/src/pages/admin_dashboard_page.dart` (referensi field yang sudah ada), `api/app/Http/Controllers/ChurchProfileController.php`

---

## 4. Tombol "Dokumentasi" di event selalu "tidak ditemukan"

**Kondisi saat ini**
- API sudah punya endpoint lengkap untuk fitur ini: `POST /events/{id}/documentation` (admin upload foto/file dokumentasi acara) dan `GET /events/{id}/documentation/download` (jemaat unduh semua file dalam bentuk `.zip`).
- App jemaat **sudah** memanggil endpoint download (`_downloadDokumentasi` di halaman dashboard event), jadi tombolnya berfungsi secara teknis.
- Tapi di Admin **tidak ada UI sama sekali** untuk upload dokumentasi event — method `uploadDocumentation` di API tidak pernah dipanggil dari aplikasi manapun. Karena tidak pernah ada yang upload, file-nya memang selalu kosong → makanya saat jemaat klik "Dokumentasi", hasilnya 404 ("tidak ditemukan"). Bukan bug, tapi fitur admin yang belum dibangun.

**Catatan dari klien**
Klien menilai fitur ini lebih cocok dipakai untuk **foto-foto dokumentasi acara**, dan akan lebih make sense kalau digabung dengan fitur Berita (poin #2) — misal satu post berita = judul + isi + lampiran foto-foto kegiatan, daripada jadi fitur upload terpisah per event.

**Yang diharapkan (pilih salah satu arah, perlu konfirmasi ke klien)**
- **Opsi A — sesuai desain awal:** Tambahkan UI upload dokumentasi di Admin pada halaman detail event (admin pilih event → upload foto/file → tersimpan via `POST /events/{id}/documentation`). Tombol download di app jemaat tidak perlu diubah.
- **Opsi B — sesuai saran klien:** Gabungkan dengan fitur Berita (poin #2) — saat admin tambah berita, sertakan upload beberapa foto sebagai lampiran/galeri yang bisa diunduh jemaat dari halaman berita. Fitur upload dokumentasi per-event yang sudah ada di API bisa di-deprecate/tidak dipakai.

**File terkait:** `api/app/Http/Controllers/EventController.php` (`uploadDocumentation`, `downloadDocumentation`), `api/app/Http/Requests/Events/UploadDocumentationRequest.php`, `lib/src/pages/jemaat_dashboard_page.dart` (`_downloadDokumentasi`), halaman admin event (belum ada UI upload)

---

## Prioritas yang disarankan
1. **#3** (fix UI render, kecil & cepat)
2. **#1** (ganti asset, kecil & cepat)
3. **#4** (perlu konfirmasi arah dulu ke klien: gabung ke Berita atau upload terpisah per event)
4. **#2** (fitur baru, perlu API + Admin + App — paling besar; kalau klien pilih Opsi B di #4, sebaiknya digarap bareng dengan ini)