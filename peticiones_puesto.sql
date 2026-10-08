-- ============================================================
-- MOLYN · Peticiones a Oficina enviadas desde un PUESTO (trabajador)
-- ============================================================
-- El trabajador puede avisar desde su puesto en Planta de que en una OT
-- sobran etiquetas (salieron menos) o de que salió un núcleo de más.
-- La petición guarda qué puesto la envió. Necesita también peticiones_ot.sql.
-- Ejecutar en el Editor SQL de Supabase.
-- ============================================================

alter table ajustes_inventario add column if not exists puesto_id bigint references puestos_trabajo(id) on delete set null;
