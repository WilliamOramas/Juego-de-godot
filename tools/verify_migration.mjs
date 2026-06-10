import pg from "pg";

const client = new pg.Client({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

await client.connect();

const queries = {
  usuarios: "SELECT COUNT(*)::int AS count FROM public.usuarios",
  progreso_resumen: "SELECT COUNT(*)::int AS count FROM public.progreso_resumen",
  sesiones: "SELECT COUNT(*)::int AS count FROM public.sesiones",
  cloud_saves: "SELECT COUNT(*)::int AS count FROM public.cloud_saves",
  triggers: `SELECT tgname, c.relname AS tabla
    FROM pg_trigger t
    JOIN pg_class c ON c.oid = t.tgrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public' AND NOT t.tgisinternal
    ORDER BY c.relname, tgname`,
  progreso_sample: "SELECT user_id, slot, puntaje, escenarios_completados FROM public.progreso_resumen LIMIT 5",
};

for (const [label, sql] of Object.entries(queries)) {
  const result = await client.query(sql);
  console.log(label + ":", JSON.stringify(result.rows, null, 2));
}

await client.end();
