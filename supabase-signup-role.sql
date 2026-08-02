-- 회원가입 시 선택한 student/teacher 역할을 profiles에 반영
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  selected_role text;
begin
  selected_role := coalesce(new.raw_user_meta_data ->> 'role', 'student');
  if selected_role not in ('student', 'teacher') then
    selected_role := 'student';
  end if;

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
    selected_role
  );

  return new;
end;
$$;