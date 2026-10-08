-- ============================================================
-- MOLYN · Copia de los partes impresos (para "Reimprimir parte")
-- ============================================================
-- Al lanzar un parte, Oficina guarda aquí el documento tal como se
-- imprimió. Desde Partes lanzados › "Reimprimir parte" se vuelve a sacar
-- exactamente igual. Los partes lanzados antes de ejecutar esto se
-- reimprimen reconstruidos con las OT y reservas actuales.
-- Ejecutar en el Editor SQL de Supabase.
-- ============================================================

create table if not exists partes_impresos (
  id bigint generated always as identity primary key,
  parte_ref text not null,
  html text not null,
  created_at timestamptz not null default now()
);
create index if not exists partes_impresos_parte_ref on partes_impresos(parte_ref);

alter table partes_impresos enable row level security;
drop policy if exists "anon_select" on partes_impresos;
create policy "anon_select" on partes_impresos for select to anon using (true);
drop policy if exists "anon_insert" on partes_impresos;
create policy "anon_insert" on partes_impresos for insert to anon with check (true);
