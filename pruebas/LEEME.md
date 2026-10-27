# Entorno de PRUEBAS

Copia de la app para probar cambios sin tocar la app real ni sus datos.

- Oficina de pruebas: https://ermolinica99.github.io/molyn-oficina/pruebas/
- Planta de pruebas: https://ermolinica99.github.io/molyn-planta/pruebas/

## Qué hay ahora (rehecho en octubre de 2026)
- `pruebas/index.html` es **la app real tal cual** más un bloque ENTORNO y, en Oficina, la pantalla
  **Informes** (productividad semanal / mensual por programa o por puesto, OEE con la jornada del turno,
  tiempos por referencia, paradas, unidades por día, Excel y PDF). Informes solo lee datos que ya
  existen en la base real: no necesita ningún SQL.
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
