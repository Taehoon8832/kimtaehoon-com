-- Supabase SQL Editor에서 전체 실행
-- 신규 가입자는 자동으로 role = member

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  name text,
  school text,
  role text not null default 'member'
    check (role in ('member', 'teacher', 'admin')),
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

drop policy if exists "회원은 자신의 프로필 조회" on public.profiles;
create policy "회원은 자신의 프로필 조회"
on public.profiles
for select
to authenticated
using ((select auth.uid()) = id);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (
    id,
    email,
    name,
    school,
    role
  )
  values (
    new.id,
    new.email,
    new.raw_user_meta_data ->> 'name',
    new.raw_user_meta_data ->> 'school',
    'member'
  );

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row
execute procedure public.handle_new_user();
