# Entorno de PRUEBAS

Copia de la app para probar cambios sin tocar la app real ni sus datos.

- Oficina de pruebas: https://ermolinica99.github.io/molyn-oficina/pruebas/
- Planta de pruebas: https://ermolinica99.github.io/molyn-planta/pruebas/

## Qué hay ahora (rehecho en octubre de 2026)
- `pruebas/index.html` es **la app real tal cual** más un bloque ENTORNO y, en Oficina, la pantalla
  **Informes** (productividad semanal / mensual por programa o por puesto, OEE con la jornada del turno,
  tiempos por referencia, paradas, unidades por día, Excel y PDF). Informes solo lee datos que ya
  existen en la base real: no necesita ningún SQL.
- **Seguridad nueva (en pruebas):** `pruebas/sql/03_seguridad.sql`. Ver el apartado «Seguridad» más abajo.
- Cambios de base de datos en desarrollo: `pruebas/sql/01_recuentos.sql` (tablas de los recuentos de inventario) y `pruebas/sql/02_tiempos.sql` (mínimo de tiradas de Tiempo por núcleo). Se aplican a la base de pruebas con "Aplicar SQL a PRUEBAS".

## Lo anterior está guardado
Todo lo que se desarrolló antes en pruebas (producto final PF, reservas de PF, calidad y expedición,
puestos por fase, avisos "no lleva" pieza, trazabilidad, lotes de tapa/platabanda, coste por colchón,
balanceo de línea, y sus SQL 01–06) está en la rama **`archivo/pruebas-completo-oct-2026`** de los dos
repositorios (molyn-oficina y molyn-planta). Para recuperar algo se trae de esa rama a `pruebas/`
(y sus SQL a `pruebas/sql/`).

## Cómo funciona
- `pruebas/index.html` usa **siempre** la base de datos de **pruebas** (Supabase `iqxstbjqjycsmlpdpwza`,
  `ES_PRUEBAS=true`), se abra desde donde se abra; guarda en el navegador con el prefijo `pruebas:` y
  muestra una franja roja "ENTORNO DE PRUEBAS".
- Los datos de pruebas se rellenan copiando la base real con el workflow
  **"Copiar datos reales a PRUEBAS"** (pestaña Actions). Solo lee la real; borra y rellena la de pruebas.

## Flujo de trabajo
1. Los cambios nuevos se hacen primero en `pruebas/index.html`.
2. Se prueban en las direcciones de pruebas.
3. Cuando están bien, se pasan al `index.html` real. Al hacerlo, el bloque ENTORNO **no** se copia y las
   líneas `SUPABASE_URL` / `SUPABASE_KEY` se dejan con la base real.

## Cambios de base de datos en desarrollo
- Van en `pruebas/sql/*.sql` (se aplican por orden y se pueden repetir sin romper nada).
- Se aplican a la base de **pruebas** con el workflow **"Aplicar SQL a PRUEBAS"** (pestaña Actions).
  "Copiar datos reales a PRUEBAS" también los aplica al final, porque la copia borra la base de pruebas.
- Al pasar los cambios a la app real, estos SQL se ejecutan también en la base real (a mano, en el
  Editor SQL de Supabase).

## Seguridad (en pruebas, noviembre de 2026)
Hasta ahora la clave pública que va en el código permitía leer y escribir toda la base de datos, y los PIN
y contraseñas se comprobaban en el navegador. Con `pruebas/sql/03_seguridad.sql` y las apps de `pruebas/`:

- **Sin sesión** no se puede leer ni escribir nada.
- **Oficina** entra con una cuenta real de Supabase (email + contraseña). Las cuentas de antes se pasan solas
  la primera vez que entran con su email y contraseña de siempre. «Solicitar acceso» sigue igual.
- **Cada tablet de planta** pide acceso la primera vez (se le pone un nombre) y un administrador la autoriza en
  Oficina → Configuración → Usuarios y costes → *Tablets de planta*. También sale el aviso arriba a la derecha.
- **Los PIN** de puestos y encargados los comprueba la base de datos; la tablet ya no los descarga.
- **Permisos por rol:** una tablet solo toca lo de planta; usuarios, puestos, accesos y tablets, solo un administrador.

### Para probarlo
1. En el proyecto de Supabase de **pruebas** → Authentication → Sign In / Providers:
   activar **Allow anonymous sign-ins** y, en Email, desactivar **Confirm email**.
2. Actions → **Copiar datos reales a PRUEBAS** (o **Aplicar SQL a PRUEBAS** si los datos ya están).
3. Abrir Oficina de pruebas y entrar con un email y contraseña de administrador de siempre.
4. Abrir Planta de pruebas en una tablet, ponerle nombre y autorizarla desde Oficina.
5. Repasar: lanzar parte, fabricar, consumir, baja y alta desde planta, recuento, ajuste de OT, usuarios y puestos.

Cada vez que se lanza «Copiar datos reales a PRUEBAS» las cuentas de oficina vuelven a las de la real (se
pasan solas otra vez al entrar) y las tablets hay que autorizarlas de nuevo.

### Qué no cubre todavía
- Un usuario de oficina que no es administrador sigue pudiendo leer los PIN de planta por la API.
- Los PIN siguen guardados sin cifrar en la base de datos (ya no salen de ella hacia las tablets).
