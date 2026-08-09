-- =========================================================
-- user_workspaces 권한 오류 해결 SQL
-- Supabase > SQL Editor > + New 에 붙여넣고 Run
-- =========================================================

-- 1) 테이블이 없으면 생성
create table if not exists public.user_workspaces (
  user_id uuid primary key references auth.users(id) on delete cascade,
  board jsonb not null default '{}'::jsonb,
  album jsonb not null default '{"years":{}}'::jsonb,
  counsel jsonb not null default '{"years":{}}'::jsonb,
  updated_at timestamptz not null default now()
);

-- 2) RLS 켜기
alter table public.user_workspaces enable row level security;

-- 3) 정책 재설정 (본인 데이터만)
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

-- 4) ★ 핵심: API(authenticated)에 테이블 사용 권한 부여
grant usage on schema public to anon, authenticated;
grant select, insert, update, delete on table public.user_workspaces to authenticated;
grant all on table public.user_workspaces to service_role;

-- 5) API 스키마 캐시 새로고침
notify pgrst, 'reload schema';
