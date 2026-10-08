-- ============================================================
-- MOLYN · Peticiones de planta sobre una OT ("salieron menos")
-- ============================================================
-- El encargado puede pedir a Oficina, desde Planta, que quite de una OT
-- las etiquetas que han sobrado porque salieron menos núcleos (p. ej.
-- lanzada con 19 y salieron 18). Se guarda en ajustes_inventario con
-- tipo 'ot_menos' y la OT en la columna nueva 'ot'.
-- Ejecutar en el Editor SQL de Supabase.
-- ============================================================

alter table ajustes_inventario add column if not exists ot text;

-- si la tabla tenía una restricción que solo admitía 'alta'/'baja' en tipo,
-- se quita para admitir también 'ot_menos'
do $$
declare r record;
begin
  for r in
    select conname from pg_constraint
    where conrelid = 'public.ajustes_inventario'::regclass
      and contype = 'c'
      and pg_get_constraintdef(oid) ilike '%tipo%'
  loop
    execute format('alter table public.ajustes_inventario drop constraint %I', r.conname);
  end loop;
end $$;
