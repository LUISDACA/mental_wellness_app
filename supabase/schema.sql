create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text unique,
  full_name text,
  created_at timestamptz not null default now()
);

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, email, full_name)
  values (new.id, new.email, split_part(new.email, '@', 1))
  on conflict (id) do nothing;
  return new;
end; $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

create table if not exists public.emotion_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  text_input text,
  detected_emotion text not null,
  score numeric check (score >= 0 and score <= 1),
  severity int check (severity between 0 and 100),
  model text,
  advice text,
  created_at timestamptz not null default now()
);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  role text check (role in ('user','assistant')) not null,
  content text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.sos_contacts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  label text not null,
  phone text,
  email text,
  created_at timestamptz not null default now()
);

create table if not exists public.recommendations (
  id uuid primary key default gen_random_uuid(),
  emotion text not null,
  title text not null,
  kind text not null,
  payload jsonb,
  active boolean not null default true
);

alter table public.profiles enable row level security;
alter table public.emotion_entries enable row level security;
alter table public.messages enable row level security;
alter table public.sos_contacts enable row level security;
alter table public.recommendations enable row level security;

create policy "profiles_self" on public.profiles for select using (auth.uid() = id);
create policy "profiles_self_update" on public.profiles for update using (auth.uid() = id);

create policy "emotion_entries_owner" on public.emotion_entries for select using (auth.uid() = user_id);
create policy "emotion_entries_insert" on public.emotion_entries for insert with check (auth.uid() = user_id);

create policy "messages_owner" on public.messages for select using (auth.uid() = user_id);
create policy "messages_insert" on public.messages for insert with check (auth.uid() = user_id);

create policy "sos_owner" on public.sos_contacts for select using (auth.uid() = user_id);
create policy "sos_insert" on public.sos_contacts for insert with check (auth.uid() = user_id);
create policy "sos_update" on public.sos_contacts for update using (auth.uid() = user_id);
create policy "sos_delete" on public.sos_contacts for delete using (auth.uid() = user_id);

create policy "recs_public_read" on public.recommendations for select using (true);
