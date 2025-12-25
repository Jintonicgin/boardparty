import 'dart:async';
import 'package:flutter/material.dart';
import '../../widgets/top_status_actions.dart';

class QuickMatchWaitingPage extends StatefulWidget {
  final String gameId;
  final String gameTitle;
  final int stake;
  final int prize;
  final int requiredPlayers;

  const QuickMatchWaitingPage({
    super.key,
    required this.gameId,
    required this.gameTitle,
    required this.stake,
    required this.prize,
    required this.requiredPlayers,
  });

  @override
  State<QuickMatchWaitingPage> createState() => _QuickMatchWaitingPageState();
}

class _QuickMatchWaitingPageState extends State<QuickMatchWaitingPage> {
  int current = 1; // 나 포함
  Timer? timer;

  @override
  void initState() {
    super.initState();
    // mock: 1.2초마다 인원 늘어나고, 다 모이면 시작 화면으로 이동
    timer = Timer.periodic(const Duration(milliseconds: 1200), (_) {
      if (!mounted) return;
      setState(() {
        if (current < widget.requiredPlayers) current++;
      });
      if (current >= widget.requiredPlayers) {
        timer?.cancel();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const _GameStartCountdownPlaceholder()),
        );
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.gameTitle} · 매칭 중'),
        actions: const [TopStatusActions(coins: 7000, diamonds: 120)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('매칭 중...', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                          const SizedBox(height: 6),
                          Text('현재 인원: $current / ${widget.requiredPlayers}'),
                          const SizedBox(height: 6),
                          Text('참가금: ${widget.stake} · 1등 프라이즈: ${widget.prize}'),
                          const SizedBox(height: 6),
                          Text('취소해도 코인은 차감되지 않습니다.',
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('취소'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameStartCountdownPlaceholder extends StatelessWidget {
  const _GameStartCountdownPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('게임 시작 (TODO)')),
      body: const Center(
        child: Text('여기에 “3…2…1… 참가금 차감 → 게임 시작” 전환 화면'),
      ),
    );
  }
}