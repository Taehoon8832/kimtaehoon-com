-- =========================================================
-- 클라우드 불러오기/저장 권한 오류 해결 (지금 바로 실행)
-- Supabase 대시보드 > SQL Editor > New query 에 전체 붙여넣고 Run
-- =========================================================
-- 원인: user_workspaces 테이블은 있어도 authenticated 역할에
--       SELECT/INSERT/UPDATE GRANT가 없으면 API가 거부합니다.
-- =========================================================

create table if not exists public.user_workspaces (
  user_id uuid primary key references auth.users(id) on delete cascade,
  board jsonb not null default '{}'::jsonb,
  album jsonb not null default '{"years":{}}'::jsonb,
  counsel jsonb not null default '{"years":{}}'::jsonb,
  updated_at timestamptz not null default now()
);

alter table public.user_workspaces enable row level security;

drop policy if exists "본인 워크스페이스 조회" on public.user_workspaces;
create policy "본인 워크스페이스 조회"
on public.user_workspaces
for select
to authenticated
using ((select auth.uid()) = user_id);

drop policy if exists "본인 워크스페이스 삽입" on public.user_workspaces;
create policy "본인 워크스페이스 삽입"
on public.user_workspaces
for insert
to authenticated
with check ((select auth.uid()) = user_id);

drop policy if exists "본인 워크스페이스 수정" on public.user_workspaces;
create policy "본인 워크스페이스 수정"
on public.user_workspaces
for update
to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

drop policy if exists "본인 워크스페이스 삭제" on public.user_workspaces;
create policy "본인 워크스페이스 삭제"
on public.user_workspaces
for delete
to authenticated
using ((select auth.uid()) = user_id);

-- ★ 핵심: 로그인 API 역할에 테이블 권한 부여
grant usage on schema public to anon, authenticated;
revoke all on table public.user_workspaces from public;
grant select, insert, update, delete on table public.user_workspaces to authenticated;
grant all on table public.user_workspaces to service_role;

-- PostgREST 스키마 캐시 새로고침
notify pgrst, 'reload schema';

-- 확인용 (선택): 권한이 authenticated에 보이면 정상
-- select grantee, privilege_type
-- from information_schema.role_table_grants
-- where table_schema = 'public' and table_name = 'user_workspaces'
-- order by grantee, privilege_type;
