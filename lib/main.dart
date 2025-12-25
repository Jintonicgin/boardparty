import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'app/app_shell.dart';

void main() {
  runApp(const BoardPartyApp());
}

class BoardPartyApp extends StatelessWidget {
  const BoardPartyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BoardParty',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: AppShell(),
    );
  }
}