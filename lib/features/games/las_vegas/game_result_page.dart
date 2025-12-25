import 'package:flutter/material.dart';

// ✅ GameModePage가 들어있는 파일 (네가 준 위치)
import '../../home/game_hub_page.dart';

// ✅ 다시하기(리플레이)를 위해 인게임 페이지 import
import 'las_vegas_play_page.dart';

/// ===== Models =====

enum SeatRole { core, mercenary, bot }

class PlayerResult {
  final int seatIndex;
  final String name;
  final SeatRole role;

  /// 라스베가스면 "돈" 또는 "점수"
  final int score;

  /// 추가로 보여주고 싶으면 사용(예: +코인)
  final int deltaCoins;

  const PlayerResult({
    required this.seatIndex,
    required this.name,
    required this.role,
    required this.score,
    this.deltaCoins = 0,
  });
}

class GameResultSummary {
  final String gameTitle; // 'LAS VEGAS'
  final int mySeatIndex;

  /// 높은 점수(돈)가 1등이라고 가정(정렬되어 있으면 베스트)
  final List<PlayerResult> leaderboardSorted;

  /// 우측 보상 박스
  final int rewardCoins;
  final int rewardExp;

  /// 하이라이트(선택)
  final String? highlight1;
  final String? highlight2;
  final String? highlight3;

  const GameResultSummary({
    required this.gameTitle,
    required this.mySeatIndex,
    required this.leaderboardSorted,
    required this.rewardCoins,
    this.rewardExp = 0,
    this.highlight1,
    this.highlight2,
    this.highlight3,
  });

  bool get hasLeaderboard => leaderboardSorted.isNotEmpty;

  PlayerResult? get winnerOrNull => hasLeaderboard ? leaderboardSorted.first : null;

  PlayerResult? myResultOrNull() {
    if (!hasLeaderboard) return null;
    for (final r in leaderboardSorted) {
      if (r.seatIndex == mySeatIndex) return r;
    }
    return null;
  }
}

/// ===== Page =====
/// - 다시하기: 같은 설정으로 LasVegasPlayPage 재시작
/// - 나가기: GameModePage(모드 선택 화면)로 이동
class GameResultPage extends StatefulWidget {
  const GameResultPage({
    super.key,
    required this.summary,

    // ✅ "나가기" 버튼이 GameModePage로 돌아가려면 필요
    required this.gameId,
    required this.gameTitle,

    // ✅ "다시하기"에 필요
    required this.playerCount,
    required this.botCount,
    required this.myPlayerIndex,

    // ✅ 다시하기 시 “원래 설정 그대로” 재구동을 위해 추가
    required this.rounds,
    required this.turnOrder,
    required this.seatNames,
    required this.selectedColorLabels,

    // ✅ 결과/재시작시 필요하면 함께 넘김 (MVP 유지)
    this.isSolo = true,
    this.stake = 0,
    this.roomCode = 'LOCAL',
  });

  final GameResultSummary summary;

  final String gameId;
  final String gameTitle;

  final int playerCount;
  final int botCount;
  final int myPlayerIndex;

  // ✅ restart payload
  final int rounds;
  final List<int> turnOrder;
  final List<String> seatNames;
  final List<String> selectedColorLabels;

  final bool isSolo;
  final int stake;
  final String roomCode;

  @override
  State<GameResultPage> createState() => _GameResultPageState();
}

class _GameResultPageState extends State<GameResultPage> {
  bool _busy = false;

  Future<void> _runBusy(Future<void> Function() job) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await job();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('오류: $e')));
    } finally {
      // ✅ Navigator로 화면이 바뀐 뒤에도 안전하게 처리
      if (!mounted) return;
      setState(() => _busy = false);
    }
  }

  Future<void> _restartGame() async {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => LasVegasPlayPage(
          playerCount: widget.playerCount,
          botCount: widget.botCount,
          myPlayerIndex: widget.myPlayerIndex,

          // ✅ 라운드/순서/이름/색 유지
          rounds: widget.rounds,
          turnOrder: widget.turnOrder,
          seatNames: widget.seatNames,
          selectedColorLabels: widget.selectedColorLabels,

          // ✅ 기타 정보도 유지 (필요하면 인게임/결과에서 사용)
          isSolo: widget.isSolo,
          stake: widget.stake,
          roomCode: widget.roomCode,
        ),
      ),
    );
  }

  Future<void> _exitToGameMode() async {
    // ✅ 결과 화면에서 "모드 선택"으로 완전 갈아타기 (스택 완전 정리)
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => GameModePage(
          gameId: widget.gameId,
          title: widget.gameTitle,
        ),
      ),
      (route) => false, // ✅ 핵심 수정: 이전 스택 전부 제거
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = widget.summary;
    final my = summary.myResultOrNull();
    final myRole = my?.role ?? SeatRole.core;
    final winner = summary.winnerOrNull;

    final useRow = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: AppBar(title: Text('${summary.gameTitle} · 결과')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: useRow
              ? Row(
                  children: [
                    Expanded(flex: 6, child: _LeftPanel(summary: summary)),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 4,
                      child: _RightPanel(
                        summary: summary,
                        myRole: myRole,
                        winner: winner,
                        busy: _busy,
                        onRestart: () => _runBusy(_restartGame),
                        onExit: () => _runBusy(_exitToGameMode),
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    Expanded(child: _LeftPanel(summary: summary)),
                    const SizedBox(height: 14),
                    _RightPanel(
                      summary: summary,
                      myRole: myRole,
                      winner: winner,
                      busy: _busy,
                      onRestart: () => _runBusy(_restartGame),
                      onExit: () => _runBusy(_exitToGameMode),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// ===== Left panel =====
class _LeftPanel extends StatelessWidget {
  const _LeftPanel({required this.summary});
  final GameResultSummary summary;

  String _fmtMoneyLike(int v) {
    final sign = v < 0 ? '-' : '';
    final abs = v.abs();
    if (abs >= 1000) return '$sign\$${(abs / 1000).round()}k';
    return '$sign$abs';
  }

  int? _myRank(GameResultSummary s) {
    for (int i = 0; i < s.leaderboardSorted.length; i++) {
      if (s.leaderboardSorted[i].seatIndex == s.mySeatIndex) return i + 1;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final winner = summary.winnerOrNull;
    final myRank = summary.hasLeaderboard ? _myRank(summary) : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.emoji_events_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    winner == null ? '결과' : '🏆 1등: ${winner.name}',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _Pill(
                  text: summary.hasLeaderboard ? '내 순위: ${myRank ?? '-'}등' : '내 순위: -',
                  tone: _PillTone.primary,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Expanded(
              child: summary.hasLeaderboard
                  ? ListView.separated(
                      itemCount: summary.leaderboardSorted.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final r = summary.leaderboardSorted[i];
                        final isMe = r.seatIndex == summary.mySeatIndex;
                        final rank = i + 1;

                        return _RankRow(
                          rank: rank,
                          name: r.name,
                          role: r.role,
                          isMe: isMe,
                          scoreLabel: _fmtMoneyLike(r.score),
                          deltaCoins: r.deltaCoins,
                        );
                      },
                    )
                  : Center(
                      child: Text(
                        '결과 데이터가 없습니다.\n(leaderboardSorted 비어있음)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            if (summary.highlight1 != null || summary.highlight2 != null || summary.highlight3 != null)
              _HighlightsBox(h1: summary.highlight1, h2: summary.highlight2, h3: summary.highlight3),
          ],
        ),
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({
    required this.rank,
    required this.name,
    required this.role,
    required this.isMe,
    required this.scoreLabel,
    required this.deltaCoins,
  });

  final int rank;
  final String name;
  final SeatRole role;
  final bool isMe;
  final String scoreLabel;
  final int deltaCoins;

  String get _roleLabel {
    switch (role) {
      case SeatRole.core:
        return 'CORE';
      case SeatRole.mercenary:
        return '용병';
      case SeatRole.bot:
        return 'BOT';
    }
  }

  @override
  Widget build(BuildContext context) {
    final outline = Theme.of(context).colorScheme.outline;
    final ring = Theme.of(context).colorScheme.primary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isMe ? ring : outline, width: isMe ? 2 : 1),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Row(
        children: [
          CircleAvatar(child: Text('$rank', style: const TextStyle(fontWeight: FontWeight.w900))),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(width: 8),
                _Pill(
                  text: _roleLabel,
                  tone: role == SeatRole.mercenary ? _PillTone.warn : _PillTone.neutral,
                ),
                if (isMe) ...[
                  const SizedBox(width: 8),
                  _Pill(text: 'ME', tone: _PillTone.primary),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(scoreLabel, style: const TextStyle(fontWeight: FontWeight.w900)),
              if (deltaCoins != 0)
                Text(
                  deltaCoins > 0 ? '+$deltaCoins' : '$deltaCoins',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HighlightsBox extends StatelessWidget {
  const _HighlightsBox({this.h1, this.h2, this.h3});
  final String? h1;
  final String? h2;
  final String? h3;

  @override
  Widget build(BuildContext context) {
    final items = [h1, h2, h3]
        .where((e) => e != null && e!.trim().isNotEmpty)
        .map((e) => e!)
        .toList();
    if (items.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('하이라이트', style: TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            for (final s in items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    const Icon(Icons.bolt_outlined, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// ===== Right panel =====
class _RightPanel extends StatelessWidget {
  const _RightPanel({
    required this.summary,
    required this.myRole,
    required this.winner,
    required this.busy,
    required this.onRestart,
    required this.onExit,
  });

  final GameResultSummary summary;
  final SeatRole myRole;
  final PlayerResult? winner;

  final bool busy;
  final VoidCallback onRestart;
  final VoidCallback onExit;

  String _fmtMoneyLike(int v) {
    final sign = v < 0 ? '-' : '';
    final abs = v.abs();
    if (abs >= 1000) return '$sign\$${(abs / 1000).round()}k';
    return '$sign$abs';
  }

  @override
  Widget build(BuildContext context) {
    final rewardCoinsLabel = summary.rewardCoins == 0 ? '-' : '+${summary.rewardCoins}';
    final rewardExpLabel = summary.rewardExp == 0 ? '-' : '+${summary.rewardExp}';

    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('보상', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 10),
                _RewardRow(icon: Icons.paid_outlined, label: '코인', value: rewardCoinsLabel),
                const SizedBox(height: 8),
                _RewardRow(icon: Icons.trending_up_outlined, label: 'EXP', value: rewardExpLabel),
                const SizedBox(height: 10),
                if (winner != null)
                  Text(
                    '승자: ${winner!.name} (${_fmtMoneyLike(winner!.score)})',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                else
                  Text(
                    '승자 정보 없음',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: busy ? null : onRestart,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: busy
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('다시 하기', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: busy ? null : onExit,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text('나가기(모드 선택)', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ),
        ),
      ],
    );
  }
}

class _RewardRow extends StatelessWidget {
  const _RewardRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900))),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
      ],
    );
  }
}

/// ===== Small UI helpers =====
enum _PillTone { primary, neutral, warn }

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.tone});
  final String text;
  final _PillTone tone;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Color bg;
    switch (tone) {
      case _PillTone.primary:
        bg = cs.primary.withOpacity(0.14);
        break;
      case _PillTone.warn:
        bg = Colors.orange.withOpacity(0.16);
        break;
      case _PillTone.neutral:
        bg = cs.surfaceContainerHighest;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: bg,
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
    );
  }
}