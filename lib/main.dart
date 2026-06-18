import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/chat/chat_screen.dart';
import 'features/chat/theme.dart';

void main() {
  runApp(const ProviderScope(child: RagApp()));
}

class RagApp extends StatelessWidget {
  const RagApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InsightEngine',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const ChatScreen(),
    );
  }
}
