-- Tampilkan penanda generik untuk izin yang disetujui di kalender lintas perangkat.
-- Tidak menampilkan alasan atau membedakan izin, sakit, dan cuti.

drop function if exists public.kalender_izin_disetujui();

create function public.kalender_izin_disetujui()
returns table (
  kid text,
  nama_karyawan text,
  jenis text,
  dari date,
  sampai date
)
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
