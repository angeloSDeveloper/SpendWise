import 'package:flutter/material.dart';

class ManualScreen extends StatelessWidget {
  const ManualScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Manuale utente')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Card(
          child: ListTile(
            leading: Icon(Icons.menu_book),
            title: Text('SpendWise — guida rapida'),
            subtitle: Text(
              'Questa sezione è pronta per essere ampliata con il manuale completo.',
            ),
          ),
        ),
        _Guide(
          title: 'Veicoli',
          icon: Icons.directions_car,
          text:
              'Aggiungi il veicolo e usa Rifornimenti, Manutenzione e Accessori. Per ricambi e accessori puoi allegare foto, leggere codici a barre e conservare venditore e garanzia.',
        ),
        _Guide(
          title: 'Spese quotidiane',
          icon: Icons.shopping_cart,
          text:
              'Scrivi cosa hai comprato: SpendWise propone automaticamente categoria e simbolo, modificabili quando serve.',
        ),
        _Guide(
          title: 'Abbonamenti',
          icon: Icons.autorenew,
          text:
              'Scegli un servizio comune, importo, periodicità settimanale, mensile o annuale e l’eventuale durata.',
        ),
        _Guide(
          title: 'Dashboard',
          icon: Icons.bar_chart,
          text:
              'Consulta riepiloghi e grafici; tocca gli elementi dei grafici per leggerne i valori.',
        ),
        _Guide(
          title: 'Impostazioni',
          icon: Icons.settings,
          text:
              'Personalizza tema, avatar e accesso biometrico sui dispositivi supportati.',
        ),
      ],
    ),
  );
}

class _Guide extends StatelessWidget {
  const _Guide({required this.title, required this.icon, required this.text});
  final String title, text;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Card(
    child: ExpansionTile(
      leading: Icon(icon),
      title: Text(title),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(text),
        ),
      ],
    ),
  );
}
