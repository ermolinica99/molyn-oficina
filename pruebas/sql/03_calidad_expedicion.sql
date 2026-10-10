-- ============================================================
-- MOLYN · PRUEBAS · Colchones defectuosos (calidad) y expedición
-- ============================================================
-- Defectos: un colchón puede volver a una fase anterior (retrabajo) o darse de baja, y siempre se
-- apunta qué fase o pieza tuvo el fallo y qué puesto la hizo (cuenta en la calidad de ese puesto).
-- Expedición: los colchones embalados (fase 'terminado') son stock de producto terminado hasta que
-- se expiden al cargar (expedido_at).
-- pf_unidades.fase admite además 'baja'. Se puede ejecutar varias veces.
-- ============================================================

create table if not exists pf_incidencias (
  id              bigint generated always as identity primary key,
  created_at      timestamptz not null default now(),
  pf_unidad       text not null,            -- PF00001-0001
  pf              text,
  sku_pf          text,
  accion          text not null,            -- retrabajo | baja
  fase_detectada  text,                     -- fase en la que estaba el colchón al verse el fallo
  fase_destino    text,                     -- retrabajo: fase a la que vuelve
  fallo_en        text not null,            -- pegado | cosido | embalaje | nucleo | tapa | platabanda
  puesto_culpable bigint,                   -- puesto que hizo esa fase o esa pieza
  puesto_detecta  bigint,                   -- puesto que lo ha marcado (null = Oficina)
  origen          text,                     -- tablet | oficina
  motivo          text,
  piezas_recuperadas text,                  -- ids de las piezas devueltas al stock, separadas por coma
  ref             text                      -- id único de la operación (la tablet puede reintentar el envío)
);
alter table pf_incidencias add column if not exists ref text;
create unique index if not exists pf_incidencias_ref on pf_incidencias(ref);
create index if not exists pf_incidencias_fecha on pf_incidencias(created_at);
create index if not exists pf_incidencias_culpable on pf_incidencias(puesto_culpable);
create index if not exists pf_incidencias_unidad on pf_incidencias(pf_unidad);

alter table pf_unidades add column if not exists expedido_at timestamptz;
alter table pf_unidades add column if not exists expedicion text;   -- referencia de la carga (albarán, cliente…)
alter table pf_unidades add column if not exists baja_at timestamptz;
create index if not exists pf_unidades_expedido on pf_unidades(expedido_at);

grant all on pf_incidencias to anon, authenticated;
alter table pf_incidencias enable row level security;
drop policy if exists "anon_select" on pf_incidencias;
create policy "anon_select" on pf_incidencias for select to anon, authenticated using (true);
drop policy if exists "anon_insert" on pf_incidencias;
create policy "anon_insert" on pf_incidencias for insert to anon, authenticated with check (true);
