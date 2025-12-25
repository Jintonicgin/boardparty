import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'order_select_page.dart';

class LasVegasDiceSelectPage extends StatefulWidget {
  final int playerCount;

  /// 봇 수(0이면 전부 사람). 솔로는 보통 playerCount-1
  final int botCount;

  /// ✅ 판수(라운드 수)
  final int rounds;

  const LasVegasDiceSelectPage({
    super.key,
    required this.playerCount,
    this.botCount = 0,
    this.rounds = 4, // ✅ 기본 4판
  });

  @override
  State<LasVegasDiceSelectPage> createState() => _LasVegasDiceSelectPageState();
}

class _LasVegasDiceSelectPageState extends State<LasVegasDiceSelectPage> {
  late final List<_DiceColor> _availableColors;
  late final List<_Seat> _seats;

  int _activeHumanIndex = 0;
  bool _botsAutoPicked = false;

  // 봇 애니메이션 연출용
  String? _botPickingName; // 지금 고르는 봇 이름
  _DiceColor? _highlightColor; // 지금 고르는 색(타일 하이라이트)
  bool _botAnimating = false;

  @override
  void initState() {
    super.initState();

    final count = widget.playerCount.clamp(2, 8);
    _availableColors = _DiceColor.palette.take(count).toList();

    final botCount = widget.botCount.clamp(0, count);
    final humanCount = (count - botCount).clamp(0, count);

    _seats = List.generate(count, (i) {
      final isBot = i >= humanCount;
      return _Seat(
        id: i,
        name: isBot ? 'BOT ${i - humanCount + 1}' : (i == 0 ? 'Me' : 'Player ${i + 1}'),
        kind: isBot ? _SeatKind.bot : _SeatKind.human,
      );
    });

    _activeHumanIndex = _firstUnselectedHuman() ?? 0;
  }

  int? _firstUnselectedHuman() {
    for (int i = 0; i < _seats.length; i++) {
      if (_seats[i].kind == _SeatKind.human && _seats[i].selected == null) return i;
    }
    return null;
  }

  bool get _anyBots => _seats.any((s) => s.kind == _SeatKind.bot);

  bool get _allHumansSelected =>
      _seats.where((s) => s.kind == _SeatKind.human).every((s) => s.selected != null);

  bool _isColorTaken(_DiceColor c) => _seats.any((s) => s.selected == c);

  void _selectColorForActiveHuman(_DiceColor c) {
    final seat = _seats[_activeHumanIndex];
    if (seat.kind != _SeatKind.human) return;

    // 이미 다른 사람이 선택한 색이면 막기 (본인 재선택은 허용)
    if (_isColorTaken(c) && seat.selected != c) return;

    setState(() {
      _seats[_activeHumanIndex] = seat.copyWith(selected: c);
    });

    // 다음 미선택 사람으로 자동 이동
    final next = _firstUnselectedHuman();
    if (next != null) {
      setState(() => _activeHumanIndex = next);
    }

    // 사람 다 골랐으면 봇이 마지막에 선택(애니메이션)
    _maybeAutoPickBotsAnimated();
  }

  void _clearSelection(int index) {
    final seat = _seats[index];
    if (seat.kind != _SeatKind.human) return;

    setState(() {
      _seats[index] = seat.copyWith(selected: null);

      // 사람이 바꾸면 봇 결과는 무효 → 봇 선택 리셋
      _botsAutoPicked = false;
      _botPickingName = null;
      _highlightColor = null;
      _botAnimating = false;
      for (int i = 0; i < _seats.length; i++) {
        if (_seats[i].kind == _SeatKind.bot) {
          _seats[i] = _seats[i].copyWith(selected: null);
        }
      }

      _activeHumanIndex = index;
    });
  }

  Future<void> _maybeAutoPickBotsAnimated() async {
    if (!_anyBots) return;
    if (!_allHumansSelected) return; // ✅ 사람 다 고르기 전엔 봇 절대 선택 X
    if (_botsAutoPicked) return;
    if (_botAnimating) return;

    _botAnimating = true;

    // 남은 색 목록
    final remaining = _availableColors.where((c) => !_isColorTaken(c)).toList();
    final rng = Random();

    // 봇들 순차 선택
    for (int i = 0; i < _seats.length; i++) {
      if (!mounted) return;
      if (_seats[i].kind != _SeatKind.bot) continue;
      if (remaining.isEmpty) break;

      final pick = remaining.removeAt(rng.nextInt(remaining.length));

      // 1) 하이라이트/상단 안내 텍스트
      setState(() {
        _botPickingName = _seats[i].name;
        _highlightColor = pick;
      });

      // 2) “고르는 중” 연출 딜레이
      await Future<void>.delayed(const Duration(milliseconds: 650));
      if (!mounted) return;

      // 3) 선택 확정
      setState(() {
        _seats[i] = _seats[i].copyWith(selected: pick);
      });

      // 4) 확정 후 살짝 텀
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }

    if (!mounted) return;

    setState(() {
      _botPickingName = null;
      _highlightColor = null;
      _botsAutoPicked = true;
      _botAnimating = false;
    });
  }

  void _goNext() {
    final done = _seats.every((s) => s.selected != null);
    if (!done) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사람이 먼저 모두 선택해야 합니다.')),
      );
      return;
    }

    // ✅ 좌석 이름/색라벨 배열 만들기
    final names = _seats.map((s) => s.name).toList();
    final labels = _seats.map((s) => s.selected!.label).toList();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LasVegasOrderSelectPage(
          playerCount: widget.playerCount,
          botCount: widget.botCount,
          rounds: widget.rounds, // ✅ 핵심: 판수 전달
          seatNames: names,
          selectedColorLabels: labels,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final humansLeft = _seats.where((s) => s.kind == _SeatKind.human && s.selected == null).length;
    final activeSeat = _seats[_activeHumanIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('LAS VEGAS · 주사위 색 선택 (R ${widget.rounds}판)'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // 좌측: 플레이어 목록
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '플레이어',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),

                  Expanded(
                    child: ListView.separated(
                      itemCount: _seats.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final s = _seats[i];
                        final isActive = i == _activeHumanIndex && s.kind == _SeatKind.human;

                        return _SeatCard(
                          seat: s,
                          isActive: isActive,
                          onTap: (s.kind == _SeatKind.human && !_botAnimating)
                              ? () => setState(() => _activeHumanIndex = i)
                              : null,
                          onClear: (s.kind == _SeatKind.human && s.selected != null && !_botAnimating)
                              ? () => _clearSelection(i)
                              : null,
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 안내 문구 + 봇 고르는 중 표시
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Theme.of(context).colorScheme.outline),
                      color: Theme.of(context).colorScheme.surface,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _botPickingName != null ? Icons.smart_toy_outlined : Icons.info_outline,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _botPickingName != null
                                ? '$_botPickingName 선택 중...'
                                : (_anyBots
                                    ? (humansLeft > 0
                                        ? '사람이 먼저 선택해야 합니다. (남은 사람 선택: $humansLeft)'
                                        : '사람 선택 완료 → 봇이 마지막에 남은 색을 선택합니다.')
                                    : '모든 플레이어가 색을 선택하세요.'),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _goNext,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('다음 (순서 정하기)'),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // 우측: 주사위 선택(2.5D 큐브)
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '주사위 색 선택',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          const Icon(Icons.touch_app_outlined),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              (activeSeat.kind == _SeatKind.human)
                                  ? '현재 선택중: ${activeSeat.name}'
                                  : '선택할 사람 좌석을 눌러주세요.',
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

                  const SizedBox(height: 12),

                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 4,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      children: _availableColors.map((c) {
                        final pickedBy = _seats.where((s) => s.selected == c).map((s) => s.name).toList();

                        final canTap = !_botAnimating &&
                            activeSeat.kind == _SeatKind.human &&
                            (!_isColorTaken(c) || activeSeat.selected == c);

                        final isSelectedByActive = activeSeat.selected == c;
                        final isBotHighlight = _highlightColor == c;

                        return _DiceCubeTile(
                          color: c,
                          takenBy: pickedBy,
                          enabled: canTap,
                          isSelected: isSelectedByActive,
                          isBotHighlight: isBotHighlight,
                          onTap: canTap ? () => _selectColorForActiveHuman(c) : null,
                        );
                      }).toList(),
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

/* ======= Models & Widgets ======= */

enum _SeatKind { human, bot }

class _Seat {
  final int id;
  final String name;
  final _SeatKind kind;
  final _DiceColor? selected;

  const _Seat({
    required this.id,
    required this.name,
    required this.kind,
    this.selected,
  });

  _Seat copyWith({String? name, _SeatKind? kind, _DiceColor? selected}) {
    return _Seat(
      id: id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      selected: selected,
    );
  }
}

class _SeatCard extends StatelessWidget {
  final _Seat seat;
  final bool isActive;
  final VoidCallback? onTap;
  final VoidCallback? onClear;

  const _SeatCard({
    required this.seat,
    required this.isActive,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isActive
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.outline;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: isActive ? 2 : 1),
          color: Theme.of(context).colorScheme.surface,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              child: Icon(seat.kind == _SeatKind.bot ? Icons.smart_toy_outlined : Icons.person_outline),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(seat.name, style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  if (seat.selected == null)
                    Text(
                      '미선택',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  else
                    Row(
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: seat.selected!.color,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Theme.of(context).colorScheme.outline),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(seat.selected!.label, style: const TextStyle(fontWeight: FontWeight.w800)),
                      ],
                    ),
                ],
              ),
            ),
            if (onClear != null)
              IconButton(
                tooltip: '선택 해제',
                onPressed: onClear,
                icon: const Icon(Icons.close),
              ),
          ],
        ),
      ),
    );
  }
}

// (아래 _DiceCubeTile / _DicePips / _DiceColor 는 너 코드 그대로)
class _DiceCubeTile extends StatefulWidget {
  final _DiceColor color;
  final List<String> takenBy;
  final bool enabled;
  final bool isSelected;
  final bool isBotHighlight;
  final VoidCallback? onTap;

  const _DiceCubeTile({
    required this.color,
    required this.takenBy,
    required this.enabled,
    required this.isSelected,
    required this.isBotHighlight,
    required this.onTap,
  });

  @override
  State<_DiceCubeTile> createState() => _DiceCubeTileState();
}

class _DiceCubeTileState extends State<_DiceCubeTile> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _lift;
  late final Animation<double> _tilt;

  bool _hover = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 180));
    _lift = Tween<double>(begin: 0, end: -6).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
    _tilt = Tween<double>(begin: 0, end: 0.08).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(covariant _DiceCubeTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    final shouldLift = widget.isSelected || widget.isBotHighlight;
    if (shouldLift) {
      _c.forward();
    } else if (!_hover) {
      _c.reverse();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Color _shade(Color base, double amount) {
    final hsl = HSLColor.fromColor(base);
    final l = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(l).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final isTaken = widget.takenBy.isNotEmpty;

    final outline = Theme.of(context).colorScheme.outline;
    final ring = Theme.of(context).colorScheme.primary;

    final top = _shade(widget.color.color, 0.18);
    final front = widget.color.color;
    final side = _shade(widget.color.color, -0.18);

    final canInteract = widget.enabled && widget.onTap != null;

    final showRing = widget.isSelected || _hover || widget.isBotHighlight;
    final ringColor = widget.isBotHighlight ? Colors.amber : ring;

    return MouseRegion(
      onEnter: (_) {
        if (!canInteract) return;
        setState(() => _hover = true);
        _c.forward();
      },
      onExit: (_) {
        setState(() => _hover = false);
        if (!widget.isSelected && !widget.isBotHighlight) _c.reverse();
      },
      child: GestureDetector(
        onTap: canInteract ? widget.onTap : null,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final lift = _lift.value;
            final tilt = _tilt.value;

            return Transform.translate(
              offset: Offset(0, lift),
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateX(-tilt)
                  ..rotateY(tilt),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 120),
                  opacity: canInteract ? 1 : 0.45,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: showRing ? ringColor : outline,
                        width: showRing ? 2 : 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: showRing ? 18 : 10,
                          offset: const Offset(0, 6),
                          color: Colors.black.withOpacity(showRing ? 0.18 : 0.12),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AspectRatio(
                          aspectRatio: 1.15,
                          child: Stack(
                            children: [
                              Positioned(
                                right: 4,
                                top: 10,
                                bottom: 6,
                                width: 18,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [side, _shade(side, -0.06)],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 10,
                                right: 14,
                                top: 2,
                                height: 18,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                        colors: [top, _shade(top, 0.05)],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 4,
                                right: 16,
                                top: 12,
                                bottom: 4,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [front, _shade(front, -0.1)],
                                      ),
                                    ),
                                    child: Center(
                                      child: _DicePips(
                                        pipColor: Colors.white.withOpacity(0.9),
                                        value: 5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (showRing)
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(18),
                                        boxShadow: [
                                          BoxShadow(
                                            blurRadius: 18,
                                            offset: const Offset(0, 0),
                                            color: ringColor.withOpacity(0.25),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(widget.color.label, style: const TextStyle(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 6),
                        if (!isTaken)
                          Text(
                            '선택 가능',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        else
                          Text(
                            '선택됨: ${widget.takenBy.join(', ')}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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
            );
          },
        ),
      ),
    );
  }
}

class _DicePips extends StatelessWidget {
  final Color pipColor;
  final int value; // 1..6
  const _DicePips({required this.pipColor, required this.value});

  @override
  Widget build(BuildContext context) {
    final map = <int, List<Alignment>>{
      1: [Alignment.center],
      2: [Alignment.topLeft, Alignment.bottomRight],
      3: [Alignment.topLeft, Alignment.center, Alignment.bottomRight],
      4: [Alignment.topLeft, Alignment.topRight, Alignment.bottomLeft, Alignment.bottomRight],
      5: [Alignment.topLeft, Alignment.topRight, Alignment.center, Alignment.bottomLeft, Alignment.bottomRight],
      6: [
        Alignment.topLeft,
        Alignment.topRight,
        Alignment.centerLeft,
        Alignment.centerRight,
        Alignment.bottomLeft,
        Alignment.bottomRight
      ],
    };

    final dots = map[value.clamp(1, 6)]!;
    return Stack(
      children: [
        for (final a in dots)
          Align(
            alignment: a,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: pipColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _DiceColor {
  final String id;
  final String label;
  final Color color;

  const _DiceColor(this.id, this.label, this.color);

  static const palette = <_DiceColor>[
    _DiceColor('red', 'RED', Colors.red),
    _DiceColor('blue', 'BLUE', Colors.blue),
    _DiceColor('yellow', 'YELLOW', Colors.amber),
    _DiceColor('green', 'GREEN', Colors.green),
    _DiceColor('purple', 'PURPLE', Colors.purple),
    _DiceColor('black', 'BLACK', Colors.black),
    _DiceColor('pink', 'PINK', Colors.pink),
    _DiceColor('orange', 'ORANGE', Colors.orange),
  ];
}