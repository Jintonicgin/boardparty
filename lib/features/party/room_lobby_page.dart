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

  void _showGameRuleDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
            child: Column(
              children: [
                // 헤더
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
                // 내용
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: _buildGameRuleContent(),
                  ),
                ),
                // 하단 버튼
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
            subsections: [
              _RuleSubsection(
                subtitle: '내 턴에 하는 일',
                items: [
                  '아직 손에 남아있는 내 주사위 전부를 굴립니다.',
                  '나온 눈 (1~6) 중 하나를 선택합니다.',
                  '선택한 눈과 같은 값이 나온 주사위를 전부 해당 번호 카지노에 한꺼번에 배치합니다.',
                  '남은 주사위는 다음 턴에 다시 굴립니다.',
                  '다음 플레이어로 턴이 넘어갑니다.',
                ],
              ),
            ],
          ),
          SizedBox(height: 16),
          _RuleCard(
            icon: Icons.calculate,
            iconColor: Color(0xFF8B5CF6),
            title: '라운드 종료 정산',
            content: '각 카지노 (1~6번) 마다 주사위 개수로 순위를 매겨 상금을 가져갑니다.',
            subsections: [
              _RuleSubsection(
                subtitle: '핵심 규칙: 동점은 전부 무효',
                isHighlight: true,
                items: [
                  '어떤 카지노에서 같은 개수로 묶인 플레이어들은 그 순위에서 모두 탈락합니다.',
                  '보통 1등 동점이 가장 중요합니다.',
                ],
              ),
              _RuleSubsection(
                subtitle: '예시',
                example: '3번 카지노에 A=4개, B=4개, C=2개라면\n\n• A와 B는 1등 동점 → 둘 다 무효\n• 남은 사람 중 C가 최다 → C가 1등으로 상금을 가져감',
              ),
              _RuleSubsection(
                subtitle: '상금 배분',
                items: [
                  '각 카지노의 돈 카드는 보통 큰 금액부터 지급됩니다.',
                  '1등이 가장 큰 카드, 2등이 다음 카드… 순으로 가져갑니다.',
                ],
              ),
            ],
          ),
          SizedBox(height: 16),
          _RuleCard(
            icon: Icons.replay,
            iconColor: Color(0xFF60A5FA),
            title: '다음 라운드',
            content: '모든 카지노 상금을 정산한 뒤, 다음 라운드에서 다시 각 카지노에 상금을 공개 배치하고 같은 방식으로 진행합니다.',
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

    // 다른 게임들은 준비 중
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

class _RuleCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? content;
  final List<String>? items;
  final List<_RuleSubsection>? subsections;

  const _RuleCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.content,
    this.items,
    this.subsections,
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
          // 헤더
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
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 내용
          if (content != null) ...[
            Text(
              content!,
              style: const TextStyle(
                height: 1.6,
                fontSize: 14,
                color: Color(0xFFE5E7EB),
              ),
            ),
            if (items != null || subsections != null) const SizedBox(height: 8),
          ],
          if (items != null)
            ...items!.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6, left: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '• ',
                        style: TextStyle(
                          height: 1.6,
                          fontSize: 14,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          item,
                          style: const TextStyle(
                            height: 1.6,
                            fontSize: 14,
                            color: Color(0xFFE5E7EB),
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          if (subsections != null)
            ...subsections!.asMap().entries.map((entry) {
              final index = entry.key;
              final subsection = entry.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (index > 0 || content != null || items != null)
                    const SizedBox(height: 12),
                  subsection,
                ],
              );
            }),
        ],
      ),
    );
  }
}

class _RuleSubsection extends StatelessWidget {
  final String subtitle;
  final String? example;
  final List<String>? items;
  final bool isHighlight;

  const _RuleSubsection({
    required this.subtitle,
    this.example,
    this.items,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: isHighlight
          ? BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isHighlight)
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFEF4444),
                  size: 18,
                ),
              if (isHighlight) const SizedBox(width: 6),
              Expanded(
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: isHighlight ? const Color(0xFFEF4444) : const Color(0xFF93C5FD),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (example != null)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF121E35),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                example!,
                style: const TextStyle(
                  height: 1.6,
                  fontSize: 13,
                  color: Color(0xFFE5E7EB),
                  fontFamily: 'monospace',
                ),
              ),
            ),
          if (items != null)
            ...items!.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4, left: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '• ',
                        style: TextStyle(
                          height: 1.6,
                          fontSize: 13,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          item,
                          style: const TextStyle(
                            height: 1.6,
                            fontSize: 13,
                            color: Color(0xFFE5E7EB),
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
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