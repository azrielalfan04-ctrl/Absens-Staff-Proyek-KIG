-- Jalankan sekali untuk menyinkronkan check-in/check-out ke Supabase.
-- Karyawan dapat menambah check-in dan mengirim check-out dengan token rahasia.
-- Hanya admin yang terdaftar dapat membaca seluruh tabel absensi.

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

alter table public.absensi add column if not exists nama_karyawan text;
alter table public.absensi add column if not exists jabatan text default '';
alter table public.absensi enable row level security;
revoke all on public.absensi from anon, authenticated;
grant insert (id, kid, nama_karyawan, jabatan, tgl, masuk, telat, lembur, jadwal, lokasi, sumber, checkin_token) on public.absensi to anon, authenticated;
grant select on public.absensi to authenticated;

drop policy if exists "Publik mencatat check-in" on public.absensi;
create policy "Publik mencatat check-in" on public.absensi for insert to anon, authenticated
  with check (
    id is not null and kid is not null and nama_karyawan is not null and tgl is not null
    and masuk is not null and pulang is null and jadwal is not null
    and checkin_token is not null
  );

drop policy if exists "Admin membaca absensi" on public.absensi;
create policy "Admin membaca absensi" on public.absensi for select to authenticated
  using (exists (select 1 from public.admin_users a where a.user_id = (select auth.uid())));

create or replace function public.simpan_pulang_absen(
  p_token uuid, p_pulang timestamptz, p_lembur integer, p_lokasi_pulang jsonb
)
returns boolean
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare jumlah integer;
begin
  update public.absensi
  set pulang = p_pulang,
      lembur = greatest(coalesce(p_lembur, 0), 0),
      lokasi_pulang = p_lokasi_pulang
  where checkin_token = p_token and pulang is null;
  get diagnostics jumlah = row_count;
  return jumlah = 1;
end
$$;

revoke all on function public.simpan_pulang_absen(uuid, timestamptz, integer, jsonb) from public;
grant execute on function public.simpan_pulang_absen(uuid, timestamptz, integer, jsonb) to anon, authenticated;
