-- ============================================================
-- MOLYN · PRUEBAS · Núcleos que se cortan de otro más largo
-- ============================================================
-- Los núcleos se fabrican a 200 de largo (y algunos anchos también a 190). Un colchón de 190 o 195 que
-- no se fabrica a esa medida gasta el núcleo de 200 del mismo programa, ancho y firmeza, y se corta en
-- el pegado. La app lo calcula con la regla de config.corte:
--   {"activo":true, "base":200, "cortables":[190,195], "fab":{"190":[90,105,135,150],"195":[]}, "umbral":10}
--   umbral: si en un parte salen al menos tantos de una medida que se corta, ese parte la fabrica a medida.
-- modelos.nucleo_consumo: excepción a mano del núcleo que gasta un modelo
--   null = lo que diga la regla · 'PROPIO' = su propio núcleo (no se corta) · otro código = ese núcleo
-- pf_ordenes.nucleo_corte: núcleo del modelo cuando se lanzó cortando otro (para avisar en el pegado).
-- Se puede ejecutar varias veces.
-- ============================================================
alter table config add column if not exists corte jsonb;
alter table modelos add column if not exists nucleo_consumo text;
alter table pf_ordenes add column if not exists nucleo_corte text;
