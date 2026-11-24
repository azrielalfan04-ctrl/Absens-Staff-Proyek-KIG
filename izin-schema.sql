-- Jalankan sekali di Supabase > SQL Editor > New query.
-- Akses publik hanya boleh membuat pengajuan berstatus menunggu.
-- Hanya akun yang dimasukkan ke admin_users yang dapat membaca/memproses semua pengajuan.

create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade
);

alter table public.admin_users enable row level security;
revoke all on public.admin_users from anon;
grant select on public.admin_users to authenticated;

drop policy if exists "Admin can see own admin marker" on public.admin_users;
create policy "Admin can see own admin marker"
  on public.admin_users for select to authenticated
  using (user_id = (select auth.uid()));

-- Rekap absensi bersama. Pengunjung hanya dapat menambah check-in;
-- admin terdaftar yang dapat membaca semua baris.
create table if not exists public.absensi (
  id text primary key,
  kid text not null,
  nama_karyawan text not null,
  jabatan text not null default '',
  tgl date not null,
  masuk timestamptz not null,
  pulang timestamptz,
  telat integer not null default 0 check (telat >= 0),
  lembur integer not null default 0 check (lembur >= 0),
  jadwal jsonb not null,
  lokasi jsonb,
  lokasi_pulang jsonb,
  sumber text not null default 'hp' check (sumber in ('hp', 'kiosk')),
  checkin_token uuid not null unique
);
alter table public.absensi enable row level security;
revoke all on public.absensi from anon, authenticated;
grant insert (id, kid, nama_karyawan, jabatan, tgl, masuk, telat, lembur, jadwal, lokasi, sumber, checkin_token) on public.absensi to anon, authenticated;
grant select on public.absensi to authenticated;
drop policy if exists "Publik mencatat check-in" on public.absensi;
create policy "Publik mencatat check-in" on public.absensi for insert to anon, authenticated
  with check (id is not null and kid is not null and nama_karyawan is not null and tgl is not null and masuk is not null and pulang is null and jadwal is not null and checkin_token is not null);
drop policy if exists "Admin membaca absensi" on public.absensi;
create policy "Admin membaca absensi" on public.absensi for select to authenticated
  using (exists (select 1 from public.admin_users a where a.user_id = (select auth.uid())));

create or replace function public.simpan_pulang_absen(p_token uuid, p_pulang timestamptz, p_lembur integer, p_lokasi_pulang jsonb)
returns boolean
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare jumlah integer;
begin
  update public.absensi
  set pulang = p_pulang, lembur = greatest(coalesce(p_lembur, 0), 0), lokasi_pulang = p_lokasi_pulang
  where checkin_token = p_token and pulang is null;
  get diagnostics jumlah = row_count;
  return jumlah = 1;
end
$$;
revoke all on function public.simpan_pulang_absen(uuid, timestamptz, integer, jsonb) from public;
grant execute on function public.simpan_pulang_absen(uuid, timestamptz, integer, jsonb) to anon, authenticated;

create table if not exists public.izin (
  id uuid primary key default gen_random_uuid(),
  kid text not null,
  nama_karyawan text not null,
  jenis text not null check (jenis in ('izin', 'sakit', 'cuti')),
  dari date not null,
  sampai date not null,
  alasan text not null check (char_length(alasan) between 3 and 200),
  status text not null default 'menunggu' check (status in ('menunggu', 'disetujui', 'ditolak')),
  t timestamptz not null default now(),
  diproses timestamptz,
  status_token uuid unique,
  created_by uuid references auth.users(id),
  constraint izin_tanggal_valid check (sampai >= dari)
);

-- Melengkapi tabel izin jika sebelumnya sudah dibuat lewat Table Editor.
alter table public.izin add column if not exists kid text;
alter table public.izin add column if not exists jenis text;
alter table public.izin add column if not exists dari date;
alter table public.izin add column if not exists sampai date;
alter table public.izin add column if not exists alasan text;
alter table public.izin add column if not exists status text default 'menunggu';
alter table public.izin add column if not exists t timestamptz default now();
alter table public.izin add column if not exists diproses timestamptz;
alter table public.izin add column if not exists status_token uuid;
create unique index if not exists izin_status_token_uidx on public.izin (status_token) where status_token is not null;
alter table public.izin add column if not exists nama_karyawan text;
alter table public.izin add column if not exists created_by uuid references auth.users(id);
alter table public.izin alter column status set default 'menunggu';
alter table public.izin alter column t set default now();

alter table public.izin enable row level security;
revoke all on public.izin from anon, authenticated;
grant insert (kid, nama_karyawan, jenis, dari, sampai, alasan, status_token) on public.izin to anon, authenticated;
grant select on public.izin to authenticated;
grant update (status, diproses) on public.izin to authenticated;

drop policy if exists "Publik hanya mengirim pengajuan menunggu" on public.izin;
create policy "Publik hanya mengirim pengajuan menunggu" on public.izin as permissive for insert to anon, authenticated with check (kid is not null and nama_karyawan is not null and jenis in ('izin', 'sakit', 'cuti') and dari is not null and sampai is not null and sampai >= dari and alasan is not null and char_length(alasan) between 3 and 200 and status = 'menunggu' and diproses is null and created_by is null and status_token is not null);

drop policy if exists "Admin membaca semua pengajuan" on public.izin;
create policy "Admin membaca semua pengajuan"
  on public.izin for select to authenticated
  using (exists (select 1 from public.admin_users a where a.user_id = (select auth.uid())));

drop policy if exists "Admin memproses pengajuan" on public.izin;
create policy "Admin memproses pengajuan" on public.izin as permissive for update to authenticated using (exists (select 1 from public.admin_users a where a.user_id = (select auth.uid()))) with check (exists (select 1 from public.admin_users a where a.user_id = (select auth.uid())));

-- Karyawan mengecek status satu pengajuan memakai token acak yang hanya tersimpan di browser pengaju.
create or replace function public.cek_status_izin(p_token uuid)
returns table (id uuid, kid text, nama_karyawan text, jenis text, dari date, sampai date, alasan text, status text, t timestamptz, diproses timestamptz)
language sql
security definer
set search_path = pg_catalog, public
as $$
  select i.id, i.kid, i.nama_karyawan, i.jenis, i.dari, i.sampai, i.alasan, i.status, i.t, i.diproses
  from public.izin i
  where i.status_token = p_token
  limit 1
$$;
revoke all on function public.cek_status_izin(uuid) from public;
grant execute on function public.cek_status_izin(uuid) to anon, authenticated;

-- Kalender hanya menampilkan penanda generik dan tanggal izin yang disetujui.
create or replace function public.kalender_izin_disetujui()
returns table (kid text, nama_karyawan text, jenis text, dari date, sampai date)
language sql
security definer
set search_path = pg_catalog, public
as $$
  select i.kid, i.nama_karyawan, 'izin'::text, i.dari, i.sampai
  from public.izin i
  where i.status = 'disetujui'
$$;
revoke all on function public.kalender_izin_disetujui() from public;
grant execute on function public.kalender_izin_disetujui() to anon, authenticated;

-- Daftarkan akun admin yang UUID-nya diberikan pengguna.
insert into public.admin_users (user_id)
values ('0ffce9eb-addd-4f68-bf5b-87509d5aaa0f')
on conflict (user_id) do nothing;
