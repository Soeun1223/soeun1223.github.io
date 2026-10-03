-- 방명록 테이블: Supabase 대시보드 > SQL Editor 에 붙여넣고 Run (여러 번 실행해도 안전)
create table if not exists public.guestbook (
  id bigint generated always as identity primary key,
  name text not null check (char_length(btrim(name)) between 1 and 20),
  message text not null check (char_length(btrim(message)) between 1 and 300),
  created_at timestamptz not null default now()
);

-- "추천해 주세요": category 와 work 가 있으면 추천글, 둘 다 비어 있으면 일반 방명록
alter table public.guestbook add column if not exists category text;
alter table public.guestbook add column if not exists work text;

alter table public.guestbook drop constraint if exists guestbook_category_check;
alter table public.guestbook add constraint guestbook_category_check
  check (category in ('드라마', '애니메이션', '영화', '음악'));

alter table public.guestbook drop constraint if exists guestbook_work_check;
alter table public.guestbook add constraint guestbook_work_check
  check (char_length(btrim(work)) between 1 and 60);

alter table public.guestbook drop constraint if exists guestbook_recommend_pair_check;
alter table public.guestbook add constraint guestbook_recommend_pair_check
  check ((category is null) = (work is null));

alter table public.guestbook enable row level security;

-- 방문자(anon)는 읽기와 글쓰기만 가능. 수정/삭제는 대시보드에서 주인만.
revoke all on public.guestbook from anon, authenticated;
grant select on public.guestbook to anon, authenticated;
grant insert (name, message, category, work) on public.guestbook to anon, authenticated;

drop policy if exists "guestbook_read" on public.guestbook;
create policy "guestbook_read" on public.guestbook
  for select to anon, authenticated using (true);

drop policy if exists "guestbook_write" on public.guestbook;
create policy "guestbook_write" on public.guestbook
  for insert to anon, authenticated with check (true);
