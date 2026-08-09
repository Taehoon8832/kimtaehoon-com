-- Supabase SQL Editor에서 실행
-- 담임(계정)별로 보드/앨범/상담 데이터를 분리 저장합니다.
-- RLS로 본인 user_id 행만 읽기/쓰기 가능합니다.

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

create or replace function public.touch_user_workspace_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists user_workspaces_set_updated_at on public.user_workspaces;
create trigger user_workspaces_set_updated_at
before update on public.user_workspaces
for each row
execute procedure public.touch_user_workspace_updated_at();
