import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter_rag_vector/core/rag/chunker.dart';
import 'package:flutter_rag_vector/core/rag/vector_store.dart';
import 'package:flutter_rag_vector/features/chat/chat_controller.dart';
import 'package:flutter_rag_vector/features/chat/chat_screen.dart';
import 'package:flutter_rag_vector/features/chat/theme.dart';

/// A chat controller seeded with a real, grounded RAG conversation so the
/// screenshots render genuine app widgets (bubbles + citation chips) without
/// requiring live Anthropic / Voyage / Pinecone API keys on the simulator.
class SeededChatController extends ChatController {
  SeededChatController(super.ref, List<ChatMessage> seed) {
    state = seed;
  }
}

RetrievedChunk _chunk(String id, String source, String text) => RetrievedChunk(
      chunk: TextChunk(
        id: id,
        sourceId: source,
        text: text,
        tokenStart: 0,
        tokenEnd: text.length ~/ 4,
      ),
      score: 0.0,
    );

List<ChatMessage> _conversation() => [
      ChatMessage(
        role: 'user',
        content: 'What is the refund window for annual plans?',
      ),
      ChatMessage(
        role: 'assistant',
        content:
            'Annual plans can be refunded within 14 days of purchase for a '
            'full refund [cite:1]. After 14 days, refunds are prorated based '
            'on unused months [cite:2].',
        citations: [
          _chunk('billing_0', 'billing_policy.md',
              'Annual subscriptions are eligible for a full refund within 14 days of the purchase date.'),
          _chunk('billing_1', 'billing_policy.md',
              'After the 14-day window, refunds are issued on a prorated basis for the remaining unused months.'),
        ],
      ),
      ChatMessage(
        role: 'user',
        content: 'Does that apply to team seats too?',
      ),
      ChatMessage(
        role: 'assistant',
        content:
            'Yes. Team seats follow the same 14-day full-refund window, and '
            'removed seats are credited at the prorated monthly rate [cite:1].',
        citations: [
          _chunk('billing_3', 'team_billing.md',
              'Team seats inherit the workspace billing policy: full refund within 14 days, prorated credit thereafter.'),
        ],
      ),
    ];

Widget _app({List<Override> overrides = const []}) => ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const ChatScreen(),
      ),
    );

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('01 empty chat', (tester) async {
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpWidget(_app());
    await tester.pump(const Duration(milliseconds: 600));
    await binding.takeScreenshot('01-empty-chat');
  });

  testWidgets('02 grounded answer with citations', (tester) async {
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpWidget(_app(overrides: [
      chatControllerProvider.overrideWith(
        (ref) => SeededChatController(ref, _conversation().sublist(0, 2)),
      ),
    ]));
    await tester.pump(const Duration(milliseconds: 600));
    await binding.takeScreenshot('02-grounded-answer');
  });

  testWidgets('03 multi-turn conversation', (tester) async {
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpWidget(_app(overrides: [
      chatControllerProvider.overrideWith(
        (ref) => SeededChatController(ref, _conversation()),
      ),
    ]));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.drag(find.byType(ListView).first, const Offset(0, -360));
    await tester.pump(const Duration(milliseconds: 600));
    await binding.takeScreenshot('03-multi-turn');
  });

  testWidgets('04 composing a question', (tester) async {
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpWidget(_app(overrides: [
      chatControllerProvider.overrideWith(
        (ref) => SeededChatController(ref, _conversation().sublist(0, 2)),
      ),
    ]));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byType(TextField));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(
        find.byType(TextField), 'How do I export my conversation history?');
    await tester.pump(const Duration(milliseconds: 600));
    await binding.takeScreenshot('04-composing-question');
  });
}
