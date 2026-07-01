# Registro lavori SpendWise

Questo documento conserva lo storico delle modifiche, delle verifiche e delle
attività ancora aperte. Le date sono espresse nel fuso orario Europe/Rome.

## 1 luglio 2026

### UX mobile, eliminazione sicura e area tester

- Aggiunto annullamento dell'ultima rata segnata come pagata, con ripristino
  del conteggio, dello stato attivo e della prossima scadenza.
- Creato un componente swipe riutilizzabile: il gesto mostra soltanto il
  cestino; l'eliminazione parte al click ed è annullabile.
- Applicato il componente a spese, abbonamenti, rate, veicoli, rifornimenti,
  manutenzioni e accessori nelle rispettive liste mobile.
- Aggiunta eliminazione API dei rifornimenti.
- Compattati i form mobile richiesti e corretti gli overflow rilevati dai test
  a 390 px.
- Semplificato il rinnovo degli abbonamenti; la modalità personalizzata
  consente di inserire direttamente il numero di mesi.
- Aggiunta selezione lingua italiano, inglese, spagnolo e tedesco; localizzati
  navigazione, componenti Material e stato sincronizzazione. La traduzione
  completa dei testi storici resta parziale.
- Aggiunto ruolo D1 `tester`, assegnato dalla migrazione all'account di Angelo,
  e dashboard riservata con quattro casi di notifica e stato persistente
  `da testare`, `superato`, `parziale` o `KO`.
- I test notifiche usano la notifica di sistema del dispositivo/browser
  corrente. Non sono push in background: Web Push/FCM e registrazione
  dispositivi restano da implementare con le relative credenziali.

### Rifiniture dopo collaudo visivo

- Ripristinata l'etichetta compatta `Spese` nella navigazione inferiore.
- Rimosso lo sfondo rosso del gesto swipe.
- Lo swipe aperto si richiude toccando un altro elemento e solo una riga può
  restare aperta alla volta.
- Aggiunta nelle Impostazioni la scelta swipe a sinistra/destra; il valore
  predefinito è ora sinistra.
- Tutti gli Snackbar passano da un unico gestore: durata configurabile da 0 a
  15 secondi, valore 0 senza banner e chiusura al tap.
- Anche l'attesa prima dell'eliminazione segue la durata configurata; con 0
  l'eliminazione è immediata.
- Semplificata la periodicità degli abbonamenti a settimanale, mensile,
  annuale o personalizzata con numero mesi inserito dall'utente.
- Corretta l'etichetta `1 mese` della pagina Analisi affinché resti su una
  riga.
- Spostato l'accesso alla dashboard tester in un'icona dedicata accanto alle
  Impostazioni nella dashboard.
- Uniformati margini e area di pressione delle icone della dashboard; il
  pulsante della dashboard tester e' ora l'ultimo a destra.
- Garantita la chiusura automatica del banner quando l'eliminazione viene
  completata, oltre alla chiusura al tap e all'annullamento gia' disponibili.
- Resi parlanti i quattro test di notifica: nome, data, importo e avanzamento
  vengono ricavati da rate e abbonamenti reali quando presenti.
- Eseguito audit localizzazione: almeno 256 stringhe UI dirette, circa 250-350
  chiavi finali stimate. Confermato `gen_l10n` come soluzione più leggera,
  senza nuove dipendenze o database; dettagli in
  `docs/localization-assessment.md`.

### Verifiche UX/tester

- `flutter analyze`: nessun problema.
- `flutter test`: 28 test superati.
- Aggiunti test del gesto swipe, attesa configurabile, annullamento e layout
  mobile dei cinque form richiesti.
- Verificata anche la scomparsa automatica del banner al completamento
  dell'eliminazione.
- Typecheck Worker TypeScript superato.
- Build web release completata.
- Migrazione D1 e deploy inizialmente non eseguiti durante lo sviluppo.

### Pubblicazione UX/tester

- Promossi con fast-forward i commit del ramo
  `feature/mobile-ux-tester-dashboard` su `dev` e `main`.
- Applicata al database D1 `spendwise-db` la migrazione
  `2026-07-01_tester_dashboard.sql`: 3 query completate con successo.
- Ricostruiti gli asset Flutter web release con API di produzione.
- Pubblicati Worker e sito SpendWise su Cloudflare.
- Versione Worker pubblicata:
  `83b4fffe-b930-42fc-9e81-ec6a9f5043ab`.
- Verificati dopo il deploy il sito pubblico (`HTTP 200`) e
  `/api/health` (`HTTP 200`, stato `ok`).
- Restano esplicitamente fuori da questo rilascio le vere notifiche push in
  background Web Push/FCM.

### Completamento handoff rate, manutenzioni e carburante

- Corretto il Worker per distinguere i campi assenti dai campi presenti con
  valore `null`: la fine contratto opzionale degli abbonamenti può ora essere
  aggiunta, modificata e rimossa.
- Aggiunta la modalità `Un acquisto` / `Più acquisti` ai piani rateali.
  Gestore, numero rate, frequenza e date sono comuni; prodotto, totale e
  importo rata restano indipendenti.
- Aggiunto `POST /api/installments/batch` con validazione preventiva e
  `DB.batch(...)`, così il salvataggio multiplo è atomico.
- Persistita `endDate` sui piani rateali e mostrata nel dettaglio, con calcolo
  di compatibilità per i piani precedenti.
- Corretto l'avanzamento delle scadenze mensili a partire dalla data iniziale
  originale e rimossa la prossima scadenza attiva alla rata conclusiva.
- Ridotto il registro manutenzioni a data, intervento e prezzo su desktop e
  mobile, conservando il dettaglio completo.
- Aggiunta la capacità serbatoio opzionale ai veicoli. Il flag `Pieno
  completo`, inizialmente disattivato, precompila i litri solo quando la
  capacità è disponibile.
- Aggiunte migrazioni D1 separate per capacità serbatoio e scadenza finale.

### Verifiche

- Rigenerati Freezed, Retrofit e Drift.
- `flutter analyze`: nessun problema.
- `flutter test`: 15 test superati, inclusi calendario settimanale,
  bisettimanale, mensile/fine mese e workflow widget singolo, multiplo e pieno
  completo.
- Typecheck Worker TypeScript superato.
- Build web release completata con API di produzione configurata.
- Il collaudo visivo completo resta da concludere sul browser dell'utente.

### Pubblicazione e inserimento Klarna

- Creato un backup D1 prima dell'intervento.
- Applicate in produzione le migrazioni per `tank_capacity_liters` ed
  `end_date`.
- Pubblicati app web e Worker Cloudflare `spendwise`.
- Versione Worker pubblicata:
  `ca19fb30-8ec6-48e8-8275-41fa04e99227`.
- Verificati endpoint health e presenza dell'endpoint batch protetto.
- Corretto l'avanzamento dell'ultima rata affinché usi la scadenza finale
  persistita, utile per il calendario Klarna 16 luglio / 15 agosto.
- Inseriti nell'account dell'utente tre piani eBay/Klarna da 3 rate, con una
  rata già pagata, importi rata `7,76`, `4,61` e `31,66` euro, prossima
  scadenza 16 luglio 2026 e scadenza finale 15 agosto 2026.
- Rimossa e verificata nel database la fine contratto di Amazon Prime, come
  richiesto durante il collaudo.
- Riavviata l'app locale su `http://localhost:52100` collegata alla nuova API
  di produzione.

## 29 giugno 2026

### Rate e sessione scaduta

- Nel form `Nuovo piano rateale` sostituita la scadenza manuale con la data
  iniziale/prima rata.
- La prossima scadenza viene calcolata automaticamente dalla data iniziale e
  dalle rate gia' pagate.
- La scadenza finale viene calcolata automaticamente in base a data iniziale,
  frequenza e numero rate.
- Aggiunta gestione piu' leggibile dell'errore `401`: se il refresh fallisce,
  i token locali vengono rimossi e il form mostra `Sessione scaduta, accedi di
  nuovo` invece del messaggio tecnico Dio.
- Aggiunti test sul calendario rateale mensile/settimanale.

## 26 giugno 2026

### Setup nuovo PC Windows

- Aggiunto `tools/bootstrap_windows.ps1` per configurare un nuovo PC Windows
  senza rilanciare lo script storico `setup_spendwise.sh`.
- Aggiunta la guida `docs/new-pc-setup.md`.
- Aggiornato `AGENTS.md` con l'avviso di non usare `setup_spendwise.sh` su un
  repository gia' implementato e con il comando di bootstrap corretto.

### Memoria operativa Codex

- Aggiunto `AGENTS.md` nella root del repository.
- Il file contiene le istruzioni stabili per riprendere SpendWise da un altro
  PC o da una nuova sessione Codex senza dipendere dalla cronologia locale.
- Documentati file da leggere a inizio sessione, versione bloccata a `1.0.0`,
  workflow Git, comandi Flutter/Cloudflare e regole di aggiornamento dello
  storico.
- Aggiunta la regola operativa di eseguire `git fetch origin --prune` e
  controllare l'allineamento del ramo quando si riprende il lavoro da piu' PC.
- Nessuna modifica al codice applicativo.

## 25 giugno 2026

### Builder avatar profilo (ramo di prova)

- Corretta la modalità mobile: aggiunta un'anteprima live compatta e fissa
  sotto la barra superiore, mentre soltanto i controlli scorrono verticalmente.
- Creato il ramo isolato `feature/avatar-builder-profile`, senza modificare o
  pubblicare il ramo stabile `dev`.
- Aggiunta in Impostazioni la sezione `Personalizza avatar`.
- Implementati anteprima live, iniziali fino a tre caratteri, icone, quattro
  forme, colori solidi, gradiente, colore personalizzato, bordo configurabile
  e dimensioni S/M/L/XL.
- Aggiunti cinque preset rapidi, randomizzazione controllata, ripristino,
  annullamento e salvataggio locale della configurazione in JSON.
- La schermata usa un layout a due colonne su desktop e verticale su mobile,
  con tema chiaro/scuro e azioni responsive.
- La versione applicazione resta `1.0.0` ed è ora visibile nelle Impostazioni.
- Aggiunti test per serializzazione, persistenza e rendering iniziali/icona.
- Verificati `flutter analyze`, tutti i test e la build web release.
- Funzione approvata dall'utente dopo il collaudo visivo locale.
- Promossa sui rami `dev` e `main` e pubblicata sul Worker Cloudflare
  `spendwise`.

## 24 giugno 2026

### Avatar stabile semplificato

- Su richiesta dell'utente, rimossi dall'interfaccia stabile tutti i controlli
  avanzati dell'avatar.
- Restano esclusivamente due scelte: Uomo e Donna.
- Conservata la possibilità di usare una fotografia personale.
- La scelta viene salvata localmente e ripristinata all'avvio.
- Il ramo sperimentale 2.5D resta separato e recuperabile.

### Avatar vettoriale moderno

- Sostituito l'avatar provvisorio basato su emoji e icone con un disegno
  vettoriale originale realizzato tramite `CustomPainter`.
- Aggiunte 5 espressioni, 3 acconciature e 2 vestiti: 30 combinazioni base.
- Aggiunte palette separate per carnagione, capelli, vestiti e sfondo.
- Conservata la possibilità di usare una fotografia e di tornare all'avatar.
- Convertite automaticamente le vecchie preferenze avatar ai nuovi valori.
- Nessun pacchetto grafico o asset esterno aggiunto.
- Aggiunto test widget che disegna e verifica tutte le 30 combinazioni.
- Verificati analisi statica, test Flutter e build web release.

### Rettifica dello stato

- Eseguito un audit dopo la segnalazione dell'utente.
- Corretto il tracciamento: alcune funzioni erano state dichiarate completate
  pur essendo parziali o non ancora collaudate.
- Il CRUD non copre ancora i rifornimenti.
- Le notifiche implementate sono promemoria interni all'app, non vere push in
  background.
- L'avatar componibile è una prima versione e il caricamento della foto deve
  ancora essere collaudato su tutte le piattaforme.
- La pagina Analisi filtra i moduli ma usa ancora dati dimostrativi.
- Creato `docs/PROJECT_STATUS.md` come fonte dello stato corrente e riscritto
  `TODO.txt` con una legenda non ambigua.

### Implementato

- Corretto il ripristino della sessione: all'avvio i token vengono validati e
  rinnovati; una sessione scaduta torna correttamente al login invece di
  mostrare errori `401` su dashboard e veicoli.
- Abbonamenti con prossima scadenza selezionabile, rinnovo settimanale,
  mensile, trimestrale, annuale o personalizzato in mesi.
- Calcolo della prossima scadenza e dettaglio abbonamento.
- Modifica ed eliminazione per spese quotidiane, abbonamenti e rate. Il CRUD
  dei rifornimenti resta da implementare.
- Gestione completa dei piani rateali e avanzamento automatico della prossima
  scadenza quando una rata viene segnata come pagata.
- Modifica, eliminazione, archiviazione e ripristino dei veicoli.
- Conferma esplicita che l'eliminazione del veicolo cancella anche rifornimenti,
  manutenzioni e accessori collegati.
- Avatar fotografico reso più robusto e prima versione dell'avatar semplice
  personalizzabile con faccina, capelli, carnagione e colore dei vestiti.
- Sezioni di navigazione configurabili; dashboard e statistiche rispettano i
  moduli selezionati.
- Preferenze e avvisi interni per le scadenze di abbonamenti e rate. Non sono
  ancora notifiche push in background.

### Verifiche

- Analisi statica Flutter.
- Test automatici Flutter.
- Build web di produzione.
- Migrazioni Cloudflare D1.
- Controllo API e pubblicazione Cloudflare Worker.

### Ancora da fare

- Vere notifiche push in background richiedono registrazione Web Push/FCM,
  service worker e salvataggio dei token dispositivo. Le preferenze e il
  calcolo delle scadenze sono predisposti; questa integrazione resta separata
  perché necessita delle credenziali del servizio push.
- Ampliare ulteriormente gli elementi grafici dell'avatar.

## Storico precedente

- 22 giugno 2026: registro manutenzione dettagliato, importazione dati Lancia
  Delta, rifornimenti, accessori veicolo, tema, dashboard, manuale e
  pubblicazione iniziale Cloudflare/GitHub.
