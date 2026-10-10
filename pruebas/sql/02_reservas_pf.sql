-- ============================================================
-- MOLYN · PRUEBAS · Reservas por PF
-- ============================================================
-- Cada reserva de núcleo, tapa o platabanda guarda la PF (colchón) para la que es:
--   - al anular una PF se liberan exactamente sus reservas;
--   - en el pegado se descuenta la reserva de esa PF y no la de otro parte.
-- Se puede ejecutar varias veces.
-- ============================================================
alter table reservas add column if not exists pf text;
create index if not exists reservas_pf on reservas(pf);
