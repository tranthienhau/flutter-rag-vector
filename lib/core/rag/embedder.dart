import 'dart:convert';
import 'package:http/http.dart' as http;

/// Embedding client. Defaults to Voyage AI which is the embeddings provider
/// recommended for use with Anthropic Claude. Returns a `List<double>` per
/// input string.
class Embedder {
  Embedder({
    required this.apiKey,
    this.model = 'voyage-3',
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String apiKey;
  final String model;
  final http.Client _client;

  static const _endpoint = 'https://api.voyageai.com/v1/embeddings';

  Future<List<List<double>>> embed(List<String> inputs) async {
    final response = await _client.post(
      Uri.parse(_endpoint),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'input': inputs, 'model': model, 'input_type': 'document'}),
    );

    if (response.statusCode != 200) {
      throw Exception('Embedding API failed: ${response.statusCode} ${response.body}');
    }

    final body = jsonDecode(response.body) as Map<String, Object?>;
    final data = body['data'] as List<Object?>;
    return data
        .map((e) => (e as Map<String, Object?>)['embedding'] as List<Object?>)
        .map((vec) => vec.map((v) => (v as num).toDouble()).toList())
        .toList();
  }

  Future<List<double>> embedQuery(String query) async {
    final result = await embed([query]);
    return result.first;
  }
}
