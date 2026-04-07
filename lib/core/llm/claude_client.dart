import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Minimal Anthropic Claude streaming client built on Server-Sent Events.
///
/// This is a thin wrapper around the /v1/messages endpoint with `stream:true`.
/// We surface raw `delta.text` events as Dart strings so the UI can render
/// tokens as they arrive.
class ClaudeClient {
  ClaudeClient({
    required this.apiKey,
    this.model = 'claude-opus-4-6',
    this.maxTokens = 1024,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String apiKey;
  final String model;
  final int maxTokens;
  final http.Client _client;

  Stream<String> streamMessage({
    required String system,
    required List<Map<String, String>> messages,
  }) async* {
    final request = http.Request(
      'POST',
      Uri.parse('https://api.anthropic.com/v1/messages'),
    );
    request.headers.addAll({
      'x-api-key': apiKey,
      'anthropic-version': '2023-06-01',
      'content-type': 'application/json',
      'accept': 'text/event-stream',
    });
    request.body = jsonEncode({
      'model': model,
      'max_tokens': maxTokens,
      'system': system,
      'messages': messages,
      'stream': true,
    });

    final streamed = await _client.send(request);
    if (streamed.statusCode != 200) {
      final body = await streamed.stream.bytesToString();
      throw Exception('Claude API failed: ${streamed.statusCode} $body');
    }

    final lines = streamed.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    await for (final line in lines) {
      if (!line.startsWith('data: ')) continue;
      final payload = line.substring(6);
      if (payload == '[DONE]') break;

      try {
        final event = jsonDecode(payload) as Map<String, Object?>;
        if (event['type'] == 'content_block_delta') {
          final delta = event['delta'] as Map<String, Object?>;
          if (delta['type'] == 'text_delta') {
            yield delta['text'] as String;
          }
        }
      } catch (_) {
        // Skip malformed events.
      }
    }
  }
}
