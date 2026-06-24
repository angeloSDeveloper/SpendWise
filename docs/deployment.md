# SpendWise — Guida al Deployment

> Stato aggiornato al 24/06/2026: SpendWise viene pubblicato come Worker con
> asset Flutter integrati, non come progetto Cloudflare Pages separato.

## Setup iniziale Cloudflare

### 1. Crea account Cloudflare
Vai su https://cloudflare.com e crea un account gratuito.

### 2. Installa Wrangler
```bash
npm install -g wrangler
wrangler login
```

### 3. Crea il database D1
```bash
cd workers
wrangler d1 create spendwise-db
# Copia il database_id nell'output e incollalo in wrangler.toml
```

### 4. Esegui schema e migrazioni
```bash
# Ambiente di sviluppo (locale)
wrangler d1 execute spendwise-db --local --file=schema.sql

# Produzione
wrangler d1 execute spendwise-db --file=schema.sql

# Migrazioni incrementali già presenti nel repository
wrangler d1 execute spendwise-db --remote \
  --file=migrations/2026-06-24_subscriptions_vehicles.sql
```

### 5. Configura i secrets
```bash
wrangler secret put JWT_SECRET
# Inserisci una stringa random di almeno 64 caratteri
```

### 6. Build Flutter

```bash
flutter build web --release --no-wasm-dry-run \
  --dart-define=API_URL=https://spendwise.lopreteangelo97.workers.dev
```

### 7. Deploy del Worker e del sito

```bash
cd workers
wrangler deploy --env production
```

URL corrente: https://spendwise.lopreteangelo97.workers.dev

Non creare un secondo progetto Pages: produrrebbe un'applicazione duplicata e
non collegata correttamente all'API.

### 8. GitHub
Nel tuo repository GitHub, vai in Settings → Secrets and variables → Actions:
- `CF_API_TOKEN`: il tuo Cloudflare API token
- `CF_ACCOUNT_ID`: il tuo Account ID (dalla dashboard Cloudflare)
- `API_URL`: URL del tuo Worker

## Dominio personalizzato (fase futura)

1. Acquista un dominio su Cloudflare Registrar o trasferiscilo
2. Collega il dominio al Worker `spendwise`
3. Aggiorna `API_URL` con il dominio definitivo

## Build Android per Play Store

```bash
# Genera il keystore (solo prima volta)
keytool -genkey -v -keystore spendwise.keystore \
  -alias spendwise -keyalg RSA -keysize 2048 -validity 10000

# Build App Bundle
flutter build appbundle --release

# Il file .aab si trova in:
# build/app/outputs/bundle/release/app-release.aab
```

Carica l'AAB nella Google Play Console per la pubblicazione.
