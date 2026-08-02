-- 1. 기존 role 제약조건 제거
alter table public.profiles
drop constraint if exists profiles_role_check;

-- 2. 기존 일반회원(member)을 학생(student)으로 변경
update public.profiles
set role = 'student'
where role = 'member';

-- 2-1. 기존 관리자(admin)는 교사(teacher)로 변경
update public.profiles
set role = 'teacher'
where role = 'admin';

-- 3. 신규 가입자의 기본 권한을 student로 변경
alter table public.profiles
alter column role set default 'student';

-- 4. student / teacher 두 권한만 허용
alter table public.profiles
add constraint profiles_role_check
check (role in ('student', 'teacher'));

-- 5. 신규 회원 생성 함수도 student로 변경
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