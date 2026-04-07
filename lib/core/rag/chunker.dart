/// Token-aware text splitter with overlap.
///
/// Real production RAG pipelines use a tokenizer aware of the embedding model
/// (e.g. tiktoken). For the POC we approximate tokens as ~4 characters which
/// is close enough for English text and keeps the file dependency-free.
class Chunker {
  Chunker({this.targetTokens = 512, this.overlapTokens = 64})
      : assert(targetTokens > overlapTokens, 'overlap must be smaller than target');

  final int targetTokens;
  final int overlapTokens;

  static const _charsPerToken = 4;

  List<TextChunk> chunk(String document, {String? sourceId}) {
    final chunks = <TextChunk>[];
    final source = sourceId ?? 'doc_${document.hashCode}';

    final targetChars = targetTokens * _charsPerToken;
    final overlapChars = overlapTokens * _charsPerToken;
    final stride = targetChars - overlapChars;

    var start = 0;
    var index = 0;
    while (start < document.length) {
      final end = (start + targetChars).clamp(0, document.length);
      final text = document.substring(start, end).trim();
      if (text.isNotEmpty) {
        chunks.add(TextChunk(
          id: '${source}_$index',
          sourceId: source,
          text: text,
          tokenStart: start ~/ _charsPerToken,
          tokenEnd: end ~/ _charsPerToken,
        ));
        index += 1;
      }
      if (end >= document.length) break;
      start += stride;
    }
    return chunks;
  }
}

class TextChunk {
  const TextChunk({
    required this.id,
    required this.sourceId,
    required this.text,
    required this.tokenStart,
    required this.tokenEnd,
  });

  final String id;
  final String sourceId;
  final String text;
  final int tokenStart;
  final int tokenEnd;
}
