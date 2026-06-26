# Istruzioni Codex per SpendWise

Queste istruzioni valgono per tutto il repository. Servono a permettere a
Codex di riprendere il lavoro da qualsiasi PC senza dipendere dalla cronologia
di una singola chat locale.

## Contesto iniziale obbligatorio

All'inizio di ogni nuova sessione su questo repository:

1. leggi `TODO.txt`;
2. leggi `docs/PROJECT_STATUS.md`;
3. leggi `docs/CHANGELOG_WORK.md`;
4. se devi pubblicare o configurare Cloudflare/GitHub, leggi anche
   `docs/deployment.md`.

Usa questi file come fonte dello stato del progetto. Non dare per completata
una funzione se in questi file risulta parziale, da verificare o mancante.

## Regole di prodotto

- L'app si chiama SpendWise.
- La versione attuale e' `1.0.0`.
- Non cambiare versione in `pubspec.yaml` o in `AppConstants.appVersion`
  finche' Angelo non lo chiede esplicitamente.
- Mantieni l'app in italiano.
- Mantieni l'API base con suffisso `/api`:
  `https://spendwise.lopreteangelo97.workers.dev/api`.
- Il Worker Cloudflare di produzione si chiama `spendwise`.
- Il database D1 si chiama `spendwise-db` e ha id
  `935a809b-2e0c-49d7-9413-3765c1c2d085`.

## Workflow Git

- Prima di modifiche importanti crea un ramo dedicato, ad esempio
  `feature/...`, `fix/...` o `docs/...`.
- Mantieni `main` e `dev` allineati quando una modifica e' approvata e
  rilasciabile.
- Non usare comandi distruttivi come `git reset --hard` o checkout forzati
  senza richiesta esplicita.
- Prima di consegnare controlla sempre `git status`.
- Se pubblichi modifiche, pusha i rami necessari su GitHub.

## Storico e tracciamento

Per ogni intervento:

1. aggiorna `TODO.txt` se cambia lo stato delle attivita';
2. aggiorna `docs/PROJECT_STATUS.md` quando cambia lo stato generale;
3. aggiungi una voce datata in `docs/CHANGELOG_WORK.md`;
4. indica in modo chiaro cosa e' completato, cosa e' parziale e cosa resta da
   fare.

Non confondere una UI predisposta con una funzione realmente attiva in
background o su servizi esterni.

## Comandi locali

Su questo progetto Flutter e Dart sono disponibili nella cartella `.tooling`.
Usa questi comandi da PowerShell:

```powershell
& .\.tooling\flutter\bin\dart.bat format <percorsi>
& .\.tooling\flutter\bin\flutter.bat analyze
& .\.tooling\flutter\bin\flutter.bat test
& .\.tooling\flutter\bin\flutter.bat build web --release --no-wasm-dry-run --dart-define=API_URL=https://spendwise.lopreteangelo97.workers.dev/api
```

Per eseguire l'app in locale:

```powershell
& .\.tooling\flutter\bin\flutter.bat run -d web-server --web-port 52100 --dart-define=API_URL=https://spendwise.lopreteangelo97.workers.dev/api
```

Per Cloudflare usa `npx.cmd` su Windows:

```powershell
& 'C:\Program Files\nodejs\npx.cmd' wrangler deploy --env production
```

Il deploy va eseguito dalla cartella `workers` e solo quando Angelo chiede di
rilasciare/pubblicare.

## Qualita'

- Esegui verifiche proporzionate al rischio della modifica.
- Per codice Flutter, di norma esegui almeno `flutter analyze` e i test
  pertinenti.
- Per modifiche solo documentali non e' necessario buildare l'app.
- Mantieni il codice pulito, leggibile e coerente con lo stile esistente.
- Evita dipendenze inutili.

## Preferenze operative di Angelo

- Angelo preferisce avanzamenti pratici, con spiegazioni brevi e chiare.
- Per modifiche grosse crea un ramo separato, cosi' si puo' tornare facilmente
  alla versione stabile.
- Se qualcosa e' incompleto, dichiaralo esplicitamente invece di considerarlo
  concluso.
- Per SpendWise la memoria principale del progetto e' nel repository, non nella
  cronologia di una singola chat.
