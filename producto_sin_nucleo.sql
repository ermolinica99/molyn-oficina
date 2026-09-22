-- Catálogo de producto + colchones "sin núcleo" (colchonetas, etc.)
-- Ejecutar en el Editor SQL de Supabase.

create table if not exists categorias_sin_nucleo (
  id bigint generated always as identity primary key,
  nombre text not null,
  activo boolean not null default true
);

alter table modelos add column if not exists sin_nucleo boolean not null default false;
alter table modelos add column if not exists categoria_sin_nucleo_id bigint references categorias_sin_nucleo(id) on delete set null;

-- RLS (mismas políticas que config_categorias/config_opciones: select/insert/update/delete libres)
alter table categorias_sin_nucleo enable row level security;
drop policy if exists "anon_select" on categorias_sin_nucleo;
create policy "anon_select" on categorias_sin_nucleo for select to anon using (true);
drop policy if exists "anon_insert" on categorias_sin_nucleo;
create policy "anon_insert" on categorias_sin_nucleo for insert to anon with check (true);
drop policy if exists "anon_update" on categorias_sin_nucleo;
create policy "anon_update" on categorias_sin_nucleo for update to anon using (true) with check (true);
drop policy if exists "anon_delete" on categorias_sin_nucleo;
create policy "anon_delete" on categorias_sin_nucleo for delete to anon using (true);
