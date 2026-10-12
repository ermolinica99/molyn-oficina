-- ============================================================
-- MOLYN · PRUEBAS · Colchones que no llevan alguna pieza
-- ============================================================
-- En el pegado hay que escanear el núcleo, la tapa y la platabanda (lo que se gasta es lo que se
-- escanea). Si un colchón de verdad no lleva alguna, en la tablet se marca "no lleva" y queda un aviso
-- en pf_sin_pieza para que Oficina lo clasifique:
--   ok_colchon  correcto, solo este colchón no la lleva
--   ok_modelo   correcto, el modelo nunca la lleva (se marca en modelos y la tablet ya no la pide)
--   error       sí la llevaba (si se sabe cuál, se descuenta y se apunta en el colchón)
-- modelos.sin_tapa / sin_platabanda: el modelo no lleva tapa / platabanda (como sin_nucleo).
-- Se puede ejecutar varias veces.
-- ============================================================
alter table modelos add column if not exists sin_tapa boolean not null default false;
alter table modelos add column if not exists sin_platabanda boolean not null default false;

create table if not exists pf_sin_pieza (
  id          bigint generated always as identity primary key,
  ref         text unique,                       -- evita duplicados si la tablet reenvía
  pf_unidad   text not null,                     -- PF00001-0001
  pf          text,
  sku_pf      text,
  pieza       text not null,                     -- nucleo | tapa | platabanda
  sku         text,                              -- referencia de la pieza que no lleva
  puesto_id   bigint,                            -- puesto que lo marcó
  created_at  timestamptz not null default now(),
  estado      text not null default 'pendiente', -- pendiente | ok_colchon | ok_modelo | error
  pieza_id    text,                              -- (error) etiqueta de la pieza que sí llevaba
  nota        text,
  resuelto_at timestamptz
);
create index if not exists pf_sin_pieza_estado on pf_sin_pieza(estado);
create index if not exists pf_sin_pieza_unidad on pf_sin_pieza(pf_unidad);

grant all on pf_sin_pieza to anon, authenticated;
alter table pf_sin_pieza enable row level security;
drop policy if exists "anon_select" on pf_sin_pieza;
create policy "anon_select" on pf_sin_pieza for select to anon, authenticated using (true);
drop policy if exists "anon_insert" on pf_sin_pieza;
create policy "anon_insert" on pf_sin_pieza for insert to anon, authenticated with check (true);
drop policy if exists "anon_update" on pf_sin_pieza;
create policy "anon_update" on pf_sin_pieza for update to anon, authenticated using (true) with check (true);
