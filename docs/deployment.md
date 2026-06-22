# SpendWise — Guida al Deployment

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

### 4. Esegui le migrazioni
```bash
# Ambiente di sviluppo (locale)
wrangler d1 execute spendwise-db --local --file=schema.sql

# Produzione
wrangler d1 execute spendwise-db --file=schema.sql
```

### 5. Configura i secrets
```bash
wrangler secret put JWT_SECRET
# Inserisci una stringa random di almeno 64 caratteri
```

### 6. Deploy del Worker
```bash
wrangler deploy
# Nota il URL dell'API (es. https://spendwise-api.nome.workers.dev)
```

### 7. Crea il progetto Pages
```bash
# Nella root del progetto Flutter
flutter build web --release --dart-define=API_URL=https://spendwise-api.nome.workers.dev

# Deploy manuale (la prima volta)
wrangler pages project create spendwise
wrangler pages deploy build/web --project-name=spendwise
```

### 8. Configura GitHub Actions
Nel tuo repository GitHub, vai in Settings → Secrets and variables → Actions:
- `CF_API_TOKEN`: il tuo Cloudflare API token
- `CF_ACCOUNT_ID`: il tuo Account ID (dalla dashboard Cloudflare)
- `API_URL`: URL del tuo Worker

## Dominio custom (fase 2)

1. Acquista un dominio su Cloudflare Registrar o trasferiscilo
2. In Cloudflare Dashboard → Pages → spendwise → Custom domains → Add custom domain
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
