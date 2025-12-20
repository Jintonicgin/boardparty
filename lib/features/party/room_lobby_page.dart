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
  late final String roomCode;

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

    roomCode = _genCode();

    _players = widget.players.clamp(_minPlayers, _maxPlayers);
    _stake = widget.stake;
    _rounds = widget.rounds;

    seats = List.generate(_players, (_) => _Seat.empty());
    seats[0] = _Seat.human(name: 'Me (Host)', ready: true);

    if (widget.isSolo) {
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
            botCount: widget.isSolo ? _players - 1 : 0,
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
          partySize: _humanCount,   // 현재 방에 있는 사람 수(코어 멤버)
          targetPlayers: _players,  // 목표 총 인원
        ),
      ),
    );

    if (!mounted || result == null) return;
    if (!result.matched) return;

    // ✅ “용병이 우리 방으로 들어오는” 연출은 하지 않고,
    //    매칭이 완료되면 바로 시작하는 흐름(MVP)
    //    (원하면 여기서 바로 _startGame() 호출하면 됨)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('매칭 성공! 용병 ${result.filledPlayers}명 확보 → 게임 시작')),
    );

    _startGame();
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
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: const [
                  Icon(Icons.info_outline),
                  SizedBox(width: 10),
                  Expanded(child: Text('게임 룰 보기 (TODO)')),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // 방 코드
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(Icons.key),
                  const SizedBox(width: 8),
                  Text(roomCode, style: const TextStyle(fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

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

          const SizedBox(height: 14),

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
              canKick: !widget.isSolo && i != 0,
              canEditBotLevel: seats[i].type == _SeatType.bot,
              botLevelLabel: _botLevelLabel,
              onAddBot: () {
                if (widget.isSolo) return;
                if (i == 0) return;

                setState(() {
                  // 이미 봇이면 무시(원하면 토글로 바꿔도 됨)
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
            // ✅ 봇이 하나라도 있으면 빠대 매칭 숨김(요구사항)
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
              onPressed: _startGame,
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

  factory _Seat.empty() =>
      const _Seat(type: _SeatType.empty, name: '빈 자리', ready: false);

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
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(botLevelLabel(e)),
                        ))
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