# Registro lavori SpendWise

Questo documento conserva lo storico delle modifiche, delle verifiche e delle
attività ancora aperte. Le date sono espresse nel fuso orario Europe/Rome.

## 24 giugno 2026

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
