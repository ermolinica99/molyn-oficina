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

-- Desde el cambio a fichaje por PUESTO, turnos/paradas/eventos se guardan con puesto_id y
-- usuario_id queda vacío. Por eso se compara por puesto_id (y por usuario_id solo en filas
-- antiguas). Antes solo se miraba usuario_id: con puestos nunca encontraba actividad, el turno
-- se cerraba 10 min después de EMPEZAR y las paradas abiertas no se cerraban nunca.

with ultima_actividad as (
  select t.id as turno_id,
         greatest(
           t.inicio,
           coalesce((select max(fe.ts) from fabricacion_eventos fe
                     where fe.ts >= t.inicio
                       and ((t.puesto_id is not null and fe.puesto_id = t.puesto_id)
                         or (t.puesto_id is null and fe.usuario_id = t.usuario_id))), t.inicio),
           coalesce((select max(coalesce(p.fin, p.inicio)) from paradas p
                     where p.inicio >= t.inicio
                       and ((t.puesto_id is not null and p.puesto_id = t.puesto_id)
                         or (t.puesto_id is null and p.usuario_id = t.usuario_id))), t.inicio)
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
set fin = greatest(p.inicio, t.fin)
from turnos t
where p.fin is null
  and t.fin is not null
  and ((t.puesto_id is not null and p.puesto_id = t.puesto_id)
    or (t.puesto_id is null and p.usuario_id = t.usuario_id))
  and p.inicio >= t.inicio
  and p.inicio <= t.fin;

-- Paradas abiertas de un día anterior que no cuelgan de ningún turno (p. ej. el turno ya se
-- cerró a mano pero la parada automática de "Preparación" se quedó abierta): se cierran en su
-- propio inicio para que no sumen horas de parada falsas ni aparezcan al día siguiente en Planta.
update paradas p
set fin = p.inicio
where p.fin is null
  and (p.inicio at time zone 'Europe/Madrid')::date < (now() at time zone 'Europe/Madrid')::date;
