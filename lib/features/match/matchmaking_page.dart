import 'dart:async';
import 'package:flutter/material.dart';

class MatchmakingResult {
  final bool matched;
  final int filledPlayers; // 이번 매칭으로 채운 인원 수(용병 수)
  const MatchmakingResult({required this.matched, required this.filledPlayers});
}

class MatchmakingPage extends StatefulWidget {
  final String gameId;
  final String gameTitle;

  /// 우리 파티(코어 멤버) 인원 수
  final int partySize;

  /// 방에서 목표로 하는 총 인원 (예: 4인 방이면 4)
  final int targetPlayers;

  const MatchmakingPage({
    super.key,
    required this.gameId,
    required this.gameTitle,
    required this.partySize,
    required this.targetPlayers,
  });

  @override
  State<MatchmakingPage> createState() => _MatchmakingPageState();
}

class _MatchmakingPageState extends State<MatchmakingPage> {
  bool _searching = false;
  double _progress = 0.0;
  Timer? _t;

  int get _need => (widget.targetPlayers - widget.partySize).clamp(0, 8);

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  void _startSearch() {
    if (_searching) return;
    if (_need <= 0) {
      Navigator.pop(context, const MatchmakingResult(matched: true, filledPlayers: 0));
      return;
    }

    setState(() {
      _searching = true;
      _progress = 0;
    });

    _t?.cancel();
    _t = Timer.periodic(const Duration(milliseconds: 120), (timer) {
      setState(() {
        _progress += 0.03;
        if (_progress >= 1.0) _progress = 1.0;
      });

      // MVP: 진행이 100% 되면 매칭 성공으로 처리
      if (_progress >= 1.0) {
        timer.cancel();
        _t = null;
        if (!mounted) return;

        Navigator.pop(
          context,
          MatchmakingResult(matched: true, filledPlayers: _need),
        );
      }
    });
  }

  void _cancel() {
    _t?.cancel();
    _t = null;
    Navigator.pop(context, const MatchmakingResult(matched: false, filledPlayers: 0));
  }

  @override
  Widget build(BuildContext context) {
    final need = _need;

    return Scaffold(
      appBar: AppBar(
        title: const Text('빠른 대전 매칭'),
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
                    const Icon(Icons.bolt_outlined),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${widget.gameTitle} · ${widget.targetPlayers}인 매칭\n'
                        '우리 파티: ${widget.partySize}명 / 필요한 용병: $need명',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            if (_searching) ...[
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 10),
              Text(
                '매칭 중… (용병 $need명 찾는 중)',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _cancel,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('취소'),
                  ),
                ),
              ),
            ] else ...[
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: need == 0 ? null : _startSearch,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('매칭 시작'),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _cancel,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('뒤로'),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}