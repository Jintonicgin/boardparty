import 'dart:async';
import 'package:flutter/material.dart';
import '../games/las_vegas/dice_select_page.dart';

class QuickMatchPage extends StatefulWidget {
  final String gameId;
  final String gameTitle;

  final int partyCount;            // 우리 파티(사람) 수
  final int totalPlayerCount;      // 게임 총 인원(예: 4~8)
  final int neededMercenaryCount;  // 필요한 용병 수

  final int rounds;
  final int stake;

  const QuickMatchPage({
    super.key,
    required this.gameId,
    required this.gameTitle,
    required this.partyCount,
    required this.totalPlayerCount,
    required this.neededMercenaryCount,
    required this.rounds,
    required this.stake,
  });

  @override
  State<QuickMatchPage> createState() => _QuickMatchPageState();
}

class _QuickMatchPageState extends State<QuickMatchPage> {
  Timer? _timer;
  int _found = 0;
  bool _done = false;

  @override
  void initState() {
    super.initState();

    // MVP: 0.9초마다 용병 1명 잡히는 느낌
    _timer = Timer.periodic(const Duration(milliseconds: 900), (t) {
      if (!mounted) return;
      setState(() {
        _found++;
        if (_found >= widget.neededMercenaryCount) {
          _found = widget.neededMercenaryCount;
          _done = true;
        }
      });

      if (_done) {
        t.cancel();
        _startGameImmediately();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startGameImmediately() {
    // ✅ 핵심: “용병이 우리 방으로 들어오는 것”이 아니라
    // “매칭 성사 → 바로 게임 시작”
    // (서버 붙이면 여기서 matchId를 받아서 게임으로 넘기면 됨)

    if (widget.gameId == 'las_vegas') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => LasVegasDiceSelectPage(
            playerCount: widget.totalPlayerCount,
            botCount: 0, // 빠대는 사람 매칭이므로 봇 없음
          ),
        ),
      );
      return;
    }

    // 다른 게임 TODO
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => _MatchStartPlaceholder(gameTitle: widget.gameTitle),
      ),
    );
  }

  void _cancel() {
    _timer?.cancel();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final need = widget.neededMercenaryCount;
    final left = (need - _found).clamp(0, need);

    return Scaffold(
      appBar: AppBar(
        title: const Text('빠대 매칭'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _cancel,
          tooltip: '취소',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(Icons.group_outlined),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${widget.gameTitle}\n파티 ${widget.partyCount}명 · 총 ${widget.totalPlayerCount}명 매칭',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '용병 찾는 중…',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: need == 0 ? 1 : (_found / need),
                      minHeight: 10,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '필요 $need명 중 $_found명 발견 (남은 $left명)',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '※ 매칭이 완료되면 방으로 초대하지 않고, 바로 게임이 시작됩니다.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _cancel,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('매칭 취소'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchStartPlaceholder extends StatelessWidget {
  final String gameTitle;
  const _MatchStartPlaceholder({required this.gameTitle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$gameTitle · 매칭 시작')),
      body: const Center(child: Text('TODO: 매칭 후 게임 시작 화면')),
    );
  }
}