# Valutazione localizzazione completa

Data audit: 1 luglio 2026.

## Stato attuale

SpendWise usa già il generatore ufficiale Flutter `gen_l10n` e dispone dei file
ARB per italiano, inglese, spagnolo e tedesco. Navigazione, componenti Material
e alcuni testi principali sono localizzati, ma gran parte delle schermate
storiche contiene ancora testo italiano direttamente nei widget.

L'audit statico ha rilevato almeno:

- 186 occorrenze di `Text(...)` con stringhe dirette;
- 57 etichette `labelText`;
- 13 tooltip;
- ulteriori messaggi dinamici, dialoghi ed errori server da catalogare.

La conversione completa richiede quindi circa 250-350 chiavi di traduzione.

## Soluzione consigliata

Continuare con `gen_l10n`, già incluso in Flutter:

- nessuna nuova dipendenza runtime;
- nessuna tabella o modifica al database;
- nessuna chiamata a servizi di traduzione esterni;
- supporto nativo a plurali, parametri e fallback;
- tree-shaking del codice non utilizzato.

Non è consigliata una libreria di traduzione automatica: aumenterebbe
dipendenze, traffico di rete, gestione privacy e rischio di testi incoerenti.

## Impatto stimato

- Codice applicativo: sostituzione meccanica e revisionata delle stringhe.
- File ARB: alcune decine di kilobyte per lingua.
- Bundle web/mobile: aumento limitato, da misurare con una build prima/dopo;
  non sono previsti asset pesanti.
- Database: nessun impatto.
- Worker: gli errori API dovranno in futuro usare codici stabili, lasciando
  all'app la traduzione del messaggio.

## Sequenza proposta

1. navigazione, autenticazione e dashboard;
2. spese, abbonamenti e rateizzazioni;
3. veicoli, manutenzioni, accessori e rifornimenti;
4. impostazioni, area tester, manuale e analisi;
5. dialoghi, validazioni, errori e test widget per ogni lingua.

Ogni fase deve mantenere l'italiano come lingua predefinita e verificare
overflow su mobile, in particolare per il tedesco.
