import { Router } from 'express';
import { z } from 'zod';
import { hashPassword, signToken, verifyPassword } from '../auth';
import { queryOne } from '../db/pool';

export const authRouter = Router();

const registerSchema = z.object({
  email: z.string().email(),
  name: z.string().min(1),
  password: z.string().min(8),
});

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
});

authRouter.post('/register', async (req, res) => {
  const parsed = registerSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: 'Invalid input', details: parsed.error.flatten() });
  }
  const { email, name, password } = parsed.data;

  const existing = await queryOne(`SELECT id FROM volunteers WHERE email = $1`, [email.toLowerCase()]);
  if (existing) {
    return res.status(409).json({ error: 'Email already registered.' });
  }

  const passwordHash = await hashPassword(password);
  const row = await queryOne<{ id: string; email: string; name: string }>(
    `INSERT INTO volunteers (email, name, password_hash)
     VALUES ($1, $2, $3) RETURNING id, email, name`,
    [email.toLowerCase(), name, passwordHash]
  );

  const token = signToken({ sub: row!.id, email: row!.email, name: row!.name });
  return res.status(201).json({ token, volunteer: row });
});

authRouter.post('/login', async (req, res) => {
  const parsed = loginSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: 'Invalid input' });
  }
  const { email, password } = parsed.data;

  const row = await queryOne<{ id: string; email: string; name: string; password_hash: string }>(
    `SELECT id, email, name, password_hash FROM volunteers WHERE email = $1`,
    [email.toLowerCase()]
  );
  if (!row || !(await verifyPassword(password, row.password_hash))) {
    return res.status(401).json({ error: 'Invalid email or password.' });
  }

  const token = signToken({ sub: row.id, email: row.email, name: row.name });
  return res.json({
    token,
    volunteer: { id: row.id, email: row.email, name: row.name },
  });
});
