# SpendWise — Specifiche di Progetto

> App Flutter multipiattaforma per la gestione intelligente delle spese personali  
> Versione spec: 1.0 | Data: Giugno 2026

---

## 1. Panoramica del Prodotto

**SpendWise** è un'applicazione cross-platform sviluppata in Flutter che consente agli utenti di tracciare, categorizzare e analizzare le proprie spese. L'app è progettata per coprire molteplici scenari d'uso quotidiano: spese ricorrenti, abbonamenti, rateizzazioni e gestione veicolo.

### Target
- Utenti singoli che vogliono tenere sotto controllo le finanze personali
- Multipiattaforma: Android (Play Store), iOS (App Store futuro), Web (Cloudflare Pages)

### Principi di design
- Mobile-first, responsive fino a desktop
- UI coerente ma adattata per categoria
- Offline-first con sync cloud
- Onboarding rapido, nessuna curva di apprendimento

---

## 2. Architettura Tecnica

### Stack

| Layer | Tecnologia |
|---|---|
| Frontend | Flutter 3.x (Dart) |
| State Management | Riverpod 2.x |
| Navigazione | GoRouter |
| DB Locale | Drift (SQLite) |
| DB Cloud | Cloudflare D1 (SQLite serverless) |
| Auth | Cloudflare Workers + JWT + bcrypt |
| API Backend | Cloudflare Workers (TypeScript) |
| Hosting Web | Cloudflare Pages |
| Storage file | Cloudflare R2 (futuro, per ricevute) |
| HTTP Client | Dio + Retrofit |
| Serializzazione | Freezed + JsonSerializable |
| UI Components | Material 3 + custom widgets |
| Charts | fl_chart |
| Internazionalizzazione | flutter_localizations (IT + EN) |

### Architettura App

```
lib/
├── main.dart
├── app/
│   ├── router.dart              # GoRouter config
│   ├── theme.dart               # Material3 theme
│   └── app.dart
├── core/
│   ├── constants/
│   ├── extensions/
│   ├── utils/
│   └── errors/
├── data/
│   ├── local/
│   │   ├── database.dart        # Drift DB
│   │   └── daos/                # Data Access Objects
│   ├── remote/
│   │   ├── api_client.dart      # Dio/Retrofit
│   │   └── endpoints/
│   └── repositories/
├── domain/
│   ├── models/                  # Freezed models
│   ├── repositories/            # Abstract interfaces
│   └── usecases/
├── presentation/
│   ├── auth/
│   │   ├── login/
│   │   └── register/
│   ├── dashboard/
│   ├── categories/
│   │   ├── daily/               # Spese quotidiane
│   │   ├── subscriptions/       # Abbonamenti
│   │   ├── installments/        # Rateizzazioni
│   │   └── vehicle/             # Gestione auto
│   ├── analytics/
│   ├── settings/
│   └── shared/
│       ├── widgets/
│       └── providers/
└── l10n/
    ├── app_it.arb
    └── app_en.arb
```

### Backend (Cloudflare Workers)

```
workers/
├── src/
│   ├── index.ts                 # Entry point router
│   ├── auth/
│   │   ├── register.ts
│   │   ├── login.ts
│   │   └── refresh.ts
│   ├── expenses/
│   │   ├── daily.ts
│   │   ├── subscriptions.ts
│   │   ├── installments.ts
│   │   └── vehicle.ts
│   ├── sync/
│   │   └── sync.ts              # Offline sync logic
│   └── middleware/
│       ├── auth.ts              # JWT verification
│       └── cors.ts
├── schema.sql                   # D1 schema
└── wrangler.toml
```

---

## 3. Database Schema

### Users
```sql
CREATE TABLE users (
  id TEXT PRIMARY KEY,              -- UUID
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  display_name TEXT,
  created_at INTEGER NOT NULL,      -- Unix timestamp
  updated_at INTEGER NOT NULL
);
```

### Categorie principali
```sql
CREATE TABLE categories (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  type TEXT NOT NULL,               -- 'daily'|'subscription'|'installment'|'vehicle'
  name TEXT NOT NULL,
  color TEXT,                       -- hex color
  icon TEXT,                        -- icon name
  is_default INTEGER DEFAULT 0,
  FOREIGN KEY (user_id) REFERENCES users(id)
);
```

### Spese quotidiane
```sql
CREATE TABLE daily_expenses (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  category_id TEXT,
  amount REAL NOT NULL,
  description TEXT,
  date INTEGER NOT NULL,            -- Unix timestamp
  note TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  synced INTEGER DEFAULT 0,
  FOREIGN KEY (user_id) REFERENCES users(id)
);
```

### Abbonamenti
```sql
CREATE TABLE subscriptions (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  name TEXT NOT NULL,               -- 'Netflix', 'Spotify', ecc.
  amount REAL NOT NULL,
  currency TEXT DEFAULT 'EUR',
  billing_cycle TEXT NOT NULL,      -- 'weekly'|'monthly'|'yearly'
  billing_day INTEGER,              -- giorno del mese/settimana
  start_date INTEGER NOT NULL,
  end_date INTEGER,                 -- null = indefinito
  url TEXT,
  icon TEXT,
  color TEXT,
  is_active INTEGER DEFAULT 1,
  note TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  synced INTEGER DEFAULT 0,
  FOREIGN KEY (user_id) REFERENCES users(id)
);
```

### Pagamenti abbonamenti (storico)
```sql
CREATE TABLE subscription_payments (
  id TEXT PRIMARY KEY,
  subscription_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  amount REAL NOT NULL,
  paid_date INTEGER NOT NULL,
  due_date INTEGER NOT NULL,
  status TEXT DEFAULT 'paid',       -- 'paid'|'pending'|'failed'
  FOREIGN KEY (subscription_id) REFERENCES subscriptions(id)
);
```

### Rateizzazioni (Klarna, ecc.)
```sql
CREATE TABLE installment_plans (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  name TEXT NOT NULL,               -- es. 'iPhone 15 - Klarna'
  provider TEXT,                    -- 'Klarna', 'Scalapay', ecc.
  total_amount REAL NOT NULL,
  installment_amount REAL NOT NULL,
  total_installments INTEGER NOT NULL,
  paid_installments INTEGER DEFAULT 0,
  frequency TEXT NOT NULL,          -- 'weekly'|'biweekly'|'monthly'
  start_date INTEGER NOT NULL,
  next_due_date INTEGER,
  is_active INTEGER DEFAULT 1,
  note TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  synced INTEGER DEFAULT 0,
  FOREIGN KEY (user_id) REFERENCES users(id)
);
```

### Rate pagate
```sql
CREATE TABLE installment_payments (
  id TEXT PRIMARY KEY,
  plan_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  installment_number INTEGER NOT NULL,
  amount REAL NOT NULL,
  due_date INTEGER NOT NULL,
  paid_date INTEGER,
  status TEXT DEFAULT 'pending',    -- 'pending'|'paid'|'overdue'
  FOREIGN KEY (plan_id) REFERENCES installment_plans(id)
);
```

### Veicoli
```sql
CREATE TABLE vehicles (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  name TEXT NOT NULL,               -- 'Fiat 500', 'Moto'
  plate TEXT,
  brand TEXT,
  model TEXT,
  year INTEGER,
  fuel_type TEXT,                   -- 'gasoline'|'diesel'|'electric'|'hybrid'
  created_at INTEGER NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id)
);
```

### Rifornimenti
```sql
CREATE TABLE fuel_entries (
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
  FOREIGN KEY (vehicle_id) REFERENCES vehicles(id)
);
```

### Pezzi / Manutenzione auto
```sql
CREATE TABLE vehicle_maintenance (
  id TEXT PRIMARY KEY,
  vehicle_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  date INTEGER NOT NULL,
  item_name TEXT NOT NULL,          -- 'Filtro olio', 'Pneumatici', ecc.
  part_code TEXT,                   -- codice identificativo pezzo
  category TEXT,                    -- 'tagliando'|'pneumatici'|'freni'|'altro'
  price REAL NOT NULL,
  quantity INTEGER DEFAULT 1,
  total_cost REAL NOT NULL,
  shop_name TEXT,                   -- officina o sito e-commerce
  shop_url TEXT,                    -- link sito acquisto
  km_at_service INTEGER,
  next_service_km INTEGER,
  next_service_date INTEGER,
  warranty_months INTEGER,
  receipt_url TEXT,                 -- R2 storage futuro
  note TEXT,
  created_at INTEGER NOT NULL,
  synced INTEGER DEFAULT 0,
  FOREIGN KEY (vehicle_id) REFERENCES vehicles(id)
);
```

### Sync log (offline)
```sql
CREATE TABLE sync_queue (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  table_name TEXT NOT NULL,
  record_id TEXT NOT NULL,
  operation TEXT NOT NULL,          -- 'insert'|'update'|'delete'
  payload TEXT NOT NULL,            -- JSON
  created_at INTEGER NOT NULL,
  attempts INTEGER DEFAULT 0
);
```

---

## 4. Funzionalità per Categoria

### 4.1 Spese Quotidiane
- Aggiunta veloce spesa (floating action button)
- Categorizzazione (caffè, spesa, parcheggio, ecc.)
- Vista giornaliera / settimanale / mensile
- Ricerca e filtri
- Export CSV

### 4.2 Abbonamenti
- Card visiva per ogni abbonamento con logo/icona
- Prossimo rinnovo evidenziato
- Costo mensile aggregato (anche abbonamenti annuali divisi per 12)
- Notifiche push pre-scadenza (3 giorni prima)
- Timeline rinnovi mensile
- Badge "in scadenza" / "attivo" / "sospeso"

### 4.3 Rateizzazioni
- Progress bar rate pagate/totali
- Contatore rate rimanenti e importo residuo
- Calendario scadenze
- Alert rate in scadenza questa settimana
- Supporto frequenze: settimanale, bisettimanale, mensile

### 4.4 Gestione Veicolo
- Multi-veicolo (es. auto + moto)
- **Rifornimenti**: storico con grafici prezzo/litro, km percorsi, consumo medio
- **Manutenzione**: elenco pezzi con codice, prezzo, negozio, link, data
  - Filtro per tipo (tagliando, pneumatici, freni, ecc.)
  - Promemoria prossima revisione (data o km)
  - Link diretto al sito di acquisto

---

## 5. UI/UX Design System

### Palette colori (Material 3)
```
Primary:     #2563EB  (blue-600) — azioni principali
Secondary:   #7C3AED  (violet-600) — accenti
Surface:     #F8FAFC  (slate-50) — sfondo
Error:       #DC2626  (red-600)
Success:     #16A34A  (green-600)
Warning:     #D97706  (amber-600)

Categorie:
Daily:       #F59E0B  (amber-500)
Subscription:#8B5CF6  (violet-500)
Installment: #EC4899  (pink-500)
Vehicle:     #10B981  (emerald-500)
```

### Tipografia
- Display: `Plus Jakarta Sans` (bold, headings)
- Body: `Inter` (regular/medium, testo)
- Mono: `JetBrains Mono` (codici pezzi auto, importi)

### Componenti chiave
- `ExpenseCard` — card universale spesa con colore categoria
- `CategoryHeader` — header colorato specifico per sezione
- `AmountDisplay` — mostra importo con colore (verde/rosso)
- `SubscriptionCard` — card con logo, importo, badge stato
- `InstallmentProgress` — barra progresso rate
- `FuelCard` — card rifornimento con icona pompa
- `MaintenanceItem` — item lista con part code e link

### Responsive Breakpoints
```
Mobile:   < 600px   → 1 colonna, bottom nav
Tablet:   600-1024px → 2 colonne, bottom nav
Desktop:  > 1024px  → sidebar nav, layout a griglia
```

---

## 6. Autenticazione e Sicurezza

### Flow
1. **Registrazione**: email + password + nome → bcrypt hash → JWT (access 15min + refresh 30gg)
2. **Login**: email/password → JWT
3. **Refresh token**: automatico, trasparente all'utente
4. **Reset password**: email OTP (Cloudflare Email Workers)
5. **Logout**: invalidazione refresh token lato server

### Storage token
- Mobile: `flutter_secure_storage` (Keychain iOS / Keystore Android)
- Web: `localStorage` + `httpOnly cookie` per refresh token

### Offline
- L'app funziona completamente offline
- Sync automatico quando torna la connessione
- Conflitti risolti: "last write wins" con timestamp
- Indicatore stato sync nella UI

---

## 7. Sync Offline/Online

### Strategia
1. Ogni write locale aggiunge un record in `sync_queue`
2. Al ritorno della connessione, `SyncService` processa la queue
3. Endpoint `/sync/push` riceve array di operazioni in batch
4. Endpoint `/sync/pull` ritorna modifiche dal server più recenti
5. Merge locale: timestamp più recente vince

### SyncService (pseudocodice)
```dart
class SyncService {
  Future<void> sync() async {
    if (!await connectivityService.isOnline) return;
    
    // 1. Push pending changes
    final pending = await db.syncQueue.getPending();
    if (pending.isNotEmpty) {
      await apiClient.pushSync(pending);
      await db.syncQueue.markSynced(pending.map((e) => e.id));
    }
    
    // 2. Pull server changes
    final lastSync = await prefs.getLastSyncTimestamp();
    final serverChanges = await apiClient.pullSync(since: lastSync);
    await db.applyServerChanges(serverChanges);
    await prefs.setLastSyncTimestamp(DateTime.now());
  }
}
```

---

## 8. Notifiche Push

### Android/iOS
- `firebase_messaging` per notifiche push native
- Worker Cloudflare schedula reminder tramite Firebase Admin SDK (futuro)
- Tipi notifiche:
  - Abbonamento in scadenza (3 giorni prima)
  - Rata Klarna in scadenza (2 giorni prima)
  - Promemoria tagliando auto (1 settimana prima)

### Web
- Web Push API (futuro)

---

## 9. Deployment

### Fase 1 (MVP — Cloudflare Free Tier)
| Servizio | Piano | Costo |
|---|---|---|
| Cloudflare Pages | Free | €0 |
| Cloudflare Workers | Free (100k req/day) | €0 |
| Cloudflare D1 | Free (5GB, 5M reads/day) | €0 |
| Dominio temporaneo | *.pages.dev | €0 |

### Fase 2 (Produzione — dominio custom)
| Servizio | Piano | Costo ~mensile |
|---|---|---|
| Cloudflare Pages Pro | $20/mese | ~€18 |
| Cloudflare Workers Paid | $5/mese | ~€5 |
| Cloudflare D1 | $0.001/GB | <€1 |
| Dominio .it o .com | ~€10-15/anno | ~€1 |
| **Totale** | | **~€25/mese** |

### CI/CD
```yaml
# .github/workflows/deploy.yml
on:
  push:
    branches: [main]
jobs:
  deploy-web:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter build web --release
      - uses: cloudflare/pages-action@v1
        with:
          apiToken: ${{ secrets.CF_API_TOKEN }}
          accountId: ${{ secrets.CF_ACCOUNT_ID }}
          projectName: spendwise
          directory: build/web
  
  deploy-worker:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: cloudflare/wrangler-action@v3
        with:
          apiToken: ${{ secrets.CF_API_TOKEN }}
          workingDirectory: workers
```

---

## 10. Roadmap

### v1.0 (MVP)
- [x] Auth (login/register/logout)
- [x] Spese quotidiane CRUD
- [x] Abbonamenti CRUD
- [x] Rateizzazioni CRUD
- [x] Gestione 1 veicolo
- [x] Dashboard con totali
- [x] Offline support
- [x] Deploy Cloudflare

### v1.1
- [ ] Multi-veicolo
- [ ] Export PDF/CSV
- [ ] Grafici analitici avanzati
- [ ] Notifiche push

### v1.2
- [ ] App Store iOS
- [ ] Tema dark
- [ ] Budgeting mensile
- [ ] Import da banca (CSV)

### v2.0
- [ ] Condivisione spese (gruppi famiglia)
- [ ] OCR ricevute (foto scontrino)
- [ ] Integrazione bancaria open banking

---

## 11. Struttura File di Progetto Completa

```
spendwise/
├── README.md
├── SPENDWISE_SPECS.md            ← questo file
├── pubspec.yaml
├── analysis_options.yaml
├── .env.example
├── .github/
│   └── workflows/
│       └── deploy.yml
├── assets/
│   ├── fonts/
│   ├── icons/
│   │   └── categories/           # SVG icone categorie
│   └── images/
├── lib/                          # (vedi sezione 2)
├── workers/                      # Cloudflare Workers backend
│   ├── src/
│   ├── schema.sql
│   └── wrangler.toml
├── test/
│   ├── unit/
│   ├── widget/
│   └── integration/
└── docs/
    ├── api.md                    # Documentazione API REST
    ├── design/                   # Mockup e design tokens
    └── deployment.md
```

---

## 12. API REST Endpoints

### Auth
```
POST /api/auth/register
POST /api/auth/login
POST /api/auth/refresh
POST /api/auth/logout
POST /api/auth/forgot-password
```

### Daily Expenses
```
GET    /api/expenses?from=&to=&category=
POST   /api/expenses
PUT    /api/expenses/:id
DELETE /api/expenses/:id
```

### Subscriptions
```
GET    /api/subscriptions
POST   /api/subscriptions
PUT    /api/subscriptions/:id
DELETE /api/subscriptions/:id
POST   /api/subscriptions/:id/pay   # registra pagamento
```

### Installments
```
GET    /api/installments
POST   /api/installments
PUT    /api/installments/:id
DELETE /api/installments/:id
POST   /api/installments/:id/pay-installment
```

### Vehicle
```
GET    /api/vehicles
POST   /api/vehicles
PUT    /api/vehicles/:id
DELETE /api/vehicles/:id

GET    /api/vehicles/:id/fuel
POST   /api/vehicles/:id/fuel
PUT    /api/vehicles/:id/fuel/:fuelId
DELETE /api/vehicles/:id/fuel/:fuelId

GET    /api/vehicles/:id/maintenance
POST   /api/vehicles/:id/maintenance
PUT    /api/vehicles/:id/maintenance/:mainId
DELETE /api/vehicles/:id/maintenance/:mainId
```

### Sync
```
POST   /api/sync/push     # invia modifiche locali
GET    /api/sync/pull     # ricevi modifiche server
```

---

*Documento generato per il progetto SpendWise — versione 1.0*
