-- ============================================================
-- MOLYN · Reinicio de datos de actividad + fichaje por puesto
-- ============================================================
-- Ejecutar en el Editor SQL de Supabase. Es IRREVERSIBLE (por eso hay
-- backup automático diario desde anoche, y puedes lanzar uno manual antes
-- desde GitHub Actions si quieres estar más tranquilo).
--
-- Borra: fabricacion_eventos, paradas, turnos, reservas, unidades, ordenes,
--        tiempos_sku, ajustes_inventario (todo el historial de actividad).
-- NO TOCA: productos, modelos, config, lotes_programa, puestos_trabajo,
--        turnos_plantilla, usuarios, usuarios_oficina, config_categorias,
--        config_opciones (catálogo, configuración y personas).
-- ============================================================

delete from fabricacion_eventos;
delete from paradas;
delete from turnos;
delete from reservas;
delete from unidades;   -- primero unidades (por la FK a ordenes)
delete from ordenes;
delete from tiempos_sku;
delete from ajustes_inventario;

-- ============================================================
-- Esquema: el fichaje/producción ahora se registra por PUESTO
-- (los operarios ya no inician sesión individual en Planta; solo el
-- encargado sigue con su PIN personal). El puesto tiene su propio PIN.
-- ============================================================

alter table puestos_trabajo add column if not exists pin text;

alter table turnos add column if not exists puesto_id bigint references puestos_trabajo(id);
alter table turnos alter column usuario_id drop not null;

alter table paradas add column if not exists puesto_id bigint references puestos_trabajo(id);
alter table paradas alter column usuario_id drop not null;

alter table fabricacion_eventos add column if not exists puesto_id bigint references puestos_trabajo(id);
alter table fabricacion_eventos alter column usuario_id drop not null;
