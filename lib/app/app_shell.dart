import 'package:flutter/material.dart';
import '../features/home/game_hub_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 1; // 기본 Home(H)

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const Center(child: Text('Store (TODO)')),
      const GameHubPage(),
      const Center(child: Text('Friends (TODO)')),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('BoardParty'),
        actions: [
          _CurrencyChip(label: '7,000', icon: Icons.monetization_on_outlined),
          const SizedBox(width: 8),
          _CurrencyChip(label: '120', icon: Icons.diamond_outlined),
          const SizedBox(width: 8),
          const CircleAvatar(radius: 16, child: Icon(Icons.person, size: 18)),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(child: pages[_index]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (v) => setState(() => _index = v),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Store'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Friends'),
        ],
      ),
    );
  }
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