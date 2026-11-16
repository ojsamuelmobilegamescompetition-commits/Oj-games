
-- OJ SAMUEL INTERNATIONAL MOBILE GAMES COMPETITION
-- Run in Supabase SQL Editor. Review policies before production deployment.
create extension if not exists pgcrypto;
create type public.staff_role as enum ('super_admin','platform_admin','tournament_director','competition_manager','moderator','results_officer','finance_officer','support_officer');
create table if not exists public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 username text unique not null,
 country text default 'Nigeria',
 primary_game text,
 avatar_url text,
 status text not null default 'pending' check(status in ('pending','approved','suspended','rejected')),
 created_at timestamptz not null default now()
);
create table if not exists public.staff_roles (
 user_id uuid primary key references auth.users(id) on delete cascade,
 role public.staff_role not null,
 active boolean not null default true,
 created_at timestamptz not null default now()
);
create or replace function public.has_role(allowed public.staff_role[])
returns boolean language sql stable security definer set search_path=public as $$
 select exists(select 1 from public.staff_roles where user_id=auth.uid() and active and role=any(allowed));
$$;
create table if not exists public.tournaments (
 id uuid primary key default gen_random_uuid(), name text not null, game text not null,
 description text, status text not null default 'upcoming',
 starts_at timestamptz, registration_deadline timestamptz, prize_pool text,
 image_url text, rules text, created_by uuid references auth.users(id), created_at timestamptz default now()
);
create table if not exists public.tournament_entries (
 id uuid primary key default gen_random_uuid(), tournament_id uuid references public.tournaments(id) on delete cascade,
 player_id uuid references public.profiles(id) on delete cascade, status text not null default 'pending',
 created_at timestamptz default now(), unique(tournament_id,player_id)
);
create table if not exists public.matches (
 id uuid primary key default gen_random_uuid(), tournament_id uuid references public.tournaments(id) on delete cascade,
 round_name text, player_a uuid references public.profiles(id), player_b uuid references public.profiles(id),
 scheduled_at timestamptz, status text not null default 'scheduled', score_a integer, score_b integer,
 winner_id uuid references public.profiles(id), result_verified boolean not null default false,
 created_at timestamptz default now()
);
create table if not exists public.match_reports (
 id uuid primary key default gen_random_uuid(), match_id uuid references public.matches(id) on delete cascade,
 submitted_by uuid references public.profiles(id), score_a integer, score_b integer, evidence_url text,
 status text not null default 'pending', reviewed_by uuid references auth.users(id), created_at timestamptz default now()
);
create table if not exists public.news (
 id uuid primary key default gen_random_uuid(), title text not null, body text not null, image_url text,
 published boolean default false, published_at timestamptz, created_by uuid references auth.users(id)
);
create table if not exists public.sponsors (
 id uuid primary key default gen_random_uuid(), name text not null, logo_url text, website_url text,
 active boolean default true, permission_confirmed boolean default false, starts_at timestamptz, ends_at timestamptz
);
create table if not exists public.advertisements (
 id uuid primary key default gen_random_uuid(), brand text, title text not null, description text,
 image_url text, target_url text, active boolean default false, starts_at timestamptz, ends_at timestamptz
);
create table if not exists public.products (
 id uuid primary key default gen_random_uuid(), name text not null, brand text, price numeric,
 promo_price numeric, image_url text, external_url text, active boolean default true
);
create table if not exists public.rewards (
 id uuid primary key default gen_random_uuid(), title text not null, description text,
 tournament_id uuid references public.tournaments(id), eligibility text, status text default 'announced'
);
create table if not exists public.reward_claims (
 id uuid primary key default gen_random_uuid(), reward_id uuid references public.rewards(id),
 player_id uuid references public.profiles(id), status text default 'pending', created_at timestamptz default now()
);
create table if not exists public.notifications (
 id uuid primary key default gen_random_uuid(), user_id uuid references auth.users(id),
 title text not null, body text, read_at timestamptz, created_at timestamptz default now()
);
create table if not exists public.support_tickets (
 id uuid primary key default gen_random_uuid(), user_id uuid references auth.users(id),
 subject text not null, message text not null, status text default 'open', assigned_to uuid references auth.users(id), created_at timestamptz default now()
);
create table if not exists public.payments (
 id uuid primary key default gen_random_uuid(), user_id uuid references auth.users(id),
 tournament_id uuid references public.tournaments(id), amount numeric not null, currency text default 'NGN',
 provider_reference text unique, status text default 'pending', created_at timestamptz default now()
);
create table if not exists public.audit_logs (
 id uuid primary key default gen_random_uuid(), actor_id uuid references auth.users(id),
 action text not null, target_table text, target_id text, details jsonb default '{}'::jsonb, created_at timestamptz default now()
);
create table if not exists public.site_settings (
 key text primary key, value jsonb not null default '{}'::jsonb, updated_at timestamptz default now()
);

alter table public.profiles enable row level security;
alter table public.staff_roles enable row level security;
alter table public.tournaments enable row level security;
alter table public.tournament_entries enable row level security;
alter table public.matches enable row level security;
alter table public.match_reports enable row level security;
alter table public.news enable row level security;
alter table public.sponsors enable row level security;
alter table public.advertisements enable row level security;
alter table public.products enable row level security;
alter table public.rewards enable row level security;
alter table public.reward_claims enable row level security;
alter table public.notifications enable row level security;
alter table public.support_tickets enable row level security;
alter table public.payments enable row level security;
alter table public.audit_logs enable row level security;
alter table public.site_settings enable row level security;

-- Public read policies expose only public-facing records.
create policy "public reads approved tournaments" on public.tournaments for select using(status in ('upcoming','registration_open','live','completed'));
create policy "public reads published news" on public.news for select using(published=true);
create policy "public reads active sponsors" on public.sponsors for select using(active=true and permission_confirmed=true);
create policy "public reads active ads" on public.advertisements for select using(active=true and (starts_at is null or starts_at<=now()) and (ends_at is null or ends_at>now()));
create policy "public reads active products" on public.products for select using(active=true);
create policy "public reads rewards" on public.rewards for select using(status='announced');
create policy "public reads verified matches" on public.matches for select using(result_verified=true or status in ('scheduled','live'));

-- Player-owned data.
create policy "players read own profile" on public.profiles for select using(id=auth.uid() or public.has_role(array['super_admin','platform_admin','moderator']::public.staff_role[]));
create policy "players update own profile" on public.profiles for update using(id=auth.uid()) with check(id=auth.uid());
create policy "players read own entries" on public.tournament_entries for select using(player_id=auth.uid() or public.has_role(array['super_admin','platform_admin','tournament_director','moderator']::public.staff_role[]));
create policy "players create own entries" on public.tournament_entries for insert with check(player_id=auth.uid());
create policy "players read own notifications" on public.notifications for select using(user_id=auth.uid());
create policy "players update own notifications" on public.notifications for update using(user_id=auth.uid()) with check(user_id=auth.uid());
create policy "players read own reward claims" on public.reward_claims for select using(player_id=auth.uid());
create policy "players submit own reward claims" on public.reward_claims for insert with check(player_id=auth.uid());
create policy "players read own support tickets" on public.support_tickets for select using(user_id=auth.uid() or public.has_role(array['super_admin','platform_admin','support_officer']::public.staff_role[]));
create policy "players create support tickets" on public.support_tickets for insert with check(user_id=auth.uid());

-- Role-gated management. Role checks are enforced in the database, not just UI.
create policy "staff manage tournaments" on public.tournaments for all using(public.has_role(array['super_admin','platform_admin','tournament_director']::public.staff_role[])) with check(public.has_role(array['super_admin','platform_admin','tournament_director']::public.staff_role[]));
create policy "staff manage matches" on public.matches for all using(public.has_role(array['super_admin','platform_admin','tournament_director','competition_manager','results_officer']::public.staff_role[])) with check(public.has_role(array['super_admin','platform_admin','tournament_director','competition_manager','results_officer']::public.staff_role[]));
create policy "staff manage match reports" on public.match_reports for all using(public.has_role(array['super_admin','platform_admin','competition_manager','results_officer']::public.staff_role[])) with check(public.has_role(array['super_admin','platform_admin','competition_manager','results_officer']::public.staff_role[]));
create policy "staff manage news" on public.news for all using(public.has_role(array['super_admin','platform_admin','moderator']::public.staff_role[])) with check(public.has_role(array['super_admin','platform_admin','moderator']::public.staff_role[]));
create policy "staff manage sponsors" on public.sponsors for all using(public.has_role(array['super_admin','platform_admin']::public.staff_role[])) with check(public.has_role(array['super_admin','platform_admin']::public.staff_role[]));
create policy "staff manage ads" on public.advertisements for all using(public.has_role(array['super_admin','platform_admin']::public.staff_role[])) with check(public.has_role(array['super_admin','platform_admin']::public.staff_role[]));
create policy "staff manage products" on public.products for all using(public.has_role(array['super_admin','platform_admin']::public.staff_role[])) with check(public.has_role(array['super_admin','platform_admin']::public.staff_role[]));
create policy "staff manage rewards" on public.rewards for all using(public.has_role(array['super_admin','platform_admin','tournament_director']::public.staff_role[])) with check(public.has_role(array['super_admin','platform_admin','tournament_director']::public.staff_role[]));
create policy "finance staff read payments" on public.payments for select using(public.has_role(array['super_admin','platform_admin','finance_officer']::public.staff_role[]));
create policy "super admin manage staff" on public.staff_roles for all using(public.has_role(array['super_admin']::public.staff_role[])) with check(public.has_role(array['super_admin']::public.staff_role[]));
create policy "super admin manage settings" on public.site_settings for all using(public.has_role(array['super_admin']::public.staff_role[])) with check(public.has_role(array['super_admin']::public.staff_role[]));
create policy "super admin read audit logs" on public.audit_logs for select using(public.has_role(array['super_admin','platform_admin']::public.staff_role[]));
create policy "staff manage support" on public.support_tickets for update using(public.has_role(array['super_admin','platform_admin','support_officer']::public.staff_role[])) with check(public.has_role(array['super_admin','platform_admin','support_officer']::public.staff_role[]));

-- Auth signup profile trigger.
create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path=public as $$
begin
 insert into public.profiles(id,username,country,primary_game)
 values(new.id,coalesce(new.raw_user_meta_data->>'username',split_part(new.email,'@',1)),coalesce(new.raw_user_meta_data->>'country','Nigeria'),new.raw_user_meta_data->>'game')
 on conflict(id) do nothing;
 return new;
end; $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();

-- NOTE: Seed the first super_admin role only through the Supabase SQL editor after
-- confirming the target auth.users UUID. Never expose service-role credentials in GitHub.
