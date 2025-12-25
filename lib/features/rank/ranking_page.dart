import 'package:flutter/material.dart';
import '../../widgets/top_status_actions.dart';

class RankingPage extends StatelessWidget {
  final String gameTitle;
  const RankingPage({super.key, required this.gameTitle});

  @override
  Widget build(BuildContext context) {
    // mock: 상위 30명 + 내 랭킹 표시 형태만
    final top = List.generate(30, (i) => (rank: i + 1, name: 'Player_${i + 1}', score: 100000 - i * 1234));
    final myRank = 187;

    return Scaffold(
      appBar: AppBar(
        title: Text('$gameTitle · 랭킹'),
        actions: const [TopStatusActions(coins: 7000, diamonds: 120)],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: top.length,
              itemBuilder: (_, i) {
                final r = top[i];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text('${r.rank}')),
                    title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.w900)),
                    trailing: Text('${r.score}', style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                );
              },
            ),
          ),
          Card(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: ListTile(
              leading: const Icon(Icons.person),
              title: const Text('내 순위', style: TextStyle(fontWeight: FontWeight.w900)),
              trailing: Text('$myRank위', style: const TextStyle(fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }
}