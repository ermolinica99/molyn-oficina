-- ============================================================
-- MOLYN · Seguridad: la base de datos decide quién entra
-- ============================================================
-- Hasta ahora la clave pública (la que va en el código de las webs) permitía leer y escribir
-- todo, y los PIN y las contraseñas se comprobaban en el navegador. Con este script:
--
--   - SIN SESIÓN no se puede leer ni escribir nada.
--   - OFICINA entra con una cuenta real de Supabase (email + contraseña). La fila de
--     usuarios_oficina solo dice su rol y si está aprobada.
--   - Cada TABLET de planta tiene su propia sesión (anónima, guardada en la tablet) y solo
--     funciona cuando un administrador la autoriza en Oficina.
--   - Los PIN de puestos y encargados se comprueban aquí, en el servidor: la tablet ya no los
--     descarga. 5 fallos seguidos = espera.
--   - Planta solo puede tocar lo suyo; usuarios, puestos, accesos y tablets solo un administrador.
--
-- ANTES de ejecutarlo, en el panel de Supabase → Authentication → Sign In / Providers:
--   1. "Allow anonymous sign-ins": ACTIVADO (lo usan las tablets).
--   2. Email → "Confirm email": desactivado si los emails de oficina no son buzones reales.
--
-- Se puede ejecutar varias veces sin romper nada.
-- Para DESHACERLO y volver a como estaba: ejecutar seguridad.sql, permitir_borrar_unidades.sql,
-- permitir_eliminar_usuarios_puestos.sql y la parte de permisos de recuentos.sql, y además:
--   grant all on all tables in schema public to anon;
--   grant all on all sequences in schema public to anon;
--   grant execute on all functions in schema public to anon;
-- ============================================================

-- ---------- 1. Tablas y columnas nuevas ----------
alter table usuarios_oficina add column if not exists auth_id uuid;
alter table usuarios_oficina add column if not exists auth_pendiente uuid;
create unique index if not exists usuarios_oficina_auth_id on usuarios_oficina(auth_id);
-- la contraseña ya no se guarda aquí: se vacía cuando la cuenta pasa a Supabase
do $$ begin
  alter table usuarios_oficina alter column pass_hash drop not null;
exception when others then null; end $$;

create table if not exists dispositivos (
  id bigint generated always as identity primary key,
  auth_id uuid not null unique,
  nombre text not null,
  estado text not null default 'pendiente',      -- pendiente | aprobado | rechazado
  creado_at timestamptz not null default now(),
  aprobado_at timestamptz,
  visto_at timestamptz
);

create table if not exists pin_intentos (
  auth_id uuid not null,
  tipo text not null,
  ref_id text not null,
  fallos int not null default 0,
  bloqueado_hasta timestamptz,
  primary key (auth_id, tipo, ref_id)
);

-- ---------- 2. Quién es quién ----------
create or replace function es_oficina() returns boolean
language sql stable security definer set search_path = public as $$
  select exists(select 1 from usuarios_oficina
                where auth_id = auth.uid() and activo is not false and estado = 'aprobado');
$$;

create or replace function es_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select exists(select 1 from usuarios_oficina
                where auth_id = auth.uid() and activo is not false and estado = 'aprobado'
                  and rol = 'administrador');
$$;

create or replace function es_planta() returns boolean
language sql stable security definer set search_path = public as $$
  select exists(select 1 from dispositivos where auth_id = auth.uid() and estado = 'aprobado');
$$;

-- ---------- 3. Oficina: acceso ----------
-- ¿Existe una cuenta antigua (anterior a este cambio) con ese email y esa contraseña, aún sin
-- pasar a Supabase? La web lo pregunta para crearle la cuenta nueva sola la primera vez que entra.
create or replace function oficina_migrable(p_email text, p_hash text) returns boolean
language sql stable security definer set search_path = public as $$
  select exists(select 1 from usuarios_oficina
                where lower(email) = lower(trim(p_email)) and auth_id is null
                  and pass_hash is not null and pass_hash = p_hash);
$$;

create or replace function oficina_json(r usuarios_oficina, p_vincular boolean default false) returns json
language sql stable as $$
  select json_build_object('id', r.id, 'email', r.email, 'nombre', r.nombre, 'rol', r.rol,
                           'estado', r.estado, 'activo', r.activo, 'vincular', p_vincular);
$$;

-- Perfil de quien tiene la sesión abierta (null si su cuenta aún no está en usuarios_oficina).
create or replace function oficina_perfil() returns json
language plpgsql stable security definer set search_path = public as $$
declare r usuarios_oficina;
begin
  select * into r from usuarios_oficina where auth_id = auth.uid();
  if not found then return null; end if;
  return oficina_json(r);
end $$;

-- Se llama justo después de entrar con email y contraseña. Enlaza la cuenta de Supabase con su
-- fila de usuarios_oficina: la suya de antes si la contraseña coincide, o una nueva "pendiente".
create or replace function oficina_entrar(p_nombre text default null, p_hash text default null) returns json
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_email text := lower(coalesce(auth.jwt() ->> 'email', ''));
  r usuarios_oficina;
begin
  if v_uid is null or v_email = '' then raise exception 'Sin sesión'; end if;
  select * into r from usuarios_oficina where auth_id = v_uid;
  if found then return oficina_json(r); end if;

  select * into r from usuarios_oficina where lower(email) = v_email and auth_id is null order by id limit 1;
  if found then
    if r.pass_hash is not null and r.pass_hash = p_hash then
      update usuarios_oficina set auth_id = v_uid, auth_pendiente = null, pass_hash = null
        where id = r.id returning * into r;
      return oficina_json(r);
    end if;
    -- el email ya tenía cuenta en MOLYN pero la contraseña no es la de antes: no se enlaza sola,
    -- un administrador tiene que confirmarlo (Usuarios → "Confirmar acceso nuevo")
    update usuarios_oficina set auth_pendiente = v_uid where id = r.id returning * into r;
    return oficina_json(r, true);
  end if;

  insert into usuarios_oficina(email, nombre, rol, estado, activo, auth_id)
    values (v_email, coalesce(nullif(trim(p_nombre), ''), v_email), 'oficina', 'pendiente', true, v_uid)
    returning * into r;
  return oficina_json(r);
end $$;

-- Un administrador confirma que la cuenta nueva de Supabase es de esa persona.
create or replace function oficina_vincular(p_id bigint) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not es_admin() then raise exception 'Solo un administrador'; end if;
  update usuarios_oficina set auth_id = auth_pendiente, auth_pendiente = null, pass_hash = null
    where id = p_id and auth_pendiente is not null;
end $$;

-- ---------- 4. Planta: tablets ----------
create or replace function mi_dispositivo() returns json
language plpgsql security definer set search_path = public as $$
declare d dispositivos;
begin
  update dispositivos set visto_at = now() where auth_id = auth.uid() returning * into d;
  if not found then return null; end if;
  return json_build_object('id', d.id, 'nombre', d.nombre, 'estado', d.estado);
end $$;

create or replace function dispositivo_solicitar(p_nombre text) returns json
language plpgsql security definer set search_path = public as $$
declare d dispositivos; v_nombre text := left(trim(coalesce(p_nombre, '')), 60);
begin
  if auth.uid() is null then raise exception 'Sin sesión'; end if;
  if v_nombre = '' then raise exception 'Pon un nombre a la tablet'; end if;
  insert into dispositivos(auth_id, nombre) values (auth.uid(), v_nombre)
    on conflict (auth_id) do update
      set nombre = excluded.nombre,
          estado = case when dispositivos.estado = 'aprobado' then 'aprobado' else 'pendiente' end
    returning * into d;
  return json_build_object('id', d.id, 'nombre', d.nombre, 'estado', d.estado);
end $$;

-- Puestos y encargados para la pantalla de entrada de la tablet. Sin el PIN: solo cuántas cifras tiene.
create or replace function planta_usuarios()
returns table(tipo text, id text, nombre text, activo boolean, pin_len int)
language plpgsql stable security definer set search_path = public as $$
begin
  if not es_planta() then raise exception 'Tablet no autorizada'; end if;
  return query
    select 'puesto'::text, p.id::text, p.nombre::text, coalesce(p.activo, true), length(coalesce(p.pin::text, ''))
      from puestos_trabajo p
    union all
    select 'encargado'::text, u.id::text, u.nombre::text, coalesce(u.activo, true), length(coalesce(u.pin::text, ''))
      from usuarios u where u.rol = 'encargado';
end $$;

-- Comprueba el PIN. Tras 5 fallos seguidos hay que esperar (30 s, y más si se sigue fallando).
create or replace function planta_login(p_tipo text, p_id text, p_pin text) returns json
language plpgsql security definer set search_path = public as $$
declare
  v_pin text; v_act boolean; v_ok boolean := false;
  i pin_intentos; v_fallos int; v_hasta timestamptz;
begin
  if not es_planta() then raise exception 'Tablet no autorizada'; end if;
  select * into i from pin_intentos where auth_id = auth.uid() and tipo = p_tipo and ref_id = p_id;
  if found and i.bloqueado_hasta is not null and i.bloqueado_hasta > now() then
    return json_build_object('ok', false, 'espera', ceil(extract(epoch from i.bloqueado_hasta - now()))::int);
  end if;
  if p_tipo = 'puesto' then
    select p.pin::text, coalesce(p.activo, true) into v_pin, v_act from puestos_trabajo p where p.id::text = p_id;
  else
    select u.pin::text, coalesce(u.activo, true) into v_pin, v_act from usuarios u where u.id::text = p_id and u.rol = 'encargado';
  end if;
  if not found or not v_act then return json_build_object('ok', false, 'inactivo', true); end if;
  v_ok := coalesce(v_pin, '') = '' or v_pin = coalesce(p_pin, '');
  if v_ok then
    delete from pin_intentos where auth_id = auth.uid() and tipo = p_tipo and ref_id = p_id;
    return json_build_object('ok', true);
  end if;
  v_fallos := coalesce(i.fallos, 0) + 1;
  if v_fallos % 5 = 0 then v_hasta := now() + make_interval(secs => 30 * least(v_fallos / 5, 20)); end if;
  insert into pin_intentos(auth_id, tipo, ref_id, fallos, bloqueado_hasta)
    values (auth.uid(), p_tipo, p_id, v_fallos, v_hasta)
    on conflict (auth_id, tipo, ref_id) do update set fallos = excluded.fallos, bloqueado_hasta = excluded.bloqueado_hasta;
  return json_build_object('ok', false, 'espera', case when v_hasta is null then 0 else ceil(extract(epoch from v_hasta - now()))::int end);
end $$;

-- ---------- 5. Permisos por tabla ----------
-- Se quitan TODAS las políticas anteriores (las "anon_*" que lo permitían todo) y se ponen las nuevas.
-- Una tabla nueva que no esté en las listas de abajo queda, por defecto, solo para Oficina.
do $$
declare t record; p record;
begin
  for t in select tablename from pg_tables where schemaname = 'public' loop
    execute format('alter table public.%I enable row level security', t.tablename);
    for p in select policyname from pg_policies where schemaname = 'public' and tablename = t.tablename loop
      execute format('drop policy %I on public.%I', p.policyname, t.tablename);
    end loop;
    if t.tablename not in ('usuarios_oficina', 'dispositivos', 'pin_intentos', 'usuarios', 'puestos_trabajo') then
      execute format('create policy oficina_todo on public.%I for all to authenticated using (es_oficina()) with check (es_oficina())', t.tablename);
    end if;
  end loop;
end $$;

-- plantilla y puestos (con sus PIN): Oficina los ve, solo un administrador los cambia
do $$
declare t text;
begin
  foreach t in array array['usuarios', 'puestos_trabajo'] loop
    execute format('create policy oficina_ver on public.%I for select to authenticated using (es_oficina())', t);
    execute format('create policy admin_crear on public.%I for insert to authenticated with check (es_admin())', t);
    execute format('create policy admin_cambiar on public.%I for update to authenticated using (es_admin()) with check (es_admin())', t);
    execute format('create policy admin_borrar on public.%I for delete to authenticated using (es_admin())', t);
  end loop;
end $$;

-- accesos de oficina: cada uno ve su fila; el resto, solo un administrador. Las filas nuevas las crea oficina_entrar()
create policy propia_o_admin on public.usuarios_oficina for select to authenticated using (auth_id = auth.uid() or es_admin());
create policy admin_cambiar on public.usuarios_oficina for update to authenticated using (es_admin()) with check (es_admin());
create policy admin_borrar on public.usuarios_oficina for delete to authenticated using (es_admin());

-- tablets: solo un administrador (la tablet consulta lo suyo con mi_dispositivo())
create policy admin_ver on public.dispositivos for select to authenticated using (es_admin());
create policy admin_cambiar on public.dispositivos for update to authenticated using (es_admin()) with check (es_admin());
create policy admin_borrar on public.dispositivos for delete to authenticated using (es_admin());
-- pin_intentos: sin políticas, solo la toca planta_login()

-- lo que puede hacer una tablet autorizada: l = leer, c = crear, m = modificar, b = borrar
do $$
declare
  permisos constant text[][] := array[
    ['unidades',            'lm'],     -- terminar (pendiente → stock) y consumir (stock → consumida)
    ['ordenes',             'l'],
    ['productos',           'l'],
    ['config',              'l'],
    ['lotes_programa',      'lcm'],
    ['tiempos_sku',         'lcm'],
    ['fabricacion_eventos', 'lcmb'],
    ['paradas',             'lcm'],
    ['turnos',              'lcm'],
    ['reservas',            'lm'],
    ['ajustes_inventario',  'lc'],     -- pedir altas, bajas y "sobran etiquetas"; resolverlas es de Oficina
    ['recuentos',           'lcm'],
    ['recuento_lineas',     'lcmb']
  ];
  i int; t text; ops text;
begin
  for i in 1 .. array_length(permisos, 1) loop
    t := permisos[i][1]; ops := permisos[i][2];
    if to_regclass('public.' || quote_ident(t)) is null then continue; end if;
    if position('l' in ops) > 0 then execute format('create policy planta_leer on public.%I for select to authenticated using (es_planta())', t); end if;
    if position('c' in ops) > 0 then execute format('create policy planta_crear on public.%I for insert to authenticated with check (es_planta())', t); end if;
    if position('m' in ops) > 0 then execute format('create policy planta_cambiar on public.%I for update to authenticated using (es_planta()) with check (es_planta())', t); end if;
    if position('b' in ops) > 0 then execute format('create policy planta_borrar on public.%I for delete to authenticated using (es_planta())', t); end if;
  end loop;
end $$;

-- ---------- 6. La clave pública sola ya no sirve ----------
revoke all on all tables in schema public from anon;
revoke all on all sequences in schema public from anon;
revoke execute on all functions in schema public from anon, public;
alter default privileges in schema public revoke all on tables from anon;
alter default privileges in schema public revoke all on sequences from anon;
alter default privileges in schema public revoke execute on functions from anon, public;

grant usage on schema public to anon, authenticated;
grant select, insert, update, delete on all tables in schema public to authenticated;
grant usage, select on all sequences in schema public to authenticated;
grant execute on all functions in schema public to authenticated;
-- lo único que se puede llamar sin sesión: comprobar una cuenta antigua de oficina al entrar por primera vez
grant execute on function oficina_migrable(text, text) to anon;

notify pgrst, 'reload schema';
