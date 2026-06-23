-- Upgrade the existing hosted errands table.
-- Current live columns are:
-- id, user_id, title, reward, description, time_to_complete, status, created_at.
-- The Flutter app now reads/writes poster_id plus runner/offers/notifications data.

alter table public.errands
  add column if not exists user_id uuid references auth.users(id) on delete set null,
  add column if not exists poster_id uuid references auth.users(id) on delete set null,
  add column if not exists poster_name text,
  add column if not exists poster_phone text,
  add column if not exists is_seed boolean not null default false,
  add column if not exists runner_id uuid references auth.users(id) on delete set null,
  add column if not exists runner_name text,
  add column if not exists runner_phone text,
  add column if not exists accepted_at timestamptz;

alter table public.errands
  alter column user_id drop not null;

update public.errands
set poster_id = user_id
where poster_id is null
  and user_id is not null;

create or replace function public.sync_errand_owner_columns()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.poster_id is null and new.user_id is not null then
    new.poster_id := new.user_id;
  end if;

  if new.user_id is null and new.poster_id is not null then
    new.user_id := new.poster_id;
  end if;

  return new;
end;
$$;

drop trigger if exists sync_errand_owner_columns_trigger
on public.errands;
create trigger sync_errand_owner_columns_trigger
before insert or update on public.errands
for each row
execute function public.sync_errand_owner_columns();

create table if not exists public.errand_offers (
  id bigint generated always as identity primary key,
  errand_id bigint not null references public.errands(id) on delete cascade,
  runner_id uuid not null references auth.users(id) on delete cascade,
  runner_name text not null,
  runner_phone text,
  message text not null,
  proposed_reward numeric(10, 2) not null,
  estimated_time text not null,
  status text not null default 'Pending'
    check (status in ('Pending', 'Accepted', 'Rejected', 'Withdrawn')),
  created_at timestamptz not null default now(),
  unique (errand_id, runner_id)
);

alter table public.errand_offers
  add column if not exists runner_phone text;

create table if not exists public.notifications (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  errand_id bigint not null references public.errands(id) on delete cascade,
  title text not null,
  message text not null,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists errands_poster_id_idx
  on public.errands (poster_id);
create index if not exists errands_runner_id_idx
  on public.errands (runner_id);
create index if not exists errand_offers_errand_id_idx
  on public.errand_offers (errand_id);
create index if not exists errand_offers_runner_id_idx
  on public.errand_offers (runner_id);
create index if not exists notifications_user_id_created_at_idx
  on public.notifications (user_id, created_at desc);

alter table public.errands enable row level security;
alter table public.errand_offers enable row level security;
alter table public.notifications enable row level security;

drop policy if exists "Anyone can read errands"
on public.errands;
create policy "Anyone can read errands"
on public.errands
for select
to authenticated
using (true);

drop policy if exists "Users can create their own errands"
on public.errands;
create policy "Users can create their own errands"
on public.errands
for insert
to authenticated
with check (
  is_seed = false
  and poster_id = auth.uid()
);

drop policy if exists "Users can update their own errands"
on public.errands;
create policy "Users can update their own errands"
on public.errands
for update
to authenticated
using (poster_id = auth.uid())
with check (
  is_seed = false
  and poster_id = auth.uid()
);

drop policy if exists "Assigned runners can update assigned errands"
on public.errands;
create policy "Assigned runners can update assigned errands"
on public.errands
for update
to authenticated
using (runner_id = auth.uid())
with check (runner_id = auth.uid());

drop policy if exists "Users can delete their own errands"
on public.errands;
create policy "Users can delete their own errands"
on public.errands
for delete
to authenticated
using (
  is_seed = false
  and poster_id = auth.uid()
);

drop policy if exists "Errand participants can read offers"
on public.errand_offers;
create policy "Errand participants can read offers"
on public.errand_offers
for select
to authenticated
using (
  runner_id = auth.uid()
  or exists (
    select 1
    from public.errands
    where errands.id = errand_offers.errand_id
      and errands.poster_id = auth.uid()
  )
);

drop policy if exists "Runners can create their own offers"
on public.errand_offers;
create policy "Runners can create their own offers"
on public.errand_offers
for insert
to authenticated
with check (
  runner_id = auth.uid()
  and exists (
    select 1
    from public.errands
    where errands.id = errand_offers.errand_id
      and errands.status = 'Open'
      and errands.runner_id is null
      and errands.poster_id is distinct from auth.uid()
  )
);

drop policy if exists "Errand participants can update offers"
on public.errand_offers;
create policy "Errand participants can update offers"
on public.errand_offers
for update
to authenticated
using (
  runner_id = auth.uid()
  or exists (
    select 1
    from public.errands
    where errands.id = errand_offers.errand_id
      and errands.poster_id = auth.uid()
  )
)
with check (
  runner_id = auth.uid()
  or exists (
    select 1
    from public.errands
    where errands.id = errand_offers.errand_id
      and errands.poster_id = auth.uid()
  )
);

drop policy if exists "Users can read their own notifications"
on public.notifications;
create policy "Users can read their own notifications"
on public.notifications
for select
to authenticated
using (user_id = auth.uid());

drop policy if exists "Users can mark their own notifications read"
on public.notifications;
create policy "Users can mark their own notifications read"
on public.notifications
for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

drop policy if exists "Errand participants can create notifications"
on public.notifications;
create policy "Errand participants can create notifications"
on public.notifications
for insert
to authenticated
with check (
  exists (
    select 1
    from public.errands
    join public.errand_offers
      on errand_offers.errand_id = errands.id
    where errands.id = notifications.errand_id
      and errands.poster_id = notifications.user_id
      and errand_offers.runner_id = auth.uid()
  )
  or exists (
    select 1
    from public.errands
    join public.errand_offers
      on errand_offers.errand_id = errands.id
    where errands.id = notifications.errand_id
      and errands.poster_id = auth.uid()
      and errand_offers.runner_id = notifications.user_id
  )
);

notify pgrst, 'reload schema';
