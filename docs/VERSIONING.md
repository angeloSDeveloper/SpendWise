# Versionamento e rami SpendWise

- Versione applicazione corrente: `1.0.0`.
- La versione non deve cambiare senza richiesta esplicita dell'utente.
- `main`: produzione stabile.
- `dev`: sviluppo approvato.
- `feature/*` e `experiment/*`: modifiche importanti ancora da verificare.

Le feature importanti vengono provate in locale sul proprio ramo. Solo dopo
l'approvazione vengono unite in `dev`, pubblicate e quindi allineate a `main`.
