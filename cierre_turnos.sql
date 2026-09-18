-- Cierre automático de turnos y paradas abandonados.
-- Pensado para ejecutarse cada 20 min desde GitHub Actions
-- (.github/workflows/cierre_turnos.yml), como respaldo de servidor para
-- cuando el operario se va sin pulsar "Finalizar turno" y el móvil deja
-- de ejecutar la app (pantalla bloqueada, sin batería, etc.): en ese caso
-- la app no puede auto-cerrar nada porque su JS ya no corre.
--
-- Sin esto, un turno que queda abierto (fin IS NULL) se sigue contando
-- hasta "ahora" cada vez que alguien mira el panel de Oficina, e infla
-- artificialmente la disponibilidad y hunde el OEE del operario.

-- 1) Paradas abiertas hace más de 2 horas: se cierran a las 2 horas
--    exactas desde que empezaron (evita que una pausa olvidada crezca
--    sin límite mientras nadie revisa el panel).
update paradas
set fin = inicio + interval '2 hours'
where fin is null
  and inicio < now() - interval '2 hours';

-- 2) Turnos abiertos sin ninguna actividad (fabricación o parada) en las
--    últimas 2 horas: se cierran en el momento del último movimiento
--    real de esa persona, no en "ahora", para que la duración del turno
--    refleje el tiempo que trabajó de verdad.
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
)
update turnos t
set fin = ua.ultimo_ts
from ultima_actividad ua
where t.id = ua.turno_id
  and ua.ultimo_ts < now() - interval '2 hours';
