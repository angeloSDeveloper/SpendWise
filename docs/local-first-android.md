# Architettura local-first e Android

Stato al 1 luglio 2026.

## Obiettivo

SpendWise deve conservare i dati prima sul dispositivo e rendere facoltativo
il backup collegato al profilo. La stessa implementazione usa IndexedDB sul
web e SQLite su Android.

## Prima implementazione

- Le risposte di spese, abbonamenti, rate, veicoli e registri collegati sono
  conservate nel database locale Drift.
- In assenza di rete, le letture usano la copia locale.
- Creazioni, modifiche e cancellazioni offline aggiornano subito la copia
  locale e vengono accodate in ordine.
- Le scritture sono locali per prime; con backup attivo la coda viene tentata
  all'apertura della dashboard e poi ogni 30 secondi.
- L'impostazione `Backup sul profilo` può sospendere volontariamente l'invio:
  i dati continuano a funzionare sul dispositivo.
- Riattivando il backup, oppure al successivo ciclo con connessione, le
  operazioni pendenti vengono inviate al Worker.
- Cache e coda sono separate per id utente, per evitare commistioni tra
  profili sullo stesso dispositivo.
- Se l'app viene riaperta senza rete, una sessione già memorizzata resta
  utilizzabile.

## Limiti dichiarati di questa fase

- Il primo accesso o la prima registrazione richiedono ancora Internet.
- La modalità completamente anonima, senza aver mai creato un profilo, non è
  ancora disponibile.
- La strategia iniziale conserva l'ordine delle operazioni; la risoluzione
  visuale dei conflitti tra modifiche contemporanee da dispositivi diversi
  resta da implementare.
- L'APK di test usa la firma debug. Prima della distribuzione Play Store serve
  un keystore di produzione custodito fuori dal repository.

## Android

- Application id: `it.lopreteangelo.spendwise`.
- Internet e notifiche Android 13+ sono dichiarati nel manifest.
- L'activity usa `FlutterFragmentActivity` per la biometria.
- Il progetto Android abilita il desugaring richiesto dalle notifiche locali.

Build di test:

```powershell
& .\.tooling\flutter\bin\flutter.bat build apk --release `
  --dart-define=API_URL=https://spendwise.lopreteangelo97.workers.dev/api
```

Output:

```text
build\app\outputs\flutter-apk\app-release.apk
```
