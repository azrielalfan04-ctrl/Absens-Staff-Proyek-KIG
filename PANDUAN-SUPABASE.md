# Menyambungkan pengajuan izin ke Supabase

Folder ini berisi versi aplikasi yang mengirim pengajuan izin ke Supabase. Data absen, pengaturan, shift, dan foto masih tersimpan lokal seperti sebelumnya; perubahan ini hanya menyinkronkan pengajuan izin.

## A. Siapkan akun admin

1. Masuk ke dashboard proyek Supabase Anda.
2. Buka **Authentication → Users**, lalu pilih **Add user**.
3. Buat pengguna admin dengan email dan kata sandi yang akan dipakai saat tombol **Masuk admin** di aplikasi. Pastikan email admin terverifikasi.
4. Setelah dibuat, salin nilai **UID** pengguna tersebut.

## B. Buat tabel dan aturan keamanan

1. Buka **SQL Editor → New query**.
2. Buka file `supabase/izin-schema.sql`, salin seluruh isinya, tempel ke SQL Editor, lalu pilih **Run**. File ini menambahkan kolom yang hilang pada tabel `izin` yang sudah ada, sehingga tidak perlu menghapus tabel atau datanya.
3. File SQL sudah memuat UID admin yang Anda kirim. Jika akun Supabase tersebut sudah dibuat, perintah di bagian bawah file akan mendaftarkannya saat Anda menjalankan SQL.
4. Jangan membuat policy yang memberi akses `SELECT` kepada `anon`. Policy dalam file ini membolehkan pengunjung mengirim pengajuan berstatus **menunggu**, tetapi hanya admin terdaftar yang dapat membaca dan memproses data.

## C. Terbitkan lewat GitHub Pages

1. Unggah isi folder ini ke repository GitHub Anda. Pertahankan struktur folder, termasuk `img/`.
2. Di repository GitHub, buka **Settings → Pages**.
3. Pada **Build and deployment**, pilih **Deploy from a branch**, pilih branch `main` dan folder `/(root)`, lalu simpan.
4. Buka tautan Pages yang diberikan GitHub.

URL proyek dan publishable key Supabase sudah diisi di `app.js`. Publishable key memang akan terlihat di browser; keamanan datanya berasal dari RLS. Jangan pernah menggantinya dengan secret/service-role key.

## D. Cara pakai

- Karyawan membuka link, memilih nama, lalu mengirim pengajuan seperti biasa.
- Admin menekan **Masuk admin** di header HP, sidebar, atau halaman **Izin**, lalu masuk dengan email/kata sandi yang dibuat di langkah A. Menu Rekap, Karyawan/Tim, Atur, dan tindakan persetujuan juga meminta login admin.
- Untuk membuka layar login admin langsung, tambahkan `?admin=1` di belakang link GitHub Pages. Link biasa tetap membuka dashboard karyawan.
- Admin memakai tombol **Muat ulang** untuk mengambil pengajuan terbaru, lalu menyetujui atau menolaknya.

Dengan pilihan **pilih nama**, aplikasi tidak memverifikasi identitas karyawan. Pengunjung yang memiliki link dapat mengirim pengajuan dengan memilih nama siapa pun, tetapi tidak dapat membaca atau mengubah status pengajuan di Supabase. Agar setiap karyawan dapat melihat riwayatnya sendiri dengan aman, perlu login masing-masing.

Pengajuan lama di `localStorage` tidak otomatis diunggah. Data dummy bawaan dihapus; lima karyawan yang diminta tetap dipertahankan. Foto, absensi, dan pengaturan belum disinkronkan.
