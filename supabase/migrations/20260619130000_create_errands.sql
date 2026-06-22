create table if not exists public.errands (
  id bigint generated always as identity primary key,
  title text not null,
  reward numeric(10, 2) not null,
  description text not null,
  time_to_complete text not null,
  status text not null default 'Open'
    check (status in ('Open', 'Completed', 'Closed')),
  created_at timestamptz not null default now(),
  user_id uuid references auth.users(id) on delete set null,
  poster_id uuid references auth.users(id) on delete set null,
  poster_name text,
  is_seed boolean not null default false
);

alter table public.errands enable row level security;

create policy "Anyone can read errands"
on public.errands
for select
to authenticated
using (true);

create policy "Users can create their own errands"
on public.errands
for insert
to authenticated
with check (
  is_seed = false
  and poster_id = auth.uid()
);

create policy "Users can update their own errands"
on public.errands
for update
to authenticated
using (poster_id = auth.uid())
with check (
  is_seed = false
  and poster_id = auth.uid()
);
