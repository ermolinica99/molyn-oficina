-- ============================================================
-- MOLYN · Borrado total de actividad + CATÁLOGO (núcleos y modelos)
-- ============================================================
-- Ejecutar en el Editor SQL de Supabase. Es IRREVERSIBLE.
--
-- ANTES DE EJECUTAR:
--   1. GitHub -> molyn-oficina -> Actions -> "Backup base de datos MOLYN"
--      -> Run workflow, y esperar a que salga en verde (copia de seguridad).
--   2. En cada tablet de Planta: que la barra de arriba diga que no queda
--      nada pendiente de enviar y que no haya ninguna unidad en curso.
--      Si una tablet tiene cosas sin enviar, las mandaría después del
--      borrado y dejaría datos sueltos.
--
-- Borra: fabricacion_eventos, paradas, turnos, reservas, unidades, ordenes,
--        tiempos_sku, ajustes_inventario (toda la actividad y el stock)
--        y además modelos y productos (todos los núcleos y modelos, con sus
--        costes de material y la marca "forzar a diario").
-- NO TOCA: usuarios, usuarios_oficina, puestos_trabajo, turnos_plantilla,
--        config, lotes_programa, categorias_sin_nucleo, config_categorias,
--        config_opciones (personas, PIN, puestos, turnos y configuración).
-- Además reinicia el contador de OT para que la próxima sea OT00001.
--
-- Va todo en una transacción: si algo falla, no se borra nada.
--
-- DESPUÉS: Oficina -> Ajustes -> Alta masiva -> importar el Excel del
-- catálogo, y recargar las tablets de Planta.
-- ============================================================

begin;

delete from fabricacion_eventos;
delete from paradas;
delete from turnos;
delete from reservas;
delete from unidades;   -- primero unidades (por la FK a ordenes)
delete from ordenes;
delete from tiempos_sku;
delete from ajustes_inventario;
delete from modelos;    -- antes que productos (los modelos apuntan a su núcleo)
delete from productos;

-- reinicia la secuencia que usa siguiente_ot() (la detecta sola por su nombre)
do $$
declare seq text;
begin
  select sequencename into seq from pg_sequences
    where schemaname='public' and sequencename ilike '%ot%'
    limit 1;
  if seq is not null then
    execute format('alter sequence %I restart with 1', seq);
  end if;
end $$;

commit;

-- comprobación: todo debe salir a 0
select 'productos' tabla, count(*) from productos
union all select 'modelos', count(*) from modelos
union all select 'ordenes', count(*) from ordenes
union all select 'unidades', count(*) from unidades
union all select 'reservas', count(*) from reservas;
