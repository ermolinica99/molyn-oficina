-- Permite borrar (no solo desactivar) usuarios y puestos_trabajo desde Oficina.
-- Ejecutar en el Editor SQL de Supabase.

drop policy if exists "anon_delete" on usuarios;
create policy "anon_delete" on usuarios for delete to anon using (true);

drop policy if exists "anon_delete" on puestos_trabajo;
create policy "anon_delete" on puestos_trabajo for delete to anon using (true);
