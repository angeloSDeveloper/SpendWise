# Stato corrente di SpendWise

Ultimo aggiornamento: 1 luglio 2026

Questo file è la fonte principale per capire cosa funziona, cosa è parziale e
cosa manca. `TODO.txt` contiene le attività operative; `CHANGELOG_WORK.md`
conserva lo storico cronologico.

## Regole di aggiornamento

Per ogni intervento futuro:

1. prima di modificare il codice, registrare la richiesta in `TODO.txt`;
2. usare `completato`, `parziale`, `da verificare` e `da fare` in modo
   esplicito;
3. non segnare una funzione come completata se manca il collaudo richiesto;
4. al termine aggiungere data, file modificati, test e deploy in
   `CHANGELOG_WORK.md`;
5. lasciare in `TODO.txt` tutto ciò che resta incompleto;
6. distinguere sempre tra interfaccia predisposta e funzione realmente attiva
   in background o su servizi esterni.

## Memoria operativa Codex

- `AGENTS.md` nella root del repository contiene le istruzioni automatiche per
  Codex quando il progetto viene aperto da un altro PC o da una nuova sessione.
- La memoria principale del progetto resta nei file versionati:
  `TODO.txt`, `docs/PROJECT_STATUS.md`, `docs/CHANGELOG_WORK.md` e
  `docs/deployment.md`.
- La cronologia di una chat locale Codex non deve essere considerata l'unica
  fonte di contesto.
- Identità del proprietario: nessun nome, cognome o indirizzo email deve
  comparire nel codice o nella UI. Package e dati dimostrativi devono essere
  neutri; gli URL infrastrutturali attuali saranno migrati al dominio
  ufficiale quando disponibile.

## Funzioni completate

- Builder avatar premium con anteprima live, preset, randomizzazione, forme,
  iniziali, icone, colori, gradiente, bordo e dimensioni.
- Registro veicoli con manutenzioni e accessori.
- Modifica, archiviazione, ripristino ed eliminazione dei veicoli.
- Abbonamenti con prossima scadenza e ricorrenza personalizzata in mesi.
- Piani rateali con prossima scadenza e registrazione della rata pagata.
- Form piani rateali con data iniziale/prima rata e scadenza finale calcolata
  automaticamente in base a frequenza e numero rate.
- Creazione atomica di piani rateali multipli e persistenza della scadenza
  finale.
- Capacità serbatoio del veicolo e precompilazione dei litri per il pieno
  completo.
- CRUD per spese quotidiane, abbonamenti, rate, manutenzioni e accessori.
- Menu principali configurabili dalle impostazioni.
- Preferenze locali per tema, avatar, biometria e promemoria.
- Avatar vettoriale leggero semplificato alle versioni Uomo e Donna, con foto
  personale opzionale.

## Funzioni parziali

- Android mobile: eliminazione abbonamenti con totale immediato e undo,
  sblocco biometrico della copia locale, OCR carburante on-device e foto
  manutenzioni disponibili nelle UI mobile. APK installato su Moto g82;
  resta il collaudo funzionale dell'utente.
- Local-first e Android sul ramo `feature/local-first-android`: dati API
  memorizzati in IndexedDB/SQLite, operazioni offline accodate, backup profilo
  disattivabile e sessione offline predisposti. APK release generato,
  installato e avviato su Pixel 7 emulato e Moto g82 5G fisico. Restano
  accesso completamente anonimo, conflitti multi-dispositivo e collaudo
  autenticato/offline su telefono.
- Pacchetto UI/tester: annullamento pagamento rate, swipe con cestino e undo,
  form mobile compatti, quattro lingue principali e dashboard tester
  implementati, verificati e pubblicati. Resta il collaudo visivo completo.
- Localizzazione: navigazione, componenti di sistema e testi principali sono
  disponibili in italiano, inglese, spagnolo e tedesco; molti testi storici
  delle singole schermate sono ancora hardcoded in italiano.
- Audit localizzazione in `docs/localization-assessment.md`: circa 250-350
  chiavi da migrare usando `gen_l10n`, senza nuove librerie o tabelle database.
- Dashboard tester: ruolo server-side, esiti persistenti e notifiche di
  sistema locali con nome, data e dettagli del record reale pronti. Non sono
  ancora vere push in background.
- Preferenze UX locali: direzione swipe e durata banner da 0 a 15 secondi; il
  banner di eliminazione viene chiuso anche al completamento dell'operazione.
- Registro manutenzioni semplificato a data, intervento e prezzo: pubblicato,
  ma resta il collaudo visivo manuale completo.
- Sessione desktop: la correzione del rinnovo token è pubblicata, ma va
  confermata sul browser che mostrava il problema.
- Avatar fotografico: gestione degli errori aggiunta, ma manca il collaudo
  multipiattaforma.
- Dashboard modulare: rispetta i flag, ma richiede verifica funzionale con
  tutte le combinazioni.
- Pagina Analisi: rispetta la visibilità dei moduli, ma usa ancora grafici e
  valori dimostrativi.
- Promemoria scadenze: vengono mostrati dentro l'app, non sono notifiche push
  in background.

## Funzioni mancanti

- Modalità locale senza aver mai creato un account e procedura successiva per
  collegare il database del dispositivo a un indirizzo email.
- Risoluzione guidata dei conflitti tra modifiche concorrenti da più
  dispositivi.
- CRUD dei rifornimenti.
- Notifiche Web Push/FCM reali.
- Test end-to-end e copertura widget delle nuove funzioni.
- Eventuali ulteriori accessori grafici per l'avatar, solo se richiesti dopo il
  collaudo visivo dell'utente.

## Ultima pubblicazione nota

- Commit applicativo: `4bcd59b`
- Worker: `https://spendwise.lopreteangelo97.workers.dev`
- Versione Worker: `83b4fffe-b930-42fc-9e81-ec6a9f5043ab`
- Database: `spendwise-db`
