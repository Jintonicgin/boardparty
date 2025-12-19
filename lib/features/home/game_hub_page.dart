import 'package:flutter/material.dart';

import '../party/create_room_page.dart';
import '../party/room_lobby_page.dart';
import '../match/quick_match_stake_page.dart';
import '../rank/ranking_page.dart';

class GameHubPage extends StatelessWidget {
  const GameHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        _GameCard(
          title: 'LAS VEGAS',
          subtitle: 'Dice & money casino game',
          icon: Icons.casino_outlined,
          gameId: 'las_vegas',
        ),
        SizedBox(height: 12),
        _GameCard(
          title: 'TICHU',
          subtitle: '4-player team trick-taking',
          icon: Icons.style_outlined,
          gameId: 'tichu',
        ),
        SizedBox(height: 12),
        _GameCard(
          title: 'BANG',
          subtitle: 'Hidden roles & shootout',
          icon: Icons.local_fire_department_outlined,
          gameId: 'bang',
        ),
        SizedBox(height: 12),
        _GameCard(
          title: '후추게임',
          subtitle: 'Coming soon',
          icon: Icons.local_dining_outlined,
          gameId: 'pepper',
        ),
      ],
    );
  }
}

class _GameCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String gameId;

  const _GameCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gameId,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => GameModePage(gameId: gameId, title: title),
          ),
        );
      },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).colorScheme.outline),
                ),
                child: Icon(icon, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

/// 게임 선택 후 모드 선택 화면
class GameModePage extends StatelessWidget {
  final String gameId;
  final String title;

  const GameModePage({
    super.key,
    required this.gameId,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final isTichu = gameId == 'tichu';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// 방 만들기
            _ModeButton(
              label: '방 만들기',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateRoomPage(
                      gameId: gameId,                 // ✅ 필수
                      gameTitle: title,               // ✅ 필수
                      mode: CreateRoomMode.online,    // ✅ 실제 enum
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            /// 방 찾기 (코드 입력 모달)
            _ModeButton(
              label: '방 찾기 (코드 입력)',
              onTap: () async {
                final code = await _showJoinByCodeDialog(context);
                if (code == null) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('방 코드 [$code] 입장 시도 (TODO)')),
                );
              },
            ),
            const SizedBox(height: 12),

            /// 빠른 대전
            _ModeButton(
              label: '빠른 대전',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QuickMatchStakePage(
                      gameId: gameId,
                      gameTitle: title,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            /// 혼자 하기
            _ModeButton(
              label: '혼자 하기 (봇)',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RoomLobbyPage(
                      gameId: gameId,
                      gameTitle: title,
                      isSolo: true,
                      players: isTichu ? 4 : 4,
                      stake: 0,
                      rounds: isTichu ? 0 : 5,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            /// 랭킹
            _ModeButton(
              label: '랭킹 확인',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RankingPage(gameTitle: title), // ✅ 수정
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _showJoinByCodeDialog(BuildContext context) async {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('방 코드 입력'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              hintText: '예) A1B2C',
              prefixIcon: Icon(Icons.key_outlined),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                final code = controller.text.trim().toUpperCase();
                if (code.length < 4) return;
                Navigator.pop(ctx, code);
              },
              child: const Text('입장'),
            ),
          ],
        );
      },
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ModeButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Text(label, style: const TextStyle(fontSize: 16)),
        ),
      ),
    );
  }
}