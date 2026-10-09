-- ============================================================
-- MOLYN · PRUEBAS · Producto final (PF)
-- ============================================================
-- A partir de la fase 3 el colchón se fabrica en línea con una OT de PRODUCTO FINAL:
--   PF00001 · Alhambra · 10 uds  →  etiquetas PF00001-0001 … PF00001-0010
-- Cada colchón pasa por 3 operaciones, numeradas desde el final:
--   3 Pegado (núcleo + tapa + platabanda)  →  2 Cosido  →  1 Embalado
-- Cada colchón puede pasar a la siguiente en cuanto termina la anterior.
--
-- Solo para la base de PRUEBAS. Se aplica sola con la acción
-- "Aplicar SQL a PRUEBAS" (y al final de "Copiar datos reales a PRUEBAS").
-- Se puede ejecutar varias veces sin romper nada.
-- ============================================================

-- contador propio de las PF (independiente del de las OT)
create sequence if not exists pf_seq;
create or replace function siguiente_pf() returns text
  language sql as $$ select 'PF' || lpad(nextval('pf_seq')::text, 5, '0') $$;

-- cabecera de cada PF (una por línea del parte)
create table if not exists pf_ordenes (
  pf           text primary key,                 -- PF00001
  sku_pf       text not null,                    -- código del modelo
  nombre       text,
  descripcion  text,                             -- descripción del parte (con configuraciones)
  cantidad     integer not null,
  sku_nucleo   text,                             -- núcleo que lleva (null = sin núcleo)
  especial     boolean not null default false,   -- externo
  parte_ref    text,
  estado       text not null default 'abierta',  -- abierta | terminada | anulada
  lanzada_at   timestamptz not null default now(),
  terminada_at timestamptz
);
create index if not exists pf_ordenes_parte on pf_ordenes(parte_ref);
create index if not exists pf_ordenes_estado on pf_ordenes(estado);

-- cada colchón (una etiqueta). "fase" es la operación que le toca ahora.
create table if not exists pf_unidades (
  id            text primary key,                -- PF00001-0001
  pf            text not null references pf_ordenes(pf) on delete cascade,
  sku_pf        text not null,
  fase          text not null default 'pegado',  -- pegado | cosido | embalaje | terminado | anulada
  nucleo_id     text,                            -- etiquetas consumidas en el pegado
  tapa_id       text,
  platabanda_id text,
  pegado_at     timestamptz,
  cosido_at     timestamptz,
  embalado_at   timestamptz
);
create index if not exists pf_unidades_pf on pf_unidades(pf);
create index if not exists pf_unidades_fase on pf_unidades(fase);

-- los tiempos de pegado/cosido/embalado se guardan en fabricacion_eventos y tiempos_sku con la
-- etiqueta del colchón (PF00001-0001) y el código <modelo>_PEG / _COS / _EMB, que no existen en
-- unidades ni en productos: si esas columnas tienen clave ajena a esas tablas, se quita.
do $$
declare r record;
begin
  for r in
    select c.conname, c.conrelid::regclass as tabla
    from pg_constraint c
    where c.contype = 'f'
      and c.conrelid in ('public.fabricacion_eventos'::regclass, 'public.tiempos_sku'::regclass)
      and c.confrelid in ('public.unidades'::regclass, 'public.productos'::regclass, 'public.ordenes'::regclass)
  loop
    execute format('alter table %s drop constraint %I', r.tabla, r.conname);
  end loop;
end $$;

-- permisos para la clave pública (igual que el resto de tablas)
grant usage, select on sequence pf_seq to anon, authenticated;
grant execute on function siguiente_pf() to anon, authenticated;
grant all on pf_ordenes, pf_unidades to anon, authenticated;
do $$
declare t text;
begin
  foreach t in array array['pf_ordenes','pf_unidades'] loop
    execute format('alter table public.%I enable row level security;', t);
    execute format('drop policy if exists "anon_select" on public.%I;', t);
    execute format('create policy "anon_select" on public.%I for select to anon, authenticated using (true);', t);
    execute format('drop policy if exists "anon_insert" on public.%I;', t);
    execute format('create policy "anon_insert" on public.%I for insert to anon, authenticated with check (true);', t);
    execute format('drop policy if exists "anon_update" on public.%I;', t);
    execute format('create policy "anon_update" on public.%I for update to anon, authenticated using (true) with check (true);', t);
  end loop;
end $$;
