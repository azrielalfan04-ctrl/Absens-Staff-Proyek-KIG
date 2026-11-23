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
alter table public.izin add column if not exists nama_karyawan text;
alter table public.izin add column if not exists created_by uuid references auth.users(id);
alter table public.izin alter column status set default 'menunggu';
alter table public.izin alter column t set default now();

alter table public.izin enable row level security;
revoke all on public.izin from anon, authenticated;
grant insert (kid, nama_karyawan, jenis, dari, sampai, alasan) on public.izin to anon, authenticated;
grant select on public.izin to authenticated;
grant update (status, diproses) on public.izin to authenticated;

drop policy if exists "Publik hanya mengirim pengajuan menunggu" on public.izin;
create policy "Publik hanya mengirim pengajuan menunggu" on public.izin as permissive for insert to anon, authenticated with check (kid is not null and nama_karyawan is not null and jenis in ('izin', 'sakit', 'cuti') and dari is not null and sampai is not null and sampai >= dari and alasan is not null and char_length(alasan) between 3 and 200 and status = 'menunggu' and diproses is null and created_by is null);

drop policy if exists "Admin membaca semua pengajuan" on public.izin;
create policy "Admin membaca semua pengajuan"
  on public.izin for select to authenticated
  using (exists (select 1 from public.admin_users a where a.user_id = (select auth.uid())));

drop policy if exists "Admin memproses pengajuan" on public.izin;
create policy "Admin memproses pengajuan" on public.izin as permissive for update to authenticated using (exists (select 1 from public.admin_users a where a.user_id = (select auth.uid()))) with check (exists (select 1 from public.admin_users a where a.user_id = (select auth.uid())));

-- Daftarkan akun admin yang UUID-nya diberikan pengguna.
insert into public.admin_users (user_id)
values ('0ffce9eb-addd-4f68-bf5b-87509d5aaa0f')
on conflict (user_id) do nothing;
