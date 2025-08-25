import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

/// 聊天流管理服务
class ChatStreamService {
  /// 向后端发起 Chat Completions 请求
  /// 默认请求体按照需求给定，如需变更内容可传入 [content]
  Future<Map<String, dynamic>?> requestChatCompletions({
    String content = 'hello',
    String roleName = '',
    String roleDescription = '',
  }) async {
    final Uri uri = Uri.parse('http://192.168.0.103:8000/v1/chat/completions');
    final Map<String, dynamic> payload = <String, dynamic>{
      'frequency_penalty': 1,
      'max_tokens': 2000,
      'messages': <Map<String, dynamic>>[
        <String, dynamic>{'content': content, 'role': 'user'},
        <String, dynamic>{
          'content': '请你扮演名为$roleName的角色，你的设定是：$roleDescription',
          'role': 'system',
        },
      ],
      'model': 'rwkv',
      'presence_penalty': 0,
      'presystem': true,
      // 非流式接口请保持 false；流式请使用 streamChatCompletions
      'stream': false,
      'temperature': 1,
      'top_p': 0.3,
    };

    try {
      final http.Response response = await http.post(
        uri,
        headers: const <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> data =
            jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('Chat completions success: ${data.toString()}');
        return data;
      } else {
        debugPrint(
          'Chat completions failed: status=${response.statusCode}, body=${response.body}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('Chat completions error: ${e.toString()}');
      return null;
    }
  }

  /// 流式输出：返回一个文本片段的 Stream
  /// 兼容 SSE (以 `data:` 前缀的行) 与纯行分隔的 JSON/文本
  Stream<String> streamChatCompletions({
    String content = 'hello',
    String roleName = '',
    String roleDescription = '',
  }) {
    final StreamController<String> controller = StreamController<String>();

    () async {
      final Uri uri = Uri.parse(
        'http://192.168.0.103:8000/v1/chat/completions',
      );
      final Map<String, dynamic> payload = <String, dynamic>{
        'frequency_penalty': 1,
        'max_tokens': 2000,
        'messages': <Map<String, dynamic>>[
          <String, dynamic>{
            'role': 'system',
            'content': '请你扮演名为$roleName的角色，你的设定是：$roleDescription',
          },
          <String, dynamic>{'role': 'user', 'content': content},
        ],
        'model': 'rwkv',
        'presence_penalty': 0,
        'stream': true,
        'temperature': 1,
        'top_p': 0.3,
      };

      final http.Client client = http.Client();
      StreamSubscription<String>? sub;
      try {
        final http.Request req = http.Request('POST', uri)
          ..headers.addAll(const <String, String>{
            'Content-Type': 'application/json',
          })
          ..body = jsonEncode(payload);
        final http.StreamedResponse resp = await client.send(req);
        if (resp.statusCode < 200 || resp.statusCode >= 300) {
          controller.addError('HTTP ${resp.statusCode}');
          await controller.close();
          client.close();
          return;
        }

        sub = resp.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen(
              (String line) {
                final String raw = line.trim();
                if (raw.isEmpty) return;

                String data = raw;
                if (data.startsWith('data:')) {
                  data = data.substring(5).trim();
                }
                if (data == '[DONE]' || data == 'DONE') {
                  controller.close();
                  client.close();
                  debugPrint('streamChatCompletions DONE');
                  return;
                }

                // 尝试解析 JSON，尽力提取常见字段，否则原样输出
                try {
                  final dynamic parsed = jsonDecode(data);
                  String? token;
                  if (parsed is Map<String, dynamic>) {
                    // OpenAI 风格：choices[0].delta.content 或 choices[0].message.content
                    final List<dynamic>? choices =
                        parsed['choices'] as List<dynamic>?;
                    if (choices != null && choices.isNotEmpty) {
                      final dynamic first = choices.first;
                      if (first is Map<String, dynamic>) {
                        final dynamic delta = first['delta'];
                        if (delta is Map<String, dynamic>) {
                          final dynamic c = delta['content'];
                          if (c is String) token = c;
                        }
                        if (token == null) {
                          final dynamic msg = first['message'];
                          if (msg is Map<String, dynamic>) {
                            final dynamic c = msg['content'];
                            if (c is String) token = c;
                          }
                        }
                      }
                    }
                    // 其他后端可能直接用 content 字段
                    token ??= parsed['content'] as String?;
                  } else if (parsed is String) {
                    // 直接字符串
                    controller.add(parsed);
                    debugPrint('streamChatCompletions parsed: $parsed');
                    return;
                  }

                  if (token != null && token.isNotEmpty) {
                    controller.add(token);
                    debugPrint('streamChatCompletions token: $token');
                  }
                } catch (_) {
                  // 非 JSON，直接输出
                  controller.add(data);
                  debugPrint('streamChatCompletions data: $data');
                }
              },
              onError: (Object e, StackTrace st) async {
                controller.addError(e);
                await controller.close();
                client.close();
              },
              onDone: () async {
                await controller.close();
                client.close();
              },
            );

        controller.onCancel = () async {
          await sub?.cancel();
          client.close();
        };
      } catch (e) {
        controller.addError(e.toString());
        await controller.close();
        client.close();
      }
    }();

    return controller.stream;
  }
}
