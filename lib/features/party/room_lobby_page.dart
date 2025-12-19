import 'dart:math';
import 'package:flutter/material.dart';
import '../../widgets/top_status_actions.dart';

class RoomLobbyPage extends StatefulWidget {
  final String gameId;
  final String gameTitle;
  final bool isSolo;
  final int players;
  final int stake;
  final int rounds; // 0이면 점수제(티츄 용)

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
  // solo면 코드가 필요 없으므로 nullable
  String? roomCode;

  late int _players;
  late int _stake;
  late int _rounds; // tichu: 0=점수제, >0=판수제 / others: 판수

  late List<_Seat> seats;

  bool get _isTichu => widget.gameId == 'tichu';
  bool get _isHost => true; // MVP: 이 화면을 연 사람 = 방장 가정

  // 게임별 최대 인원 (요구: 라스베가스 최대 8)
  int get _maxPlayers => _isTichu ? 4 : 8;
  int get _minPlayers => _isTichu ? 4 : 2;

  /// 게스트(호스트 제외) 사람들만 준비 완료인지
  bool get allReady => seats.asMap().entries
      .where((e) => e.key != 0) // 0번(호스트) 제외
      .where((e) => e.value.isHuman)
      .every((e) => e.value.ready);

  @override
  void initState() {
    super.initState();

    roomCode = widget.isSolo ? null : _genCode();

    _players = widget.players;
    _stake = widget.stake;
    _rounds = widget.rounds;

    // 티츄는 강제 4인
    if (_isTichu) _players = 4;
    if (_players < _minPlayers) _players = _minPlayers;
    if (_players > _maxPlayers) _players = _maxPlayers;

    seats = List.generate(_players, (_) => _Seat.empty());

    // host(0번) 고정
    seats[0] = _Seat.human(name: 'Me (Host)', ready: true);

    // solo면 나머지 봇으로 채움
    if (widget.isSolo) {
      _fillSoloBots();
    }
  }

  void _fillSoloBots() {
    // host 제외 1..end 는 항상 봇이거나 빈자리면 봇으로
    for (int i = 1; i < seats.length; i++) {
      seats[i] = _Seat.bot(level: seats[i].botLevel ?? BotLevel.mid);
    }
  }

  void _setSoloPlayers(int next) {
    if (!widget.isSolo) return;

    // 티츄는 고정
    if (_isTichu) return;

    if (next < _minPlayers) next = _minPlayers;
    if (next > _maxPlayers) next = _maxPlayers;

    if (next == _players) return;

    setState(() {
      if (next < _players) {
        // 줄이기: 뒤에서부터 자르기
        seats = seats.sublist(0, next);
      } else {
        // 늘리기: 빈 자리 추가
        final add = next - _players;
        seats = [...seats, ...List.generate(add, (_) => _Seat.empty())];
      }

      _players = next;

      // host 자리 강제 고정
      seats[0] = _Seat.human(name: 'Me (Host)', ready: true);

      // solo는 나머지 봇으로 자동 채움
      _fillSoloBots();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.gameTitle} · 대기방'),
        actions: const [TopStatusActions(coins: 7000, diamonds: 120)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '게임 룰 보기 (TODO)',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (!widget.isSolo) ...[
                const SizedBox(width: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    child: Row(
                      children: [
                        const Icon(Icons.key_outlined),
                        const SizedBox(width: 8),
                        Text(roomCode ?? '', style: const TextStyle(fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),

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

                      // ✅ 온라인만 "방 옵션 변경" (solo는 +/−로 조절)
                      if (!widget.isSolo && _isHost)
                        TextButton.icon(
                          onPressed: _openEditOptions,
                          icon: const Icon(Icons.tune),
                          label: const Text('방 옵션 변경'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // ✅ solo & (티츄 제외) : 인원 +/− Stepper 제공
                  if (widget.isSolo && !_isTichu)
                    Row(
                      children: [
                        const Expanded(child: Text('인원')),
                        IconButton(
                          tooltip: '인원 감소',
                          onPressed: _players <= _minPlayers ? null : () => _setSoloPlayers(_players - 1),
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text(
                          '$_players명',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                        ),
                        IconButton(
                          tooltip: '인원 증가',
                          onPressed: _players >= _maxPlayers ? null : () => _setSoloPlayers(_players + 1),
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(최대 $_maxPlayers)',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      ],
                    )
                  else
                    Text('인원: $_players명'),

                  const SizedBox(height: 4),
                  Text(
                    _isTichu
                        ? '방식: ${_rounds == 0 ? '점수제' : '판수제($_rounds판)'}'
                        : '판수: $_rounds판',
                  ),
                  const SizedBox(height: 4),
                  Text(widget.isSolo ? '참가금: 무료(솔로)' : '참가금: $_stake 코인 (시작 시 차감)'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),
          const Text('플레이어', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),

          ...List.generate(
            seats.length,
            (i) => _SeatTile(
              index: i,
              seat: seats[i],
              isHost: i == 0,
              canKick: !widget.isSolo && i != 0,
              canEditBotLevel: seats[i].type == _SeatType.bot,
              showTeamSelect: _isTichu && seats[i].type == _SeatType.human,
              onToggleReady: () {
                if (widget.isSolo) return;
                if (i == 0) return; // 호스트는 준비 없음
                setState(() => seats[i] = seats[i].copyWith(ready: !seats[i].ready));
              },
              onAddBotHere: () {
                if (i == 0) return; // 호스트 자리는 봇 추가 불가
                setState(() => seats[i] = _Seat.bot(level: BotLevel.mid));
              },
              onKick: () async {
                if (i == 0) return; // 호스트 제거 불가
                final ok = await _confirm(context, '이 플레이어/봇을 제거할까요?');
                if (!ok) return;
                setState(() => seats[i] = _Seat.empty());
              },
              onBotLevelChanged: (lvl) {
                if (i == 0) return;
                setState(() => seats[i] = seats[i].copyWith(botLevel: lvl));
              },
              onTeamChanged: (t) {
                if (i == 0) return;
                setState(() => seats[i] = seats[i].copyWith(team: t));
              },
            ),
          ),

          const SizedBox(height: 18),

          if (!widget.isSolo)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('방 찾기는 “코드 입력” 화면에서 들어옵니다 (TODO)')),
                      );
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('방 찾기 (코드 입력 안내)'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: allReady
                        ? () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const _GameStartPlaceholder()),
                            );
                          }
                        : null,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('시작'),
                    ),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const _GameStartPlaceholder()),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('바로 시작'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------
  // 방 옵션 수정 팝업 (온라인 전용)
  // ---------------------------
  void _openEditOptions() {
    final playerOptions =
        _isTichu ? const <int>[4] : const <int>[2, 3, 4, 5, 6, 7, 8];

    final stakeOptions = const <int>[3000, 5000, 10000];
    final roundsOptions = List<int>.generate(10, (i) => i + 1);
    final tichuRoundOptions = const <int>[1, 3, 5];

    int tempPlayers = _players;
    int tempStake = _stake;
    int tempRounds = _rounds;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final isTichuScoreMode = _isTichu && tempRounds == 0;

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 8,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.gameTitle} · 방 옵션 변경',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 14),

                  _LabeledRow(
                    label: '인원',
                    child: DropdownButtonFormField<int>(
                      value: tempPlayers,
                      items: playerOptions
                          .map((v) => DropdownMenuItem(value: v, child: Text('$v명')))
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setModalState(() => tempPlayers = v);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (_isTichu) ...[
                    _LabeledRow(
                      label: '방식',
                      child: DropdownButtonFormField<int>(
                        value: tempRounds == 0 ? 0 : 1,
                        items: const [
                          DropdownMenuItem(value: 0, child: Text('점수제')),
                          DropdownMenuItem(value: 1, child: Text('판수제')),
                        ],
                        onChanged: (v) {
                          if (v == null) return;
                          setModalState(() {
                            if (v == 0) {
                              tempRounds = 0;
                            } else {
                              tempRounds = tempRounds == 0 ? 3 : tempRounds;
                              if (!tichuRoundOptions.contains(tempRounds)) tempRounds = 3;
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (!isTichuScoreMode)
                      _LabeledRow(
                        label: '판수',
                        child: DropdownButtonFormField<int>(
                          value: tichuRoundOptions.contains(tempRounds) ? tempRounds : 3,
                          items: tichuRoundOptions
                              .map((v) => DropdownMenuItem(value: v, child: Text('$v판')))
                              .toList(),
                          onChanged: (v) {
                            if (v == null) return;
                            setModalState(() => tempRounds = v);
                          },
                        ),
                      ),
                  ] else ...[
                    _LabeledRow(
                      label: '판수',
                      child: DropdownButtonFormField<int>(
                        value: tempRounds,
                        items: roundsOptions
                            .map((v) => DropdownMenuItem(value: v, child: Text('$v판')))
                            .toList(),
                        onChanged: (v) {
                          if (v == null) return;
                          setModalState(() => tempRounds = v);
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  _LabeledRow(
                    label: '참가금',
                    child: DropdownButtonFormField<int>(
                      value: tempStake,
                      items: stakeOptions
                          .map((v) => DropdownMenuItem(value: v, child: Text('$v 코인')))
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setModalState(() => tempStake = v);
                      },
                    ),
                  ),

                  const SizedBox(height: 18),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text('취소'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () async {
                            final ok = await _applyRoomOptions(
                              newPlayers: tempPlayers,
                              newStake: tempStake,
                              newRounds: tempRounds,
                            );
                            if (ok && mounted) Navigator.pop(ctx);
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text('저장'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<bool> _applyRoomOptions({
    required int newPlayers,
    required int newStake,
    required int newRounds,
  }) async {
    if (_isTichu && newPlayers != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('티츄는 4인 고정입니다.')),
      );
      return false;
    }

    if (newPlayers != _players) {
      if (newPlayers < _minPlayers) return false;
      if (newPlayers > _maxPlayers) return false;

      if (newPlayers < _players) {
        for (int i = newPlayers; i < seats.length; i++) {
          final s = seats[i];
          if (s.type == _SeatType.human) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('인원을 줄이려면 먼저 사람 자리를 비워주세요.')),
            );
            return false;
          }
        }
        seats = seats.sublist(0, newPlayers);
      } else {
        final add = newPlayers - _players;
        seats = [...seats, ...List.generate(add, (_) => _Seat.empty())];
      }

      seats[0] = _Seat.human(name: 'Me (Host)', ready: true);
    }

    setState(() {
      _players = newPlayers;
      _stake = newStake;
      _rounds = newRounds;
    });

    return true;
  }

  // ---------------------------
  // utils
  // ---------------------------
  String _genCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = Random();
    return List.generate(5, (_) => chars[r.nextInt(chars.length)]).join();
  }

  Future<bool> _confirm(BuildContext context, String msg) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('확인'),
        content: Text(msg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('확인')),
        ],
      ),
    );
    return res ?? false;
  }
}

class _LabeledRow extends StatelessWidget {
  final String label;
  final Widget child;

  const _LabeledRow({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
        const SizedBox(width: 12),
        Expanded(child: child),
      ],
    );
  }
}

class _GameStartPlaceholder extends StatelessWidget {
  const _GameStartPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('게임 시작 (TODO)')),
      body: const Center(child: Text('여기에 “주사위 색 선택 → 순서 정하기 → 게임 진행” UI로 연결')),
    );
  }
}

enum _SeatType { empty, human, bot }
enum BotLevel { low, mid, high, master }
enum TichuTeam { random, team1, team2 }

class _Seat {
  final _SeatType type;
  final String name;
  final bool ready;
  final BotLevel? botLevel;
  final TichuTeam team;

  const _Seat({
    required this.type,
    required this.name,
    required this.ready,
    required this.botLevel,
    required this.team,
  });

  factory _Seat.empty() => const _Seat(
        type: _SeatType.empty,
        name: '빈 자리',
        ready: false,
        botLevel: null,
        team: TichuTeam.random,
      );

  factory _Seat.human({required String name, required bool ready}) => _Seat(
        type: _SeatType.human,
        name: name,
        ready: ready,
        botLevel: null,
        team: TichuTeam.random,
      );

  factory _Seat.bot({required BotLevel level}) => _Seat(
        type: _SeatType.bot,
        name: 'BOT',
        ready: true,
        botLevel: level,
        team: TichuTeam.random,
      );

  bool get isHuman => type == _SeatType.human;

  _Seat copyWith({
    _SeatType? type,
    String? name,
    bool? ready,
    BotLevel? botLevel,
    TichuTeam? team,
  }) {
    return _Seat(
      type: type ?? this.type,
      name: name ?? this.name,
      ready: ready ?? this.ready,
      botLevel: botLevel ?? this.botLevel,
      team: team ?? this.team,
    );
  }
}

class _SeatTile extends StatelessWidget {
  final int index;
  final _Seat seat;
  final bool isHost;
  final bool canKick;
  final bool canEditBotLevel;
  final bool showTeamSelect;
  final VoidCallback onToggleReady;
  final VoidCallback onAddBotHere;
  final VoidCallback onKick;
  final ValueChanged<BotLevel> onBotLevelChanged;
  final ValueChanged<TichuTeam> onTeamChanged;

  const _SeatTile({
    required this.index,
    required this.seat,
    required this.isHost,
    required this.canKick,
    required this.canEditBotLevel,
    required this.showTeamSelect,
    required this.onToggleReady,
    required this.onAddBotHere,
    required this.onKick,
    required this.onBotLevelChanged,
    required this.onTeamChanged,
  });

  @override
  Widget build(BuildContext context) {
    final title = seat.type == _SeatType.empty
        ? '빈 자리'
        : (seat.type == _SeatType.bot ? 'BOT (${_botLabel(seat.botLevel!)})' : seat.name);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(child: Text('${index + 1}')),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                      const SizedBox(width: 8),
                      if (isHost) _tag(context, 'HOST'),
                      if (seat.type == _SeatType.bot) _tag(context, 'BOT'),
                    ],
                  ),
                  if (showTeamSelect && seat.type == _SeatType.human) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _teamChip(context, TichuTeam.random, '무작위', seat.team, onTeamChanged),
                        _teamChip(context, TichuTeam.team1, '1팀', seat.team, onTeamChanged),
                        _teamChip(context, TichuTeam.team2, '2팀', seat.team, onTeamChanged),
                      ],
                    ),
                  ],
                  if (canEditBotLevel && seat.type == _SeatType.bot) ...[
                    const SizedBox(height: 8),
                    DropdownButtonFormField<BotLevel>(
                      value: seat.botLevel!,
                      items: BotLevel.values
                          .map((e) => DropdownMenuItem(value: e, child: Text(_botLabel(e))))
                          .toList(),
                      onChanged: (v) => v == null ? null : onBotLevelChanged(v),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (seat.type == _SeatType.empty)
              IconButton(
                tooltip: '봇 추가',
                onPressed: onAddBotHere,
                icon: const Icon(Icons.add_circle_outline),
              )
            else if (seat.type == _SeatType.human)
              isHost
                  ? const SizedBox.shrink()
                  : FilledButton(
                      onPressed: onToggleReady,
                      child: Text(seat.ready ? '준비됨' : '준비'),
                    )
            else
              const SizedBox.shrink(),
            if (seat.type != _SeatType.empty && canKick)
              IconButton(
                tooltip: '제거',
                onPressed: onKick,
                icon: const Icon(Icons.close),
              ),
          ],
        ),
      ),
    );
  }

  Widget _tag(BuildContext context, String t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Text(t, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
    );
  }

  Widget _teamChip(
    BuildContext context,
    TichuTeam v,
    String label,
    TichuTeam selected,
    ValueChanged<TichuTeam> onChanged,
  ) {
    return ChoiceChip(
      label: Text(label),
      selected: v == selected,
      onSelected: (_) => onChanged(v),
    );
  }

  String _botLabel(BotLevel l) {
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
}