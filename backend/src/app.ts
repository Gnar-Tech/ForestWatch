import cors from 'cors';
import express, { NextFunction, Request, Response } from 'express';
import { config } from './config';
import { authRouter } from './routes/auth.routes';
import { dumpSitesRouter } from './routes/dumpSites.routes';
import { UPLOAD_DIR } from './upload';

export function createApp() {
  const app = express();

  app.use(
    cors({
      origin: (origin, cb) => {
        // Allow non-browser clients (mobile app, curl) with no Origin header.
        if (!origin || config.corsOrigins.includes(origin)) return cb(null, true);
        return cb(new Error(`Origin not allowed by CORS: ${origin}`));
      },
    })
  );
  app.use(express.json());
  app.use(express.urlencoded({ extended: true }));

  // Serve uploaded photos.
  app.use('/uploads', express.static(UPLOAD_DIR));

  app.get('/health', (_req, res) => res.json({ ok: true }));

  app.use('/api/auth', authRouter);
  app.use('/api/dump-sites', dumpSitesRouter);

  // Central error handler (multer errors, thrown route errors, etc.)
  app.use((err: any, _req: Request, res: Response, _next: NextFunction) => {
    console.error(err);
    const status = err?.status ?? 500;
    res.status(status).json({ error: err?.message ?? 'Internal server error.' });
  });

  return app;
}
