import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

import 'chunker.dart';

class RetrievedChunk {
  const RetrievedChunk({required this.chunk, required this.score});
  final TextChunk chunk;
  final double score;
}

abstract class VectorStore {
  Future<void> upsert(List<TextChunk> chunks, List<List<double>> embeddings);
  Future<List<RetrievedChunk>> query(List<double> embedding, {int topK = 5, double minScore = 0.0});
}

/// Pure-Dart in-memory vector store. Used for offline / first-run UX so the
/// app is functional before the user wires up Pinecone.
class InMemoryVectorStore implements VectorStore {
  final List<_StoredVector> _items = [];

  @override
  Future<void> upsert(List<TextChunk> chunks, List<List<double>> embeddings) async {
    assert(chunks.length == embeddings.length);
    for (var i = 0; i < chunks.length; i++) {
      _items.removeWhere((v) => v.chunk.id == chunks[i].id);
      _items.add(_StoredVector(chunk: chunks[i], embedding: embeddings[i]));
    }
  }

  @override
  Future<List<RetrievedChunk>> query(
    List<double> embedding, {
    int topK = 5,
    double minScore = 0.0,
  }) async {
    final scored = _items
        .map((v) => RetrievedChunk(
              chunk: v.chunk,
              score: _cosine(embedding, v.embedding),
            ))
        .where((r) => r.score >= minScore)
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    return scored.take(topK).toList();
  }

  static double _cosine(List<double> a, List<double> b) {
    if (a.length != b.length || a.isEmpty) return 0;
    var dot = 0.0, na = 0.0, nb = 0.0;
    for (var i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      na += a[i] * a[i];
      nb += b[i] * b[i];
    }
    if (na == 0 || nb == 0) return 0;
    return dot / (math.sqrt(na) * math.sqrt(nb));
  }
}

class _StoredVector {
  _StoredVector({required this.chunk, required this.embedding});
  final TextChunk chunk;
  final List<double> embedding;
}

/// Pinecone REST adapter. Uses the v2 API (`*-svc.pinecone.io/vectors/*`).
class PineconeVectorStore implements VectorStore {
  PineconeVectorStore({
    required this.apiKey,
    required this.indexHost,
    this.namespace = 'default',
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String apiKey;
  final String indexHost; // e.g. https://my-index-xyz.svc.us-east-1-aws.pinecone.io
  final String namespace;
  final http.Client _client;

  @override
  Future<void> upsert(List<TextChunk> chunks, List<List<double>> embeddings) async {
    final vectors = [
      for (var i = 0; i < chunks.length; i++)
        {
          'id': chunks[i].id,
          'values': embeddings[i],
          'metadata': {
            'source_id': chunks[i].sourceId,
            'text': chunks[i].text,
            'token_start': chunks[i].tokenStart,
            'token_end': chunks[i].tokenEnd,
          },
        }
    ];

    final response = await _client.post(
      Uri.parse('$indexHost/vectors/upsert'),
      headers: _headers(),
      body: jsonEncode({'vectors': vectors, 'namespace': namespace}),
    );
    if (response.statusCode != 200) {
      throw Exception('Pinecone upsert failed: ${response.statusCode} ${response.body}');
    }
  }

  @override
  Future<List<RetrievedChunk>> query(
    List<double> embedding, {
    int topK = 5,
    double minScore = 0.0,
  }) async {
    final response = await _client.post(
      Uri.parse('$indexHost/query'),
      headers: _headers(),
      body: jsonEncode({
        'namespace': namespace,
        'vector': embedding,
        'topK': topK,
        'includeMetadata': true,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Pinecone query failed: ${response.statusCode} ${response.body}');
    }

    final body = jsonDecode(response.body) as Map<String, Object?>;
    final matches = (body['matches'] as List<Object?>).cast<Map<String, Object?>>();
    return matches
        .map((m) {
          final metadata = m['metadata'] as Map<String, Object?>;
          return RetrievedChunk(
            chunk: TextChunk(
              id: m['id'] as String,
              sourceId: metadata['source_id'] as String,
              text: metadata['text'] as String,
              tokenStart: (metadata['token_start'] as num).toInt(),
              tokenEnd: (metadata['token_end'] as num).toInt(),
            ),
            score: (m['score'] as num).toDouble(),
          );
        })
        .where((r) => r.score >= minScore)
        .toList();
  }

  Map<String, String> _headers() => {
        'Api-Key': apiKey,
        'Content-Type': 'application/json',
      };
}
