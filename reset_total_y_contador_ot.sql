-- ============================================================
-- MOLYN · Borrado total de actividad + reinicio del contador de OT
-- ============================================================
-- Ejecutar en el Editor SQL de Supabase. Es IRREVERSIBLE.
--
-- Borra: fabricacion_eventos, paradas, turnos, reservas, unidades, ordenes,
--        tiempos_sku, ajustes_inventario.
-- NO TOCA: productos, modelos, config, lotes_programa, puestos_trabajo,
--        turnos_plantilla, usuarios, usuarios_oficina.
-- Además reinicia el contador de OT para que la próxima sea OT00001.
-- ============================================================

delete from fabricacion_eventos;
delete from paradas;
delete from turnos;
delete from reservas;
delete from unidades;   -- primero unidades (por la FK a ordenes)
delete from ordenes;
delete from tiempos_sku;
delete from ajustes_inventario;

-- reinicia la secuencia que usa siguiente_ot() (la detecta sola por su nombre)
do $$
declare seq text;
begin
  select sequencename into seq from pg_sequences
    where schemaname='public' and sequencename ilike '%ot%'
    limit 1;
  if seq is not null then
    execute format('alter sequence %I restart with 1', seq);
  end if;
end $$;
