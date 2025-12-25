import 'package:flutter/material.dart';
import '../../widgets/top_status_actions.dart';
import 'room_lobby_page.dart';

enum CreateRoomMode { online, solo }

class CreateRoomPage extends StatefulWidget {
  final String gameId;
  final String gameTitle;
  final CreateRoomMode mode;

  const CreateRoomPage({
    super.key,
    required this.gameId,
    required this.gameTitle,
    required this.mode,
  });

  @override
  State<CreateRoomPage> createState() => _CreateRoomPageState();
}

class _CreateRoomPageState extends State<CreateRoomPage> {
  int players = 4;
  int stake = 3000;
  int rounds = 1;

  bool get isTichu => widget.gameId == 'tichu';

  @override
  void initState() {
    super.initState();
    if (isTichu) players = 4; // 티츄 4인 고정(지금 가정)
  }

  @override
  Widget build(BuildContext context) {
    final isSolo = widget.mode == CreateRoomMode.solo;

    return Scaffold(
      appBar: AppBar(
        title: Text(isSolo ? '${widget.gameTitle} · 혼자하기' : '${widget.gameTitle} · 방 만들기'),
        actions: const [TopStatusActions(coins: 7000, diamonds: 120)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionTitle('인원수'),
          const SizedBox(height: 8),
          if (isTichu)
            const _FixedPill('티츄는 4인 고정')
          else
            _Dropdown<int>(
              value: players,
              items: const [2, 3, 4, 5, 6, 7, 8],
              labelBuilder: (v) => '$v명',
              onChanged: (v) => setState(() => players = v),
            ),

          const SizedBox(height: 16),
          _SectionTitle(isTichu ? '게임 방식(점수/판수)' : '판수'),
          const SizedBox(height: 8),
          if (isTichu)
            _Dropdown<String>(
              value: rounds == 0 ? '점수제' : '판수제',
              items: const ['점수제', '판수제'],
              labelBuilder: (v) => v,
              onChanged: (v) => setState(() => rounds = (v == '점수제') ? 0 : 1),
            )
          else
            _Dropdown<int>(
              value: rounds,
              items: const [1, 3, 5],
              labelBuilder: (v) => '${v}판',
              onChanged: (v) => setState(() => rounds = v),
            ),

          const SizedBox(height: 16),
          _SectionTitle(isSolo ? '참가금 (혼자하기: 무료)' : '참가금'),
          const SizedBox(height: 8),
          if (isSolo)
            const _FixedPill('혼자하기는 코인 소모 없음 · 랭킹 반영 안 됨')
          else
            _StakeSelector(
              value: stake,
              onChanged: (v) => setState(() => stake = v),
            ),

          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('취소'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => RoomLobbyPage(
                          gameId: widget.gameId,
                          gameTitle: widget.gameTitle,
                          isSolo: isSolo,
                          players: isTichu ? 4 : players,
                          stake: isSolo ? 0 : stake,
                          rounds: rounds,
                        ),
                      ),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('방 생성'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
    );
  }
}

class _FixedPill extends StatelessWidget {
  final String text;
  const _FixedPill(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Text(text, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final String Function(T) labelBuilder;
  final ValueChanged<T> onChanged;

  const _Dropdown({
    required this.value,
    required this.items,
    required this.labelBuilder,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items
          .map((e) => DropdownMenuItem<T>(
                value: e,
                child: Text(labelBuilder(e)),
              ))
          .toList(),
      onChanged: (v) => v == null ? null : onChanged(v),
    );
  }
}

class _StakeSelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _StakeSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final options = const [3000, 5000, 10000];

    return Row(
      children: options.map((v) {
        final selected = v == value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: v == options.last ? 0 : 10),
            child: OutlinedButton(
              onPressed: () => onChanged(v),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text('${v.toString()} 코인'),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}