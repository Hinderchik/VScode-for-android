import 'dart:convert';
import 'package:dio/dio.dart';
import '../services/tor_service.dart';

class ClimService {
  static Dio _buildDio(String apiKey) {
    final options = BaseOptions(
      baseUrl: 'https://api.anthropic.com',
      headers: {
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
      },
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
    );
    final dio = Dio(options);
    if (TorService.isRunning) {
      // Route through Orbot SOCKS5
      // Dio doesn't support SOCKS5 natively; use HttpClient adapter
      // For now we rely on system-level proxy set by Orbot
    }
    return dio;
  }

  static Future<String> sendMessage({
    required String apiKey,
    required String model,
    required List<Map<String, String>> messages,
    int maxTokens = 2048,
  }) async {
    final dio = _buildDio(apiKey);
    final response = await dio.post('/v1/messages', data: {
      'model': model,
      'messages': messages,
      'max_tokens': maxTokens,
    });
    final data = response.data;
    return (data['content'] as List).first['text'] as String;
  }

  static Future<String> explainCode({
    required String apiKey,
    required String model,
    required String code,
    required String language,
  }) async {
    return sendMessage(
      apiKey: apiKey,
      model: model,
      messages: [
        {
          'role': 'user',
          'content':
              'Explain this $language code concisely:\n\n```$language\n$code\n```',
        }
      ],
    );
  }

  static Future<String> completeCode({
    required String apiKey,
    required String model,
    required String prefix,
    required String language,
  }) async {
    return sendMessage(
      apiKey: apiKey,
      model: model,
      messages: [
        {
          'role': 'user',
          'content':
              'Complete this $language code. Return ONLY the completion, no explanation:\n\n```$language\n$prefix',
        }
      ],
      maxTokens: 512,
    );
  }
}
