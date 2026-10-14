-- ============================================================
-- MOLYN · Núcleos que se cortan de otro más largo (base de datos REAL)
-- ============================================================
-- Ejecutar UNA vez en el Editor SQL de Supabase del proyecto REAL antes de usar la regla de corte.
-- Solo añade dos columnas (no borra ni cambia datos). Se puede ejecutar varias veces.
--   config.corte            la regla (Configuración → Diario / Personalizado → Núcleos que se cortan)
--   modelos.nucleo_consumo  excepción por modelo: null = la regla · 'PROPIO' = su propio núcleo · otro código
-- ============================================================
alter table config add column if not exists corte jsonb;
alter table modelos add column if not exists nucleo_consumo text;
