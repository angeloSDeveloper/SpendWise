# Shared Widgets

L'agente deve implementare i seguenti widget riutilizzabili:

## expense_card.dart
Widget generico per mostrare una spesa con:
- leading: icona colorata con sfondo categoria
- title: descrizione
- subtitle: data + nota (opzionale)
- trailing: importo (rosso)
- onTap callback

## category_header.dart
Widget header colorato per le schermate categoria:
- color: Color (del tema categoria)
- title: String
- subtitle: String (es. totale mese)
- icon: IconData
- children: List<Widget> (widget aggiuntivi nell'header)

## amount_display.dart
Mostra un importo formattato con:
- amount: double
- currency: String (default 'EUR')
- style: TextStyle
- isNegative: bool (per mostrare in rosso)

## sync_status_indicator.dart
Piccola icona nella AppBar che mostra:
- Verde con checkmark: sincronizzato
- Arancio con orologio: modifiche in attesa
- Grigio con wifi-off: offline
- Spinner: sincronizzazione in corso

## empty_state.dart
Widget per stati vuoti con:
- icon: Widget (lottie animation o SVG)
- title: String
- subtitle: String
- action: Widget (opzionale)

## loading_overlay.dart
Overlay di caricamento semi-trasparente

## confirm_delete_dialog.dart
Dialog di conferma eliminazione generico

## custom_text_field.dart
TextField stilizzato con validazione inline

## subscription_card.dart
Card completa per abbonamento (vedi istruzioni SubscriptionsScreen)

## installment_progress_card.dart
Card con progress bar per piano rateizzazione

## fuel_entry_item.dart
ListTile per rifornimento

## maintenance_item.dart
ListTile per voce manutenzione con part code copiabile
