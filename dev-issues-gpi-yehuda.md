# Dev Issues — Aplikasi GPI Yehuda
**Diperbarui:** 1 Juli 2026 | **Sumber:** Temuan klien + verifikasi source code

---

## 🔴 Bug — Harus Diperbaiki

### 1. Registrasi akun gagal (alur KK tidak berfungsi)
**Temuan:** Registrasi jemaat gagal, tidak jelas di mana data KK tersimpan.

**Root cause (dari kode):**
Registrasi di `login_page.dart` mengirim banyak field (name, username, email, password, nomor_kk, usia, alamat, dll). Backend di `AuthController::register` sudah memvalidasi bahwa nama harus cocok dengan `kk_registrations.nama_kepala_keluarga` atau user yang sudah ada di KK yang sama. Kemungkinan gagal karena: (a) data KK belum diinput admin ke tabel `kk_registrations` sebelum jemaat daftar, atau (b) normalisasi nama tidak cocok (case/spasi).

**Yang harus dilakukan:**
- Pastikan alur admin: admin wajib input data KK dulu via `admin_kk_management_page.dart` sebelum jemaat bisa daftar.
- Tambahkan pesan error yang lebih jelas di UI saat registrasi gagal karena KK tidak ditemukan (saat ini hanya `_error` string biasa).
- Investigasi log error spesifik di production.

**File:** `lib/src/pages/login_page.dart` → `_submitRegister()`, `api/app/Http/Controllers/AuthController.php` → `register()`, `api/app/Models/KKRegistration.php`

---

### 2. Broadcast notifikasi selalu gagal
**Temuan:** Klik kirim broadcast dari Admin tidak berhasil.

**Root cause (dari kode):**
Backend `NotificationController::broadcast` dan `PushNotificationService` sudah lengkap dan terhubung ke FCM. Flutter juga sudah ada `_kirimBroadcast()` di `admin_dashboard_page.dart`. Kemungkinan penyebab: (a) FCM server key belum dikonfigurasi di environment production, (b) tidak ada device yang terdaftar FCM token (jika belum ada yang login dari native app), (c) throttle rate limit `broadcast` terlalu ketat.

**Yang harus dilakukan:**
- Cek konfigurasi FCM di `.env` production (`FIREBASE_CREDENTIALS` atau key terkait).
- Pastikan ada device aktif dengan FCM token terdaftar di tabel `user_devices` sebelum mencoba broadcast.
- Tampilkan pesan error dari API response ke UI (saat ini hanya `_snack(error.message)` — pastikan error message dari API cukup deskriptif).

**File:** `api/app/Services/PushNotificationService.php`, `api/app/Http/Controllers/NotificationController.php`, `lib/src/pages/admin_dashboard_page.dart` → `_kirimBroadcast()`

---

### 3. Upload foto profil gagal
**Temuan:** Klik upload foto profil tidak berhasil.

**Root cause (dari kode):**
Backend `AuthController::uploadProfilePhoto` dan endpoint `POST /auth/me/photo` sudah ada dan diuji. Flutter punya dua path: `uploadProfilePhoto` (file path, untuk mobile) dan `uploadProfilePhotoBytes` (bytes dari FilePicker, untuk web). Kemungkinan penyebab di production: (a) `php artisan storage:link` belum dijalankan sehingga `/storage/` tidak bisa diakses, atau (b) permission folder `storage/app/public/profile-photos` belum writable.

**Yang harus dilakukan:**
- Jalankan `php artisan storage:link` di server production.
- Pastikan `storage/app/public/` writable oleh web server (`chmod -R 775 storage`).
- Verifikasi `APP_URL` di `.env` production sudah benar agar `Storage::url()` menghasilkan URL yang bisa diakses.

**File:** `api/app/Http/Controllers/AuthController.php` → `uploadProfilePhoto()`, `lib/src/core/api_client.dart` → `uploadProfilePhoto()` / `uploadProfilePhotoBytes()`

---

### 4. Foreign key `events.category` tidak berelasi ke `event_categories`
**Temuan:** Di database, tabel event dan event_kategori tidak memiliki FK constraint.

**Root cause (dari kode):**
Migration `create_events_table.php` mendefinisikan kolom `category` sebagai `$table->string('category', 80)` — hanya string biasa, bukan foreign key ke `event_categories.code`. Relasi hanya enforced lewat validasi aplikasi (`exists:event_categories,code`), bukan di level database.

**Yang harus dilakukan:**
- Buat migration baru yang menambah FK constraint: `$table->foreign('category')->references('code')->on('event_categories')->restrictOnDelete()`.
- Atau pertimbangkan ubah ke integer FK (`category_id`) jika ingin lebih proper — tapi ini butuh update lebih banyak kode.
- Periksa tabel lain yang mungkin punya masalah serupa.

**File:** `api/database/migrations/2026_03_26_000002_create_events_table.php`, `api/app/Models/Event.php`

---

### 5. Dark/light mode tidak tersimpan saat reload
**Temuan:** Pengaturan dark/light mode kembali ke default saat app di-refresh.

**Root cause (dari kode):**
Di `main.dart` (`_GerejaAppState`), `ThemeMode _themeMode = ThemeMode.system` hanya disimpan di in-memory state. Toggle via `_setDarkMode(bool)` tidak menyimpan ke `SharedPreferences`. Padahal `SharedPreferences` sudah dipakai untuk token dan role — tinggal tambahkan key untuk theme.

**Yang harus dilakukan:**
```dart
// Di _GerejaAppState.initState(), load preference:
final prefs = await SharedPreferences.getInstance();
final savedDark = prefs.getBool('theme_dark');
if (savedDark != null) {
  _themeMode = savedDark ? ThemeMode.dark : ThemeMode.light;
}

// Di _setDarkMode(bool darkMode):
final prefs = await SharedPreferences.getInstance();
await prefs.setBool('theme_dark', darkMode);
setState(() { _themeMode = darkMode ? ThemeMode.dark : ThemeMode.light; });
```

**File:** `lib/main.dart` → `_GerejaAppState`

---

## 🟡 Fitur Belum Dibangun

### 6. Fitur Berita/Rekap Acara (Admin & App Jemaat)
**Temuan:** Ada halaman berita di app jemaat tapi tidak bisa tambah dari Admin.

**Kondisi saat ini:** `jemaat_berita_page.dart` punya UI tapi data hardcode kosong (`_berita = []`). Tidak ada model, migration, endpoint, atau menu admin untuk berita sama sekali.

**Scope yang perlu dibangun:**
- **Database:** tabel `news` (id, title, body, cover_image nullable, created_by, published_at, timestamps).
- **API:** `GET /news` (publik), `POST /news`, `PUT /news/{id}`, `DELETE /news/{id}` (admin only).
- **Admin:** menu "Berita" dengan form tambah/edit/hapus + upload foto.
- **App Jemaat:** `jemaat_berita_page.dart` fetch dari `GET /news`, tampilkan list → detail.

**File:** `lib/src/pages/jemaat_berita_page.dart`, `api/app/Http/Controllers/`, `api/app/Models/`, `api/routes/api.php`

---

### 7. Fitur Download Dokumentasi dipindah ke Berita
**Temuan:** Tombol "Dokumentasi" di event selalu "tidak ditemukan" — tidak ada UI upload di Admin.

**Kondisi saat ini:** Endpoint `POST /events/{id}/documentation` dan `GET /events/{id}/documentation/download` sudah ada di API. Tombol download juga sudah ada di app jemaat. Tapi tidak ada UI upload di Admin → file selalu kosong → selalu 404.

**Yang harus dilakukan:**
- Hapus tombol download dokumentasi dari halaman event di app jemaat.
- Gabungkan ke fitur Berita (issue #6): saat admin tambah berita/rekap acara, sertakan upload beberapa foto/file sebagai lampiran yang bisa diunduh jemaat dari halaman berita.
- Endpoint `POST /events/{id}/documentation` yang lama bisa di-deprecate.

**File:** `lib/src/pages/jemaat_dashboard_page.dart` → `_downloadDokumentasi()`, `api/app/Http/Controllers/EventController.php`

---

### 8. CRUD Kategori Event belum ada di Admin
**Temuan:** Kategori tidak bisa ditambahkan dari Admin.

**Kondisi saat ini:** Tabel `event_categories` sudah ada dengan 4 data seed (ibadah, persekutuan, doa, pelayanan_sosial). Endpoint `GET /events/categories` sudah ada. Tapi tidak ada endpoint CRUD maupun UI Admin untuk kelola kategori.

**Yang harus dilakukan:**
- **API:** `POST /events/categories`, `PUT /events/categories/{id}`, `DELETE /events/categories/{id}` (admin only). Clear cache `event_categories.active` setelah mutasi.
- **Admin:** tambah UI kelola kategori (nama, kode, urutan, aktif/nonaktif).

**File:** `api/app/Http/Controllers/EventController.php` → `categories()`, `api/app/Models/EventCategory.php`, `api/routes/api.php`

---

### 9. Link sosial media tidak tampil di app jemaat
**Temuan:** Admin sudah input IG & TikTok di profil gereja tapi tidak muncul di app jemaat.

**Kondisi saat ini:** Admin bisa simpan `metadata.instagram` dan `metadata.tiktok` via `PUT /church/profile`. App jemaat sudah fetch `GET /church/profile` tapi hanya pakai `name`, `address`, dan `logo` — field metadata sosmed diabaikan di UI.

**Yang harus dilakukan:**
- Di `jemaat_dashboard_page.dart`, tambah section "Sosial Media" yang render IG & TikTok dari `_gereja['metadata']` sebagai link yang bisa di-tap.
- Sembunyikan section jika semua field sosmed kosong.

**File:** `lib/src/pages/jemaat_dashboard_page.dart` → `_gereja` state

---

### 10. Logo PWA masih default Flutter
**Temuan:** Icon di homescreen/taskbar masih logo Flutter.

**Kondisi saat ini:** `web/manifest.json` dan `web/index.html` sudah benar. File gambar di `web/icons/` dan `web/favicon.png` yang belum diganti.

**Yang harus dilakukan:**
- Ganti 5 file: `Icon-192.png`, `Icon-512.png`, `Icon-maskable-192.png`, `Icon-maskable-512.png`, `favicon.png` dengan logo gereja (ukuran & nama tetap sama).
- Icon maskable harus punya safe-zone padding (logo tidak terpotong di Android).
- Setelah ganti: rebuild PWA + clear cache service worker.

**File:** `web/icons/`, `web/favicon.png`

---

## 🔵 Perubahan Alur (UX/Requirement)

### 11. Alur registrasi akun disederhanakan
**Permintaan klien:** Ganti "Daftar Jemaat" menjadi "Daftar Akun" dengan form yang lebih ringkas.

**Alur baru yang diinginkan:**
1. User input **Nama Lengkap** dan **Nomor KK** (verifikasi ke data jemaat yang sudah ada).
2. Jika tidak ditemukan → tampilkan: *"Anda belum terdaftar sebagai jemaat atau nama yang dimasukkan ada kesalahan."*
3. Jika ditemukan → user isi **username** dan **password** saja.
4. Field usia, alamat, jenis kelamin, email, phone → hapus dari form registrasi (bisa diisi di edit profil setelah login).

**Di sisi Admin:**
- Field username & password di form data jemaat menjadi opsional (tidak wajib diisi admin, cukup jika jemaat daftar sendiri).

**Catatan:** Backend `AuthController::register` sudah punya logika validasi nama vs KK. Yang berubah hanya form Flutter dan field apa saja yang dikirim.

**File:** `lib/src/pages/login_page.dart` → form `_registerFormKey`, `lib/src/pages/admin_jemaat_form_page.dart`

---

### 12. Format tanggal event: ubah ke `dd/mm/yyyy`
**Permintaan klien:** Tampilan tanggal di halaman event menggunakan format `dd/mm/yyyy`.

**Kondisi saat ini:** Dua format berbeda dipakai:
- `jemaat_berita_page.dart`: `dd MMMM yyyy HH:mm WITA` (e.g. "30 Juni 2026 17:00 WITA")
- `admin_dashboard_page.dart`: `yyyy-MM-dd HH:mm WITA`

**Yang harus dilakukan:**
- Standardisasi satu helper `formatTanggal()` yang menghasilkan `dd/mm/yyyy` (atau `dd/mm/yyyy HH:mm` jika jam perlu ditampilkan).
- Terapkan ke semua halaman yang menampilkan tanggal event.

**File:** `lib/src/pages/jemaat_berita_page.dart` → `_formatTanggal()`, `lib/src/pages/admin_dashboard_page.dart` → `_labelTanggalEvent()`

---

## 🎨 Perbaikan UI & UX

### 13. Refine UI — tampilan terlalu kaku
**Tujuan:** Membuat tampilan lebih luwes, terasa lebih modern dan tidak template-ish.

**Area yang perlu diperhatikan:**

**Spacing & layout**
- Padding antar elemen terlalu seragam (semua `const EdgeInsets.all(16)` / `SizedBox(height: 8)`). Gunakan spacing yang lebih bervariasi untuk memberi hierarki visual — konten utama lebih menonjol, konten sekunder lebih tipis.
- List item di dashboard terlalu padat — tambah `contentPadding` dan `minLeadingWidth` pada `ListTile`.

**Typography**
- Gunakan variasi `fontWeight` lebih konsisten: judul section `w700`, label `w600`, body `w400`.
- Subtitle dan hint text perlu kontras yang cukup — cek di light mode apakah tidak terlalu pucat.

**Cards & container**
- Radius kartu saat ini `BorderRadius.circular(20)` tapi beberapa container dalam kartu masih `16` — standardisasi inner radius ke `12`, outer ke `20`.
- Shadow terlalu minimal di light mode — tambah sedikit elevasi agar card terasa lebih terpisah dari background.

**Empty state**
- Halaman yang datanya kosong (list berita, list event) hanya menampilkan nothing atau placeholder teks. Tambahkan ilustrasi/ikon kosong yang lebih friendly.

**Form fields**
- Input di form registrasi/edit profil terlalu berdempetan. Ganti `Column` dengan spacing minimal menjadi `Column` dengan `gap` 12–16 antar field.
- Label dan hint text pada `TextFormField` bisa lebih deskriptif (mis. hintText menunjukkan contoh format).

---

### 14. Perbaikan state dark/light mode di seluruh UI
**Tujuan:** Pastikan semua komponen mengikuti tema yang aktif secara konsisten.

**Masalah yang ditemukan:**

**Warna hardcode**
- Beberapa widget masih pakai warna hardcode (mis. `Color(0xFF121212)`, `Colors.white`) alih-alih `theme.colorScheme.*`. Ini menyebabkan elemen tampak salah warna saat mode berganti.
- Gradient latar login (`Color(0xFFE9F4F2)` untuk light, `Color(0xFF121212)` untuk dark) sudah benar, tapi perlu dicek apakah semua halaman lain juga konsisten.

**Widget yang perlu dicek:**
- `ChurchLogo` widget — pastikan fallback warna logo mengikuti `isDark`.
- Icon dan badge di dashboard — beberapa masih pakai `Colors.grey` hardcode.
- Snackbar — backgroundColor hardcode, seharusnya ikut `theme.colorScheme.inverseSurface`.
- `CircleAvatar` / foto profil placeholder — warna background saat foto null harus ikut surface color.

**Yang harus dilakukan:**
- Audit seluruh penggunaan `Color(0x...)` dan `Colors.*` literal di halaman utama, ganti dengan `Theme.of(context).colorScheme.*` atau `theme.colorScheme.*`.
- Pastikan `isDark` tidak hanya dibaca dari `widget.darkMode` (bool prop) tapi bisa juga dari `Theme.of(context).brightness` agar konsisten meski ada race condition saat rebuild.
- Selesaikan persistensi theme (lihat issue #5 di atas) agar state tidak reset.

**File:** `lib/src/pages/*.dart` (semua halaman), `lib/src/widgets/*.dart`

---

## Ringkasan Prioritas

| # | Issue | Tipe | Estimasi |
|---|-------|------|----------|
| 5 | Dark mode tidak tersimpan | Bug | XS |
| 12 | Format tanggal `dd/mm/yyyy` | Change | XS |
| 9 | Sosmed tidak tampil di jemaat | Bug | XS |
| 10 | Logo PWA masih Flutter | Bug | XS |
| 3 | Upload foto profil gagal | Bug | S |
| 2 | Broadcast notifikasi gagal | Bug | S |
| 1 | Registrasi akun gagal | Bug | S |
| 4 | FK event–kategori tidak ada | Bug | S |
| 11 | Alur registrasi disederhanakan | Change | M |
| 13 | Refine UI (keseluruhan) | UI | M |
| 14 | Dark mode konsisten di UI | UI | M |
| 8 | CRUD kategori event | Feature | M |
| 7 | Dokumentasi pindah ke Berita | Feature | M |
| 6 | Fitur Berita dari nol | Feature | L |
