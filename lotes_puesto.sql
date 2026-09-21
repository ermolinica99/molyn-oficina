-- Vincula cada programa de núcleo (N001-N012) con el puesto de trabajo que lo fabrica,
-- para poder calcular el coste de mano de obra real (x2 si el puesto tiene 2 personas).
-- Ejecutar en el Editor SQL de Supabase.

alter table lotes_programa add column if not exists puesto_id bigint references puestos_trabajo(id);
