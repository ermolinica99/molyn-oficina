# Entorno de PRUEBAS

Copia de la app para probar cambios sin tocar la app real ni sus datos.

- Oficina de pruebas: https://ermolinica99.github.io/molyn-oficina/pruebas/
- Planta de pruebas: https://ermolinica99.github.io/molyn-planta/pruebas/

## Cómo funciona
- `pruebas/index.html` es la misma app con un bloque ENTORNO: bajo `/pruebas/` se conecta a la
  base de datos de **pruebas** (Supabase `iqxstbjqjycsmlpdpwza`), guarda en el navegador con el
  prefijo `pruebas:` y muestra una franja roja "ENTORNO DE PRUEBAS". Fuera de `/pruebas/` el
  bloque no hace nada.
- Los datos de pruebas se rellenan copiando la base real con el workflow
  **"Copiar datos reales a PRUEBAS"** (pestaña Actions). Solo lee la real; borra y rellena la de pruebas.

## Flujo de trabajo
1. Los cambios nuevos se hacen primero en `pruebas/index.html`.
2. Se prueban en las direcciones de pruebas.
3. Cuando están bien, se copia `pruebas/index.html` sobre el `index.html` real (el bloque ENTORNO
   sigue funcionando: en la raíz usa la base real).
