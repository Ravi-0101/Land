-- ClayEstates database schema for PostgreSQL / Supabase
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null,
  email text not null unique,
  phone text,
  whatsapp text,
  address text,
  city text,
  state text,
  postal_code text,
  preferred_contact text default 'Phone',
  bio text,
  languages text[] not null default '{}',
  avatar text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.listings (
  id text primary key,
  seller_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  location text not null,
  price numeric(14, 2) not null default 0 check (price >= 0),
  size text,
  type text not null check (type in ('Residential', 'Commercial', 'Agricultural', 'Industrial', 'Plot')),
  description text,
  status text not null default 'active' check (status in ('active', 'sold', 'archived')),
  plot_count integer not null default 0 check (plot_count >= 0),
  plot_details jsonb,
  contact jsonb not null default '{}'::jsonb,
  is_featured boolean not null default false,
  rating numeric(2, 1) not null default 0 check (rating between 0 and 5),
  review_count integer not null default 0 check (review_count >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.listing_features (
  listing_id text not null references public.listings(id) on delete cascade,
  feature text not null,
  primary key (listing_id, feature)
);

create table if not exists public.listing_images (
  listing_id text not null references public.listings(id) on delete cascade,
  url text not null,
  sort_order integer not null default 0,
  primary key (listing_id, sort_order)
);

create table if not exists public.favorites (
  user_id uuid not null references public.profiles(id) on delete cascade,
  listing_id text not null references public.listings(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, listing_id)
);

create table if not exists public.inquiries (
  id uuid primary key default gen_random_uuid(),
  listing_id text not null references public.listings(id) on delete cascade,
  buyer_id uuid not null references public.profiles(id) on delete cascade,
  message text not null,
  status text not null default 'new' check (status in ('new', 'read', 'closed')),
  created_at timestamptz not null default now()
);

create index if not exists listings_status_created_idx on public.listings(status, created_at desc);
create index if not exists listings_seller_idx on public.listings(seller_id);
create index if not exists inquiries_listing_idx on public.inquiries(listing_id, created_at desc);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at before update on public.profiles
for each row execute function public.set_updated_at();

drop trigger if exists listings_set_updated_at on public.listings;
create trigger listings_set_updated_at before update on public.listings
for each row execute function public.set_updated_at();

alter table public.profiles enable row level security;
alter table public.listings enable row level security;
alter table public.listing_features enable row level security;
alter table public.listing_images enable row level security;
alter table public.favorites enable row level security;
alter table public.inquiries enable row level security;

drop policy if exists "Anyone can view active listings" on public.listings;
create policy "Anyone can view active listings" on public.listings for select using (status = 'active');
drop policy if exists "Owners can manage listings" on public.listings;
create policy "Owners can manage listings" on public.listings for all to authenticated
using (seller_id = auth.uid()) with check (seller_id = auth.uid());

drop policy if exists "Anyone can view listing features" on public.listing_features;
create policy "Anyone can view listing features" on public.listing_features for select using (true);
drop policy if exists "Owners can manage listing features" on public.listing_features;
create policy "Owners can manage listing features" on public.listing_features for all to authenticated
using (exists (select 1 from public.listings where id = listing_id and seller_id = auth.uid()))
with check (exists (select 1 from public.listings where id = listing_id and seller_id = auth.uid()));

drop policy if exists "Anyone can view listing images" on public.listing_images;
create policy "Anyone can view listing images" on public.listing_images for select using (true);
drop policy if exists "Owners can manage listing images" on public.listing_images;
create policy "Owners can manage listing images" on public.listing_images for all to authenticated
using (exists (select 1 from public.listings where id = listing_id and seller_id = auth.uid()))
with check (exists (select 1 from public.listings where id = listing_id and seller_id = auth.uid()));

drop policy if exists "Users can manage their favorites" on public.favorites;
create policy "Users can manage their favorites" on public.favorites for all to authenticated
using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "Users can view their profile" on public.profiles;
create policy "Users can view their profile" on public.profiles for select to authenticated using (id = auth.uid());
drop policy if exists "Users can update their profile" on public.profiles;
create policy "Users can update their profile" on public.profiles for update to authenticated
using (id = auth.uid()) with check (id = auth.uid());

drop policy if exists "Buyers can create inquiries" on public.inquiries;
create policy "Buyers can create inquiries" on public.inquiries for insert to authenticated
with check (buyer_id = auth.uid());
drop policy if exists "Participants can view inquiries" on public.inquiries;
create policy "Participants can view inquiries" on public.inquiries for select to authenticated
using (buyer_id = auth.uid() or exists (select 1 from public.listings where id = listing_id and seller_id = auth.uid()));
