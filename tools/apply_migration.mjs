import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import pg from "pg";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const rootDir = path.resolve(__dirname, "..");

const connectionString = process.env.DATABASE_URL;
if (!connectionString) {
  console.error("DATABASE_URL is required.");
  process.exit(1);
}

const migrationSql = fs.readFileSync(
  path.join(rootDir, "database_migration_apply.sql"),
  "utf8"
);

const client = new pg.Client({
  connectionString,
  ssl: { rejectUnauthorized: false },
});

const checks = [
  {
    label: "progreso_resumen table",
    sql: `SELECT EXISTS (
      SELECT 1 FROM information_schema.tables
      WHERE table_schema = 'public' AND table_name = 'progreso_resumen'
    ) AS ok`,
  },
  {
    label: "protocolo_maestro seeds",
    sql: "SELECT COUNT(*)::int AS count FROM public.protocolo_maestro",
  },
  {
    label: "finalizar_sesion_transaccional RPC",
    sql: `SELECT EXISTS (
      SELECT 1 FROM pg_proc WHERE proname = 'finalizar_sesion_transaccional'
    ) AS ok`,
  },
  {
    label: "v_dashboard_jugador view",
    sql: `SELECT EXISTS (
      SELECT 1 FROM information_schema.views
      WHERE table_schema = 'public' AND table_name = 'v_dashboard_jugador'
    ) AS ok`,
  },
  {
    label: "escenarios",
    sql: "SELECT id_escenario, nombre FROM public.escenarios ORDER BY 1",
  },
];

try {
  await client.connect();
  console.log("Connected to Supabase PostgreSQL");

  await client.query(migrationSql);
  console.log("Migration applied successfully\n");

  for (const check of checks) {
    const result = await client.query(check.sql);
    console.log(`[OK] ${check.label}:`, JSON.stringify(result.rows));
  }
} catch (error) {
  console.error("Migration failed:", error.message);
  if (error.position) {
    console.error("SQL position:", error.position);
  }
  process.exit(1);
} finally {
  await client.end();
}
