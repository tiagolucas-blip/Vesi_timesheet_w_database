/**
 * Shared Postgres pool for every api/*.js function. Prefixed with an
 * underscore so Vercel treats it as a helper module, not a route.
 *
 * DATABASE_URL must point at the schema in db/schema.sql, seeded with
 * db/seed.sql for local dev. In production this is Neon / Vercel Postgres.
 */
import pg from "pg";

const { Pool } = pg;

let pool;

export function getPool() {
  if (!pool) {
    const connectionString = process.env.DATABASE_URL;
    if (!connectionString) {
      throw new Error("DATABASE_URL is not set");
    }
    pool = new Pool({
      connectionString,
      ssl: /localhost|127\.0\.0\.1/.test(connectionString) ? false : { rejectUnauthorized: false },
      max: 5,
    });
  }
  return pool;
}

export async function query(text, params) {
  return getPool().query(text, params);
}

export async function withTransaction(fn) {
  const client = await getPool().connect();
  try {
    await client.query("BEGIN");
    const result = await fn(client);
    await client.query("COMMIT");
    return result;
  } catch (err) {
    await client.query("ROLLBACK");
    throw err;
  } finally {
    client.release();
  }
}

/** ISO Monday..Sunday (7 dates) for the week whose Monday is startISO. */
export function weekDates(startISO) {
  const [y, m, d] = startISO.split("-").map(Number);
  const base = new Date(Date.UTC(y, m - 1, d));
  return Array.from({ length: 7 }, (_, i) => {
    const dt = new Date(base);
    dt.setUTCDate(dt.getUTCDate() + i);
    return dt.toISOString().slice(0, 10);
  });
}

export function sendError(res, status, error, detail) {
  res.status(status).json(detail ? { error, detail } : { error });
}
