import 'package:flutter/material.dart';

class TopStatusActions extends StatelessWidget {
  final int coins;
  final int diamonds;

  const TopStatusActions({
    super.key,
    required this.coins,
    required this.diamonds,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CurrencyChip(label: _fmt(coins), icon: Icons.monetization_on_outlined),
        const SizedBox(width: 8),
        _CurrencyChip(label: _fmt(diamonds), icon: Icons.diamond_outlined),
        const SizedBox(width: 8),
        const CircleAvatar(radius: 16, child: Icon(Icons.person, size: 18)),
        const SizedBox(width: 12),
      ],
    );
  }

  String _fmt(int n) => n.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+$)'),
        (m) => '${m[1]},',
      );
}

class _CurrencyChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _CurrencyChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}