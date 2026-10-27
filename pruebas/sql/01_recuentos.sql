-- ============================================================
-- MOLYN · Recuentos de inventario (en desarrollo, base de PRUEBAS)
-- ============================================================
-- El encargado cuenta en Planta → Inventario (QR de la hoja, etiqueta o
-- núcleo a mano). Cada conteo se guarda aquí con lo que decía la app en
-- ese momento. Al terminar, Oficina revisa el cuadre (hoja rellenada) y
-- aplica los ajustes. Se puede ejecutar varias veces sin romper nada.
-- ============================================================

create table if not exists recuentos (
  id bigint generated always as identity primary key,
  tipo text not null default 'completo',          -- completo | ciclico
  estado text not null default 'abierto',         -- abierto | terminado | aplicado | anulado
  creado_por bigint,                              -- usuario que lo empezó (encargado)
  creado_at timestamptz not null default now(),
  terminado_at timestamptz,
  aplicado_at timestamptz,
  nota text
);

create table if not exists recuento_lineas (
  id bigint generated always as identity primary key,
  recuento_id bigint not null references recuentos(id) on delete cascade,
  sku text not null,
  app_disp int not null default 0,                -- lo que decía la app al contar
  app_madur int not null default 0,
  app_total int not null default 0,
  contado int not null,
  hoja int,                                       -- lo que ponía la hoja impresa (si se escaneó su QR)
  contado_por bigint,
  contado_at timestamptz not null default now(),
  estado text not null default 'pendiente',       -- pendiente | aplicado | descartado
  aplicado_at timestamptz,
  unique (recuento_id, sku)
);
create index if not exists recuento_lineas_sku on recuento_lineas(sku);

-- permisos para la clave anon (como el resto de tablas, ver seguridad.sql);
-- aquí también se deja borrar una línea (contar de nuevo o quitarla del recuento)
do $$
declare t text;
begin
  foreach t in array array['recuentos','recuento_lineas'] loop
    execute format('alter table public.%I enable row level security;', t);
    execute format('drop policy if exists "anon_select" on public.%I;', t);
    execute format('create policy "anon_select" on public.%I for select to anon using (true);', t);
    execute format('drop policy if exists "anon_insert" on public.%I;', t);
    execute format('create policy "anon_insert" on public.%I for insert to anon with check (true);', t);
    execute format('drop policy if exists "anon_update" on public.%I;', t);
    execute format('create policy "anon_update" on public.%I for update to anon using (true) with check (true);', t);
  end loop;
end $$;
drop policy if exists "anon_delete" on public.recuento_lineas;
create policy "anon_delete" on public.recuento_lineas for delete to anon using (true);
