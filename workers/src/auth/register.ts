import { Context } from 'hono';
import bcrypt from 'bcryptjs';
import { createSession, Env, jsonError, publicUser } from './tokens';

const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const passwordPattern = /^(?=.*[A-Z])(?=.*\d).{8,}$/;

export async function register(c: Context<{ Bindings: Env }>) {
  const body = await c.req.json<{ email?: string; password?: string; name?: string }>().catch(() => ({} as { email?: string; password?: string; name?: string }));
  const email = body.email?.trim().toLowerCase();
  if (!email || !emailPattern.test(email)) return jsonError(c, 'Email non valida', 400);
  if (!body.password || !passwordPattern.test(body.password)) {
    return jsonError(c, 'La password deve avere almeno 8 caratteri, una maiuscola e un numero', 400);
  }
  const existing = await c.env.DB.prepare('SELECT id FROM users WHERE email = ?').bind(email).first();
  if (existing) return jsonError(c, 'Email già registrata', 409);

  const id = crypto.randomUUID();
  const now = Date.now();
  const hash = await bcrypt.hash(body.password, 12);
  await c.env.DB.prepare(
    'INSERT INTO users (id,email,password_hash,display_name,created_at,updated_at) VALUES (?,?,?,?,?,?)',
  ).bind(id, email, hash, body.name?.trim() || null, now, now).run();
  const user = { id, email, display_name: body.name?.trim() || null, created_at: now };
  return c.json({ data: { user: publicUser(user), tokens: await createSession(c.env, id) }, error: null }, 201);
}
