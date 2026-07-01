import { Context } from 'hono';
import bcrypt from 'bcryptjs';
import { createSession, Env, jsonError, publicUser } from './tokens';

export async function login(c: Context<{ Bindings: Env }>) {
  const body = await c.req.json<{ email?: string; password?: string }>().catch(() => ({} as { email?: string; password?: string }));
  if (!body.email || !body.password) return jsonError(c, 'Email e password sono obbligatorie', 400);
  const user = await c.env.DB.prepare(
    'SELECT id,email,password_hash,display_name,role,created_at FROM users WHERE email = ?',
  ).bind(body.email.trim().toLowerCase()).first<Record<string, unknown>>();
  if (!user || !(await bcrypt.compare(body.password, String(user.password_hash)))) {
    return jsonError(c, 'Credenziali non valide', 401);
  }
  return c.json({ data: { user: publicUser(user), tokens: await createSession(c.env, String(user.id)) }, error: null });
}
