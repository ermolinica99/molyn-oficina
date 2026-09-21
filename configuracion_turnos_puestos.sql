-- Turnos y puestos de trabajo + coste por operario
-- Ejecutar en el Editor SQL de Supabase.

create table if not exists turnos_plantilla (
  id bigint generated always as identity primary key,
  nombre text not null,
  tipo text not null default 'continuo', -- 'continuo' (un tramo) | 'partido' (dos tramos, ej. mañana y tarde)
  hora_inicio time not null default '06:00',   -- tramo 1 (continuo: único tramo)
  hora_fin time not null default '14:00',
  hora_inicio2 time,                            -- tramo 2, solo si tipo='partido'
  hora_fin2 time,
  descanso_min integer not null default 30,     -- descanso dentro del tramo (ej. desayuno)
  activo boolean not null default true
);
-- si la tabla ya existía de una ejecución anterior de este script:
alter table turnos_plantilla add column if not exists tipo text not null default 'continuo';
alter table turnos_plantilla add column if not exists hora_inicio2 time;
alter table turnos_plantilla add column if not exists hora_fin2 time;

create table if not exists puestos_trabajo (
  id bigint generated always as identity primary key,
  nombre text not null,
  capacidad integer not null default 1,
  activo boolean not null default true
);

alter table usuarios add column if not exists turno_id bigint references turnos_plantilla(id);
alter table usuarios add column if not exists puesto_id bigint references puestos_trabajo(id);
alter table usuarios add column if not exists coste_hora numeric;

-- RLS (mismas políticas que el resto de tablas: select/insert/update libres, sin delete)
alter table turnos_plantilla enable row level security;
drop policy if exists "anon_select" on turnos_plantilla;
create policy "anon_select" on turnos_plantilla for select to anon using (true);
drop policy if exists "anon_insert" on turnos_plantilla;
create policy "anon_insert" on turnos_plantilla for insert to anon with check (true);
drop policy if exists "anon_update" on turnos_plantilla;
create policy "anon_update" on turnos_plantilla for update to anon using (true) with check (true);

alter table puestos_trabajo enable row level security;
drop policy if exists "anon_select" on puestos_trabajo;
create policy "anon_select" on puestos_trabajo for select to anon using (true);
drop policy if exists "anon_insert" on puestos_trabajo;
create policy "anon_insert" on puestos_trabajo for insert to anon with check (true);
drop policy if exists "anon_update" on puestos_trabajo;
create policy "anon_update" on puestos_trabajo for update to anon using (true) with check (true);
