import 'package:flutter/material.dart';
import '../../widgets/top_status_actions.dart';
import 'quick_match_waiting_page.dart';

class QuickMatchStakePage extends StatelessWidget {
  final String gameId;
  final String gameTitle;

  const QuickMatchStakePage({
    super.key,
    required this.gameId,
    required this.gameTitle,
  });

  int _prize(int stake) {
    switch (stake) {
      case 3000:
        return 5000;
      case 5000:
        return 8000;
      case 10000:
        return 15000;
      default:
        return (stake * 1.5).round();
    }
  }

  @override
  Widget build(BuildContext context) {
    final stakes = const [3000, 5000, 10000];

    return Scaffold(
      appBar: AppBar(
        title: Text('$gameTitle · 빠른대전'),
        actions: const [TopStatusActions(coins: 7000, diamonds: 120)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('참가 금액 선택', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          ...stakes.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  child: ListTile(
                    leading: const Icon(Icons.monetization_on_outlined),
                    title: Text('$s 코인'),
                    subtitle: Text('🏆 1등 프라이즈: ${_prize(s)} 코인'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => QuickMatchWaitingPage(
                            gameId: gameId,
                            gameTitle: gameTitle,
                            stake: s,
                            prize: _prize(s),
                            requiredPlayers: (gameId == 'tichu' || gameId == 'las_vegas') ? 4 : 4,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              )),
          const SizedBox(height: 8),
          Text(
            '※ 매칭 취소 시 코인은 차감되지 않습니다.\n※ 인원이 모이면 즉시 시작합니다.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}