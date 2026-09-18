-- ============================================================
-- MOLYN · Seguridad (RLS) para Supabase
-- ============================================================
-- Objetivo: la clave "anon" que usan las webs (Oficina y Planta) queda
-- expuesta en el código público de GitHub. Sin RLS, cualquiera con esa
-- clave puede leer y BORRAR cualquier fila de cualquier tabla directamente
-- contra la API REST de Supabase, sin pasar por la web.
--
-- Con este script:
--   - Se puede seguir leyendo/insertando/actualizando todo igual que ahora
--     (las apps no dejan de funcionar).
--   - DELETE solo se permite en 'reservas' y 'fabricacion_eventos'
--     (las únicas tablas donde la app borra filas hoy).
--   - En el resto de tablas, DELETE queda bloqueado a nivel de base de
--     datos, aunque alguien tenga la clave anon y la use directamente.
--
-- Ejecutar completo en el Editor SQL de Supabase.
-- ============================================================

do $$
declare
  t text;
  tablas text[] := array[
    'productos','modelos','ordenes','unidades','reservas','config',
    'lotes_programa','usuarios','usuarios_oficina','fabricacion_eventos',
    'paradas','turnos','tiempos_sku','ajustes_inventario',
    'config_categorias','config_opciones'
  ];
begin
  foreach t in array tablas loop
    execute format('alter table public.%I enable row level security;', t);

    execute format('drop policy if exists "anon_select" on public.%I;', t);
    execute format('create policy "anon_select" on public.%I for select to anon using (true);', t);

    execute format('drop policy if exists "anon_insert" on public.%I;', t);
    execute format('create policy "anon_insert" on public.%I for insert to anon with check (true);', t);

    execute format('drop policy if exists "anon_update" on public.%I;', t);
    execute format('create policy "anon_update" on public.%I for update to anon using (true) with check (true);', t);
  end loop;
end $$;

-- DELETE solo donde la app realmente borra filas hoy
drop policy if exists "anon_delete" on public.reservas;
create policy "anon_delete" on public.reservas for delete to anon using (true);

drop policy if exists "anon_delete" on public.fabricacion_eventos;
create policy "anon_delete" on public.fabricacion_eventos for delete to anon using (true);

-- Nota: si en el futuro añades una tabla nueva, tendrás que darle
-- las mismas políticas (o añadirla a la lista de arriba y re-ejecutar).
