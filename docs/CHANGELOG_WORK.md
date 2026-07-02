# Registro lavori SpendWise

Questo documento conserva lo storico delle modifiche, delle verifiche e delle
attività ancora aperte. Le date sono espresse nel fuso orario Europe/Rome.

## 2 luglio 2026

### Sistema temi premium e identita' visiva

- Creato il ramo isolato `feature/premium-theme-system`.
- Ripristinato `Oceano` come tema predefinito per le nuove installazioni.
- Reso `Gold` piu' sobrio con fondo nero/antracite, bordi caldi e oro
  `#C9A227` limitato agli elementi attivi e alle azioni principali.
- Aggiunti i temi `Emerald`, `Violet`, `Crimson` e `Graphite`.
- Estesa la configurazione centralizzata con colori per hover, contrasto,
  bordi e testi; input, pulsanti, card, chip e navigazione usano ora questi
  valori senza colori locali duplicati.
- Migliorata la login card con bordo sottile, glow tematico leggero, input e
  password eye allineati al tema e nuovo testo:
  `Tutto cio' che conta, in un unico posto.`
- Uniformata la nomenclatura principale su `Dashboard`; nell'editor della
  dashboard `Widget` e' diventato `Personalizzazione`.
- Disegnato un marchio vettoriale originale `S + check` per login e favicon
  web, senza dipendenze grafiche aggiuntive.
- Rafforzati bordi e hover delle card interattive della dashboard.
- Mantenuta la versione applicativa `1.0.0`.
- `flutter analyze`: nessun problema.
- `flutter test`: 40 test superati.
- Verifica browser integrata non eseguita per assenza di un browser collegato
  alla sessione; resta il collaudo visivo manuale prima del rilascio.

### Guida iniziale e nomenclatura Panoramica

- Confermato il comportamento one-shot dell'onboarding tramite preferenza
  persistente: la guida automatica compare solo al primo utilizzo.
- Rimosso il comando `Guida` dalla schermata di login, evitando che venga
  riproposta durante gli accessi ordinari.
- Conservato nelle Impostazioni il comando volontario per rivedere la guida.
- Sostituito `Dashboard` con `Panoramica` nell'intestazione, nella navigazione,
  nel manuale, nell'editor e nei messaggi dell'interfaccia italiana.
- Conservato il termine `dashboard` esclusivamente nei nomi tecnici interni e
  nel testo promozionale dell'onboarding.
- Aggiunto test di persistenza che verifica che un onboarding completato non
  venga riproposto all'accesso successivo.
- `flutter analyze`: nessun problema.
- `flutter test`: 41 test superati.

### Aggiornamento immediato eliminazione abbonamenti

- Separato l'esito della DELETE dall'esito della sincronizzazione offline.
- La riga viene esclusa subito dalla lista e il totale viene ricalcolato nello
  stesso frame.
- Il record viene ripristinato soltanto se fallisce la DELETE; un errore della
  sincronizzazione successiva non fa piu' ricomparire un abbonamento gia'
  cancellato dal server.
- Il provider viene invalidato subito dopo la DELETE per riallineare la cache
  senza attendere il cambio di pagina.

### Fix blocco salvataggio abbonamenti

- Individuato il blocco nel percorso local-first: POST e PUT attendevano la
  scrittura IndexedDB prima di completare il form anche con backup cloud
  attivo.
- Le scritture online vengono ora inviate immediatamente al Worker; se manca
  la connessione, l'interceptor le applica localmente e le inserisce nella
  coda offline.
- Aggiunto un timeout di invio HTTP di 15 secondi per impedire richieste senza
  limite e garantire il ripristino del pulsante in caso di errore.

### Temi, avatar dashboard e diagnostica sincronizzazione

- Creato il ramo isolato `feature/gold-theme-sync-feedback`.
- Aggiunto il tema predefinito `Gold`, con fondo grigio Vesuvio, superfici
  antracite e accenti giallo/oro.
- La precedente palette blu resta selezionabile come tema `Oceano`; aggiunto
  anche il tema `Smeraldo`.
- La scelta del tema colore e' persistente e indipendente dalla scelta
  chiaro/sistema/scuro. Per le nuove installazioni la modalita' predefinita e'
  scura.
- Sostituiti i colori blu fissi della dashboard con il colore del tema attivo.
- La dashboard usa ora la configurazione avatar condivisa con le
  Impostazioni: iniziali `AC`, eventuale icona, forma, colori, bordo o foto.
- Sostituito `Cruscotto` con `Dashboard` in intestazione, onboarding, login ed
  editor widget.
- La sincronizzazione manuale mostra un messaggio di esito, il numero di
  modifiche inviate oppure il motivo leggibile dell'errore.
- Migliorato il replay della coda: una DELETE gia' applicata che restituisce
  `404` viene considerata completata e rimossa dalla coda.
- Corretto il difetto che rendeva instabili le eliminazioni: quando il backup
  cloud e' attivo, le DELETE vengono inviate immediatamente al Worker invece
  di essere sempre rinviate alla coda locale. In assenza di rete
  l'interceptor applica comunque la cancellazione locale e la accoda.
- La correzione vale sia per il cestino dopo swipe sia per il pulsante
  `Elimina` nel dettaglio dell'abbonamento.
- Rifinita la barra di navigazione mobile: sotto 480 px `Abbonamenti` diventa
  `Abbon.` e `Rateizzazioni` diventa `Rate`, evitando testi su due righe.
- Ridotto il testo delle etichette a 10,5 px e aggiunti bordo nero da 1,25 px,
  raggio coerente e ombra leggera per separare la barra dai contenuti.
- `flutter analyze`: nessun problema.
- `flutter test`: 39 test superati.
- Build web release completata.
- Pubblicata la modifica su Cloudflare dopo l'allineamento di `main`, `dev` e
  del ramo feature.

### Pubblicazione temi, sincronizzazione e navigazione mobile

- Ricostruita la web app release con API di produzione.
- Pubblicati Worker `spendwise` e asset Flutter integrati.
- Versione Cloudflare:
  `d2dd90ce-4432-4123-a061-972784a4e940`.
- Verificati dopo il deploy il sito pubblico (`HTTP 200`) e
  `/api/health` (`HTTP 200`, stato `ok`).

### Eliminazione immediata e dashboard responsive approvate

- Rimosso temporaneamente il flusso di annullamento delle eliminazioni:
  lo swipe rivela il cestino e il click esegue subito la cancellazione.
- L'eliminazione degli abbonamenti aggiorna immediatamente lista, numero di
  elementi e totale mensile; in caso di errore il record viene ripristinato.
- Dopo le eliminazioni local-first viene richiesta subito la sincronizzazione
  remota; il provider viene ricaricato solo dopo sincronizzazione riuscita,
  evitando che un record cancellato ricompaia dal server.
- Applicato lo stesso invio immediato della coda a spese, rate, veicoli,
  rifornimenti, manutenzioni e accessori eliminati tramite swipe.
- Centrato il carosello dei riepiloghi sullo stesso contenitore da 1180 px
  usato da intestazione e widget.
- Da 600 px in su i riepiloghi si riposizionano automaticamente su piu' righe;
  sotto 600 px conservano lo scorrimento orizzontale mobile.
- Aggiunti scorrimento verticale esplicito e scrollbar visibile su web,
  mantenendo spazio sufficiente sopra la navigazione inferiore.
- Aggiunto test responsive a 820 px e aggiornati i test swipe per verificare
  eliminazione immediata e assenza del comando `ANNULLA`.
- `flutter analyze`: nessun problema.
- `flutter test`: 38 test superati.
- Build web release completata.
- Nuova grafica approvata dall'utente; rami feature, `dev` e `main` allineati.
- Il collaudo e l'allineamento rami hanno preceduto il deploy registrato nella
  sezione successiva.

### Pubblicazione UI approvata

- Ricostruita la web app release con API di produzione.
- Pubblicati Worker `spendwise` e asset Flutter integrati.
- Versione Cloudflare:
  `26ea9803-bf3d-4419-9f36-3ba079fd69e6`.
- Verificati dopo il deploy il sito pubblico (`HTTP 200`) e
  `/api/health` (`HTTP 200`, stato `ok`).

### Fix caricamento infinito dashboard web

- Verificati server locale, API Cloudflare, CORS e singoli endpoint: tutte le
  richieste rispondevano correttamente con HTTP `200` in circa 55-70 ms.
- Individuato il blocco nell'interceptor local-first: dopo la risposta di rete
  attendeva quattro scritture IndexedDB concorrenti prima di completare i
  Future della dashboard.
- Reso il salvataggio della cache asincrono e non bloccante, con timeout di
  sicurezza a 3 secondi e isolamento degli errori della sola cache.
- Escluse dal nuovo salvataggio le risposte gia' provenienti da cache locale o
  replay offline.
- `flutter analyze`: nessun problema.
- `flutter test`: 37 test superati.

## 1 luglio 2026

### Prototipo UI finance moderna e cruscotto personalizzabile

- Creato da `dev` il ramo isolato `feature/hootz-inspired-ui`; `dev`, `main`
  e produzione non sono stati modificati.
- Studiati i pattern pubblici di Hootz e i 14 riferimenti forniti, mantenendo
  illustrazioni, marchio e codice originali di SpendWise.
- Aggiunto onboarding interattivo in quattro passaggi con panoramica di
  moduli, dashboard, analisi e sicurezza.
- Aggiunte configurazione facoltativa di PIN e biometria durante la guida e
  richiesta di configurazione sicurezza al primo accesso autenticato.
- Ridisegnato il login con layout mobile/desktop, stile scuro premium e
  accesso Google predisposto. Google OAuth reale resta disabilitato finche'
  non saranno configurati Client ID e verifica server-side.
- Ridisegnato il cruscotto con riepiloghi superiori cliccabili, azioni rapide,
  grafici e ultime spese.
- Aggiunto editor persistente per mostrare, nascondere, riordinare e
  ridimensionare i widget nei formati 4x4 e 4x8.
- Aggiornati tema globale e navigazione responsive; aggiunta nelle
  Impostazioni la voce per rivedere la guida iniziale.
- `flutter analyze`: nessun problema.
- `flutter test`: 37 test superati; aggiunti test per persistenza layout,
  fallback JSON, onboarding mobile ed editor widget mobile senza overflow.
- Build web release riuscita e prototipo avviato su
  `http://localhost:52100`.
- Il controllo visivo automatizzato nel browser integrato non e' stato
  possibile per indisponibilita' del browser nella sessione; resta il
  collaudo visivo dell'utente.

### PIN applicativo

- Aggiunta in Sicurezza la configurazione di un PIN numerico di almeno 4
  cifre, con conferma, modifica e disattivazione previa verifica.
- Il PIN non viene conservato in chiaro: sale casuale e hash SHA-256 sono
  salvati nello storage sicuro del dispositivo.
- Aggiunta schermata di sblocco all'avvio con PIN oppure biometria.
- Logout e sessione server non cancellano la configurazione PIN locale.
- Analisi pulita, 34 test superati, build web/APK riuscite e APK installato
  sul Moto g82 5G.
- Pubblicati web e Worker con versione
  `3f5939ef-d964-4af7-afa6-6b5b110ba970`; rami allineati.

### Rifiniture Android, biometria e acquisizione immagini

- Gli abbonamenti con undo vengono rimossi subito dalla lista e dal totale;
  `Annulla` ripristina il record entro la durata configurata.
- Compattata l'etichetta `Fine contratto` per impedirne il ritorno a capo.
- La biometria sblocca la sessione locale all'avvio; con sessione server
  scaduta i dati locali restano accessibili, mentre il backup richiede login.
- Aggiunto OCR latino on-device con ML Kit per leggere totale, litri e prezzo
  al litro da fotocamera o galleria nel nuovo rifornimento.
- Foto manutenzione da fotocamera/galleria confermate e limitate alle UI
  mobile; nessuna immagine OCR viene inviata a servizi esterni.
- `flutter analyze` pulito, 32 test superati, build web e APK release riuscite.
- APK aggiornato installato e avviato su Moto g82 5G.
- Promossi con fast-forward ramo feature, `dev` e `main`; web app e Worker
  pubblicati in produzione con versione
  `f474aeb9-7722-41d7-90cc-574bd30a124e`.

### Prima base local-first e Android

- Creato il ramo isolato `feature/local-first-android`; produzione, `main` e
  `dev` non sono stati modificati.
- Aggiunte in Drift le tabelle persistenti `api_cache` e
  `offline_requests`, disponibili in IndexedDB sul web e SQLite su Android.
- Le letture dei moduli principali usano la cache quando la rete non è
  disponibile; le scritture aggiornano subito la copia locale e vengono
  accodate in ordine.
- Aggiunta in Impostazioni l'opzione `Backup sul profilo`: disattivandola i
  dati restano sul dispositivo, riattivandola parte l'invio della coda.
- Le scritture vengono confermate sul dispositivo prima dell'invio; il backup
  tenta la coda all'apertura della dashboard e ogni 30 secondi.
- Separati cache e operazioni pendenti per utente.
- Predisposto il Worker ad accettare gli id locali dei registri veicolo. La
  modifica server resta da pubblicare quando il ramo verrà approvato.
- Conservata una sessione già valida quando l'app viene riaperta senza rete.
- Creato il progetto Android con application id neutro
  `app.spendwise.mobile`, permessi Internet/notifiche, supporto
  biometrico e configurazione notifiche locali.
- Generato `app-release.apk` con API di produzione, firma di test e dimensione
  di circa 81 MB.
- APK installato e avviato realmente su emulatore Pixel 7; verificata la
  schermata login mobile e il processo applicativo.
- APK installato via USB e avviato con successo anche su dispositivo fisico
  Moto g82 5G con Android 13.
- `flutter analyze`: nessun problema.
- `flutter test`: 31 test superati, inclusi cache per utente, mutazioni locali
  e ordine della coda.
- Build web release e build APK release completate.
- Restano parziali la modalità completamente anonima, la gestione visuale dei
  conflitti multi-dispositivo e il collaudo autenticato/offline su telefono.

### Identità neutra del progetto

- Stabilito che web e Android restano un unico progetto Flutter; Android
  Studio è uno strumento complementare per SDK, emulatori, log e firma.
- Sostituito il package Android personale con `app.spendwise.mobile` prima di
  qualsiasi pubblicazione sul Play Store.
- Rimossi email, nomi personali e fallback account dall'autorizzazione tester,
  dagli esempi UI e dalla migrazione riproducibile.
- Aggiunta in `AGENTS.md` la regola permanente che vieta nuovi riferimenti
  personali e richiede la migrazione degli URL temporanei al futuro dominio.

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
- Aggiunto ruolo D1 `tester`, assegnato all'account amministrativo,
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
