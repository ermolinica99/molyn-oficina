-- ============================================================
-- MOLYN · Modelos ESPECIALES (externos)
-- ============================================================
-- Añade la marca "especial" a los modelos. En Producción, el botón
-- "☆ Especial" de cada línea la guarda en el modelo, y la próxima vez que
-- ese modelo entre en un parte ya sale marcado. Sus líneas salen en hojas
-- de parte aparte (núcleo disponible / no disponible), aunque consumen y
-- reservan los mismos núcleos que el resto.
-- Ejecutar en el Editor SQL de Supabase.
-- ============================================================

alter table modelos add column if not exists especial boolean not null default false;
