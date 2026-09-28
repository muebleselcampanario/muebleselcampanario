-- Muebles El Campanario - migración V4
-- Ejecutar UNA VEZ en Supabase > SQL Editor.
-- No contiene claves secretas.

-- 1) Clasificación por línea y subcategoría
alter table public.products add column if not exists line text;
alter table public.products add column if not exists subcategory text;
alter table public.products add column if not exists finish_personalizable boolean not null default false;

update public.products
set line = coalesce(nullif(line,''), 'rustica')
where line is null or line='';

update public.products
set subcategory = coalesce(nullif(subcategory,''), nullif(category,''), 'Decoración')
where subcategory is null or subcategory='';

alter table public.products alter column line set default 'rustica';
alter table public.products alter column subcategory set default 'Decoración';

-- 2) Contactos del formulario público
create table if not exists public.contact_leads (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  email text not null,
  phone text not null,
  interest text,
  message text,
  privacy_consent boolean not null default false,
  privacy_consent_at timestamptz,
  marketing_consent boolean not null default false,
  marketing_consent_at timestamptz,
  privacy_policy_version text not null default '2026-09-11',
  consent_source text not null default 'website_form',
  status text not null default 'nuevo',
  created_at timestamptz not null default now()
);

alter table public.contact_leads enable row level security;

-- El visitante solo puede crear un registro con autorización de tratamiento.
drop policy if exists "Public can insert leads with privacy consent" on public.contact_leads;
create policy "Public can insert leads with privacy consent"
on public.contact_leads
for insert
to anon, authenticated
with check (
  privacy_consent = true
  and status = 'nuevo'
  and privacy_policy_version is not null
  and consent_source = 'website_form'
);

-- Solo administradores pueden consultar/modificar los contactos.
drop policy if exists "Admins can read leads" on public.contact_leads;
create policy "Admins can read leads"
on public.contact_leads
for select
to authenticated
using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'));

drop policy if exists "Admins can update leads" on public.contact_leads;
create policy "Admins can update leads"
on public.contact_leads
for update
to authenticated
using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'))
with check (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'));

drop policy if exists "Admins can delete leads" on public.contact_leads;
create policy "Admins can delete leads"
on public.contact_leads
for delete
to authenticated
using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'));

-- El servidor fija las marcas de tiempo de consentimiento y el estado inicial.
create or replace function public.set_lead_consent_metadata()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.privacy_consent is distinct from true then
    raise exception 'Se requiere autorización para el tratamiento de datos personales.';
  end if;
  new.status := 'nuevo';
  new.privacy_consent_at := coalesce(new.privacy_consent_at, now());
  if new.marketing_consent = true then
    new.marketing_consent_at := coalesce(new.marketing_consent_at, now());
  else
    new.marketing_consent_at := null;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_lead_consent_metadata on public.contact_leads;
create trigger trg_lead_consent_metadata
before insert on public.contact_leads
for each row execute function public.set_lead_consent_metadata();

-- 3) Opiniones: asegurar tabla y RLS (si ya existe, estas instrucciones son inocuas)
create table if not exists public.reviews (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  name text not null,
  text text not null,
  stars integer not null check (stars between 1 and 5),
  status text not null default 'pending',
  created_at timestamptz not null default now()
);

alter table public.reviews enable row level security;

drop policy if exists "Public can read approved reviews" on public.reviews;
create policy "Public can read approved reviews"
on public.reviews for select to anon, authenticated
using (status = 'approved');

drop policy if exists "Public can submit reviews" on public.reviews;
create policy "Public can submit reviews"
on public.reviews for insert to anon, authenticated
with check (status = 'pending');

drop policy if exists "Admins manage reviews" on public.reviews;
create policy "Admins manage reviews"
on public.reviews for all to authenticated
using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'))
with check (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'));

-- 4) Índices útiles
create index if not exists idx_products_line_subcategory on public.products(line, subcategory);
create index if not exists idx_leads_created_at on public.contact_leads(created_at desc);
create index if not exists idx_leads_marketing on public.contact_leads(marketing_consent);

-- Nota: el formulario guarda la autorización obligatoria y la autorización comercial por separado.
-- La autorización comercial NO es requisito para enviar una solicitud.
