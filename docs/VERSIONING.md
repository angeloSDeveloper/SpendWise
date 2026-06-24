# Versionamento e rami SpendWise

## Versione applicazione

La versione corrente è `1.0.0`.

Non deve essere modificata automaticamente. Un cambio versione deve essere
effettuato solo dopo una richiesta esplicita dell'utente.

Il valore tecnico nel `pubspec.yaml` è `1.0.0+1`: `1.0.0` è la versione
visibile, `+1` è il build number richiesto dagli strumenti Flutter.

## Strategia dei rami

- `main`: versione stabile pubblicata.
- `dev`: sviluppo approvato e integrato.
- `experiment/*` o `feature/*`: modifiche importanti ancora da valutare.

Per modifiche importanti:

1. creare un ramo da `dev`;
2. implementare e verificare in locale;
3. non distribuire in produzione;
4. chiedere approvazione visiva/funzionale;
5. solo dopo approvazione unire in `dev`, pubblicare e allineare `main`;
6. se rifiutata, eliminare il ramo senza alterare la versione stabile.
