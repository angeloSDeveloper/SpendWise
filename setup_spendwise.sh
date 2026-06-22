#!/usr/bin/env bash
# =============================================================================
# SPENDWISE — Script di scaffolding per agenti Codex / AI coding assistants
# =============================================================================
# Questo script genera la struttura completa del progetto SpendWise.
# Da eseguire nella root del progetto dopo aver creato la cartella.
#
# Utilizzo:
#   chmod +x setup_spendwise.sh
#   ./setup_spendwise.sh
#
# Prerequisiti:
#   - Flutter SDK 3.x installato
#   - Node.js 18+ installato
#   - Wrangler CLI installato (npm install -g wrangler)
#   - Git inizializzato nella cartella
# =============================================================================

set -e
echo "🚀 SpendWise — Avvio scaffolding progetto..."

# =============================================================================
# ISTRUZIONI PER L'AGENTE AI (Codex / GPT-4 / Claude)
# =============================================================================
# Quando questo script viene passato all'agente, l'agente deve:
#
# 1. LEGGERE tutto questo file dall'inizio alla fine prima di scrivere codice
# 2. CREARE tutti i file elencati nella sezione FILE_STRUCTURE
# 3. IMPLEMENTARE il codice Dart/Flutter seguendo le specifiche in SPENDWISE_SPECS.md
# 4. IMPLEMENTARE il backend Cloudflare Workers in TypeScript
# 5. CONFIGURARE wrangler.toml e schema.sql per Cloudflare D1
# 6. NON saltare nessun file: ogni file elencato deve esistere con contenuto reale
#
# ORDINE DI IMPLEMENTAZIONE CONSIGLIATO:
#   1. pubspec.yaml con tutte le dipendenze
#   2. workers/schema.sql + wrangler.toml
#   3. lib/core/ (costanti, estensioni, errori)
#   4. lib/domain/models/ (Freezed models per ogni entità)
#   5. lib/data/local/ (Drift database + DAOs)
#   6. lib/data/remote/ (Dio client + endpoints)
#   7. lib/data/repositories/ (implementazioni)
#   8. lib/presentation/auth/ (login + register screens)
#   9. lib/presentation/dashboard/
#   10. lib/presentation/categories/ (tutte e 4 le categorie)
#   11. lib/presentation/analytics/
#   12. lib/app/ (router + theme)
#   13. workers/src/ (tutti gli endpoint backend)
#   14. .github/workflows/deploy.yml
# =============================================================================

echo "📁 Creazione struttura cartelle..."

# Root directories
mkdir -p assets/{fonts,icons/categories,images}
mkdir -p docs/design
mkdir -p test/{unit,widget,integration}

# Flutter lib structure
mkdir -p lib/app
mkdir -p lib/core/{constants,extensions,utils,errors}
mkdir -p lib/data/{local/daos,remote/endpoints,repositories}
mkdir -p lib/domain/{models,repositories,usecases}
mkdir -p lib/presentation/{auth/{login,register},dashboard,analytics,settings,shared/{widgets,providers}}
mkdir -p lib/presentation/categories/{daily,subscriptions,installments,vehicle}
mkdir -p lib/l10n

# Backend (Cloudflare Workers)
mkdir -p workers/src/{auth,expenses,sync,middleware}

# GitHub Actions
mkdir -p .github/workflows

echo "✅ Struttura cartelle creata."

# =============================================================================
# FILE: pubspec.yaml
# =============================================================================
cat > pubspec.yaml << 'PUBSPEC'
name: spendwise
description: Gestione intelligente delle spese personali
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  # State management
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5

  # Navigation
  go_router: ^14.0.0

  # Local database (SQLite)
  drift: ^2.18.0
  sqlite3_flutter_libs: ^0.5.0
  path_provider: ^2.1.3
  path: ^1.9.0

  # HTTP
  dio: ^5.4.3
  retrofit: ^4.1.0

  # Serialization
  freezed_annotation: ^2.4.1
  json_annotation: ^4.9.0

  # Secure storage
  flutter_secure_storage: ^9.0.0

  # Connectivity
  connectivity_plus: ^6.0.3

  # Charts
  fl_chart: ^0.68.0

  # UI utilities
  intl: ^0.19.0
  cached_network_image: ^3.3.1
  shimmer: ^3.0.0
  lottie: ^3.1.0

  # Notifications
  flutter_local_notifications: ^17.2.0

  # Utilities
  uuid: ^4.4.0
  shared_preferences: ^2.3.1
  url_launcher: ^6.3.0
  share_plus: ^9.0.0

  # Icons
  flutter_svg: ^2.0.10+1
  material_design_icons_flutter: ^7.0.7296

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  build_runner: ^2.4.11
  freezed: ^2.5.2
  json_serializable: ^6.8.0
  retrofit_generator: ^8.1.0
  drift_dev: ^2.18.0
  riverpod_generator: ^2.4.3
  custom_lint: ^0.6.4
  riverpod_lint: ^2.3.10

flutter:
  uses-material-design: true
  generate: true  # per l10n

  assets:
    - assets/icons/categories/
    - assets/images/
    - assets/fonts/

  fonts:
    - family: PlusJakartaSans
      fonts:
        - asset: assets/fonts/PlusJakartaSans-Regular.ttf
        - asset: assets/fonts/PlusJakartaSans-Medium.ttf
          weight: 500
        - asset: assets/fonts/PlusJakartaSans-Bold.ttf
          weight: 700
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter-Regular.ttf
        - asset: assets/fonts/Inter-Medium.ttf
          weight: 500
    - family: JetBrainsMono
      fonts:
        - asset: assets/fonts/JetBrainsMono-Regular.ttf
PUBSPEC

echo "✅ pubspec.yaml creato."

# =============================================================================
# FILE: analysis_options.yaml
# =============================================================================
cat > analysis_options.yaml << 'ANALYSIS'
include: package:flutter_lints/flutter.yaml

analyzer:
  plugins:
    - custom_lint
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"

linter:
  rules:
    prefer_single_quotes: true
    avoid_print: true
    always_use_package_imports: true
ANALYSIS

# =============================================================================
# FILE: l10n.yaml
# =============================================================================
cat > l10n.yaml << 'L10N'
arb-dir: lib/l10n
template-arb-file: app_it.arb
output-localization-file: app_localizations.dart
L10N

# =============================================================================
# FILE: lib/l10n/app_it.arb
# =============================================================================
cat > lib/l10n/app_it.arb << 'ARBFILE'
{
  "@@locale": "it",
  "appName": "SpendWise",
  "dashboard": "Dashboard",
  "dailyExpenses": "Spese Quotidiane",
  "subscriptions": "Abbonamenti",
  "installments": "Rateizzazioni",
  "vehicle": "Veicolo",
  "analytics": "Analisi",
  "settings": "Impostazioni",
  "login": "Accedi",
  "register": "Registrati",
  "email": "Email",
  "password": "Password",
  "name": "Nome",
  "save": "Salva",
  "cancel": "Annulla",
  "delete": "Elimina",
  "edit": "Modifica",
  "add": "Aggiungi",
  "total": "Totale",
  "thisMonth": "Questo mese",
  "upcoming": "In scadenza",
  "active": "Attivo",
  "inactive": "Sospeso",
  "paid": "Pagato",
  "pending": "In attesa",
  "overdue": "Scaduto",
  "amount": "Importo",
  "date": "Data",
  "description": "Descrizione",
  "category": "Categoria",
  "note": "Note",
  "monthly": "Mensile",
  "yearly": "Annuale",
  "weekly": "Settimanale",
  "noData": "Nessun dato disponibile",
  "syncComplete": "Sincronizzazione completata",
  "offlineMode": "Modalità offline",
  "fuel": "Rifornimento",
  "maintenance": "Manutenzione",
  "liters": "Litri",
  "pricePerLiter": "Prezzo/litro",
  "odometer": "Chilometri",
  "partCode": "Codice pezzo",
  "shopName": "Negozio/Sito",
  "nextService": "Prossimo servizio",
  "installmentProgress": "{paid} di {total} rate pagate",
  "@installmentProgress": {
    "placeholders": {
      "paid": {"type": "int"},
      "total": {"type": "int"}
    }
  }
}
ARBFILE

# =============================================================================
# FILE: lib/core/constants/app_constants.dart
# =============================================================================
cat > lib/core/constants/app_constants.dart << 'DARTFILE'
// ============================================================
// ISTRUZIONE PER L'AGENTE: Implementa questo file con i seguenti contenuti
// ============================================================
// Classe AppConstants con:
// - static const String apiBaseUrl = 'https://api.spendwise.pages.dev'
//   (durante sviluppo: 'http://localhost:8787')
// - static const String appName = 'SpendWise'
// - static const String appVersion = '1.0.0'
// - static const int syncIntervalSeconds = 30
// - static const int tokenRefreshMarginSeconds = 60
// - Chiavi per SharedPreferences: kLastSyncKey, kUserIdKey, kAccessTokenKey
// - Costanti per le categorie veicolo: kFuelTypes, kMaintenanceCategories
//
// Classe AppColors con:
// - static const Color primary = Color(0xFF2563EB)
// - static const Color secondary = Color(0xFF7C3AED)
// - static const Color daily = Color(0xFFF59E0B)
// - static const Color subscription = Color(0xFF8B5CF6)
// - static const Color installment = Color(0xFFEC4899)
// - static const Color vehicle = Color(0xFF10B981)
// - static const Color success = Color(0xFF16A34A)
// - static const Color error = Color(0xFFDC2626)
// - static const Color warning = Color(0xFFD97706)
// ============================================================

// PLACEHOLDER — L'agente deve sostituire questo con l'implementazione reale
class AppConstants {
  // Vedi istruzioni sopra
}
DARTFILE

# =============================================================================
# FILE: lib/domain/models/README.md
# =============================================================================
cat > lib/domain/models/README.md << 'MODELSREADME'
# Domain Models

L'agente deve creare i seguenti file usando il package `freezed`:

## File da creare:

### user.dart
```dart
@freezed
class User with _$User {
  const factory User({
    required String id,
    required String email,
    String? displayName,
    required DateTime createdAt,
  }) = _User;
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
```

### daily_expense.dart
Campi: id, userId, categoryId, amount, description, date, note, createdAt, updatedAt, synced

### subscription.dart
Campi: id, userId, name, amount, currency, billingCycle (enum: weekly/monthly/yearly),
billingDay, startDate, endDate, url, icon, color, isActive, note, createdAt, updatedAt, synced

### installment_plan.dart
Campi: id, userId, name, provider, totalAmount, installmentAmount, totalInstallments,
paidInstallments, frequency (enum), startDate, nextDueDate, isActive, note

### installment_payment.dart
Campi: id, planId, userId, installmentNumber, amount, dueDate, paidDate, status (enum)

### vehicle.dart
Campi: id, userId, name, plate, brand, model, year, fuelType (enum), createdAt

### fuel_entry.dart
Campi: id, vehicleId, userId, date, liters, pricePerLiter, totalCost, stationName,
kmOdometer, isFullTank, note, createdAt, synced

### vehicle_maintenance.dart
Campi: id, vehicleId, userId, date, itemName, partCode, category (enum: tagliando/
pneumatici/freni/elettrico/altro), price, quantity, totalCost, shopName, shopUrl,
kmAtService, nextServiceKm, nextServiceDate, warrantyMonths, receiptUrl, note, createdAt, synced

### auth_tokens.dart
Campi: accessToken, refreshToken, expiresAt

NOTA: Tutti i modelli devono avere `@freezed` annotation e generare i file `.g.dart` e `.freezed.dart`
MODELSREADME

# =============================================================================
# FILE: lib/data/local/database.dart — Istruzioni Drift
# =============================================================================
cat > lib/data/local/database.dart << 'DRIFTDB'
// ============================================================
// ISTRUZIONE PER L'AGENTE: Implementa il database Drift
// ============================================================
// Crea una classe AppDatabase usando @DriftDatabase con le seguenti tabelle:
//
// 1. DailyExpensesTable — mappa daily_expenses dal schema SQL
// 2. SubscriptionsTable — mappa subscriptions
// 3. SubscriptionPaymentsTable — mappa subscription_payments
// 4. InstallmentPlansTable — mappa installment_plans
// 5. InstallmentPaymentsTable — mappa installment_payments
// 6. VehiclesTable — mappa vehicles
// 7. FuelEntriesTable — mappa fuel_entries
// 8. VehicleMaintenanceTable — mappa vehicle_maintenance
// 9. SyncQueueTable — mappa sync_queue
// 10. CategoriesTable — mappa categories
//
// Per ogni tabella, crea il corrispondente DAO in lib/data/local/daos/
// con metodi CRUD completi + query per filtri data e sync pending.
//
// Il database deve essere un Singleton accessibile via Riverpod provider.
// ============================================================

// PLACEHOLDER — L'agente deve implementare il database Drift completo
DRIFTDB

# =============================================================================
# FILE: lib/data/remote/api_client.dart — Retrofit + Dio
# =============================================================================
cat > lib/data/remote/api_client.dart << 'APICLIENT'
// ============================================================
// ISTRUZIONE PER L'AGENTE: Implementa il client HTTP con Retrofit
// ============================================================
// 1. Crea un DioClient con:
//    - baseUrl da AppConstants.apiBaseUrl
//    - Interceptor per aggiungere JWT header (Authorization: Bearer <token>)
//    - Interceptor per refresh automatico del token (401 → refresh → retry)
//    - Timeout: connect 10s, receive 30s
//    - Logging in modalità debug
//
// 2. Crea le seguenti classi @RestApi (Retrofit):
//
//    AuthApiClient:
//      @POST('/auth/register')  Future<AuthResponse> register(@Body() RegisterRequest body)
//      @POST('/auth/login')     Future<AuthResponse> login(@Body() LoginRequest body)
//      @POST('/auth/refresh')   Future<AuthResponse> refreshToken(@Body() RefreshRequest body)
//      @POST('/auth/logout')    Future<void> logout()
//
//    ExpensesApiClient:
//      @GET('/expenses')        Future<List<DailyExpense>> getExpenses(...)
//      @POST('/expenses')       Future<DailyExpense> createExpense(@Body() ...)
//      @PUT('/expenses/{id}')   Future<DailyExpense> updateExpense(...)
//      @DELETE('/expenses/{id}') Future<void> deleteExpense(...)
//
//    (e analoghi per subscriptions, installments, vehicles, fuel, maintenance, sync)
//
// 3. Crea i modelli di request/response con @freezed:
//    RegisterRequest, LoginRequest, RefreshRequest, AuthResponse (con tokens + user)
// ============================================================

// PLACEHOLDER — L'agente deve implementare il client API Retrofit completo
APICLIENT

# =============================================================================
# FILE: lib/app/theme.dart
# =============================================================================
cat > lib/app/theme.dart << 'THEMEAPP'
// ============================================================
// ISTRUZIONE PER L'AGENTE: Implementa il tema Material 3
// ============================================================
// Crea AppTheme con due metodi statici: lightTheme() e darkTheme()
//
// lightTheme deve usare:
//   - colorScheme da ColorScheme.fromSeed(seedColor: Color(0xFF2563EB), brightness: Brightness.light)
//   - fontFamily: 'Inter' per bodyText, 'PlusJakartaSans' per displayText e headings
//   - useMaterial3: true
//   - cardTheme: borderRadius 16, elevation 0, con border sottile
//   - inputDecorationTheme: outline style, borderRadius 12
//   - elevatedButtonTheme: borderRadius 12, padding horizontal 24
//   - appBarTheme: elevation 0, backgroundColor surface, centerTitle false
//   - navigationBarTheme: height 65, indicatorColor primary con 10% opacity
//   - chipTheme: borderRadius 20
//
// darkTheme simile ma con brightness: Brightness.dark
//
// Crea anche CategoryColors helper:
//   static Color forType(CategoryType type) → ritorna il colore giusto per ogni categoria
// ============================================================

// PLACEHOLDER — L'agente deve implementare il tema completo
THEMEAPP

# =============================================================================
# FILE: lib/app/router.dart
# =============================================================================
cat > lib/app/router.dart << 'ROUTERAPP'
// ============================================================
// ISTRUZIONE PER L'AGENTE: Implementa il routing GoRouter
// ============================================================
// Crea AppRouter usando GoRouter con:
//
// Routes:
//   /                    → redirect a /dashboard se autenticato, /login altrimenti
//   /login               → LoginScreen
//   /register            → RegisterScreen
//   /dashboard           → DashboardScreen (con ShellRoute per bottom nav)
//   /daily               → DailyExpensesScreen
//   /daily/add           → AddDailyExpenseScreen
//   /daily/:id           → EditDailyExpenseScreen
//   /subscriptions       → SubscriptionsScreen
//   /subscriptions/add   → AddSubscriptionScreen
//   /subscriptions/:id   → SubscriptionDetailScreen
//   /installments        → InstallmentsScreen
//   /installments/add    → AddInstallmentScreen
//   /installments/:id    → InstallmentDetailScreen
//   /vehicle             → VehicleScreen (lista veicoli)
//   /vehicle/add         → AddVehicleScreen
//   /vehicle/:id         → VehicleDetailScreen (con tab: rifornimenti, manutenzione)
//   /vehicle/:id/fuel/add → AddFuelScreen
//   /vehicle/:id/maintenance/add → AddMaintenanceScreen
//   /analytics           → AnalyticsScreen
//   /settings            → SettingsScreen
//
// ShellRoute deve mostrare la bottom navigation bar su mobile (< 600px)
// e la sidebar navigation su desktop (> 1024px)
//
// redirect globale: controlla token in SecureStorage, redirect a /login se assente
// ============================================================

// PLACEHOLDER — L'agente deve implementare il router GoRouter completo
ROUTERAPP

# =============================================================================
# FILE: lib/presentation/auth/login/login_screen.dart
# =============================================================================
cat > lib/presentation/auth/login/login_screen.dart << 'LOGINSCREEN'
// ============================================================
// ISTRUZIONE PER L'AGENTE: Implementa la schermata di Login
// ============================================================
// LoginScreen deve essere una ConsumerWidget con:
//
// UI:
//   - Logo SpendWise in alto (SVG o icona + testo)
//   - Titolo "Bentornato" e sottotitolo "Accedi al tuo account"
//   - Campo email (TextFormField con validazione email)
//   - Campo password (TextFormField con obscureText + toggle visibilità)
//   - Pulsante "Accedi" (ElevatedButton, full-width, loading state)
//   - Link "Hai dimenticato la password?"
//   - Divider "oppure"
//   - Link "Non hai un account? Registrati" → naviga a /register
//
// Logica:
//   - Usa AuthNotifier (Riverpod) per gestire il login
//   - In caso di errore, mostra SnackBar con messaggio
//   - In caso di successo, GoRouter naviga a /dashboard
//   - Gestisci loading state con indicatore sul pulsante
//
// Responsive:
//   - Su desktop: card centrata con maxWidth 400
//   - Su mobile: full-width con padding
// ============================================================

// PLACEHOLDER — L'agente deve implementare LoginScreen completo
LOGINSCREEN

# =============================================================================
# FILE: lib/presentation/auth/register/register_screen.dart
# =============================================================================
cat > lib/presentation/auth/register/register_screen.dart << 'REGISTERSCREEN'
// ============================================================
// ISTRUZIONE PER L'AGENTE: Implementa la schermata di Registrazione
// ============================================================
// RegisterScreen simile a LoginScreen ma con:
//
// Campi form:
//   - Nome completo
//   - Email
//   - Password (min 8 caratteri, 1 maiuscola, 1 numero)
//   - Conferma password
//   - Checkbox accettazione termini e privacy policy
//
// Validazione in tempo reale con feedback visivo
// Pulsante "Crea account"
// Link "Hai già un account? Accedi"
//
// Dopo registrazione: login automatico → /dashboard
// ============================================================

// PLACEHOLDER — L'agente deve implementare RegisterScreen completo
REGISTERSCREEN

# =============================================================================
# FILE: lib/presentation/dashboard/dashboard_screen.dart
# =============================================================================
cat > lib/presentation/dashboard/dashboard_screen.dart << 'DASHSCREEN'
// ============================================================
// ISTRUZIONE PER L'AGENTE: Implementa la Dashboard principale
// ============================================================
// DashboardScreen deve mostrare:
//
// Header:
//   - Saluto personalizzato "Ciao, [Nome]!"
//   - Data corrente
//   - Icona sync con stato (sincronizzato/in attesa/offline)
//
// Riepilogo mese corrente:
//   - Card grande "Spese totali questo mese" con importo
//   - 4 mini-card colorate una per categoria:
//     • Spese quotidiane (giallo)
//     • Abbonamenti (viola)
//     • Rate (rosa)
//     • Veicolo (verde)
//
// Sezione "In scadenza questa settimana":
//   - Lista orizzontale scrollabile di abbonamenti/rate in scadenza
//   - Ogni item mostra: nome, importo, giorni alla scadenza
//   - Colore urgency: rosso <3gg, arancio 3-7gg, verde >7gg
//
// Sezione "Ultime spese":
//   - Lista delle ultime 5 transazioni di tutte le categorie
//   - Con icona categoria, descrizione, importo, data
//
// FAB: pulsante + per aggiungere velocemente una spesa quotidiana
//
// Bottom Navigation (mobile) con 5 tab:
//   Home, Spese, Abbonamenti, Rate, Veicolo
// Sidebar (desktop) con le stesse voci + Analisi + Impostazioni
// ============================================================

// PLACEHOLDER — L'agente deve implementare DashboardScreen completo
DASHSCREEN

# =============================================================================
# FILE: lib/presentation/categories/subscriptions/subscriptions_screen.dart
# =============================================================================
cat > lib/presentation/categories/subscriptions/subscriptions_screen.dart << 'SUBSSCREEN'
// ============================================================
// ISTRUZIONE PER L'AGENTE: Implementa la schermata Abbonamenti
// ============================================================
// SubscriptionsScreen deve mostrare:
//
// Header colorato viola con:
//   - Totale mensile aggregato (abbonamenti annuali / 12)
//   - Numero abbonamenti attivi
//
// Lista abbonamenti con SubscriptionCard:
//   Ogni card deve avere:
//   - Logo/icona dell'abbonamento (da URL o icona predefinita)
//   - Nome abbonamento (Netflix, Spotify, Amazon Prime, ecc.)
//   - Importo + frequenza ("€15,99/mese", "€49,90/anno")
//   - Prossima data di rinnovo
//   - Badge stato: "Attivo" (verde) / "In scadenza" (arancio) / "Sospeso" (grigio)
//   - Menu contestuale (3 punti): Modifica, Segna come pagato, Sospendi, Elimina
//
// Filtri: Tutti / Mensili / Annuali / Settimanali
//
// FAB: aggiungi abbonamento → AddSubscriptionScreen
//
// AddSubscriptionScreen deve avere:
//   - Campo nome con suggerimenti predefiniti (Netflix, Spotify, Amazon Prime,
//     Disney+, YouTube Premium, iCloud, Microsoft 365, ecc.)
//   - Campo importo
//   - Selector frequenza: Settimanale / Mensile / Annuale
//   - Selector giorno di addebito
//   - Data inizio
//   - Data fine (opzionale)
//   - URL sito (opzionale)
//   - Note
// ============================================================

// PLACEHOLDER — L'agente deve implementare SubscriptionsScreen completo
SUBSSCREEN

# =============================================================================
# FILE: lib/presentation/categories/installments/installments_screen.dart
# =============================================================================
cat > lib/presentation/categories/installments/installments_screen.dart << 'INSTALLSCREEN'
// ============================================================
// ISTRUZIONE PER L'AGENTE: Implementa la schermata Rateizzazioni
// ============================================================
// InstallmentsScreen deve mostrare:
//
// Header colorato rosa con:
//   - Importo totale residuo su tutte le rateizzazioni attive
//   - Numero piani attivi
//
// Lista piani rateizzazione con InstallmentPlanCard:
//   - Nome piano (es. "iPhone 15 Pro — Klarna")
//   - Provider (Klarna, Scalapay, CartaSì, ecc.)
//   - Progress bar: rate pagate / totali (con percentuale)
//   - Importo singola rata + frequenza
//   - Data prossima rata con countdown giorni
//   - Importo residuo
//   - Badge: "In corso" / "Scaduta" / "Completata"
//
// Sezione "In scadenza questa settimana" in cima (se presenti)
//
// FAB: aggiungi piano rateizzazione
//
// AddInstallmentScreen:
//   - Nome articolo
//   - Provider (dropdown con suggerimenti: Klarna, Scalapay, PayPal, Altro)
//   - Importo totale
//   - Numero di rate
//   - Calcolo automatico importo rata
//   - Frequenza: Settimanale / Bisettimanale / Mensile
//   - Data prima rata
//   - Note
//
// InstallmentDetailScreen:
//   - Lista di tutte le rate con stato (pagata ✓ / in attesa ○ / scaduta ✗)
//   - Pulsante "Segna come pagata" per la rata corrente
//   - Storico pagamenti con date
// ============================================================

// PLACEHOLDER — L'agente deve implementare InstallmentsScreen completo
INSTALLSCREEN

# =============================================================================
# FILE: lib/presentation/categories/vehicle/vehicle_screen.dart
# =============================================================================
cat > lib/presentation/categories/vehicle/vehicle_screen.dart << 'VEHICLESCREEN'
// ============================================================
// ISTRUZIONE PER L'AGENTE: Implementa la schermata Veicolo
// ============================================================
// VehicleScreen:
//   - Lista veicoli dell'utente (card con nome, targa, brand)
//   - Se nessun veicolo: empty state con pulsante "Aggiungi veicolo"
//   - FAB: aggiungi veicolo
//
// VehicleDetailScreen (per ogni veicolo):
//   - Header verde con nome veicolo, targa, brand/modello/anno
//   - TabBar con 2 tab: "Rifornimenti" e "Manutenzione"
//
// TAB RIFORNIMENTI:
//   - Card riepilogo: totale speso, litri totali, consumo medio (km/L)
//   - Grafico lineare: andamento prezzo/litro nel tempo (fl_chart)
//   - Lista rifornimenti in ordine cronologico inverso
//   - Ogni item: data, litri, €/litro, totale, stazione, km
//   - FAB: aggiungi rifornimento
//
//   AddFuelScreen:
//     - Data (default oggi)
//     - Litri riforniti
//     - Prezzo per litro → calcolo automatico totale
//     - Nome stazione (opzionale)
//     - Km contachilometri (opzionale)
//     - Toggle "Pieno completo"
//     - Note
//
// TAB MANUTENZIONE:
//   - Filtri per categoria: Tutti / Tagliando / Pneumatici / Freni / Elettrico / Altro
//   - Lista manutenzioni con MaintenanceCard:
//     • Data acquisto/intervento
//     • Nome pezzo/intervento
//     • CODICE PEZZO (in font monospace, copiabile con tap)
//     • Prezzo (+ quantità se > 1)
//     • Negozio/sito con link cliccabile (url_launcher)
//     • Km all'intervento
//     • Prossimo intervento (data o km)
//     • Badge garanzia (se presente)
//   - FAB: aggiungi manutenzione
//
//   AddMaintenanceScreen:
//     - Nome pezzo/intervento
//     - Categoria (dropdown: Tagliando, Pneumatici, Freni, Elettrico, Batteria, Altro)
//     - Codice pezzo (campo con hint "es. 5W40 / 7701478114")
//     - Prezzo unitario
//     - Quantità (default 1)
//     - Totale calcolato automaticamente
//     - Negozio o sito web
//     - URL sito acquisto (con pulsante "Apri")
//     - Data acquisto/intervento
//     - Km al momento dell'intervento
//     - Prossimo intervento: data (DatePicker) E/O km
//     - Mesi garanzia
//     - Note
// ============================================================

// PLACEHOLDER — L'agente deve implementare VehicleScreen completo
VEHICLESCREEN

# =============================================================================
# FILE: lib/presentation/categories/daily/daily_expenses_screen.dart
# =============================================================================
cat > lib/presentation/categories/daily/daily_expenses_screen.dart << 'DAILYSCREEN'
// ============================================================
// ISTRUZIONE PER L'AGENTE: Implementa la schermata Spese Quotidiane
// ============================================================
// DailyExpensesScreen:
//
// Header giallo/ambra con:
//   - Totale spese mese corrente
//   - Confronto con mese precedente (+ o - percentuale)
//
// Selector periodo: Oggi / Settimana / Mese / Anno
//
// Lista spese raggruppata per giorno:
//   - Header giorno con totale giornaliero
//   - Ogni spesa: icona categoria, descrizione, nota, importo
//   - Swipe-to-delete con conferma
//   - Tap per modifica
//
// Categorie predefinite per spese quotidiane:
//   ☕ Caffè/Bar, 🛒 Spesa, 🍕 Ristorante, ⛽ Carburante,
//   🅿️ Parcheggio, 🚌 Trasporti, 💊 Farmacia, 👕 Abbigliamento,
//   🎬 Intrattenimento, 📦 E-commerce, 💡 Bollette, 🔧 Casa, 📌 Altro
//
// FAB: bottom sheet per aggiunta veloce:
//   - Import preimpostato dei valori comuni (0.50€, 1€, 1.20€, 2€, 5€, 10€)
//   - Campo importo con numpad custom
//   - Selector categoria (icone in griglia)
//   - Campo descrizione (opzionale)
//   - Data (default oggi, modificabile)
// ============================================================

// PLACEHOLDER — L'agente deve implementare DailyExpensesScreen completo
DAILYSCREEN

# =============================================================================
# FILE: lib/presentation/analytics/analytics_screen.dart
# =============================================================================
cat > lib/presentation/analytics/analytics_screen.dart << 'ANALYTICSSCREEN'
// ============================================================
// ISTRUZIONE PER L'AGENTE: Implementa la schermata Analisi
// ============================================================
// AnalyticsScreen con fl_chart:
//
// Selector periodo: Ultimo mese / Ultimi 3 mesi / Ultimi 6 mesi / Anno
//
// 1. Grafico a torta: distribuzione spese per categoria (4 colori)
//
// 2. Grafico a barre: andamento mensile ultimi 6 mesi (barre impilate per categoria)
//
// 3. Card riepilogo per categoria con:
//    - Totale periodo
//    - Media mensile
//    - Mese più costoso
//
// 4. "Top 5 spese singole" del periodo
//
// 5. Sezione veicolo (se presente):
//    - Consumo medio km/L nel tempo
//    - Costo totale carburante vs manutenzione (grafico a barre)
// ============================================================

// PLACEHOLDER — L'agente deve implementare AnalyticsScreen completo
ANALYTICSSCREEN

# =============================================================================
# FILE: lib/presentation/shared/providers/auth_provider.dart
# =============================================================================
cat > lib/presentation/shared/providers/auth_provider.dart << 'AUTHPROVIDER'
// ============================================================
// ISTRUZIONE PER L'AGENTE: Implementa i provider Riverpod per auth
// ============================================================
// 1. authRepositoryProvider: Provider<AuthRepository> — singleton
//
// 2. authStateProvider: StateNotifierProvider<AuthNotifier, AuthState>
//    AuthState è un @freezed con varianti:
//      AuthState.initial()
//      AuthState.loading()
//      AuthState.authenticated(User user)
//      AuthState.unauthenticated()
//      AuthState.error(String message)
//
//    AuthNotifier deve avere:
//      Future<void> login(String email, String password)
//      Future<void> register(String email, String password, String name)
//      Future<void> logout()
//      Future<void> checkAuthStatus()  ← chiamato all'avvio app
//
// 3. currentUserProvider: Provider<User?> derivato da authStateProvider
//
// 4. syncServiceProvider: Provider<SyncService>
//    SyncService deve:
//      - Avviarsi in background ogni 30 secondi se online
//      - Processare la sync_queue locale
//      - Aggiornare syncStatusProvider
//
// 5. syncStatusProvider: StateProvider<SyncStatus>
//    enum SyncStatus { synced, pending, syncing, offline, error }
// ============================================================

// PLACEHOLDER — L'agente deve implementare i provider completi
AUTHPROVIDER

# =============================================================================
# FILE: lib/presentation/shared/widgets/README.md
# =============================================================================
cat > lib/presentation/shared/widgets/README.md << 'WIDGETSREADME'
# Shared Widgets

L'agente deve implementare i seguenti widget riutilizzabili:

## expense_card.dart
Widget generico per mostrare una spesa con:
- leading: icona colorata con sfondo categoria
- title: descrizione
- subtitle: data + nota (opzionale)
- trailing: importo (rosso)
- onTap callback

## category_header.dart
Widget header colorato per le schermate categoria:
- color: Color (del tema categoria)
- title: String
- subtitle: String (es. totale mese)
- icon: IconData
- children: List<Widget> (widget aggiuntivi nell'header)

## amount_display.dart
Mostra un importo formattato con:
- amount: double
- currency: String (default 'EUR')
- style: TextStyle
- isNegative: bool (per mostrare in rosso)

## sync_status_indicator.dart
Piccola icona nella AppBar che mostra:
- Verde con checkmark: sincronizzato
- Arancio con orologio: modifiche in attesa
- Grigio con wifi-off: offline
- Spinner: sincronizzazione in corso

## empty_state.dart
Widget per stati vuoti con:
- icon: Widget (lottie animation o SVG)
- title: String
- subtitle: String
- action: Widget (opzionale)

## loading_overlay.dart
Overlay di caricamento semi-trasparente

## confirm_delete_dialog.dart
Dialog di conferma eliminazione generico

## custom_text_field.dart
TextField stilizzato con validazione inline

## subscription_card.dart
Card completa per abbonamento (vedi istruzioni SubscriptionsScreen)

## installment_progress_card.dart
Card con progress bar per piano rateizzazione

## fuel_entry_item.dart
ListTile per rifornimento

## maintenance_item.dart
ListTile per voce manutenzione con part code copiabile
WIDGETSREADME

# =============================================================================
# BACKEND: Cloudflare Workers
# =============================================================================

# schema SQL D1
cat > workers/schema.sql << 'SQLSCHEMA'
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
  url TEXT,
  icon TEXT,
  color TEXT,
  is_active INTEGER DEFAULT 1,
  note TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
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
  note TEXT,
  created_at INTEGER NOT NULL,
  FOREIGN KEY (vehicle_id) REFERENCES vehicles(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Indici per performance
CREATE INDEX IF NOT EXISTS idx_daily_expenses_user_date ON daily_expenses(user_id, date);
CREATE INDEX IF NOT EXISTS idx_subscriptions_user ON subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_installment_plans_user ON installment_plans(user_id);
CREATE INDEX IF NOT EXISTS idx_vehicles_user ON vehicles(user_id);
CREATE INDEX IF NOT EXISTS idx_fuel_entries_vehicle_date ON fuel_entries(vehicle_id, date);
CREATE INDEX IF NOT EXISTS idx_vehicle_maintenance_vehicle ON vehicle_maintenance(vehicle_id);
SQLSCHEMA

echo "✅ schema.sql creato."

# =============================================================================
# FILE: workers/wrangler.toml
# =============================================================================
cat > workers/wrangler.toml << 'WRANGLER'
name = "spendwise-api"
main = "src/index.ts"
compatibility_date = "2024-01-01"
compatibility_flags = ["nodejs_compat"]

[vars]
ENVIRONMENT = "development"
JWT_SECRET = "CHANGE_ME_IN_PRODUCTION_USE_WRANGLER_SECRET"
JWT_ACCESS_EXPIRY = "900"       # 15 minuti in secondi
JWT_REFRESH_EXPIRY = "2592000"  # 30 giorni in secondi

[[d1_databases]]
binding = "DB"
database_name = "spendwise-db"
database_id = "INSERISCI_QUI_IL_TUO_D1_DATABASE_ID"

# Per produzione, usa: wrangler secret put JWT_SECRET

[env.production]
name = "spendwise-api-prod"
vars = { ENVIRONMENT = "production" }
WRANGLER

# =============================================================================
# FILE: workers/src/index.ts
# =============================================================================
cat > workers/src/index.ts << 'WORKERINDEX'
// ============================================================
// ISTRUZIONE PER L'AGENTE: Implementa il router principale Cloudflare Worker
// ============================================================
// Usa itty-router o hono per il routing HTTP.
// Consiglio: usa Hono (npm install hono) per la semplicità.
//
// Struttura del router:
//
// POST  /api/auth/register     → auth/register.ts
// POST  /api/auth/login        → auth/login.ts
// POST  /api/auth/refresh      → auth/refresh.ts
// POST  /api/auth/logout       → auth/logout.ts (richiede auth)
//
// // Tutte le route seguenti richiedono JWT valido (authMiddleware)
// GET   /api/expenses          → expenses/daily.ts :: getExpenses
// POST  /api/expenses          → expenses/daily.ts :: createExpense
// PUT   /api/expenses/:id      → expenses/daily.ts :: updateExpense
// DELETE /api/expenses/:id     → expenses/daily.ts :: deleteExpense
//
// (analoghe per subscriptions, installments, vehicles, fuel, maintenance)
//
// POST  /api/sync/push         → sync/sync.ts :: pushSync
// GET   /api/sync/pull         → sync/sync.ts :: pullSync
//
// Middleware CORS: permette origins flutter web + localhost
// Middleware auth: verifica JWT, aggiunge user_id al context
//
// Ogni handler deve:
// - Validare input
// - Verificare che la risorsa appartenga all'utente autenticato
// - Usare prepared statements per D1 (prevenzione SQL injection)
// - Ritornare JSON con struttura { data: ..., error: null } o { data: null, error: "msg" }
//
// Tipo Env:
// interface Env {
//   DB: D1Database;
//   JWT_SECRET: string;
//   JWT_ACCESS_EXPIRY: string;
//   JWT_REFRESH_EXPIRY: string;
// }
// ============================================================

export default {
  async fetch(request: Request, env: any, ctx: any): Promise<Response> {
    // PLACEHOLDER — L'agente deve implementare il router Hono completo
    return new Response(JSON.stringify({ error: "Not implemented" }), {
      status: 501,
      headers: { "Content-Type": "application/json" }
    });
  }
};
WORKERINDEX

# =============================================================================
# FILE: workers/src/auth/register.ts
# =============================================================================
cat > workers/src/auth/register.ts << 'REGISTERWORKER'
// ============================================================
// ISTRUZIONE PER L'AGENTE: Implementa la registrazione utente
// ============================================================
// Logica:
// 1. Valida email (regex) e password (min 8 chars, 1 maiuscola, 1 numero)
// 2. Controlla se email già registrata in D1
// 3. Hash password con bcryptjs (npm install bcryptjs)
// 4. Genera UUID v4 per user_id
// 5. Inserisce in users
// 6. Genera access_token (JWT, 15min) e refresh_token (JWT, 30gg)
// 7. Salva hash del refresh_token in refresh_tokens table
// 8. Ritorna { user: {id, email, displayName}, tokens: {accessToken, refreshToken} }
//
// NOTA: usa Web Crypto API per JWT invece di jsonwebtoken
// (Cloudflare Workers non supporta Node.js crypto direttamente)
// Usa jose (npm install jose) per JWT in edge runtime
// ============================================================

// PLACEHOLDER — implementare
REGISTERWORKER

cat > workers/src/auth/login.ts << 'LOGINWORKER'
// ============================================================
// ISTRUZIONE PER L'AGENTE: Implementa il login
// ============================================================
// 1. Trova utente per email
// 2. Confronta password con bcrypt.compare
// 3. Genera nuovi token
// 4. Salva refresh token
// 5. Ritorna user + tokens
// ============================================================
// PLACEHOLDER — implementare
LOGINWORKER

cat > workers/src/middleware/auth.ts << 'AUTHMIDDLEWARE'
// ============================================================
// ISTRUZIONE PER L'AGENTE: Implementa il middleware JWT
// ============================================================
// 1. Estrai token da Authorization: Bearer <token>
// 2. Verifica firma con jose
// 3. Controlla scadenza
// 4. Aggiunge user_id al context Hono: c.set('userId', payload.sub)
// 5. Se non valido: return 401 JSON error
// ============================================================
// PLACEHOLDER — implementare
AUTHMIDDLEWARE

cat > workers/src/middleware/cors.ts << 'CORSMIDDLEWARE'
// ============================================================
// ISTRUZIONE PER L'AGENTE: Implementa CORS middleware
// ============================================================
// Allowed origins:
// - http://localhost:*  (sviluppo)
// - https://*.pages.dev (Cloudflare Pages staging)
// - https://spendwise.it (produzione, futuro)
//
// Headers da permettere:
// - Content-Type, Authorization, X-Requested-With
//
// Gestisci preflight OPTIONS request
// ============================================================
// PLACEHOLDER — implementare
CORSMIDDLEWARE

# =============================================================================
# FILE: .github/workflows/deploy.yml
# =============================================================================
cat > .github/workflows/deploy.yml << 'CICD'
name: Deploy SpendWise

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

env:
  FLUTTER_VERSION: '3.22.0'
  NODE_VERSION: '20'

jobs:
  # ============================================================
  # Job 1: Test Flutter
  # ============================================================
  test-flutter:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ env.FLUTTER_VERSION }}
          channel: 'stable'
          cache: true
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Run code generation
        run: flutter pub run build_runner build --delete-conflicting-outputs
      
      - name: Analyze
        run: flutter analyze
      
      - name: Test
        run: flutter test --coverage
  
  # ============================================================
  # Job 2: Build e Deploy Web su Cloudflare Pages
  # ============================================================
  deploy-web:
    needs: test-flutter
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
      - uses: actions/checkout@v4
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ env.FLUTTER_VERSION }}
          channel: 'stable'
          cache: true
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Run code generation
        run: flutter pub run build_runner build --delete-conflicting-outputs
      
      - name: Build web
        run: |
          flutter build web \
            --release \
            --web-renderer canvaskit \
            --dart-define=API_URL=${{ secrets.API_URL }}
      
      - name: Deploy to Cloudflare Pages
        uses: cloudflare/pages-action@v1
        with:
          apiToken: ${{ secrets.CF_API_TOKEN }}
          accountId: ${{ secrets.CF_ACCOUNT_ID }}
          projectName: spendwise
          directory: build/web
          gitHubToken: ${{ secrets.GITHUB_TOKEN }}
  
  # ============================================================
  # Job 3: Deploy Worker su Cloudflare
  # ============================================================
  deploy-worker:
    needs: test-flutter
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
      - uses: actions/checkout@v4
      
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
      
      - name: Install Worker dependencies
        working-directory: workers
        run: npm install
      
      - name: Deploy Worker
        uses: cloudflare/wrangler-action@v3
        with:
          apiToken: ${{ secrets.CF_API_TOKEN }}
          workingDirectory: workers
          command: deploy --env production
  
  # ============================================================
  # Job 4: Build APK Android (solo su tag v*)
  # ============================================================
  build-android:
    runs-on: ubuntu-latest
    if: startsWith(github.ref, 'refs/tags/v')
    
    steps:
      - uses: actions/checkout@v4
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ env.FLUTTER_VERSION }}
          channel: 'stable'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Run code generation
        run: flutter pub run build_runner build --delete-conflicting-outputs
      
      - name: Build APK
        run: |
          flutter build apk \
            --release \
            --dart-define=API_URL=${{ secrets.API_URL }}
      
      - name: Build App Bundle (Play Store)
        run: |
          flutter build appbundle \
            --release \
            --dart-define=API_URL=${{ secrets.API_URL }}
      
      - name: Upload APK artifact
        uses: actions/upload-artifact@v4
        with:
          name: spendwise-apk
          path: build/app/outputs/flutter-apk/app-release.apk
      
      - name: Upload AAB artifact
        uses: actions/upload-artifact@v4
        with:
          name: spendwise-aab
          path: build/app/outputs/bundle/release/app-release.aab
CICD

echo "✅ GitHub Actions workflow creato."

# =============================================================================
# FILE: workers/package.json
# =============================================================================
cat > workers/package.json << 'PKGJSON'
{
  "name": "spendwise-workers",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "dev": "wrangler dev",
    "deploy": "wrangler deploy",
    "db:migrate": "wrangler d1 execute spendwise-db --file=schema.sql",
    "db:migrate:prod": "wrangler d1 execute spendwise-db --env production --file=schema.sql"
  },
  "dependencies": {
    "hono": "^4.4.0",
    "jose": "^5.6.3",
    "bcryptjs": "^2.4.3",
    "uuid": "^10.0.0"
  },
  "devDependencies": {
    "@cloudflare/workers-types": "^4.20240718.0",
    "typescript": "^5.5.3",
    "wrangler": "^3.65.0"
  }
}
PKGJSON

# =============================================================================
# FILE: workers/tsconfig.json
# =============================================================================
cat > workers/tsconfig.json << 'TSCFG'
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ES2022",
    "moduleResolution": "Bundler",
    "lib": ["ES2022"],
    "types": ["@cloudflare/workers-types"],
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noImplicitReturns": true,
    "skipLibCheck": true
  }
}
TSCFG

# =============================================================================
# FILE: .env.example
# =============================================================================
cat > .env.example << 'ENVEXAMPLE'
# SpendWise — Variabili d'ambiente
# Copia in .env e compila con i tuoi valori

# API URL (Worker Cloudflare)
API_URL=https://spendwise-api.YOUR_SUBDOMAIN.workers.dev

# Per sviluppo locale
# API_URL=http://localhost:8787

# Cloudflare (per CI/CD, non necessario in locale)
# CF_API_TOKEN=
# CF_ACCOUNT_ID=
ENVEXAMPLE

# =============================================================================
# FILE: docs/deployment.md
# =============================================================================
cat > docs/deployment.md << 'DEPLOYMENTDOC'
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
DEPLOYMENTDOC

# =============================================================================
# FILE: README.md
# =============================================================================
cat > README.md << 'READMEFILE'
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
READMEFILE

echo ""
echo "=============================================="
echo "✅ SpendWise — Scaffolding completato!"
echo "=============================================="
echo ""
echo "Struttura creata:"
echo "  ├── pubspec.yaml"
echo "  ├── README.md"
echo "  ├── SPENDWISE_SPECS.md (da copiare qui)"
echo "  ├── .env.example"
echo "  ├── lib/ (struttura Flutter)"
echo "  ├── workers/ (Cloudflare Workers)"
echo "  └── .github/workflows/deploy.yml"
echo ""
echo "📋 PROSSIMI PASSI PER L'AGENTE:"
echo ""
echo "  1. Implementa tutti i file con PLACEHOLDER nel codice"
echo "     (ogni file ha istruzioni dettagliate nei commenti)"
echo ""
echo "  2. Esegui la code generation:"
echo "     flutter pub run build_runner build --delete-conflicting-outputs"
echo ""
echo "  3. Setup Cloudflare:"
echo "     cd workers && npm install"
echo "     wrangler d1 create spendwise-db"
echo "     wrangler d1 execute spendwise-db --local --file=schema.sql"
echo "     wrangler dev"
echo ""
echo "  4. Test locale:"
echo "     flutter run -d chrome --dart-define=API_URL=http://localhost:8787"
echo ""
echo "Leggi SPENDWISE_SPECS.md per l'architettura completa."
echo "=============================================="
