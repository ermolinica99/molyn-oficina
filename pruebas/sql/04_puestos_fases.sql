-- ============================================================
-- MOLYN · PRUEBAS · Fases de cada puesto de trabajo
-- ============================================================
-- Cada puesto dice qué fases hace (puede ser más de una, y varias puestos pueden hacer la misma):
--   nucleo, tapa, platabanda, pegado, cosido, embalaje
-- Vacío o null = puede hacer cualquier fase.
-- La primera vez se rellena con lo que ya estaba asignado en lotes_programa (un puesto por fase/programa).
-- Se puede ejecutar varias veces.
-- ============================================================
alter table puestos_trabajo add column if not exists fases text[];

update puestos_trabajo p set fases = x.fs
from (
  select puesto_id, array_agg(distinct case programa
           when 'TAPA' then 'tapa' when 'PTB' then 'platabanda'
           when 'PEG' then 'pegado' when 'COS' then 'cosido' when 'EMB' then 'embalaje'
           else 'nucleo' end) as fs
  from lotes_programa where puesto_id is not null group by puesto_id
) x
where p.id = x.puesto_id and p.fases is null;
