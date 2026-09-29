-- ============================================================
-- MOLYN · Permitir borrar unidades desde Oficina
-- ============================================================
-- seguridad.sql solo deja borrar filas en 'reservas' y 'fabricacion_eventos'.
-- Pero Oficina SÍ necesita borrar unidades en estas acciones:
--   - Órdenes de trabajo -> Cerrar / Anular (borra las unidades pendientes)
--   - Partes lanzados -> Anular OT / Anular parte completo
--   - Inventario físico -> Baja
--   - Aprobaciones -> aprobar una BAJA pedida desde Planta
-- Sin este permiso Supabase no da ningún error: simplemente no borra nada.
-- (La nueva versión de Oficina ya lo detecta y avisa, pero la acción no se completa.)
--
-- Ejecutar en el Editor SQL de Supabase. Se puede ejecutar varias veces sin problema.
-- ============================================================

drop policy if exists "anon_delete" on public.unidades;
create policy "anon_delete" on public.unidades for delete to anon using (true);
