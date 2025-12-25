import 'dart:math';
import 'package:flutter/material.dart';

import '../../widgets/top_status_actions.dart';
import '../games/las_vegas/dice_select_page.dart';
import '../match/matchmaking_page.dart';

class RoomLobbyPage extends StatefulWidget {
  final String gameId;
  final String gameTitle;
  final bool isSolo;
  final int players;
  final int stake;
  final int rounds;

  const RoomLobbyPage({
    super.key,
    required this.gameId,
    required this.gameTitle,
    required this.isSolo,
    required this.players,
    required this.stake,
    required this.rounds,
  });

  @override
  State<RoomLobbyPage> createState() => _RoomLobbyPageState();
}

class _RoomLobbyPageState extends State<RoomLobbyPage> {
  // ✅ 혼자하기는 방코드 필요 없음 → nullable
  String? roomCode;

  late int _players;
  late int _stake;
  late int _rounds;

  late List<_Seat> seats;

  bool get _isTichu => widget.gameId == 'tichu';
  bool get _isLasVegas => widget.gameId == 'las_vegas';
  bool get _isHost => true;

  int get _maxPlayers => _isTichu ? 4 : 8;
  int get _minPlayers => _isTichu ? 4 : 2;

  bool get _hasBot => seats.any((s) => s.type == _SeatType.bot);

  int get _filledCount => seats.where((s) => s.type != _SeatType.empty).length;
  int get _humanCount => seats.where((s) => s.type == _SeatType.human).length;

  bool get _allHumansReady =>
      seats.asMap().entries
          .where((e) => e.key != 0)
          .where((e) => e.value.type == _SeatType.human)
          .every((e) => e.value.ready);

  bool get _canStartOnline {
    final filled = _filledCount;
    return filled == _players && _allHumansReady;
  }

  @override
  void initState() {
    super.initState();

    // ✅ 방코드는 "혼자하기"가 아닐 때만 생성
    roomCode = widget.isSolo ? null : _genCode();

    _players = widget.players.clamp(_minPlayers, _maxPlayers);
    _stake = widget.stake;
    _rounds = widget.rounds;

    seats = List.generate(_players, (_) => _Seat.empty());
    seats[0] = _Seat.human(name: 'Me (Host)', ready: true);

    if (widget.isSolo) {
      // ✅ 혼자하기 기본: 2명(나 + 봇1) 보장
      if (_players < 2) _players = 2;

      // seats 길이 보정
      seats = List.generate(_players, (_) => _Seat.empty());
      seats[0] = _Seat.human(name: 'Me (Host)', ready: true);
      for (int i = 1; i < seats.length; i++) {
        seats[i] = _Seat.bot(level: BotLevel.mid);
      }
    }
  }

  void _startGame() {
    if (_isLasVegas) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LasVegasDiceSelectPage(
            playerCount: _players,
            botCount: widget.isSolo ? (_players - 1) : 0,
          ),
        ),
      );
      return;
    }

    // TODO: 다른 게임 연결
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('TODO: 해당 게임 시작 화면 연결')),
    );
  }

  Future<void> _startMatchmaking() async {
    // 봇이 있으면 매칭 금지(요구사항)
    if (_hasBot) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('봇을 추가한 상태에서는 빠대 매칭을 할 수 없어요.')),
      );
      return;
    }

    final result = await Navigator.of(context).push<MatchmakingResult>(
      MaterialPageRoute(
        builder: (_) => MatchmakingPage(
          gameId: widget.gameId,
          gameTitle: widget.gameTitle,
          partySize: _humanCount,
          targetPlayers: _players,
        ),
      ),
    );

    if (!mounted || result == null) return;
    if (!result.matched) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('매칭 성공! 용병 ${result.filledPlayers}명 확보 → 게임 시작')),
    );

    _startGame();
  }

  // =========================
  // ✅ SOLO: 봇 추가/제거로 인원(2~8) 조절
  // =========================
  void _soloAddBot() {
    if (!widget.isSolo) return;
    if (_players >= _maxPlayers) return;

    setState(() {
      _players += 1;
      seats = List.of(seats)..add(_Seat.bot(level: BotLevel.mid));
    });
  }

  void _soloRemoveBot() {
    if (!widget.isSolo) return;
    if (_players <= _minPlayers) return;

    // 마지막 좌석이 봇일 때만 제거(안전)
    if (seats.length <= 1) return;
    final last = seats.last;
    if (last.type != _SeatType.bot) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('마지막 좌석이 봇일 때만 제거할 수 있어요.')),
      );
      return;
    }

    setState(() {
      seats = List.of(seats)..removeLast();
      _players -= 1;
    });
  }

  String _botLevelLabel(BotLevel l) {
    switch (l) {
      case BotLevel.low:
        return '하수';
      case BotLevel.mid:
        return '중수';
      case BotLevel.high:
        return '고수';
      case BotLevel.master:
        return '마스터';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.gameTitle} · 대기방'),
        actions: const [
          TopStatusActions(coins: 7000, diamonds: 120),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 게임 룰
          Card(
            child: InkWell(
              onTap: _showGameRuleDialog,
              borderRadius: BorderRadius.circular(14),
              child: const Padding(
                padding: EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(Icons.info_outline),
                    SizedBox(width: 10),
                    Expanded(child: Text('게임 룰 보기')),
                    Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ✅ 방 코드는 "방 만들기(온라인)"에서만 노출. 혼자하기는 숨김.
          if (!widget.isSolo) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(Icons.key),
                    const SizedBox(width: 8),
                    Text(roomCode ?? '-', style: const TextStyle(fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // 방 옵션
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text('방 설정', style: TextStyle(fontWeight: FontWeight.w900)),
                      ),
                      if (!widget.isSolo)
                        TextButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.tune),
                          label: const Text('방 옵션 변경'),
                        ),
                    ],
                  ),
                  Text('인원: $_players명'),
                  Text(_isTichu ? '방식/판수: $_rounds' : '판수: $_rounds판'),
                  Text(widget.isSolo ? '참가금: 무료' : '참가금: $_stake 코인'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ✅ 혼자하기: 인원(=봇) 조절 UI 추가
          if (widget.isSolo && !_isTichu) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text('혼자하기 인원 조절', style: TextStyle(fontWeight: FontWeight.w900)),
                    ),
                    OutlinedButton.icon(
                      onPressed: (_players > _minPlayers) ? _soloRemoveBot : null,
                      icon: const Icon(Icons.remove),
                      label: const Text('봇 제거'),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.icon(
                      onPressed: (_players < _maxPlayers) ? _soloAddBot : null,
                      icon: const Icon(Icons.add),
                      label: const Text('봇 추가'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],

          const Text(
            '플레이어',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 8),

          ...List.generate(
            seats.length,
            (i) => _SeatTile(
              index: i,
              seat: seats[i],
              // ✅ 혼자하기는 킥 개념이 “봇 제거”로 위에서 처리 → 여기선 킥 버튼 안 씀
              canKick: !widget.isSolo && i != 0,
              canEditBotLevel: seats[i].type == _SeatType.bot,
              botLevelLabel: _botLevelLabel,
              onAddBot: () {
                // 온라인 방에서만 빈자리에 봇 추가(요구사항 유지)
                if (widget.isSolo) return;
                if (i == 0) return;

                setState(() {
                  seats[i] = _Seat.bot(level: seats[i].botLevel ?? BotLevel.mid);
                });
              },
              onKick: () {
                if (i == 0) return;
                setState(() {
                  seats[i] = _Seat.empty();
                });
              },
              onToggleReady: () {
                if (i == 0) return;
                setState(() {
                  seats[i] = seats[i].copyWith(ready: !seats[i].ready);
                });
              },
              onBotLevelChanged: (lvl) {
                setState(() {
                  seats[i] = seats[i].copyWith(botLevel: lvl);
                });
              },
            ),
          ),

          const SizedBox(height: 18),

          if (!widget.isSolo) ...[
            if (!_hasBot)
              FilledButton(
                onPressed: _startMatchmaking,
                child: const Text('빠대 매칭'),
              ),
            if (!_hasBot) const SizedBox(height: 8),

            FilledButton(
              onPressed: _canStartOnline ? _startGame : null,
              child: const Text('시작'),
            ),
          ] else
            FilledButton(
              // ✅ 혼자하기는 _players가 실제 플레이 인원. 최소 2명 보장됨.
              onPressed: _players >= 2 ? _startGame : null,
              child: const Text('바로 시작'),
            ),
        ],
      ),
    );
  }

  String _genCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = Random();
    return List.generate(5, (_) => chars[r.nextInt(chars.length)]).join();
  }

  void _showGameRuleDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.casino, color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${widget.gameTitle} 게임 룰',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: _buildGameRuleContent(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('확인'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGameRuleContent() {
    if (_isLasVegas) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _RuleCard(
            icon: Icons.flag,
            iconColor: Color(0xFF22C55E),
            title: '목표',
            content: '4라운드(또는 설정된 라운드) 동안 카지노에서 돈을 가장 많이 따는 플레이어가 승리합니다.',
          ),
          SizedBox(height: 16),
          _RuleCard(
            icon: Icons.settings,
            iconColor: Color(0xFF3B82F6),
            title: '준비 (라운드 시작)',
            items: [
              '카지노는 1~6번이 있습니다.',
              '각 카지노에는 돈 카드(상금)를 공개로 놓습니다.',
              '각 카지노의 공개된 상금 합이 최소 \$50,000 이상이 되도록 채웁니다.',
              '각 플레이어는 자기 색 주사위 8개를 가집니다.',
            ],
          ),
          SizedBox(height: 16),
          _RuleCard(
            icon: Icons.play_circle_outline,
            iconColor: Color(0xFFF59E0B),
            title: '진행',
            content: '플레이는 주사위를 굴리고 → 한 숫자를 선택해 → 해당 카지노에 배치를 반복합니다.\n\n모든 주사위를 다 놓으면 라운드가 끝납니다.',
          ),
          SizedBox(height: 16),
          _RuleCard(
            icon: Icons.emoji_events,
            iconColor: Color(0xFFFCD34D),
            title: '게임 종료 & 승리',
            content: '마지막 라운드까지 끝나면, 각자 딴 돈을 합산해서 총액이 가장 큰 플레이어가 승리합니다.',
          ),
        ],
      );
    }

    return const Text('게임 룰이 준비 중입니다.');
  }
}

/* ====== Models ====== */

enum _SeatType { empty, human, bot }
enum BotLevel { low, mid, high, master }

class _Seat {
  final _SeatType type;
  final String name;
  final bool ready;
  final BotLevel? botLevel;

  const _Seat({
    required this.type,
    required this.name,
    required this.ready,
    this.botLevel,
  });

  factory _Seat.empty() => const _Seat(type: _SeatType.empty, name: '빈 자리', ready: false);

  factory _Seat.human({required String name, required bool ready}) =>
      _Seat(type: _SeatType.human, name: name, ready: ready);

  factory _Seat.bot({required BotLevel level}) =>
      _Seat(type: _SeatType.bot, name: 'BOT', ready: true, botLevel: level);

  _Seat copyWith({bool? ready, BotLevel? botLevel}) {
    return _Seat(
      type: type,
      name: name,
      ready: ready ?? this.ready,
      botLevel: botLevel ?? this.botLevel,
    );
  }
}

/* ====== UI ====== */

class _RuleCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? content;
  final List<String>? items;

  const _RuleCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.content,
    this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1A2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF22335A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (content != null)
            Text(
              content!,
              style: const TextStyle(height: 1.6, fontSize: 14, color: Color(0xFFE5E7EB)),
            ),
          if (items != null) ...[
            if (content != null) const SizedBox(height: 10),
            ...items!.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 6, left: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('• ', style: TextStyle(height: 1.6, fontSize: 14, color: Color(0xFF9CA3AF))),
                  ]..followedBy([
                      Expanded(
                        child: Text(
                          item,
                          style: const TextStyle(height: 1.6, fontSize: 14, color: Color(0xFFE5E7EB)),
                        ),
                      ),
                    ]).toList(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SeatTile extends StatelessWidget {
  final int index;
  final _Seat seat;
  final bool canKick;
  final bool canEditBotLevel;
  final String Function(BotLevel) botLevelLabel;

  final VoidCallback onAddBot;
  final VoidCallback onKick;
  final VoidCallback onToggleReady;
  final ValueChanged<BotLevel> onBotLevelChanged;

  const _SeatTile({
    required this.index,
    required this.seat,
    required this.canKick,
    required this.canEditBotLevel,
    required this.botLevelLabel,
    required this.onAddBot,
    required this.onKick,
    required this.onToggleReady,
    required this.onBotLevelChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Text('${index + 1}')),
        title: Text(seat.name),
        subtitle: seat.type == _SeatType.bot && seat.botLevel != null
            ? Text('난이도: ${botLevelLabel(seat.botLevel!)}')
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (seat.type == _SeatType.empty)
              IconButton(icon: const Icon(Icons.add), onPressed: onAddBot),

            if (seat.type == _SeatType.human && index != 0)
              FilledButton(
                onPressed: onToggleReady,
                child: Text(seat.ready ? '준비됨' : '준비'),
              ),

            if (seat.type == _SeatType.bot && canEditBotLevel)
              DropdownButton<BotLevel>(
                value: seat.botLevel ?? BotLevel.mid,
                onChanged: (v) => v == null ? null : onBotLevelChanged(v),
                items: BotLevel.values
                    .map((e) => DropdownMenuItem(value: e, child: Text(botLevelLabel(e))))
                    .toList(),
              ),

            if (seat.type != _SeatType.empty && canKick)
              IconButton(icon: const Icon(Icons.close), onPressed: onKick),
          ],
        ),
      ),
    );
  }
}