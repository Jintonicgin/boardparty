import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'las_vegas_play_page.dart'; // ✅ 실제 경로로 맞추기

class LasVegasOrderSelectPage extends StatefulWidget {
  const LasVegasOrderSelectPage({
    super.key,
    required this.playerCount,
    required this.botCount,
    required this.rounds, // ✅ 추가
    required this.seatNames,
    required this.selectedColorLabels, // seatIndex -> "RED" 같은 라벨(표시용)
  });

  final int playerCount;
  final int botCount;

  /// ✅ 판수(라운드 수)
  final int rounds;

  final List<String> seatNames;
  final List<String> selectedColorLabels;

  @override
  State<LasVegasOrderSelectPage> createState() => _LasVegasOrderSelectPageState();
}

class _LasVegasOrderSelectPageState extends State<LasVegasOrderSelectPage> {
  final _rng = Random();
  bool _rolling = false;

  /// _order[rank] = seatIndex
  List<int> _order = [];

  @override
  void initState() {
    super.initState();
    _order = List<int>.generate(widget.playerCount, (i) => i);
  }

  Future<void> _rollOrder() async {
    if (_rolling) return;

    setState(() => _rolling = true);

    // 연출: 여러 번 셔플되며 "굴리는" 느낌
    for (int k = 0; k < 14; k++) {
      await Future<void>.delayed(Duration(milliseconds: 60 + k * 10));
      if (!mounted) return;
      setState(() {
        _order.shuffle(_rng);
      });
    }

    setState(() => _rolling = false);
  }

  void _goNext() {
    if (_rolling) return;

    // MVP: 내 플레이어 index는 0("Me")로 가정
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => LasVegasPlayPage(
          playerCount: widget.playerCount,
          botCount: widget.botCount,
          myPlayerIndex: 0,

          // ✅ 핵심: 판수/턴순서 전달
          rounds: widget.rounds,
          turnOrder: List<int>.from(_order),

          // ✅ (선택) 결과 화면/표시용으로 이름/색도 같이 넘겨두면 편함
          seatNames: List<String>.from(widget.seatNames),
          selectedColorLabels: List<String>.from(widget.selectedColorLabels),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canNext = !_rolling;

    return Scaffold(
      appBar: AppBar(title: Text('LAS VEGAS · 순서 정하기 (R ${widget.rounds}판)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('턴 순서', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ListView.separated(
                          itemCount: _order.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, rank) {
                            final idx = _order[rank];
                            return _OrderTile(
                              rank: rank + 1,
                              name: widget.seatNames[idx],
                              colorLabel: widget.selectedColorLabels[idx],
                              rolling: _rolling,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              onPressed: _rolling ? null : _rollOrder,
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Text('굴려서 순서 정하기', style: TextStyle(fontWeight: FontWeight.w900)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(
                              onPressed: canNext ? _goNext : null,
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Text('게임 시작', style: TextStyle(fontWeight: FontWeight.w900)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _rolling ? '순서 정하는 중…' : '원하는 만큼 굴린 뒤 “게임 시작”을 누르세요.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              flex: 4,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('설명', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                      const SizedBox(height: 10),
                      Text(
                        '• 이 화면은 MVP용 “순서 결정” 단계입니다.\n'
                        '• 실제 온라인은 서버에서 확정된 순서를 내려줘야 합니다.\n'
                        '• 지금은 UI 흐름 연결을 위해 로컬에서 랜덤 셔플합니다.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({
    required this.rank,
    required this.name,
    required this.colorLabel,
    required this.rolling,
  });

  final int rank;
  final String name;
  final String colorLabel;
  final bool rolling;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 120),
      opacity: rolling ? 0.7 : 1.0,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          color: Theme.of(context).colorScheme.surface,
        ),
        child: Row(
          children: [
            CircleAvatar(child: Text('$rank')),
            const SizedBox(width: 12),
            Expanded(
              child: Text(name, style: const TextStyle(fontWeight: FontWeight.w900)),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                border: Border.all(color: Theme.of(context).colorScheme.outline),
              ),
              child: Text(colorLabel, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}