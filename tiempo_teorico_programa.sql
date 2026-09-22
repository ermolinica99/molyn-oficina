-- Tiempo teórico por programa (N001-N012), usado como valor por defecto
-- para los núcleos que todavía no llegan al mínimo de unidades fabricadas
-- para tener un tiempo real aprendido (en vez de un único valor fijo de 4:30
-- para todos los programas por igual).
-- Ejecutar en el Editor SQL de Supabase.

alter table lotes_programa add column if not exists tiempo_teorico_seg integer;
