import 'package:flutter/material.dart';
import '../../widgets/top_status_actions.dart';

class JoinByCodePage extends StatefulWidget {
  final String gameTitle;
  const JoinByCodePage({super.key, required this.gameTitle});

  @override
  State<JoinByCodePage> createState() => _JoinByCodePageState();
}

class _JoinByCodePageState extends State<JoinByCodePage> {
  final ctrl = TextEditingController();

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.gameTitle} · 코드로 참가'),
        actions: const [TopStatusActions(coins: 7000, diamonds: 120)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: ctrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: '방 코드',
                hintText: '예: A7K3P',
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  // TODO: 서버 붙이면 코드로 룸 조회 후 입장
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('코드 "${ctrl.text}"로 참가 (TODO: 서버 연결)')),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('참가'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}