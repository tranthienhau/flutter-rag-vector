import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/llm/claude_client.dart';
import '../../core/rag/chunker.dart';
import '../../core/rag/embedder.dart';
import '../../core/rag/rag_session.dart';
import '../../core/rag/vector_store.dart';

const _anthropicKey = String.fromEnvironment('ANTHROPIC_API_KEY', defaultValue: '');
const _voyageKey = String.fromEnvironment('VOYAGE_API_KEY', defaultValue: '');
const _pineconeKey = String.fromEnvironment('PINECONE_API_KEY', defaultValue: '');
const _pineconeHost = String.fromEnvironment('PINECONE_HOST', defaultValue: '');

final ragSessionProvider = Provider<RagSession>((ref) {
  final VectorStore store = _pineconeKey.isEmpty || _pineconeHost.isEmpty
      ? InMemoryVectorStore()
      : PineconeVectorStore(apiKey: _pineconeKey, indexHost: _pineconeHost);

  return RagSession(
    chunker: Chunker(),
    embedder: Embedder(apiKey: _voyageKey),
    vectorStore: store,
    claude: ClaudeClient(apiKey: _anthropicKey),
  );
});

class ChatMessage {
  ChatMessage({required this.role, required this.content, this.citations = const []});
  final String role; // 'user' | 'assistant'
  String content;
  List<RetrievedChunk> citations;

  Map<String, String> toApiFormat() => {'role': role, 'content': content};
}

class ChatController extends StateNotifier<List<ChatMessage>> {
  ChatController(this._ref) : super(const []);
  final Ref _ref;

  Future<void> addDocument(String text) async {
    await _ref.read(ragSessionProvider).addDocument(text);
  }

  Future<void> ask(String question) async {
    final userMessage = ChatMessage(role: 'user', content: question);
    final assistantMessage = ChatMessage(role: 'assistant', content: '');
    state = [...state, userMessage, assistantMessage];

    final history = state
        .where((m) => m != assistantMessage)
        .map((m) => m.toApiFormat())
        .toList();

    final session = _ref.read(ragSessionProvider);
    await for (final token in session.ask(
      question: question,
      history: history,
      onRetrieved: (chunks) {
        assistantMessage.citations = chunks;
        state = [...state];
      },
    )) {
      assistantMessage.content += token;
      state = [...state];
    }
  }
}

final chatControllerProvider =
    StateNotifierProvider<ChatController, List<ChatMessage>>((ref) {
  return ChatController(ref);
});
