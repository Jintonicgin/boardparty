import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

import 'game_result_page.dart';

class LasVegasPlayPage extends StatefulWidget {
  const LasVegasPlayPage({
    super.key,
    required this.playerCount,
    this.botCount = 0,
    this.myPlayerIndex = 0,

    // ✅ 결과 페이지로 넘길 때 필요(없으면 기본값)
    this.isSolo = true,
    this.stake = 0,
    this.rounds = 1, // MVP: 1라운드만
    this.roomCode = 'LOCAL',
  });

  final int playerCount;
  final int botCount; // 뒤쪽부터 botCount명은 BOT
  final int myPlayerIndex;

  // ✅ result routing info
  final bool isSolo;
  final int stake;
  final int rounds;
  final String roomCode;

  @override
  State<LasVegasPlayPage> createState() => _LasVegasPlayPageState();
}

enum _TurnPhase { waitingRoll, rolling, selecting, committing, betweenTurns }

class _LasVegasPlayPageState extends State<LasVegasPlayPage>
    with TickerProviderStateMixin {
  final _rng = Random();

  // 현재 턴(한 명)의 주사위
  late List<int> _dice; // 확정 값
  late List<int> _displayDice; // 굴림 중 표시 값

  // ✅ 라운드 동안 플레이어별 남은 주사위 개수(라스베가스 룰 느낌)
  late List<int> _remainingDiceCountByPlayer;

  // 선택 상태(사람 턴)
  final Set<int> _selectedIndices = {};
  int? _lockedValue;

  // 턴/플레이어
  late int _currentPlayer;
  late int _humanCount;

  _TurnPhase _phase = _TurnPhase.waitingRoll;

  // 카지노 상태: casinos[casinoValue][playerIndex] = dice count
  late final List<List<int>> _casinos; // 0..6 (1..6 사용)

  // 돈 덱 / 카지노 돈카드 스택
  late List<int> _moneyDeck;
  late final List<List<int>> _casinoMoney; // casinoMoney[casinoValue] = cards list

  // Fly 애니메이션: 위치 측정 key
  final List<GlobalKey> _casinoKeys =
      List.generate(7, (_) => GlobalKey()); // 1..6 사용
  late List<GlobalKey> _dieKeys;

  // Roll 애니메이션: 타이머
  Timer? _rollTicker;

  // Bot 연출
  String? _botStatus;

  bool _finished = false;

  @override
  void initState() {
    super.initState();

    final count = widget.playerCount.clamp(2, 8);
    final botCount = widget.botCount.clamp(0, count);
    _humanCount = (count - botCount).clamp(0, count);

    _casinos = List.generate(7, (_) => List.filled(count, 0));
    _casinoMoney = List.generate(7, (_) => <int>[]);

    _currentPlayer = 0;

    _resetRound();
    _startTurn(playerIndex: 0);
  }

  @override
  void dispose() {
    _rollTicker?.cancel();
    super.dispose();
  }

  bool get _isBotTurn => _currentPlayer >= _humanCount;
  bool get _isMyTurn => !_isBotTurn && _currentPlayer == widget.myPlayerIndex;

  // ===== Round init =====
  void _resetRound() {
    _finished = false;

    // ✅ 라운드 시작 시: 각 플레이어 주사위 8개로 초기화
    _remainingDiceCountByPlayer = List<int>.filled(widget.playerCount, 8);

    _moneyDeck = _buildMoneyDeck();
    _shuffle(_moneyDeck);

    for (int c = 1; c <= 6; c++) {
      _casinoMoney[c].clear();
      final take = min(_moneyDeck.length, 1 + _rng.nextInt(3));
      for (int i = 0; i < take; i++) {
        _casinoMoney[c].add(_moneyDeck.removeLast());
      }
    }

    // 카지노 쌓인 주사위 초기화
    for (int c = 1; c <= 6; c++) {
      for (int p = 0; p < widget.playerCount; p++) {
        _casinos[c][p] = 0;
      }
    }
  }

  List<int> _buildMoneyDeck() {
    // MVP 덱 느낌: 10k~90k 각 3장
    final cards = <int>[];
    for (int v = 10; v <= 90; v += 10) {
      for (int k = 0; k < 3; k++) {
        cards.add(v * 1000);
      }
    }
    return cards;
  }

  void _shuffle(List<int> list) {
    for (int i = list.length - 1; i > 0; i--) {
      final j = _rng.nextInt(i + 1);
      final tmp = list[i];
      list[i] = list[j];
      list[j] = tmp;
    }
  }

  // ===== Game end check =====
  bool get _allPlayersOutOfDice =>
      _remainingDiceCountByPlayer.every((x) => x <= 0);

  Future<void> _finishGameAndGoResult() async {
    if (_finished) return;
    _finished = true;

    final scores = _computeScores(); // seatIndex -> score(money)
    final leaderboard = <PlayerResult>[];

    for (int i = 0; i < widget.playerCount; i++) {
      final isBot = i >= _humanCount;
      leaderboard.add(
        PlayerResult(
          seatIndex: i,
          name: isBot ? 'BOT ${i - _humanCount + 1}' : (i == 0 ? 'Me' : 'P${i + 1}'),
          role: isBot ? SeatRole.bot : SeatRole.core, // MVP: 사람=core로 취급
          score: scores[i],
          deltaCoins: 0,
        ),
      );
    }

    // 점수 내림차순 정렬
    leaderboard.sort((a, b) => b.score.compareTo(a.score));

    final my = leaderboard.firstWhere(
      (e) => e.seatIndex == widget.myPlayerIndex,
      orElse: () => leaderboard.first,
    );

    final summary = GameResultSummary(
      gameTitle: 'LAS VEGAS',
      mySeatIndex: widget.myPlayerIndex,
      leaderboardSorted: leaderboard,
      rewardCoins: max(0, my.score ~/ 1000), // MVP: 돈/1000을 코인처럼
      rewardExp: 0,
      highlight1: '라운드 종료: 모든 플레이어 주사위 소진',
      highlight2: 'MVP 규칙: 카지노별 최다 단독 1등만 돈 획득',
      highlight3: '동률(최다 동점)은 해당 카지노 무효 처리',
    );

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => GameResultPage(
          summary: summary,
          gameId: 'las_vegas',
          gameTitle: 'LAS VEGAS',
          playerCount: widget.playerCount,
          botCount: widget.botCount,
          myPlayerIndex: widget.myPlayerIndex,
        ),
      ),
    );
  }

  /// MVP 점수 계산:
  /// - 카지노별로 주사위 최다 단독 1등만 해당 카지노의 돈(합계) 전부 획득
  /// - 최다 동점이면 무효
  List<int> _computeScores() {
    final scores = List<int>.filled(widget.playerCount, 0);

    for (int c = 1; c <= 6; c++) {
      final stacks = _casinos[c]; // player별 쌓인 주사위
      int best = 0;
      for (final v in stacks) {
        if (v > best) best = v;
      }
      if (best == 0) continue;

      // best 가진 사람들
      final winners = <int>[];
      for (int p = 0; p < stacks.length; p++) {
        if (stacks[p] == best) winners.add(p);
      }

      // 동률이면 무효
      if (winners.length != 1) continue;

      final winP = winners.first;
      final moneySum = _casinoMoney[c].fold(0, (a, b) => a + b);
      scores[winP] += moneySum;
    }

    return scores;
  }

  // ===== Turn control =====
  void _startTurn({required int playerIndex}) {
    if (_finished) return;

    _currentPlayer = playerIndex;
    _selectedIndices.clear();
    _lockedValue = null;

    // ✅ 여기서 “무조건 8개” 만들지 말고, 라운드에서 남은 개수를 가져옴
    final remain = _remainingDiceCountByPlayer[_currentPlayer].clamp(0, 8);

    _dice = List<int>.filled(remain, 1);
    _displayDice = List<int>.filled(remain, 1);

    _phase = _TurnPhase.waitingRoll;
    _botStatus = null;

    setState(() {});

    // ✅ 남은 주사위 0이면 턴 스킵
    if (remain == 0) {
      Future.delayed(const Duration(milliseconds: 250), () {
        if (!mounted) return;
        _endTurnAndNext();
      });
      return;
    }

    // BOT 턴이면 자동 진행
    if (_isBotTurn) {
      _runBotTurn();
    }
  }

  void _endTurnAndNext() {
    if (_finished) return;

    // ✅ 종료 체크: 전원 주사위 0이면 결과로
    if (_allPlayersOutOfDice) {
      _finishGameAndGoResult();
      return;
    }

    final next = (_currentPlayer + 1) % widget.playerCount;

    setState(() {
      _phase = _TurnPhase.betweenTurns;
    });

    Future.delayed(const Duration(milliseconds: 420), () {
      if (!mounted) return;
      _startTurn(playerIndex: next);
    });
  }

  // ===== Roll animation =====
  Future<void> _rollDiceAnimated({required String whoLabel}) async {
    if (_phase == _TurnPhase.rolling) return;

    // ✅ 남은 주사위 0개면 굴릴 수 없음 → 턴 종료
    if (_dice.isEmpty) {
      setState(() {
        _botStatus = '$whoLabel 주사위가 남아있지 않아요.';
      });
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;
      _endTurnAndNext();
      return;
    }

    setState(() {
      _phase = _TurnPhase.rolling;
      _botStatus = '$whoLabel 주사위 굴리는 중…';
    });

    _rollTicker?.cancel();

    _rollTicker = Timer.periodic(const Duration(milliseconds: 60), (_) {
      setState(() {
        for (int i = 0; i < _displayDice.length; i++) {
          _displayDice[i] = _rng.nextInt(6) + 1;
        }
      });
    });

    await Future<void>.delayed(const Duration(milliseconds: 900));
    _rollTicker?.cancel();
    _rollTicker = null;

    _dice = List.generate(_dice.length, (_) => _rng.nextInt(6) + 1);
    _displayDice = List.of(_dice);

    setState(() {
      _phase = _TurnPhase.selecting;
      _botStatus = null;
    });
  }

  // ===== Human selection =====
  bool _enabledForValue(int v) => _lockedValue == null || v == _lockedValue;

  void _toggleSelect(int i) {
    if (_phase != _TurnPhase.selecting) return;
    if (!_isMyTurn) return;

    final v = _dice[i];
    if (!_enabledForValue(v)) return;

    setState(() {
      if (_selectedIndices.contains(i)) {
        _selectedIndices.remove(i);
      } else {
        _selectedIndices.add(i);
      }

      if (_selectedIndices.isEmpty) {
        _lockedValue = null;
      } else {
        _lockedValue ??= v;
        _selectedIndices.removeWhere((idx) => _dice[idx] != _lockedValue);
      }
    });
  }

  int get _selectedCount => _selectedIndices.length;
  int? get _targetCasino => _lockedValue;

  // ===== BOT turn =====
  Future<void> _runBotTurn() async {
    final who = 'BOT ${_currentPlayer - _humanCount + 1}';

    await _rollDiceAnimated(whoLabel: who);
    if (!mounted) return;
    if (_phase != _TurnPhase.selecting) return;

    setState(() {
      _botStatus = '$who 생각 중…';
    });
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    final counts = List<int>.filled(7, 0);
    for (final v in _dice) {
      counts[v]++;
    }

    int best = 1;
    for (int v = 2; v <= 6; v++) {
      if (counts[v] > counts[best]) best = v;
    }

    // tie-break: 돈 합계 큰 카지노 선호
    final bestCandidates = <int>[];
    final maxCnt = counts[best];
    for (int v = 1; v <= 6; v++) {
      if (counts[v] == maxCnt) bestCandidates.add(v);
    }
    if (bestCandidates.length > 1) {
      bestCandidates.sort((a, b) => _casinoMoneySum(b).compareTo(_casinoMoneySum(a)));
      best = bestCandidates.first;
    }

    final idxs = <int>[];
    for (int i = 0; i < _dice.length; i++) {
      if (_dice[i] == best) idxs.add(i);
    }

    setState(() {
      _selectedIndices
        ..clear()
        ..addAll(idxs);
      _lockedValue = best;
      _botStatus = '$who → $best 선택 (${idxs.length}개)';
    });

    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;

    await _commitSelectedToCasinoWithFly(committerLabel: who);
  }

  int _casinoMoneySum(int casino) => _casinoMoney[casino].fold(0, (a, b) => a + b);

  // ===== Fly commit =====
  Future<void> _commitSelectedToCasinoWithFly({required String committerLabel}) async {
    final casino = _targetCasino;
    if (casino == null || _selectedIndices.isEmpty) return;
    if (_phase != _TurnPhase.selecting) return;

    setState(() {
      _phase = _TurnPhase.committing;
      _botStatus = '$committerLabel 올려넣는 중…';
    });

    final overlay = Overlay.of(context);
    if (overlay == null) return;

    final targetRect = _globalRectOfKey(_casinoKeys[casino]);
    if (targetRect == null) return;

    final picked = _selectedIndices.toList()..sort((a, b) => b.compareTo(a));

    final items = <_FlyItem>[];
    for (final idx in picked) {
      if (idx < 0 || idx >= _dieKeys.length) continue;
      final fromRect = _globalRectOfKey(_dieKeys[idx]);
      if (fromRect == null) continue;
      items.add(_FlyItem(from: fromRect, value: _dice[idx]));
    }
    if (items.isEmpty) return;

    await _playFlyAnimation(overlay, items, targetRect);
    if (!mounted) return;

    setState(() {
      _casinos[casino][_currentPlayer] += picked.length;

      for (final idx in picked) {
        if (idx >= 0 && idx < _dice.length) {
          _dice.removeAt(idx);
        }
      }
      _displayDice = List.of(_dice);

      // ✅ “라운드 단위 남은 주사위” 저장 (이게 핵심)
      _remainingDiceCountByPlayer[_currentPlayer] = _dice.length;

      _selectedIndices.clear();
      _lockedValue = null;
      _botStatus = null;
    });

    _endTurnAndNext();
  }

  Rect? _globalRectOfKey(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject();
    if (box is! RenderBox) return null;
    final topLeft = box.localToGlobal(Offset.zero);
    return Rect.fromLTWH(topLeft.dx, topLeft.dy, box.size.width, box.size.height);
  }

  Future<void> _playFlyAnimation(
      OverlayState overlay, List<_FlyItem> items, Rect targetRect) async {
    final futures = <Future<void>>[];
    for (int i = 0; i < items.length; i++) {
      futures.add(_flyOne(overlay, items[i], targetRect, delayMs: i * 55));
    }
    await Future.wait(futures);
  }

  Future<void> _flyOne(OverlayState overlay, _FlyItem item, Rect targetRect,
      {required int delayMs}) async {
    if (delayMs > 0) await Future<void>.delayed(Duration(milliseconds: delayMs));

    final c = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
    final curve = CurvedAnimation(parent: c, curve: Curves.easeInOutCubic);

    final fromCenter = item.from.center;
    final toCenter = targetRect.center;

    final mid = Offset(
      (fromCenter.dx + toCenter.dx) / 2,
      min(fromCenter.dy, toCenter.dy) - 90,
    );

    final entry = OverlayEntry(
      builder: (_) {
        return AnimatedBuilder(
          animation: curve,
          builder: (_, __) {
            final t = curve.value;
            final p = _quadBezier(fromCenter, mid, toCenter, t);
            final scale = lerpDouble(1.0, 0.55, t)!;
            final rot = lerpDouble(0.0, 0.95, t)!;

            return Positioned(
              left: p.dx - 20,
              top: p.dy - 20,
              child: Transform.rotate(
                angle: rot,
                child: Transform.scale(
                  scale: scale,
                  child: _FlyDieBubble(value: item.value),
                ),
              ),
            );
          },
        );
      },
    );

    overlay.insert(entry);
    await c.forward();
    entry.remove();
    c.dispose();
  }

  Offset _quadBezier(Offset p0, Offset p1, Offset p2, double t) {
    final u = 1 - t;
    final x = u * u * p0.dx + 2 * u * t * p1.dx + t * t * p2.dx;
    final y = u * u * p0.dy + 2 * u * t * p1.dy + t * t * p2.dy;
    return Offset(x, y);
  }

  // ===== UI =====
  @override
  Widget build(BuildContext context) {
    _dieKeys = List.generate(_displayDice.length, (_) => GlobalKey());

    final title = _isBotTurn
        ? 'BOT ${_currentPlayer - _humanCount + 1} 턴'
        : (_currentPlayer == widget.myPlayerIndex ? '내 턴' : 'Player ${_currentPlayer + 1} 턴');

    final highlightCasino = _targetCasino;
    final previewAdd = _selectedCount;

    final remainForCurrent = _remainingDiceCountByPlayer[_currentPlayer];

    return Scaffold(
      appBar: AppBar(
        title: Text('LAS VEGAS · 인게임 MVP ($title)'),
        actions: [
          TextButton(
            onPressed: () {
              _resetRound();
              _startTurn(playerIndex: 0);
            },
            child: const Text('라운드 리셋(임시)', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Row(
          children: [
            Expanded(
              flex: 7,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _CasinoBoard(
                  casinoKeys: _casinoKeys,
                  casinos: _casinos,
                  casinoMoney: _casinoMoney,
                  playerCount: widget.playerCount,
                  humanCount: _humanCount,
                  highlightCasino: highlightCasino,
                  previewAddCount: previewAdd,
                  previewForPlayerIndex: _currentPlayer,
                ),
              ),
            ),
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
                child: Column(
                  children: [
                    _StatusCard(
                      title: title,
                      phase: _phase,
                      botStatus: _botStatus,
                      lockedValue: _lockedValue,
                      selectedCount: _selectedCount,
                      remainingDice: remainForCurrent,
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: _DiceTray(
                        dice: _displayDice,
                        dieKeys: _dieKeys,
                        selectedIndices: _selectedIndices,
                        lockedValue: _lockedValue,
                        enabledTap: (_phase == _TurnPhase.selecting) && _isMyTurn,
                        onTapDie: _toggleSelect,
                        rolling: _phase == _TurnPhase.rolling,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_isMyTurn) ...[
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _phase == _TurnPhase.waitingRoll
                              ? () => _rollDiceAnimated(whoLabel: 'Me')
                              : null,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Text('굴리기', style: TextStyle(fontWeight: FontWeight.w900)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: (_phase == _TurnPhase.selecting && _selectedCount > 0)
                              ? () => _commitSelectedToCasinoWithFly(committerLabel: 'Me')
                              : null,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Text(
                              _selectedCount == 0
                                  ? '올려넣기'
                                  : '올려넣기 (${_targetCasino}번 × $_selectedCount)',
                              style: const TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: null,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Text('상대 턴 진행 중…'),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* =======================
   Widgets
======================= */

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.title,
    required this.phase,
    required this.botStatus,
    required this.lockedValue,
    required this.selectedCount,
    required this.remainingDice,
  });

  final String title;
  final _TurnPhase phase;
  final String? botStatus;
  final int? lockedValue;
  final int selectedCount;
  final int remainingDice;

  @override
  Widget build(BuildContext context) {
    String line;
    switch (phase) {
      case _TurnPhase.waitingRoll:
        line = remainingDice <= 0 ? '주사위 없음(턴 스킵)' : '굴리기를 눌러 시작';
        break;
      case _TurnPhase.rolling:
        line = '주사위 굴리는 중…';
        break;
      case _TurnPhase.selecting:
        line = lockedValue == null
            ? '주사위를 클릭해 숫자를 선택'
            : '선택 중: $lockedValue (선택 $selectedCount개)';
        break;
      case _TurnPhase.committing:
        line = '올려넣는 중…';
        break;
      case _TurnPhase.betweenTurns:
        line = '다음 플레이어로…';
        break;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.casino_outlined),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text(
                    botStatus ?? line,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text('남은 $remainingDice',
                style: const TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

class _DiceTray extends StatelessWidget {
  const _DiceTray({
    required this.dice,
    required this.dieKeys,
    required this.selectedIndices,
    required this.lockedValue,
    required this.enabledTap,
    required this.onTapDie,
    required this.rolling,
  });

  final List<int> dice;
  final List<GlobalKey> dieKeys;
  final Set<int> selectedIndices;
  final int? lockedValue;
  final bool enabledTap;
  final void Function(int index) onTapDie;
  final bool rolling;

  bool _enabledFor(int v) => lockedValue == null || v == lockedValue;

  @override
  Widget build(BuildContext context) {
    if (dice.isEmpty) {
      return const Center(child: Text('주사위 없음'));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.builder(
          itemCount: dice.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.05,
          ),
          itemBuilder: (_, i) {
            final v = dice[i];
            final selected = selectedIndices.contains(i);
            final enabled = _enabledFor(v) && enabledTap && !rolling;

            return _DieTile(
              key: dieKeys[i],
              value: v,
              selected: selected,
              enabled: enabled,
              rolling: rolling,
              onTap: () => onTapDie(i),
            );
          },
        ),
      ),
    );
  }
}

class _DieTile extends StatefulWidget {
  const _DieTile({
    super.key,
    required this.value,
    required this.selected,
    required this.enabled,
    required this.rolling,
    required this.onTap,
  });

  final int value;
  final bool selected;
  final bool enabled;
  final bool rolling;
  final VoidCallback onTap;

  @override
  State<_DieTile> createState() => _DieTileState();
}

class _DieTileState extends State<_DieTile> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _spin;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
    _spin = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _c, curve: Curves.linear));
  }

  @override
  void didUpdateWidget(covariant _DieTile oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.rolling) {
      if (!_c.isAnimating) _c.repeat();
    } else {
      if (_c.isAnimating) _c.stop();
      _c.value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final outline = Theme.of(context).colorScheme.outline;
    final ring = Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: widget.enabled ? widget.onTap : null,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 120),
        opacity: widget.enabled ? 1.0 : 0.35,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, widget.selected ? -6 : 0, 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.selected ? ring : outline,
              width: widget.selected ? 2 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                blurRadius: widget.selected ? 16 : 10,
                offset: const Offset(0, 7),
                color: Colors.black.withOpacity(widget.selected ? 0.16 : 0.10),
              ),
            ],
            color: Theme.of(context).colorScheme.surface,
          ),
          child: Center(
            child: AnimatedBuilder(
              animation: _spin,
              builder: (_, __) {
                final a = widget.rolling ? _spin.value * 6.28 : 0.0;
                return Transform.rotate(
                  angle: a,
                  child: Text(
                    '${widget.value}',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _CasinoBoard extends StatelessWidget {
  const _CasinoBoard({
    required this.casinoKeys,
    required this.casinos,
    required this.casinoMoney,
    required this.playerCount,
    required this.humanCount,
    required this.highlightCasino,
    required this.previewAddCount,
    required this.previewForPlayerIndex,
  });

  final List<GlobalKey> casinoKeys;
  final List<List<int>> casinos;
  final List<List<int>> casinoMoney;
  final int playerCount;
  final int humanCount;

  final int? highlightCasino;
  final int previewAddCount;
  final int previewForPlayerIndex;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: List.generate(6, (i) {
        final c = i + 1;
        final hi = highlightCasino == c;
        final preview = hi ? previewAddCount : 0;

        return _CasinoCard(
          key: casinoKeys[c],
          casinoValue: c,
          stacks: casinos[c],
          playerCount: playerCount,
          humanCount: humanCount,
          highlight: hi,
          previewAddCount: preview,
          previewForPlayerIndex: previewForPlayerIndex,
          moneyCards: casinoMoney[c],
        );
      }),
    );
  }
}

class _CasinoCard extends StatelessWidget {
  const _CasinoCard({
    super.key,
    required this.casinoValue,
    required this.stacks,
    required this.playerCount,
    required this.humanCount,
    required this.highlight,
    required this.previewAddCount,
    required this.previewForPlayerIndex,
    required this.moneyCards,
  });

  final int casinoValue;
  final List<int> stacks;
  final int playerCount;
  final int humanCount;

  final bool highlight;
  final int previewAddCount;
  final int previewForPlayerIndex;

  final List<int> moneyCards;

  int get _moneySum => moneyCards.fold(0, (a, b) => a + b);
  String _fmt(int v) => '\$${(v / 1000).round()}k';

  String _playerLabel(int p) {
    if (p < humanCount) return (p == 0) ? 'Me' : 'P${p + 1}';
    return 'BOT ${p - humanCount + 1}';
  }

  @override
  Widget build(BuildContext context) {
    final ring = Theme.of(context).colorScheme.primary;
    final outline = Theme.of(context).colorScheme.outline;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      transform: Matrix4.translationValues(0, highlight ? -3 : 0, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlight ? ring : outline,
          width: highlight ? 2.2 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: highlight ? 18 : 10,
            offset: const Offset(0, 8),
            color: Colors.black.withOpacity(highlight ? 0.16 : 0.10),
          ),
        ],
        color: Theme.of(context).colorScheme.surface,
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('카지노 $casinoValue',
                  style: const TextStyle(fontWeight: FontWeight.w900)),
              const Spacer(),
              if (highlight && previewAddCount > 0)
                _Pill(text: '+$previewAddCount', color: ring.withOpacity(0.14)),
            ],
          ),
          const SizedBox(height: 8),
          _MoneyStack(cards: moneyCards, sumLabel: _fmt(_moneySum), fmt: _fmt),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: playerCount,
              itemBuilder: (_, p) {
                final base = stacks[p];
                final add = (p == previewForPlayerIndex) ? previewAddCount : 0;
                final c = base + add;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      SizedBox(width: 58, child: Text(_playerLabel(p))),
                      const SizedBox(width: 8),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: (c / 8.0).clamp(0.0, 1.0),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 26,
                        child: Text('$c', textAlign: TextAlign.right),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MoneyStack extends StatelessWidget {
  const _MoneyStack({
    required this.cards,
    required this.sumLabel,
    required this.fmt,
  });

  final List<int> cards;
  final String sumLabel;
  final String Function(int) fmt;

  @override
  Widget build(BuildContext context) {
    final outline = Theme.of(context).colorScheme.outline;
    final bg = Theme.of(context).colorScheme.surfaceContainerHighest;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: bg,
        border: Border.all(color: outline),
      ),
      child: Row(
        children: [
          SizedBox(
            height: 34,
            width: 120,
            child: Stack(
              children: [
                for (int i = 0; i < cards.length; i++)
                  Positioned(
                    left: i * 12.0,
                    child: _MoneyCardMini(label: fmt(cards[i])),
                  ),
              ],
            ),
          ),
          const Spacer(),
          Text('합계 $sumLabel',
              style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _MoneyCardMini extends StatelessWidget {
  const _MoneyCardMini({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        boxShadow: [
          BoxShadow(
            blurRadius: 6,
            offset: const Offset(0, 3),
            color: Colors.black.withOpacity(0.10),
          ),
        ],
      ),
      child: Text(label,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color,
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Text(text,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
    );
  }
}

class _FlyItem {
  final Rect from;
  final int value;
  const _FlyItem({required this.from, required this.value});
}

class _FlyDieBubble extends StatelessWidget {
  const _FlyDieBubble({required this.value});
  final int value;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          boxShadow: [
            BoxShadow(
              blurRadius: 14,
              offset: const Offset(0, 8),
              color: Colors.black.withOpacity(0.18),
            ),
          ],
        ),
        child: Text('$value',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
      ),
    );
  }
}

// helper
double? lerpDouble(num? a, num? b, double t) {
  if (a == null && b == null) return null;
  a ??= 0.0;
  b ??= 0.0;
  return a + (b - a) * t;
}