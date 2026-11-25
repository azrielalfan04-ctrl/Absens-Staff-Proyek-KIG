-- Bagikan aturan lokasi kantor ke semua perangkat.
-- Lokasi kantor perlu dibaca aplikasi karyawan untuk memeriksa radius.

create table if not exists public.pengaturan_lokasi (
  id smallint primary key check (id = 1),
  lat double precision,
  lng double precision,
  radius integer not null default 100 check (radius between 20 and 5000),
  pakai boolean not null default false,
  wajib boolean not null default false,
  constraint lokasi_koordinat_valid check (
    (lat is null or lat between -90 and 90)
    and (lng is null or lng between -180 and 180)
  )
);

alter table public.pengaturan_lokasi enable row level security;
revoke all on public.pengaturan_lokasi from anon, authenticated;
grant select on public.pengaturan_lokasi to anon, authenticated;
grant insert, update on public.pengaturan_lokasi to authenticated;

drop policy if exists "Semua perangkat membaca aturan lokasi" on public.pengaturan_lokasi;
create policy "Semua perangkat membaca aturan lokasi"
  on public.pengaturan_lokasi for select to anon, authenticated
  using (true);

drop policy if exists "Admin mengatur lokasi kantor" on public.pengaturan_lokasi;
create policy "Admin mengatur lokasi kantor"
  on public.pengaturan_lokasi for insert to authenticated
  with check (exists (select 1 from public.admin_users a where a.user_id = (select auth.uid())));

drop policy if exists "Admin memperbarui lokasi kantor" on public.pengaturan_lokasi;
create policy "Admin memperbarui lokasi kantor"
  on public.pengaturan_lokasi for update to authenticated
  using (exists (select 1 from public.admin_users a where a.user_id = (select auth.uid())))
  with check (exists (select 1 from public.admin_users a where a.user_id = (select auth.uid())));
