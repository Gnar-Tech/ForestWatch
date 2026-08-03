import fs from 'fs';
import path from 'path';
import { pool } from './pool';

/** Applies schema.sql to the configured database. */
export async function runMigrations(): Promise<void> {
  const schemaPath = path.join(__dirname, 'schema.sql');
  const sql = fs.readFileSync(schemaPath, 'utf8');
  await pool.query(sql);
}

// Allow running directly: `npm run migrate`
if (require.main === module) {
  runMigrations()
    .then(() => {
      console.log('Migrations applied.');
      return pool.end();
    })
    .then(() => process.exit(0))
    .catch((err) => {
      console.error('Migration failed:', err);
      process.exit(1);
    });
}
