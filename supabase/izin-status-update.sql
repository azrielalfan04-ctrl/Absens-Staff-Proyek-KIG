-- Jalankan sekali setelah tabel public.izin sudah ada.
-- Ini memungkinkan pengaju mengecek status hanya untuk token acak yang tersimpan
-- di browser pengaju. Tidak memberi akses SELECT publik ke seluruh tabel izin.

alter table public.izin add column if not exists status_token uuid;
create unique index if not exists izin_status_token_uidx
  on public.izin (status_token) where status_token is not null;

revoke select on public.izin from anon;
grant insert (kid, nama_karyawan, jenis, dari, sampai, alasan, status_token) on public.izin to anon, authenticated;

drop policy if exists "Publik hanya mengirim pengajuan menunggu" on public.izin;
create policy "Publik hanya mengirim pengajuan menunggu"
  on public.izin as permissive for insert to anon, authenticated
  with check (
    kid is not null and nama_karyawan is not null
    and jenis in ('izin', 'sakit', 'cuti')
    and dari is not null and sampai is not null and sampai >= dari
    and alasan is not null and char_length(alasan) between 3 and 200
    and status = 'menunggu' and diproses is null and created_by is null
    and status_token is not null
  );

create or replace function public.cek_status_izin(p_token uuid)
returns table (
  id uuid, kid text, nama_karyawan text, jenis text,
  dari date, sampai date, alasan text, status text,
  t timestamptz, diproses timestamptz
)
language sql
security definer
set search_path = pg_catalog, public
as $$
  select i.id, i.kid, i.nama_karyawan, i.jenis, i.dari, i.sampai,
         i.alasan, i.status, i.t, i.diproses
  from public.izin i
  where i.status_token = p_token
  limit 1
$$;

revoke all on function public.cek_status_izin(uuid) from public;
grant execute on function public.cek_status_izin(uuid) to anon, authenticated;
