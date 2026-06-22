import { createMiddleware } from 'hono/factory';
import { Env, verifyToken } from '../auth/tokens';

export const authMiddleware = createMiddleware<{ Bindings: Env; Variables: { userId: string } }>(async (c, next) => {
  const header = c.req.header('Authorization');
  if (!header?.startsWith('Bearer ')) return c.json({ data: null, error: 'Autenticazione richiesta' }, 401);
  try {
    const payload = await verifyToken(c.env, header.slice(7), 'access');
    c.set('userId', payload.sub!);
    return next();
  } catch { return c.json({ data: null, error: 'Token non valido o scaduto' }, 401); }
});
