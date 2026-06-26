# Setup SpendWise su un nuovo PC Windows

Questa guida serve per riprendere il progetto da un altro computer senza
dipendere dalla cronologia della chat locale.

## Prerequisiti

- Git
- Node.js 20 o superiore
- Accesso al repository GitHub `angeloSDeveloper/SpendWise`

Flutter non deve essere installato globalmente: lo script di bootstrap lo
scarica nella cartella locale `.tooling`, che non viene versionata su GitHub.

## Primo avvio

Clona il repository:

```powershell
git clone https://github.com/angeloSDeveloper/SpendWise.git
cd SpendWise
```

Esegui il bootstrap:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\bootstrap_windows.ps1
```

Lo script:

- scarica Flutter stable nella cartella `.tooling`;
- esegue `flutter pub get`;
- installa le dipendenze Node del Worker.

## Avvio locale

```powershell
.\.tooling\flutter\bin\flutter.bat run -d web-server --web-port 52100 --dart-define=API_URL=https://spendwise.lopreteangelo97.workers.dev/api
```

Poi apri:

```text
http://localhost:52100
```

## Note importanti

- Non eseguire `setup_spendwise.sh` su un repository gia' implementato: e' uno
  script storico di scaffolding e puo' sovrascrivere file.
- Prima di iniziare da un PC diverso, fai sempre:

```powershell
git fetch origin --prune
git pull --ff-only
```

- Se Git segnala modifiche locali o divergenze, fermati e chiedi prima di
  scartare o sovrascrivere qualcosa.
