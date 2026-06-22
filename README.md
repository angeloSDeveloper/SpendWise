# SpendWise 💰

> Gestione intelligente delle spese personali — Flutter + Cloudflare

[![Deploy](https://github.com/yourusername/spendwise/actions/workflows/deploy.yml/badge.svg)](https://github.com/yourusername/spendwise/actions)

## Funzionalità

- 📅 **Spese quotidiane** — Traccia ogni spesa con categoria e descrizione
- 📱 **Abbonamenti** — Gestisci Netflix, Spotify, Amazon Prime con alert scadenze
- 💳 **Rateizzazioni** — Klarna, Scalapay e qualsiasi piano rateale
- 🚗 **Veicolo** — Rifornimenti, manutenzioni con codici pezzi e link acquisto
- 📊 **Analisi** — Grafici e statistiche sui tuoi consumi
- 🔄 **Offline first** — Funziona senza internet, si sincronizza quando disponibile

## Stack Tecnico

- **Flutter 3.x** (Android, iOS, Web)
- **Riverpod 2** (state management)
- **Drift** (SQLite locale)
- **Cloudflare Workers** (backend API)
- **Cloudflare D1** (database SQL serverless)
- **Cloudflare Pages** (hosting web)

## Sviluppo Locale

```bash
# Clone
git clone https://github.com/yourusername/spendwise.git
cd spendwise

# Installa dipendenze Flutter
flutter pub get

# Genera codice (Freezed, Drift, Retrofit)
flutter pub run build_runner build --delete-conflicting-outputs

# Avvia il Worker in locale
cd workers && npm install && wrangler dev

# In un altro terminale, avvia Flutter web
cd .. && flutter run -d chrome --dart-define=API_URL=http://localhost:8787

# Oppure su dispositivo Android
flutter run -d android --dart-define=API_URL=http://10.0.2.2:8787
```

## Deployment

Vedi [docs/deployment.md](docs/deployment.md)

## Architettura

Vedi [SPENDWISE_SPECS.md](SPENDWISE_SPECS.md)

## License

MIT
