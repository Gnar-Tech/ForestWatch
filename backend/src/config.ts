import dotenv from 'dotenv';

dotenv.config();

function required(name: string, fallback?: string): string {
  const v = process.env[name] ?? fallback;
  if (v === undefined) {
    throw new Error(`Missing required env var: ${name}`);
  }
  return v;
}

export const config = {
  port: parseInt(process.env.PORT ?? '4000', 10),
  databaseUrl: required(
    'DATABASE_URL',
    'postgres://forestwatch:forestwatch@localhost:5432/forestwatch'
  ),
  jwtSecret: required('JWT_SECRET', 'dev-insecure-secret-change-me'),
  publicUrl: (process.env.PUBLIC_URL ?? 'http://localhost:4000').replace(/\/$/, ''),
  corsOrigins: (process.env.CORS_ORIGINS ?? 'http://localhost:5173,http://localhost:3000')
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean),
};
