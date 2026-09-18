-- Cierre de turnos que quedaron abiertos de un día para otro.
-- Pensado para ejecutarse cada 20 min desde GitHub Actions
-- (.github/workflows/cierre_turnos.yml), como respaldo de servidor para
-- cuando el operario se va sin pulsar "Finalizar turno" y el móvil deja
-- de ejecutar la app (pantalla bloqueada, sin batería, etc.): en ese caso
-- la app no puede auto-cerrar nada porque su JS ya no corre.
--
-- Regla: si al llegar la medianoche (hora de España) un turno sigue
-- abierto, se cierra 10 minutos después del último evento de producción
-- de esa persona — no a medianoche exacta, ni en el momento en que corre
-- este job. Es idempotente: no pasa nada si se ejecuta varias veces
-- después de medianoche, solo actúa una vez por turno.
--
-- Sin esto, un turno abandonado se sigue contando hasta "ahora" cada vez
-- que alguien mira el panel de Productividad en Oficina, e infla
-- artificialmente la disponibilidad y hunde el OEE del operario.

with ultima_actividad as (
  select t.id as turno_id,
         greatest(
           t.inicio,
           coalesce((select max(ts) from fabricacion_eventos fe
                     where fe.usuario_id = t.usuario_id and fe.ts >= t.inicio), t.inicio),
           coalesce((select max(coalesce(p.fin, p.inicio)) from paradas p
                     where p.usuario_id = t.usuario_id and p.inicio >= t.inicio), t.inicio)
         ) as ultimo_ts
  from turnos t
  where t.fin is null
    -- el turno empezó un día natural (España) anterior al de hoy
    and (t.inicio at time zone 'Europe/Madrid')::date < (now() at time zone 'Europe/Madrid')::date
)
update turnos t
set fin = ua.ultimo_ts + interval '10 minutes'
from ultima_actividad ua
where t.id = ua.turno_id;

-- Cierra también cualquier parada que hubiera quedado abierta dentro de
-- esos turnos, con el mismo fin, para que no siga corriendo sin límite.
update paradas p
set fin = t.fin
from turnos t
where p.fin is null
  and t.fin is not null
  and p.usuario_id = t.usuario_id
  and p.inicio >= t.inicio
  and p.inicio <= t.fin;
