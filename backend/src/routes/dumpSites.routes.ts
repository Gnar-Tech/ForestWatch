import { Router } from 'express';
import { z } from 'zod';
import { AuthedRequest, optionalAuth, requireAuth } from '../auth';
import { query, queryOne } from '../db/pool';
import { serializeCleanup, serializeDumpSite } from '../serialize';
import { upload } from '../upload';

export const dumpSitesRouter = Router();

const num = (v: unknown) => (v === '' || v == null ? null : Number(v));

/* ------------------------- Create a dump site ------------------------- */
// Auth required — reporters must be logged in. Multipart with `photo`.
dumpSitesRouter.post('/', requireAuth, upload.single('photo'), async (req: AuthedRequest, res) => {
  const b = req.body ?? {};
  const schema = z.object({
    title: z.string().min(1),
    latitude: z.coerce.number(),
    longitude: z.coerce.number(),
  });
  const parsed = schema.safeParse(b);
  if (!parsed.success) {
    return res.status(400).json({ error: 'title, latitude, longitude are required.' });
  }

  // Idempotency: if the device already synced this clientId, return it.
  if (b.clientId) {
    const existing = await queryOne(`SELECT * FROM dump_sites WHERE client_id = $1`, [b.clientId]);
    if (existing) return res.status(200).json(serializeDumpSite(existing));
  }

  const photoPath = req.file ? req.file.filename : null;
  const row = await queryOne(
    `INSERT INTO dump_sites
       (client_id, title, description, category, severity, status,
        latitude, longitude, accuracy, altitude, photo_path, reporter_name, reporter_id)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13)
     RETURNING *`,
    [
      b.clientId ?? null,
      b.title,
      b.description ?? '',
      b.category ?? 'litter',
      b.severity ?? 'medium',
      b.status ?? 'reported',
      Number(b.latitude),
      Number(b.longitude),
      num(b.accuracy),
      num(b.altitude),
      photoPath,
      b.reporterName || req.volunteer?.name || null,
      req.volunteer?.sub ?? null,
    ]
  );
  return res.status(201).json(serializeDumpSite(row));
});

/* ---------------------------- List sites ---------------------------- */
// Public list for the website map. Supports ?status= filter.
dumpSitesRouter.get('/', async (req, res) => {
  const status = typeof req.query.status === 'string' ? req.query.status : null;
  const rows = await query(
    `SELECT d.*, COUNT(c.id) AS cleanup_count
     FROM dump_sites d
     LEFT JOIN cleanup_reports c ON c.dump_site_id = d.id
     ${status ? 'WHERE d.status = $1' : ''}
     GROUP BY d.id
     ORDER BY d.created_at DESC`,
    status ? [status] : []
  );
  return res.json(rows.map(serializeDumpSite));
});

/* --------------------------- Get one site --------------------------- */
dumpSitesRouter.get('/:id', async (req, res) => {
  const site = await queryOne(`SELECT * FROM dump_sites WHERE id = $1`, [req.params.id]);
  if (!site) return res.status(404).json({ error: 'Not found.' });
  const cleanups = await query(
    `SELECT * FROM cleanup_reports WHERE dump_site_id = $1 ORDER BY created_at DESC`,
    [req.params.id]
  );
  return res.json({
    ...serializeDumpSite(site),
    cleanups: cleanups.map(serializeCleanup),
  });
});

/* ------------------------- Update a dump site ------------------------- */
// Only the reporter who created it can edit.
dumpSitesRouter.patch('/:id', requireAuth, async (req: AuthedRequest, res) => {
  const site = await queryOne(`SELECT reporter_id FROM dump_sites WHERE id = $1`, [req.params.id]);
  if (!site) return res.status(404).json({ error: 'Not found.' });
  if (site.reporter_id !== req.volunteer!.sub) {
    return res.status(403).json({ error: 'You can only edit your own reports.' });
  }

  const b = req.body ?? {};
  const schema = z.object({
    title: z.string().min(1).optional(),
    description: z.string().optional(),
    category: z.string().optional(),
    severity: z.string().optional(),
    status: z.enum(['reported', 'in_progress', 'cleaned']).optional(),
  });
  const parsed = schema.safeParse(b);
  if (!parsed.success) return res.status(400).json({ error: 'Invalid input.' });

  const fields: string[] = [];
  const values: any[] = [];
  let idx = 1;
  for (const [key, val] of Object.entries(parsed.data)) {
    if (val !== undefined) {
      fields.push(`${key} = $${idx}`);
      values.push(val);
      idx++;
    }
  }
  if (fields.length === 0) return res.status(400).json({ error: 'Nothing to update.' });

  fields.push(`updated_at = now()`);
  values.push(req.params.id);
  const row = await queryOne(
    `UPDATE dump_sites SET ${fields.join(', ')} WHERE id = $${idx} RETURNING *`,
    values
  );
  return res.json(serializeDumpSite(row));
});

/* ------------------------- Delete a dump site ------------------------- */
// Only the reporter who created it can delete.
dumpSitesRouter.delete('/:id', requireAuth, async (req: AuthedRequest, res) => {
  const site = await queryOne(`SELECT reporter_id FROM dump_sites WHERE id = $1`, [req.params.id]);
  if (!site) return res.status(404).json({ error: 'Not found.' });
  if (site.reporter_id !== req.volunteer!.sub) {
    return res.status(403).json({ error: 'You can only delete your own reports.' });
  }
  await query(`DELETE FROM dump_sites WHERE id = $1`, [req.params.id]);
  return res.json({ ok: true });
});

/* ------------------------- Update site status ------------------------- */
// Requires a logged-in volunteer.
dumpSitesRouter.patch('/:id/status', requireAuth, async (req, res) => {
  const schema = z.object({ status: z.enum(['reported', 'in_progress', 'cleaned']) });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: 'Invalid status.' });

  const row = await queryOne(
    `UPDATE dump_sites SET status = $1, updated_at = now() WHERE id = $2 RETURNING *`,
    [parsed.data.status, req.params.id]
  );
  if (!row) return res.status(404).json({ error: 'Not found.' });
  return res.json(serializeDumpSite(row));
});

/* --------------------- Cleanup reports for a site --------------------- */
dumpSitesRouter.get('/:id/cleanups', async (req, res) => {
  const rows = await query(
    `SELECT * FROM cleanup_reports WHERE dump_site_id = $1 ORDER BY created_at DESC`,
    [req.params.id]
  );
  return res.json(rows.map(serializeCleanup));
});

// Create a cleanup report. optionalAuth: website volunteers are logged in;
// mobile submissions may include a name without a login.
dumpSitesRouter.post(
  '/:id/cleanups',
  optionalAuth,
  upload.single('photo'),
  async (req: AuthedRequest, res) => {
    const b = req.body ?? {};
    const site = await queryOne(`SELECT id FROM dump_sites WHERE id = $1`, [req.params.id]);
    if (!site) return res.status(404).json({ error: 'Dump site not found.' });

    if (b.clientId) {
      const existing = await queryOne(`SELECT * FROM cleanup_reports WHERE client_id = $1`, [b.clientId]);
      if (existing) return res.status(200).json(serializeCleanup(existing));
    }

    const volunteerName = req.volunteer?.name ?? b.volunteerName ?? '';
    if (!volunteerName.trim()) {
      return res.status(400).json({ error: 'volunteerName is required.' });
    }

    const photoPath = req.file ? req.file.filename : null;
    const row = await queryOne(
      `INSERT INTO cleanup_reports
         (client_id, dump_site_id, volunteer_id, volunteer_name, notes, photo_path)
       VALUES ($1,$2,$3,$4,$5,$6)
       RETURNING *`,
      [
        b.clientId ?? null,
        req.params.id,
        req.volunteer?.sub ?? null,
        volunteerName,
        b.notes ?? '',
        photoPath,
      ]
    );
    return res.status(201).json(serializeCleanup(row));
  }
);
