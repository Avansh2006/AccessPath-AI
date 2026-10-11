create extension if not exists pgcrypto;

create table public.places (
  id text primary key,
  name text not null check (length(name) between 2 and 160),
  category text not null,
  address text not null default '',
  phone text,
  website text,
  directions_url text,
  description text not null default '',
  latitude double precision not null check (latitude between -90 and 90),
  longitude double precision not null check (longitude between -180 and 180),
  accessibility_features jsonb not null default '[]'::jsonb,
  image_urls jsonb not null default '[]'::jsonb,
  photos jsonb not null default '[]'::jsonb,
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create type public.rating_status as enum ('rated', 'unknown', 'notApplicable');

create table public.reviews (
  id text primary key,
  place_id text not null references public.places(id) on delete cascade,
  created_by uuid not null references auth.users(id),
  user_name text not null default 'Community member',
  comment text not null check (length(comment) between 12 and 4000),
  overall_rating double precision not null check (overall_rating between 0 and 10),
  reviewer_context jsonb not null default '{}'::jsonb,
  step_free_status public.rating_status not null default 'unknown',
  step_free_rating double precision check (step_free_rating between 0 and 5),
  lifts_status public.rating_status not null default 'unknown',
  lifts_rating double precision check (lifts_rating between 0 and 5),
  accessible_washrooms_status public.rating_status not null default 'unknown',
  accessible_washrooms_rating double precision check (accessible_washrooms_rating between 0 and 5),
  seating_status public.rating_status not null default 'unknown',
  seating_rating double precision check (seating_rating between 0 and 5),
  wayfinding_status public.rating_status not null default 'unknown',
  wayfinding_rating double precision check (wayfinding_rating between 0 and 5),
  helpful_votes integer not null default 0 check (helpful_votes >= 0),
  reported boolean not null default false,
  created_at timestamptz not null default now(),
  constraint rated_values_present check (
    (step_free_status <> 'rated' or step_free_rating is not null) and
    (lifts_status <> 'rated' or lifts_rating is not null) and
    (accessible_washrooms_status <> 'rated' or accessible_washrooms_rating is not null) and
    (seating_status <> 'rated' or seating_rating is not null) and
    (wayfinding_status <> 'rated' or wayfinding_rating is not null)
  )
);

create index places_location_idx on public.places(latitude, longitude);
create index reviews_place_created_idx on public.reviews(place_id, created_at desc);

alter table public.places enable row level security;
alter table public.reviews enable row level security;

create policy "places readable by everyone" on public.places for select using (true);
create policy "authenticated users create places" on public.places for insert
  to authenticated with check (auth.uid() = created_by);
create policy "owners update places" on public.places for update
  to authenticated using (auth.uid() = created_by) with check (auth.uid() = created_by);
create policy "reviews readable by everyone" on public.reviews for select using (not reported);
create policy "authenticated users create reviews" on public.reviews for insert
  to authenticated with check (auth.uid() = created_by);
create policy "authors update reviews" on public.reviews for update
  to authenticated using (auth.uid() = created_by) with check (auth.uid() = created_by);

grant select on public.places, public.reviews to anon, authenticated;
grant insert, update on public.places, public.reviews to authenticated;
