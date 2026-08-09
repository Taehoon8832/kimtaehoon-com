-- Supabase SQL Editor에서 실행
-- 본 사이트 회원은 담임교사로 통일합니다.

-- 1) 기존 회원 역할을 모두 교사로
update public.profiles
set role = 'teacher'
where role is distinct from 'teacher';

-- 2) 앞으로 가입하는 회원의 기본 역할도 교사
alter table public.profiles alter column role set default 'teacher';

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
    coalesce(nullif(new.raw_user_meta_data ->> 'role', ''), 'teacher')
  )
  on conflict (id) do update
    set email = excluded.email,
        name = coalesce(excluded.name, public.profiles.name),
        school = coalesce(excluded.school, public.profiles.school),
        role = 'teacher';

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row
execute procedure public.handle_new_user();
