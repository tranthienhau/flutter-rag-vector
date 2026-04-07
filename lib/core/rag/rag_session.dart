import 'dart:async';

import '../llm/claude_client.dart';
import 'chunker.dart';
import 'embedder.dart';
import 'vector_store.dart';

/// Orchestrates the embed -> retrieve -> generate pipeline.
///
/// `addDocument` is fire-and-forget for the UI but waits for chunking and
/// embedding to finish before resolving so the caller can surface a "ready"
/// state. `ask` returns a stream of generated tokens AND a one-shot list of
/// retrieved chunks via the `onRetrieved` callback so the UI can render
/// citation chips before the first token arrives.
class RagSession {
  RagSession({
    required this.chunker,
    required this.embedder,
    required this.vectorStore,
    required this.claude,
  });

  final Chunker chunker;
  final Embedder embedder;
  final VectorStore vectorStore;
  final ClaudeClient claude;

  Future<void> addDocument(String text, {String? sourceId}) async {
    final chunks = chunker.chunk(text, sourceId: sourceId);
    if (chunks.isEmpty) return;
    final embeddings = await embedder.embed(chunks.map((c) => c.text).toList());
    await vectorStore.upsert(chunks, embeddings);
  }

  Stream<String> ask({
    required String question,
    required List<Map<String, String>> history,
    void Function(List<RetrievedChunk> chunks)? onRetrieved,
  }) async* {
    final queryEmbedding = await embedder.embedQuery(question);
    final retrieved = await vectorStore.query(queryEmbedding, topK: 5, minScore: 0.65);
    onRetrieved?.call(retrieved);

    final system = _buildSystemPrompt(retrieved);
    final messages = [
      ...history,
      {'role': 'user', 'content': question},
    ];

    yield* claude.streamMessage(system: system, messages: messages);
  }

  String _buildSystemPrompt(List<RetrievedChunk> retrieved) {
    final buffer = StringBuffer();
    buffer.writeln(
      'You are a helpful assistant. Answer the user using ONLY the context '
      'below. If the answer is not in the context, say you do not know. Cite '
      'each fact with [cite:N] where N is the index of the chunk you used.',
    );
    buffer.writeln();
    for (var i = 0; i < retrieved.length; i++) {
      final chunk = retrieved[i].chunk;
      buffer.writeln('<context index="${i + 1}" source="${chunk.sourceId}">');
      buffer.writeln(chunk.text);
      buffer.writeln('</context>');
    }
    return buffer.toString();
  }
}
