-- 방문자 수: Supabase 대시보드 > SQL Editor 에 붙여넣고 Run (여러 번 실행해도 안전)
-- 날짜(한국 시간)별 방문 수를 저장한다. TODAY = 오늘 칸, TOTAL = 전체 합계.
create table if not exists public.visits (
  day date primary key,
  count integer not null default 0
);

-- 방문자는 표를 직접 읽거나 고칠 수 없고, 아래 두 함수만 쓸 수 있다.
alter table public.visits enable row level security;
revoke all on public.visits from anon, authenticated;

-- 방문 1회 기록 후 오늘/전체 방문 수를 돌려준다
create or replace function public.record_visit()
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  today date := (now() at time zone 'Asia/Seoul')::date;
begin
  insert into public.visits (day, count) values (today, 1)
  on conflict (day) do update set count = public.visits.count + 1;

  return json_build_object(
    'today', (select count from public.visits where day = today),
    'total', (select coalesce(sum(count), 0) from public.visits)
  );
end;
$$;

-- 기록하지 않고 오늘/전체 방문 수만 돌려준다
create or replace function public.get_visits()
returns json
language sql
stable
security definer
set search_path = public
as $$
  select json_build_object(
    'today', coalesce((select count from public.visits where day = (now() at time zone 'Asia/Seoul')::date), 0),
    'total', coalesce((select sum(count) from public.visits), 0)
  );
$$;

revoke execute on function public.record_visit() from public;
revoke execute on function public.get_visits() from public;
grant execute on function public.record_visit() to anon, authenticated;
grant execute on function public.get_visits() to anon, authenticated;
