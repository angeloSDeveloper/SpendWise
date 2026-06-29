# Registro lavori SpendWise

Questo documento conserva lo storico delle modifiche, delle verifiche e delle
attività ancora aperte. Le date sono espresse nel fuso orario Europe/Rome.

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
