import 'package:flutter/material.dart';

class CategoryHeader extends StatelessWidget {
  const CategoryHeader({
    required this.color,
    required this.title,
    required this.value,
    required this.subtitle,
    super.key,
  });
  final Color color;
  final String title, value, subtitle;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: color,
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
    ),
    child: SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineLarge?.copyWith(color: Colors.white),
          ),
          Text(subtitle, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    ),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.message,
    required this.action,
    super.key,
  });
  final IconData icon;
  final String message;
  final VoidCallback action;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 72, color: Theme.of(context).colorScheme.outline),
        const SizedBox(height: 16),
        Text(message),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: action,
          icon: const Icon(Icons.add),
          label: const Text('Aggiungi'),
        ),
      ],
    ),
  );
}

String euro(num amount) =>
    '€ ${amount.toStringAsFixed(2).replaceAll('.', ',')}';
