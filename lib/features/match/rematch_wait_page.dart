import 'dart:async';
import 'package:flutter/material.dart';

import '../result/game_result_page.dart'; // SeatRole 재사용

/// 리매치 대기 결과
class RematchOutcome {
  final bool started;
  final bool left;
  const RematchOutcome({required this.started, required this.left});
}

class RematchSeat {
  final int seatIndex;
  final String name;
  final SeatRole role;
  final bool ready;

  const RematchSeat({
    required this.seatIndex,
    required this.name,
    required this.role,
    required this.ready,
  });

  RematchSeat copyWith({bool? ready}) {
    return RematchSeat(
      seatIndex: seatIndex,
      name: name,
      role: role,
      ready: ready ?? this.ready,
    );
  }
}

/// 코어만 리매치 가능.
/// - 봇은 자동 ready
/// - 코어 전원 ready면 호스트만 "리매치 시작" 가능
/// - 용병은 이 화면에 진입 자체가 막혀야 정상(상위에서 차단)
class RematchWaitPage extends StatefulWidget {
  const RematchWaitPage({
    super.key,
    required this.gameId,
    required this.gameTitle,
    required this.roomCode,
    required this.mySeatIndex,
    required this.seats,
    required this.isHost,
  });

  final String gameId;
  final String gameTitle;
  final String roomCode;

  final int mySeatIndex;
  final List<RematchSeat> seats;

  final bool isHost;

  @override
  State<RematchWaitPage> createState() => _RematchWaitPageState();
}

class _RematchWaitPageState extends State<RematchWaitPage> {
  late List<RematchSeat> _seats;
  Timer? _fakeNetworkTicker;

  @override
  void initState() {
    super.initState();
    _seats = widget.seats.map((s) {
      if (s.role == SeatRole.bot) return s.copyWith(ready: true);
      return s;
    }).toList();

    // MVP: 네트워크 느낌용 "상태 동기화" 틱(실제 서버 붙이면 제거)
    _fakeNetworkTicker = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _fakeNetworkTicker?.cancel();
    super.dispose();
  }

  bool get _myIsCore {
    final me = _seats.where((s) => s.seatIndex == widget.mySeatIndex).toList();
    if (me.isEmpty) return true;
    return me.first.role == SeatRole.core;
  }

  bool get _allCoreReady {
    final cores = _seats.where((s) => s.role == SeatRole.core).toList();
    if (cores.isEmpty) return true;
    return cores.every((s) => s.ready);
  }

  void _toggleMyReady() {
    final i = _seats.indexWhere((s) => s.seatIndex == widget.mySeatIndex);
    if (i < 0) return;

    final me = _seats[i];
    if (me.role != SeatRole.core) return;

    setState(() {
      _seats[i] = me.copyWith(ready: !me.ready);
    });
  }

  Future<void> _startRematch() async {
    // 호스트만 가능 + 코어 전원 ready
    if (!widget.isHost) return;
    if (!_allCoreReady) return;

    // TODO: 서버에 "rematch start" 요청 후, 성공하면 pop(started:true)
    Navigator.of(context).pop(const RematchOutcome(started: true, left: false));
  }

  void _leave() {
    Navigator.of(context).pop(const RematchOutcome(started: false, left: true));
  }

  @override
  Widget build(BuildContext context) {
    final me = _seats.firstWhere(
      (s) => s.seatIndex == widget.mySeatIndex,
      orElse: () => const RematchSeat(seatIndex: 0, name: 'Me', role: SeatRole.core, ready: true),
    );

    final canStart = widget.isHost && _allCoreReady;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.gameTitle} · 리매치 대기'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              flex: 6,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.groups_outlined),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '코어 멤버 리매치 준비',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: Theme.of(context).colorScheme.outline),
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            ),
                            child: Text('방 코드: ${widget.roomCode}', style: const TextStyle(fontWeight: FontWeight.w900)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '• 용병은 리매치에 참여하지 않습니다.\n'
                        '• 코어 멤버가 모두 준비되면 호스트가 시작할 수 있습니다.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 12),

                      Expanded(
                        child: ListView.separated(
                          itemCount: _seats.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, idx) {
                            final s = _seats[idx];
                            final isMe = s.seatIndex == widget.mySeatIndex;
                            return _RematchSeatTile(
                              seat: s,
                              isMe: isMe,
                            );
                          },
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
              child: Column(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('내 상태', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                          const SizedBox(height: 10),
                          Text(
                            '역할: ${_roleLabel(me.role)}\n'
                            '호스트: ${widget.isHost ? 'YES' : 'NO'}\n'
                            '코어 준비 완료: ${_allCoreReady ? 'YES' : 'NO'}',
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

                  if (_myIsCore) ...[
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _toggleMyReady,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Text(
                            me.ready ? '준비 해제' : '준비',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: canStart ? _startRematch : null,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text('리매치 시작(호스트)', style: TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _leave,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text('나가기', style: TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ),

                  const Spacer(),

                  Text(
                    widget.isHost
                        ? (canStart ? '전원 준비 완료! 시작 가능' : '코어 멤버가 모두 준비해야 시작 가능')
                        : '호스트가 시작합니다…',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
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

  String _roleLabel(SeatRole r) {
    switch (r) {
      case SeatRole.core:
        return 'CORE';
      case SeatRole.mercenary:
        return '용병';
      case SeatRole.bot:
        return 'BOT';
    }
  }
}

class _RematchSeatTile extends StatelessWidget {
  const _RematchSeatTile({required this.seat, required this.isMe});

  final RematchSeat seat;
  final bool isMe;

  String get _roleLabel {
    switch (seat.role) {
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
    final ring = Theme.of(context).colorScheme.primary;
    final outline = Theme.of(context).colorScheme.outline;

    final border = isMe ? ring : outline;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: isMe ? 2 : 1),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Row(
        children: [
          CircleAvatar(
            child: Icon(
              seat.role == SeatRole.bot ? Icons.smart_toy_outlined : Icons.person_outline,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    seat.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(width: 8),
                _Pill(text: _roleLabel),
                if (isMe) ...[
                  const SizedBox(width: 8),
                  _Pill(text: 'ME'),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          _ReadyChip(ready: seat.ready),
        ],
      ),
    );
  }
}

class _ReadyChip extends StatelessWidget {
  const _ReadyChip({required this.ready});
  final bool ready;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = ready ? cs.primary.withOpacity(0.14) : cs.surfaceContainerHighest;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        color: bg,
      ),
      child: Text(
        ready ? 'READY' : 'WAIT',
        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
    );
  }
}