import bcrypt from 'bcryptjs';
import { NextFunction, Request, Response } from 'express';
import jwt from 'jsonwebtoken';
import { config } from './config';

export interface AuthPayload {
  sub: string; // volunteer id
  email: string;
  name: string;
}

export async function hashPassword(plain: string): Promise<string> {
  return bcrypt.hash(plain, 10);
}

export async function verifyPassword(plain: string, hash: string): Promise<boolean> {
  return bcrypt.compare(plain, hash);
}

export function signToken(payload: AuthPayload): string {
  return jwt.sign(payload, config.jwtSecret, { expiresIn: '30d' });
}

export interface AuthedRequest extends Request {
  volunteer?: AuthPayload;
}

function readToken(req: Request): string | null {
  const header = req.headers.authorization;
  if (header && header.startsWith('Bearer ')) return header.slice(7);
  return null;
}

/** Rejects the request unless a valid volunteer JWT is present. */
export function requireAuth(req: AuthedRequest, res: Response, next: NextFunction): void {
  const token = readToken(req);
  if (!token) {
    res.status(401).json({ error: 'Authentication required.' });
    return;
  }
  try {
    req.volunteer = jwt.verify(token, config.jwtSecret) as AuthPayload;
    next();
  } catch {
    res.status(401).json({ error: 'Invalid or expired token.' });
  }
}

/** Attaches volunteer if a valid token exists, but never rejects. */
export function optionalAuth(req: AuthedRequest, _res: Response, next: NextFunction): void {
  const token = readToken(req);
  if (token) {
    try {
      req.volunteer = jwt.verify(token, config.jwtSecret) as AuthPayload;
    } catch {
      /* ignore invalid token in optional mode */
    }
  }
  next();
}
