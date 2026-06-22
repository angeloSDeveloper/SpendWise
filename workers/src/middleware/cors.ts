import { createMiddleware } from 'hono/factory';

const allowed = (origin: string) => /^http:\/\/localhost(?::\d+)?$/.test(origin)
  || /^https:\/\/[^/]+\.pages\.dev$/.test(origin) || origin === 'https://spendwise.it';

export const corsMiddleware = createMiddleware(async (c, next) => {
  const origin = c.req.header('Origin') || '';
  if (origin && allowed(origin)) c.header('Access-Control-Allow-Origin', origin);
  c.header('Vary', 'Origin');
  c.header('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With');
  c.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  if (c.req.method === 'OPTIONS') return c.body(null, 204);
  return next();
});
