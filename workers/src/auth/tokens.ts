import { Context } from 'hono';
import { SignJWT, jwtVerify } from 'jose';

export interface Env {
  DB: D1Database;
  JWT_SECRET: string;
  JWT_ACCESS_EXPIRY: string;
  JWT_REFRESH_EXPIRY: string;
}

const key = (secret: string) => new TextEncoder().encode(secret);
const digest = async (value: string) => Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256', new TextEncoder().encode(value))))
  .map((part) => part.toString(16).padStart(2, '0')).join('');

async function sign(env: Env, userId: string, type: 'access' | 'refresh', seconds: number) {
  return new SignJWT({ type }).setProtectedHeader({ alg: 'HS256' }).setSubject(userId)
    .setIssuedAt().setExpirationTime(`${seconds}s`).setJti(crypto.randomUUID()).sign(key(env.JWT_SECRET));
}

export async function createSession(env: Env, userId: string) {
  const accessSeconds = Number(env.JWT_ACCESS_EXPIRY || 900);
  const refreshSeconds = Number(env.JWT_REFRESH_EXPIRY || 2592000);
  const accessToken = await sign(env, userId, 'access', accessSeconds);
  const refreshToken = await sign(env, userId, 'refresh', refreshSeconds);
  await env.DB.prepare('INSERT INTO refresh_tokens (id,user_id,token_hash,expires_at,created_at) VALUES (?,?,?,?,?)')
    .bind(crypto.randomUUID(), userId, await digest(refreshToken), Date.now() + refreshSeconds * 1000, Date.now()).run();
  return { accessToken, refreshToken, expiresAt: new Date(Date.now() + accessSeconds * 1000).toISOString() };
}

export async function verifyToken(env: Env, token: string, type: 'access' | 'refresh') {
  const { payload } = await jwtVerify(token, key(env.JWT_SECRET), { algorithms: ['HS256'] });
  if (payload.type !== type || !payload.sub) throw new Error('Invalid token');
  return payload;
}

export async function refresh(c: Context<{ Bindings: Env }>) {
  const body = await c.req.json<{ refreshToken?: string }>().catch(() => ({} as { refreshToken?: string }));
  if (!body.refreshToken) return jsonError(c, 'Refresh token obbligatorio', 400);
  try {
    const refreshToken = body.refreshToken;
    const payload = await verifyToken(c.env, refreshToken, 'refresh');
    const hash = await digest(refreshToken);
    const stored = await c.env.DB.prepare('SELECT id FROM refresh_tokens WHERE token_hash = ? AND expires_at > ?')
      .bind(hash, Date.now()).first<{ id: string }>();
    if (!stored) return jsonError(c, 'Refresh token non valido', 401);
    await c.env.DB.prepare('DELETE FROM refresh_tokens WHERE id = ?').bind(stored.id).run();
    const user = await c.env.DB.prepare('SELECT id,email,display_name,created_at FROM users WHERE id = ?')
      .bind(payload.sub).first<Record<string, unknown>>();
    if (!user) return jsonError(c, 'Utente non trovato', 401);
    return c.json({ data: { user: publicUser(user), tokens: await createSession(c.env, payload.sub!) }, error: null });
  } catch { return jsonError(c, 'Refresh token non valido', 401); }
}

export async function logout(c: Context<{ Bindings: Env; Variables: { userId: string } }>) {
  await c.env.DB.prepare('DELETE FROM refresh_tokens WHERE user_id = ?').bind(c.get('userId')).run();
  return c.json({ data: null, error: null });
}

export const publicUser = (row: Record<string, unknown>) => ({
  id: row.id, email: row.email, displayName: row.display_name, createdAt: new Date(Number(row.created_at)).toISOString(),
});
export const jsonError = (c: Context, error: string, status: 400 | 401 | 403 | 404 | 409 | 500) =>
  c.json({ data: null, error }, status);
