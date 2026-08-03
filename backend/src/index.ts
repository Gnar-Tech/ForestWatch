import { createApp } from './app';
import { config } from './config';
import { pool } from './db/pool';
import { runMigrations } from './db/migrate';

async function main() {
  // Ensure the schema exists before serving requests.
  await runMigrations();

  const app = createApp();
  app.listen(config.port, () => {
    console.log(`ForestWatch API listening on http://localhost:${config.port}`);
  });
}

main().catch(async (err) => {
  console.error('Failed to start server:', err);
  await pool.end().catch(() => {});
  process.exit(1);
});
