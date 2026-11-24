# Menyambungkan pengajuan izin ke Supabase

Folder ini berisi versi aplikasi yang menyinkronkan pengajuan izin dan catatan check-in/check-out ke Supabase. Pengaturan, shift, dan foto tetap tersimpan lokal.

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
5. Karena tabel izin Anda sudah dibuat, jalankan isi terbaru `supabase/izin-status-update.sql` di **SQL Editor → New query → Run**. Jika pernah menjalankan versi sebelumnya, jalankan ulang file yang terbaru; file ini sekarang juga menambahkan fungsi untuk tanda kalender bersama.
6. Jalankan isi `supabase/absensi-sync-update.sql` sekali di **SQL Editor → New query → Run**. Ini membuat tabel absensi bersama: publik dapat mengirim check-in, sementara hanya admin terdaftar dapat membaca seluruh rekap. Jangan unggah kode aplikasi terbaru sebelum kedua SQL berhasil dijalankan.

## C. Terbitkan lewat GitHub Pages

1. Setelah SQL status berhasil dijalankan, unggah isi folder ini ke repository GitHub Anda dan timpa file lama. Pertahankan struktur folder, termasuk `img/`.
2. Di repository GitHub, buka **Settings → Pages**.
3. Pada **Build and deployment**, pilih **Deploy from a branch**, pilih branch `main` dan folder `/(root)`, lalu simpan.
4. Buka tautan Pages yang diberikan GitHub.

URL proyek dan publishable key Supabase sudah diisi di `app.js`. Publishable key memang akan terlihat di browser; keamanan datanya berasal dari RLS. Jangan pernah menggantinya dengan secret/service-role key.

## D. Cara pakai

- Karyawan membuka link, memilih nama, lalu mengirim pengajuan seperti biasa.
- Admin menekan **Masuk admin** di header HP, sidebar, atau halaman **Izin**, lalu masuk dengan email/kata sandi yang dibuat di langkah A. Menu Rekap, Karyawan/Tim, Atur, dan tindakan persetujuan juga meminta login admin.
- Untuk membuka layar login admin langsung, tambahkan `?admin=1` di belakang link GitHub Pages. Link biasa tetap membuka dashboard karyawan.
- Admin memakai tombol **Muat ulang** untuk mengambil pengajuan terbaru, lalu menyetujui atau menolaknya.
- Check-in/check-out baru akan dikirim ke Supabase, lalu muncul pada rekap setelah admin masuk. Perangkat harus tersambung internet saat absen; jika sinkronisasi gagal, aplikasi memberi pesan bahwa catatan hanya tersimpan di perangkat itu.
- Setelah pembaruan dipasang dan SQL status dijalankan, pengaju dapat melihat status pengajuan dari browser/perangkat tempat ia mengirimnya, melalui tab **Izin**. Aplikasi mengecek pembaruan saat tab Izin dibuka dan berkala selama halaman itu terbuka; status yang berubah akan muncul sebagai pesan. Tombol **Muat ulang** juga bisa dipakai.
- Kalender mengambil pengajuan yang disetujui dari Supabase agar tanda tanggalnya terlihat di perangkat lain. Untuk privasi, tanda bersama ditampilkan sebagai **Izin** generik; alasan dan pembedaan sakit/cuti hanya terlihat oleh admin serta pengaju di browsernya.

Token status izin dan check-in tersimpan di browser pengaju. Jadi status izin dan check-out perlu dilakukan dari browser/perangkat yang sama. Pengajuan izin dan absensi lama tidak otomatis diunggah. Pemberitahuan status izin tampil di dalam aplikasi, bukan push notification ketika aplikasi tertutup. Dengan pilihan **pilih nama**, aplikasi tidak memverifikasi identitas karyawan; setiap pengunjung dapat memilih nama dan mengirim check-in.

Pengajuan lama di `localStorage` tidak otomatis diunggah. Data dummy bawaan dihapus; lima karyawan yang diminta tetap dipertahankan. Foto, absensi, dan pengaturan belum disinkronkan.
