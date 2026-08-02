-- Supabase SQL Editor에서 실행
-- 역할: student(학생), teacher(교사)

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  name text,
  school text,
  role text not null default 'student'
    check (role in ('student', 'teacher')),
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

drop policy if exists "회원은 자신의 프로필 조회" on public.profiles;
drop policy if exists "본인 프로필 조회" on public.profiles;
create policy "본인 프로필 조회"
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
    'student'
  );

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row
execute procedure public.handle_new_user();

-- 이미 profiles가 있는 경우 역할 체계 마이그레이션
alter table public.profiles drop constraint if exists profiles_role_check;
update public.profiles set role = 'student' where role = 'member';
update public.profiles set role = 'teacher' where role = 'admin';
alter table public.profiles alter column role set default 'student';
alter table public.profiles
  add constraint profiles_role_check
  check (role in ('student', 'teacher'));