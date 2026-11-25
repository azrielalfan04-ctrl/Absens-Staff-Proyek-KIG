-- Sinkronisasi profil karyawan untuk aplikasi di banyak perangkat.
-- PIN dan foto sengaja tidak disimpan/dibagikan dalam tabel ini.

create table if not exists public.karyawan (
  id text primary key,
  nama text not null,
  jabatan text not null default '',
  shift text not null default 'pagi',
  hari_kerja integer[] not null default array[1, 2, 3, 4, 5, 6],
  aktif boolean not null default true,
  warna text not null default '#4f46e5',
  mulai date
);

alter table public.karyawan enable row level security;
revoke all on public.karyawan from anon, authenticated;

-- Kolom profil dasar dapat dibaca oleh aplikasi karyawan; PIN/foto tidak ada di tabel.
grant select (id, nama, jabatan, shift, hari_kerja, aktif, warna, mulai)
  on public.karyawan to anon, authenticated;
grant insert, update, delete on public.karyawan to authenticated;

drop policy if exists "Semua perangkat membaca profil karyawan" on public.karyawan;
create policy "Semua perangkat membaca profil karyawan"
  on public.karyawan for select to anon, authenticated
  using (true);

drop policy if exists "Admin menambah profil karyawan" on public.karyawan;
create policy "Admin menambah profil karyawan"
  on public.karyawan for insert to authenticated
  with check (exists (select 1 from public.admin_users a where a.user_id = (select auth.uid())));

drop policy if exists "Admin mengubah profil karyawan" on public.karyawan;
create policy "Admin mengubah profil karyawan"
  on public.karyawan for update to authenticated
  using (exists (select 1 from public.admin_users a where a.user_id = (select auth.uid())))
  with check (exists (select 1 from public.admin_users a where a.user_id = (select auth.uid())));

drop policy if exists "Admin menghapus profil karyawan" on public.karyawan;
create policy "Admin menghapus profil karyawan"
  on public.karyawan for delete to authenticated
  using (exists (select 1 from public.admin_users a where a.user_id = (select auth.uid())));
