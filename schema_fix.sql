-- Fix: drop existing policies and recreate all cleanly
-- Run this in Supabase SQL Editor

-- Drop existing policies that may conflict
drop policy if exists "Users can read own role" on public.user_roles;
drop policy if exists "Admins can read all roles" on public.user_roles;
drop policy if exists "All authenticated can read products" on public.products;
drop policy if exists "Admins can modify products" on public.products;
drop policy if exists "All authenticated can read stock" on public.stock;
drop policy if exists "All authenticated can update stock" on public.stock;
drop policy if exists "Admins can insert/delete stock" on public.stock;
drop policy if exists "Admins can manage purchases" on public.purchases;
drop policy if exists "All authenticated can insert jornadas" on public.jornadas;
drop policy if exists "All authenticated can read jornadas" on public.jornadas;
drop policy if exists "Admins can modify jornadas" on public.jornadas;
drop policy if exists "All authenticated can insert caja" on public.caja;
drop policy if exists "Admins can read/modify caja" on public.caja;
drop policy if exists "Admins can manage adjustments" on public.stock_adjustments;

-- Recreate all tables (if not exists - safe to run)
create table if not exists public.user_roles (
  id uuid references auth.users(id) on delete cascade primary key,
  role text not null default 'vendedor',
  name text,
  created_at timestamptz default now()
);
alter table public.user_roles enable row level security;

create table if not exists public.products (
  id serial primary key,
  tag text not null default 'General',
  title text not null,
  supplier text default '',
  cost text default '$0',
  sale1 text default '$0',
  sale1_label text default 'x1',
  sale2 text default '$0',
  sale2_label text default 'x2',
  qty_num integer default 0,
  qty_display text default '0 unidades',
  total_cost text default '$0',
  single boolean default false,
  img1 text default '',
  img2 text default '',
  imgs jsonb default '[]',
  obs text default '',
  date_bought date,
  active boolean default true,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
alter table public.products enable row level security;

create table if not exists public.stock (
  product_id integer references public.products(id) on delete cascade primary key,
  qty integer not null default 0,
  updated_at timestamptz default now()
);
alter table public.stock enable row level security;

create table if not exists public.purchases (
  id bigint generated always as identity primary key,
  product_id integer references public.products(id),
  product_title text,
  date date,
  qty integer,
  cost numeric,
  sale1 numeric,
  sale2 numeric,
  note text default '',
  pago text default 'efectivo',
  created_at timestamptz default now()
);
alter table public.purchases enable row level security;

create table if not exists public.jornadas (
  id text primary key,
  fecha date not null,
  vendedor text,
  obs_dia text default '',
  anulada boolean default false,
  cc_inicio numeric default 0,
  efec_real numeric default 0,
  cc_final numeric default 0,
  efec_esperado numeric default 0,
  diff numeric default 0,
  total_efec numeric default 0,
  total_transf numeric default 0,
  total_ventas numeric default 0,
  total_gastos numeric default 0,
  ganancia numeric default 0,
  ganancia_real numeric default 0,
  margen_ganancia numeric default 0,
  total_prendas integer default 0,
  total_vintage integer default 0,
  total_desc numeric default 0,
  comisiones numeric default 0,
  costo_transferencias numeric default 0,
  cmv numeric default 0,
  pct_efectivo numeric default 0,
  margen_promedio numeric default 0,
  conversion numeric default 0,
  clientes_hoy integer default 0,
  tickets integer default 0,
  ventas jsonb default '[]',
  gastos jsonb default '[]',
  edit_log jsonb default '[]',
  created_at timestamptz default now()
);
alter table public.jornadas enable row level security;

create table if not exists public.caja (
  id bigint generated always as identity primary key,
  jornada_id text references public.jornadas(id),
  fecha date,
  vendedor text,
  total_ventas numeric default 0,
  tot_efec numeric default 0,
  tot_transf numeric default 0,
  total_gastos numeric default 0,
  comisiones numeric default 0,
  costo_transferencias numeric default 0,
  cmv numeric default 0,
  total_desc numeric default 0,
  clientes_hoy integer default 0,
  tickets integer default 0,
  prendas integer default 0,
  pct_efectivo numeric default 0,
  margen_promedio numeric default 0,
  margen_ganancia numeric default 0,
  conversion numeric default 0,
  ganancia_real numeric default 0,
  diff numeric default 0,
  created_at timestamptz default now()
);
alter table public.caja enable row level security;

create table if not exists public.stock_adjustments (
  id bigint generated always as identity primary key,
  date date,
  time_str text,
  by_user text,
  items jsonb default '[]',
  total_faltantes integer default 0,
  valor_perdida numeric default 0,
  created_at timestamptz default now()
);
alter table public.stock_adjustments enable row level security;

-- Recreate all policies
create policy "Users can read own role" on public.user_roles
  for select using (auth.uid() = id);
create policy "Admins can read all roles" on public.user_roles
  for select using (
    exists (select 1 from public.user_roles where id = auth.uid() and role = 'admin')
  );

create policy "All authenticated can read products" on public.products
  for select using (auth.role() = 'authenticated');
create policy "Admins can modify products" on public.products
  for all using (
    exists (select 1 from public.user_roles where id = auth.uid() and role = 'admin')
  );

create policy "All authenticated can read stock" on public.stock
  for select using (auth.role() = 'authenticated');
create policy "Admins can modify stock" on public.stock
  for all using (
    exists (select 1 from public.user_roles where id = auth.uid() and role = 'admin')
  );
create policy "Vendedores can update stock" on public.stock
  for update using (auth.role() = 'authenticated');

create policy "Admins can manage purchases" on public.purchases
  for all using (
    exists (select 1 from public.user_roles where id = auth.uid() and role = 'admin')
  );

create policy "Authenticated can insert jornadas" on public.jornadas
  for insert with check (auth.role() = 'authenticated');
create policy "Authenticated can read jornadas" on public.jornadas
  for select using (auth.role() = 'authenticated');
create policy "Admins can modify jornadas" on public.jornadas
  for update using (
    exists (select 1 from public.user_roles where id = auth.uid() and role = 'admin')
  );

create policy "Authenticated can insert caja" on public.caja
  for insert with check (auth.role() = 'authenticated');
create policy "Admins can read/modify caja" on public.caja
  for all using (
    exists (select 1 from public.user_roles where id = auth.uid() and role = 'admin')
  );

create policy "Admins can manage adjustments" on public.stock_adjustments
  for all using (
    exists (select 1 from public.user_roles where id = auth.uid() and role = 'admin')
  );

-- Trigger updated_at
create or replace function public.handle_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists products_updated_at on public.products;
create trigger products_updated_at
  before update on public.products
  for each row execute procedure public.handle_updated_at();

-- Helper function to set admin role
create or replace function public.set_user_admin(user_id uuid)
returns void as $$
begin
  insert into public.user_roles(id, role)
  values (user_id, 'admin')
  on conflict (id) do update set role = 'admin';
end;
$$ language plpgsql security definer;

-- Helper: auto-create user_role on signup
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.user_roles (id, role, name)
  values (new.id, 'vendedor', new.email)
  on conflict (id) do nothing;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
