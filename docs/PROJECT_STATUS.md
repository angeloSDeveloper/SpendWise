# Stato corrente di SpendWise

Ultimo aggiornamento: 29 giugno 2026

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

## Funzioni completate

- Builder avatar premium con anteprima live, preset, randomizzazione, forme,
  iniziali, icone, colori, gradiente, bordo e dimensioni.
- Registro veicoli con manutenzioni e accessori.
- Modifica, archiviazione, ripristino ed eliminazione dei veicoli.
- Abbonamenti con prossima scadenza e ricorrenza personalizzata in mesi.
- Piani rateali con prossima scadenza e registrazione della rata pagata.
- Form piani rateali con data iniziale/prima rata e scadenza finale calcolata
  automaticamente in base a frequenza e numero rate.
- CRUD per spese quotidiane, abbonamenti, rate, manutenzioni e accessori.
- Menu principali configurabili dalle impostazioni.
- Preferenze locali per tema, avatar, biometria e promemoria.
- Avatar vettoriale leggero semplificato alle versioni Uomo e Donna, con foto
  personale opzionale.

## Funzioni parziali

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

- CRUD dei rifornimenti.
- Notifiche Web Push/FCM reali.
- Test end-to-end e copertura widget delle nuove funzioni.
- Eventuali ulteriori accessori grafici per l'avatar, solo se richiesti dopo il
  collaudo visivo dell'utente.

## Ultima pubblicazione nota

- Commit precedente: `a86592c`
- Worker: `https://spendwise.lopreteangelo97.workers.dev`
- Database: `spendwise-db`
