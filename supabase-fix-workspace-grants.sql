-- Supabase SQL Editor에서 실행
-- user_workspaces 테이블 API 접근 권한 보정 + 스키마 캐시 갱신

grant usage on schema public to authenticated;
grant select, insert, update, delete on table public.user_workspaces to authenticated;

-- PostgREST(스키마 캐시) 새로고침
notify pgrst, 'reload schema';
