import { config } from './config';

function photoUrl(photoPath: string | null): string | null {
  if (!photoPath) return null;
  return `${config.publicUrl}/uploads/${photoPath}`;
}

export function serializeDumpSite(row: any) {
  return {
    id: row.id,
    clientId: row.client_id,
    title: row.title,
    description: row.description,
    category: row.category,
    severity: row.severity,
    status: row.status,
    latitude: row.latitude,
    longitude: row.longitude,
    accuracy: row.accuracy,
    altitude: row.altitude,
    photoUrl: photoUrl(row.photo_path),
    reporterName: row.reporter_name,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
    cleanupCount: row.cleanup_count != null ? Number(row.cleanup_count) : undefined,
  };
}

export function serializeCleanup(row: any) {
  return {
    id: row.id,
    clientId: row.client_id,
    dumpSiteId: row.dump_site_id,
    volunteerId: row.volunteer_id,
    volunteerName: row.volunteer_name,
    notes: row.notes,
    photoUrl: photoUrl(row.photo_path),
    createdAt: row.created_at,
  };
}
