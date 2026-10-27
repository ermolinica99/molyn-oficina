-- ============================================================
-- MOLYN · Tiempos por núcleo (en desarrollo, base de PRUEBAS)
-- ============================================================
-- Mínimo de tiradas (lotes cerrados en la tablet) para que un núcleo use su
-- propio tiempo en vez del estándar del programa. Se cambia en Oficina →
-- Tiempo por núcleo. Se puede ejecutar varias veces sin romper nada.
-- ============================================================
alter table config add column if not exists min_tiradas int not null default 7;
