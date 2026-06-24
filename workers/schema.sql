-- SpendWise — Cloudflare D1 Schema
-- Eseguire con: wrangler d1 execute spendwise-db --file=schema.sql

CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  display_name TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS refresh_tokens (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  token_hash TEXT NOT NULL,
  expires_at INTEGER NOT NULL,
  created_at INTEGER NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS categories (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  type TEXT NOT NULL CHECK(type IN ('daily','subscription','installment','vehicle')),
  name TEXT NOT NULL,
  color TEXT,
  icon TEXT,
  is_default INTEGER DEFAULT 0,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS daily_expenses (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  category_id TEXT,
  amount REAL NOT NULL,
  description TEXT,
  date INTEGER NOT NULL,
  note TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  synced INTEGER DEFAULT 0,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS subscriptions (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  name TEXT NOT NULL,
  amount REAL NOT NULL,
  currency TEXT DEFAULT 'EUR',
  billing_cycle TEXT NOT NULL CHECK(billing_cycle IN ('weekly','monthly','yearly')),
  billing_day INTEGER,
  start_date INTEGER NOT NULL,
  end_date INTEGER,
  next_due_date INTEGER,
  recurrence_months INTEGER,
  url TEXT,
  icon TEXT,
  color TEXT,
  is_active INTEGER DEFAULT 1,
  note TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  synced INTEGER DEFAULT 0,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS subscription_payments (
  id TEXT PRIMARY KEY,
  subscription_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  amount REAL NOT NULL,
  paid_date INTEGER NOT NULL,
  due_date INTEGER NOT NULL,
  status TEXT DEFAULT 'paid' CHECK(status IN ('paid','pending','failed')),
  FOREIGN KEY (subscription_id) REFERENCES subscriptions(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS installment_plans (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  name TEXT NOT NULL,
  provider TEXT,
  total_amount REAL NOT NULL,
  installment_amount REAL NOT NULL,
  total_installments INTEGER NOT NULL,
  paid_installments INTEGER DEFAULT 0,
  frequency TEXT NOT NULL CHECK(frequency IN ('weekly','biweekly','monthly')),
  start_date INTEGER NOT NULL,
  next_due_date INTEGER,
  is_active INTEGER DEFAULT 1,
  note TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  synced INTEGER DEFAULT 0,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS installment_payments (
  id TEXT PRIMARY KEY,
  plan_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  installment_number INTEGER NOT NULL,
  amount REAL NOT NULL,
  due_date INTEGER NOT NULL,
  paid_date INTEGER,
  status TEXT DEFAULT 'pending' CHECK(status IN ('pending','paid','overdue')),
  FOREIGN KEY (plan_id) REFERENCES installment_plans(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS vehicles (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  name TEXT NOT NULL,
  plate TEXT,
  brand TEXT,
  model TEXT,
  year INTEGER,
  fuel_type TEXT CHECK(fuel_type IN ('gasoline','diesel','electric','hybrid','lpg')),
  is_archived INTEGER DEFAULT 0,
  created_at INTEGER NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS fuel_entries (
  id TEXT PRIMARY KEY,
  vehicle_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  date INTEGER NOT NULL,
  liters REAL NOT NULL,
  price_per_liter REAL NOT NULL,
  total_cost REAL NOT NULL,
  station_name TEXT,
  km_odometer INTEGER,
  is_full_tank INTEGER DEFAULT 1,
  note TEXT,
  created_at INTEGER NOT NULL,
  synced INTEGER DEFAULT 0,
  FOREIGN KEY (vehicle_id) REFERENCES vehicles(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS vehicle_maintenance (
  id TEXT PRIMARY KEY,
  vehicle_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  date INTEGER NOT NULL,
  item_name TEXT NOT NULL,
  part_code TEXT,
  category TEXT CHECK(category IN ('tagliando','pneumatici','freni','elettrico','batteria','carrozzeria','altro')),
  price REAL NOT NULL,
  quantity INTEGER DEFAULT 1,
  total_cost REAL NOT NULL,
  shop_name TEXT,
  shop_url TEXT,
  km_at_service INTEGER,
  next_service_km INTEGER,
  next_service_date INTEGER,
  warranty_months INTEGER,
  receipt_url TEXT,
  items_json TEXT,
  note TEXT,
  created_at INTEGER NOT NULL,
  synced INTEGER DEFAULT 0,
  FOREIGN KEY (vehicle_id) REFERENCES vehicles(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS vehicle_accessories (
  id TEXT PRIMARY KEY,
  vehicle_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  date INTEGER NOT NULL,
  item_name TEXT NOT NULL,
  part_code TEXT,
  category TEXT DEFAULT 'altro',
  price REAL NOT NULL,
  quantity INTEGER DEFAULT 1,
  total_cost REAL NOT NULL,
  shop_name TEXT,
  shop_url TEXT,
  km_at_service INTEGER,
  next_service_km INTEGER,
  next_service_date INTEGER,
  warranty_months INTEGER,
  receipt_url TEXT,
  items_json TEXT,
  note TEXT,
  created_at INTEGER NOT NULL,
  synced INTEGER DEFAULT 0,
  FOREIGN KEY (vehicle_id) REFERENCES vehicles(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS sync_queue (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  table_name TEXT NOT NULL,
  record_id TEXT NOT NULL,
  operation TEXT NOT NULL CHECK(operation IN ('insert','update','delete')),
  payload TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  attempts INTEGER DEFAULT 0,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Indici per performance
CREATE INDEX IF NOT EXISTS idx_daily_expenses_user_date ON daily_expenses(user_id, date);
CREATE INDEX IF NOT EXISTS idx_subscriptions_user ON subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_installment_plans_user ON installment_plans(user_id);
CREATE INDEX IF NOT EXISTS idx_vehicles_user ON vehicles(user_id);
CREATE INDEX IF NOT EXISTS idx_fuel_entries_vehicle_date ON fuel_entries(vehicle_id, date);
CREATE INDEX IF NOT EXISTS idx_vehicle_maintenance_vehicle ON vehicle_maintenance(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_vehicle_accessories_vehicle ON vehicle_accessories(vehicle_id);
