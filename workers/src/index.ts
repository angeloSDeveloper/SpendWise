import { Hono } from 'hono';
import { register } from './auth/register';
import { login } from './auth/login';
import { Env, logout, refresh } from './auth/tokens';
import { authMiddleware } from './middleware/auth';
import { corsMiddleware } from './middleware/cors';

type Variables = { userId: string };
type AppContext = { Bindings: Env; Variables: Variables };
const app = new Hono<AppContext>();
app.use('*', corsMiddleware);
app.onError((error, c) => {
  console.error(error);
  return c.json({ data: null, error: 'Errore interno del server' }, 500);
});
app.get('/api/health', (c) => c.json({ data: { status: 'ok' }, error: null }));
app.post('/api/auth/register', register);
app.post('/api/auth/login', login);
app.post('/api/auth/refresh', refresh);
app.use('/api/*', authMiddleware);
app.post('/api/auth/logout', logout);

const resources = {
  expenses: { table: 'daily_expenses', fields: ['category_id','amount','description','date','note'] },
  subscriptions: { table: 'subscriptions', fields: ['name','amount','currency','billing_cycle','billing_day','start_date','end_date','url','icon','color','is_active','note'] },
  installments: { table: 'installment_plans', fields: ['name','provider','total_amount','installment_amount','total_installments','paid_installments','frequency','start_date','next_due_date','is_active','note'] },
  vehicles: { table: 'vehicles', fields: ['name','plate','brand','model','year','fuel_type'] },
} as const;

const bodyValue = (body: Record<string, unknown>, snake: string) => {
  const camel = snake.replace(/_([a-z])/g, (_, char: string) => char.toUpperCase());
  return body[snake] ?? body[camel] ?? null;
};
const serialize = (row: Record<string, unknown>) => Object.fromEntries(Object.entries(row).map(([key, value]) => [
  key.replace(/_([a-z])/g, (_, char: string) => char.toUpperCase()),
  (key.endsWith('_at') || key === 'date' || key.endsWith('_date')) && typeof value === 'number' ? new Date(value).toISOString() : value,
]));

for (const [path, config] of Object.entries(resources)) {
  app.get(`/api/${path}`, async (c) => {
    const conditions = ['user_id = ?'];
    const values: unknown[] = [c.get('userId')];
    if (path === 'expenses') {
      const from = c.req.query('from'); const to = c.req.query('to'); const category = c.req.query('category');
      if (from) { conditions.push('date >= ?'); values.push(Date.parse(from)); }
      if (to) { conditions.push('date <= ?'); values.push(Date.parse(to)); }
      if (category) { conditions.push('category_id = ?'); values.push(category); }
    }
    const result = await c.env.DB.prepare(`SELECT * FROM ${config.table} WHERE ${conditions.join(' AND ')} ORDER BY ${path === 'vehicles' ? 'created_at' : path === 'expenses' ? 'date' : 'updated_at'} DESC`).bind(...values).all<Record<string, unknown>>();
    return c.json({ data: result.results.map(serialize), error: null });
  });
  app.post(`/api/${path}`, async (c) => {
    const body = await c.req.json<Record<string, unknown>>().catch(() => ({} as Record<string, unknown>));
    const required = path === 'expenses' ? ['amount','date'] : path === 'vehicles' ? ['name'] : path === 'installments' ? ['name','total_amount','installment_amount','total_installments','frequency','start_date'] : ['name','amount','billing_cycle','start_date'];
    if (required.some((field) => bodyValue(body, field) == null)) return c.json({ data: null, error: 'Campi obbligatori mancanti' }, 400);
    const id = typeof body.id === 'string' ? body.id : crypto.randomUUID();
    const now = Date.now();
    const fields = [...config.fields]; const values = fields.map((field) => bodyValue(body, field));
    const extraFields = config.table === 'vehicles' ? ['created_at'] : ['created_at','updated_at'];
    await c.env.DB.prepare(`INSERT INTO ${config.table} (id,user_id,${fields.join(',')},${extraFields.join(',')}) VALUES (${Array(2 + fields.length + extraFields.length).fill('?').join(',')})`)
      .bind(id, c.get('userId'), ...values, ...extraFields.map(() => now)).run();
    const row = await c.env.DB.prepare(`SELECT * FROM ${config.table} WHERE id = ?`).bind(id).first<Record<string, unknown>>();
    return c.json({ data: serialize(row!), error: null }, 201);
  });
  app.put(`/api/${path}/:id`, async (c) => {
    const body = await c.req.json<Record<string, unknown>>().catch(() => ({} as Record<string, unknown>));
    const fields = config.fields.filter((field) => bodyValue(body, field) !== null);
    if (!fields.length) return c.json({ data: null, error: 'Nessun campo da aggiornare' }, 400);
    const set = fields.map((field) => `${field} = ?`);
    if (config.table !== 'vehicles') set.push('updated_at = ?');
    const result = await c.env.DB.prepare(`UPDATE ${config.table} SET ${set.join(',')} WHERE id = ? AND user_id = ?`)
      .bind(...fields.map((field) => bodyValue(body, field)), ...(config.table === 'vehicles' ? [] : [Date.now()]), c.req.param('id'), c.get('userId')).run();
    if (!result.meta.changes) return c.json({ data: null, error: 'Risorsa non trovata' }, 404);
    const row = await c.env.DB.prepare(`SELECT * FROM ${config.table} WHERE id = ?`).bind(c.req.param('id')).first<Record<string, unknown>>();
    return c.json({ data: serialize(row!), error: null });
  });
  app.delete(`/api/${path}/:id`, async (c) => {
    const result = await c.env.DB.prepare(`DELETE FROM ${config.table} WHERE id = ? AND user_id = ?`).bind(c.req.param('id'), c.get('userId')).run();
    return result.meta.changes ? c.json({ data: null, error: null }) : c.json({ data: null, error: 'Risorsa non trovata' }, 404);
  });
}

const childResource = (kind: 'fuel' | 'maintenance') => kind === 'fuel'
  ? { table: 'fuel_entries', fields: ['date','liters','price_per_liter','total_cost','station_name','km_odometer','is_full_tank','note'] }
  : { table: 'vehicle_maintenance', fields: ['date','item_name','part_code','category','price','quantity','total_cost','shop_name','shop_url','km_at_service','next_service_km','next_service_date','warranty_months','receipt_url','note'] };
for (const kind of ['fuel','maintenance'] as const) {
  const config = childResource(kind);
  app.get(`/api/vehicles/:id/${kind}`, async (c) => {
    const rows = await c.env.DB.prepare(`SELECT * FROM ${config.table} WHERE vehicle_id = ? AND user_id = ? ORDER BY date DESC`)
      .bind(c.req.param('id'), c.get('userId')).all<Record<string, unknown>>();
    return c.json({ data: rows.results.map(serialize), error: null });
  });
  app.post(`/api/vehicles/:id/${kind}`, async (c) => {
    const owns = await c.env.DB.prepare('SELECT id FROM vehicles WHERE id = ? AND user_id = ?').bind(c.req.param('id'), c.get('userId')).first();
    if (!owns) return c.json({ data: null, error: 'Veicolo non trovato' }, 404);
    const body = await c.req.json<Record<string, unknown>>().catch(() => ({} as Record<string, unknown>));
    const id = crypto.randomUUID(); const now = Date.now();
    await c.env.DB.prepare(`INSERT INTO ${config.table} (id,vehicle_id,user_id,${config.fields.join(',')},created_at) VALUES (${Array(config.fields.length + 4).fill('?').join(',')})`)
      .bind(id, c.req.param('id'), c.get('userId'), ...config.fields.map((field) => bodyValue(body, field)), now).run();
    const row = await c.env.DB.prepare(`SELECT * FROM ${config.table} WHERE id = ?`).bind(id).first<Record<string, unknown>>();
    return c.json({ data: serialize(row!), error: null }, 201);
  });
  app.put(`/api/vehicles/:id/${kind}/:childId`, async (c) => {
    const body = await c.req.json<Record<string, unknown>>().catch(() => ({} as Record<string, unknown>));
    const fields = config.fields.filter((field) => bodyValue(body, field) !== null);
    if (!fields.length) return c.json({ data: null, error: 'Nessun campo da aggiornare' }, 400);
    const result = await c.env.DB.prepare(`UPDATE ${config.table} SET ${fields.map((f) => `${f} = ?`).join(',')} WHERE id = ? AND vehicle_id = ? AND user_id = ?`)
      .bind(...fields.map((field) => bodyValue(body, field)), c.req.param('childId'), c.req.param('id'), c.get('userId')).run();
    return result.meta.changes ? c.json({ data: { id: c.req.param('childId') }, error: null }) : c.json({ data: null, error: 'Risorsa non trovata' }, 404);
  });
  app.delete(`/api/vehicles/:id/${kind}/:childId`, async (c) => {
    const result = await c.env.DB.prepare(`DELETE FROM ${config.table} WHERE id = ? AND vehicle_id = ? AND user_id = ?`)
      .bind(c.req.param('childId'), c.req.param('id'), c.get('userId')).run();
    return result.meta.changes ? c.json({ data: null, error: null }) : c.json({ data: null, error: 'Risorsa non trovata' }, 404);
  });
}

app.post('/api/installments/:id/pay-installment', async (c) => {
  const userId = c.get('userId'); const id = c.req.param('id');
  const plan = await c.env.DB.prepare('SELECT * FROM installment_plans WHERE id = ? AND user_id = ?').bind(id, userId).first<Record<string, unknown>>();
  if (!plan) return c.json({ data: null, error: 'Piano non trovato' }, 404);
  const paid = Number(plan.paid_installments) + 1;
  if (paid > Number(plan.total_installments)) return c.json({ data: null, error: 'Piano già completato' }, 409);
  await c.env.DB.batch([
    c.env.DB.prepare('INSERT INTO installment_payments (id,plan_id,user_id,installment_number,amount,due_date,paid_date,status) VALUES (?,?,?,?,?,?,?,?)')
      .bind(crypto.randomUUID(), id, userId, paid, plan.installment_amount, plan.next_due_date || Date.now(), Date.now(), 'paid'),
    c.env.DB.prepare('UPDATE installment_plans SET paid_installments = ?, is_active = ?, updated_at = ? WHERE id = ?')
      .bind(paid, paid < Number(plan.total_installments) ? 1 : 0, Date.now(), id),
  ]);
  return c.json({ data: { paidInstallments: paid }, error: null });
});

app.post('/api/sync/push', async (c) => {
  type Operation = { table?: string; recordId?: string; operation?: string; payload?: string | Record<string, unknown> };
  const body = await c.req.json<{ operations?: Operation[] }>().catch(() => ({} as { operations?: Operation[] }));
  const configs: Record<string, { fields: readonly string[] }> = {
    daily_expenses: resources.expenses, subscriptions: resources.subscriptions,
    installment_plans: resources.installments, vehicles: resources.vehicles,
    fuel_entries: childResource('fuel'), vehicle_maintenance: childResource('maintenance'),
  };
  const statements: D1PreparedStatement[] = [];
  for (const operation of body.operations || []) {
    const config = operation.table ? configs[operation.table] : null;
    if (!config || !operation.recordId || !['insert','update','delete'].includes(operation.operation || '')) {
      return c.json({ data: null, error: 'Operazione di sincronizzazione non valida' }, 400);
    }
    if (operation.operation === 'delete') {
      statements.push(c.env.DB.prepare(`DELETE FROM ${operation.table} WHERE id = ? AND user_id = ?`).bind(operation.recordId, c.get('userId')));
      continue;
    }
    let payload: Record<string, unknown>;
    try { payload = typeof operation.payload === 'string' ? JSON.parse(operation.payload) as Record<string, unknown> : operation.payload || {}; }
    catch { return c.json({ data: null, error: 'Payload di sincronizzazione non valido' }, 400); }
    const fields = config.fields.filter((field) => bodyValue(payload, field) !== null);
    if (operation.operation === 'insert') {
      const now = Date.now(); const timestampFields = operation.table === 'vehicles' || operation.table === 'fuel_entries' || operation.table === 'vehicle_maintenance' ? ['created_at'] : ['created_at','updated_at'];
      const columns = ['id','user_id',...fields,...timestampFields];
      statements.push(c.env.DB.prepare(`INSERT OR REPLACE INTO ${operation.table} (${columns.join(',')}) VALUES (${columns.map(() => '?').join(',')})`)
        .bind(operation.recordId, c.get('userId'), ...fields.map((field) => bodyValue(payload, field)), ...timestampFields.map((field) => bodyValue(payload, field) ?? now)));
    } else if (fields.length) {
      const set = fields.map((field) => `${field} = ?`);
      if (!['vehicles','fuel_entries','vehicle_maintenance'].includes(operation.table!)) set.push('updated_at = ?');
      statements.push(c.env.DB.prepare(`UPDATE ${operation.table} SET ${set.join(',')} WHERE id = ? AND user_id = ?`)
        .bind(...fields.map((field) => bodyValue(payload, field)), ...(!['vehicles','fuel_entries','vehicle_maintenance'].includes(operation.table!) ? [Date.now()] : []), operation.recordId, c.get('userId')));
    }
  }
  if (statements.length) await c.env.DB.batch(statements);
  return c.json({ data: { accepted: statements.length, syncedAt: new Date().toISOString() }, error: null });
});
app.get('/api/sync/pull', async (c) => {
  const since = Number(c.req.query('since') || 0); const userId = c.get('userId');
  const changes: Record<string, unknown[]> = {};
  for (const config of Object.values(resources)) {
    if (config.table === 'vehicles') continue;
    const rows = await c.env.DB.prepare(`SELECT * FROM ${config.table} WHERE user_id = ? AND updated_at > ?`).bind(userId, since).all<Record<string, unknown>>();
    changes[config.table] = rows.results.map(serialize);
  }
  return c.json({ data: { changes, syncedAt: new Date().toISOString() }, error: null });
});
app.notFound((c) => c.req.path.startsWith('/api/')
  ? c.json({ data: null, error: 'Endpoint non trovato' }, 404)
  : c.env.ASSETS.fetch(c.req.raw));

export default app;
