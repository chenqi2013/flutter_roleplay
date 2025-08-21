import 'package:get/get.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:rwkv_mobile_flutter/from_rwkv.dart';
import 'package:rwkv_mobile_flutter/rwkv_mobile_flutter.dart';
import 'package:rwkv_mobile_flutter/to_rwkv.dart' as to_rwkv;
// import 'dart:math';

import 'package:rwkv_mobile_flutter/types.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_roleplay/constant/constant.dart';
import 'package:flutter_roleplay/download_dialog.dart';
import 'package:flutter_roleplay/hometabs/roleplay_chat_page.dart';
import 'package:flutter_roleplay/models/chat_message_model.dart';
import 'package:flutter_roleplay/services/database_helper.dart';

class RolePlayChatController extends GetxController {
  /// Send message to RWKV isolate
  SendPort? _sendPort; //比如发送停止，发送prompt等

  /// Context for showing dialogs - can be set externally
  BuildContext? _context;

  /// Set context for showing dialogs
  void setContext(BuildContext context) {
    _context = context;
  }

  /// Get current context
  BuildContext? get currentContext => _context ?? Get.context;

  /// Receive message from RWKV isolate
  late final _receivePort =
      ReceivePort(); //主要接收子isolate发送来的消息，比如生成的token，或者子的sendport发送过来后给_sendPort赋值

  final RxInt prefillSpeed = 0.obs;
  final RxInt decodeSpeed = 0.obs;
  bool isGenerating = false;
  late Completer<void> _initRuntimeCompleter = Completer<void>();
  Timer? _getTokensTimer; // 未使用，先注释避免 lint 警告
  String prompt11 = '<EOD>User: 读博可以改变一个人的性格吗\n\nAssistant: <think>\n</think>';
  String prompt = '阿甘，讲讲你的故事';
  String role11 =
      '你叫汉克，来自《阿甘正传》，是阿甘一生最好的朋友。虽然你身体残疾，但你总是以乐观的态度面对生活，并鼓励阿甘勇敢地追求梦想。';

  StreamController<String>? localChatController;
  bool isModelLoaded = false;
  late String rmpack;

  // 数据库帮助类实例
  final DatabaseHelper _dbHelper = DatabaseHelper();
  bool isNeedSaveAiMessage = false;
  @override
  void onInit() async {
    super.onInit();
    _receivePort.listen((message) {
      if (message is SendPort) {
        _sendPort = message;
        debugPrint("receive SendPort: $message");
      } else {
        // // debugPrint("receive message: $message");
        // if (!isGenerating) {
        //   isGenerating = true;
        //   generate(prompt);
        // }
        if (message is ResponseBufferContent) {
          String result = message.responseBufferContent;
          // debugPrint(
          //   'receive ResponseBufferContent: $result,length=${result.length}',
          // );
          if (localChatController != null && !localChatController!.isClosed) {
            localChatController!.add(result);
            // debugPrint('Added to localChatController stream');
          } else {
            debugPrint('localChatController is null or closed');
          }
        } else if (message is Speed) {
          // var decodeSpeed = message.decodeSpeed;
          // var prefillProgress = message.prefillProgress;
          // var prefillSpeed = message.prefillSpeed;
          // debugPrint(
          //   'receive Speed: $decodeSpeed, $prefillProgress, $prefillSpeed',
          // );
        } else if (message is IsGenerating) {
          var generating = message.isGenerating;
          if (!generating && isNeedSaveAiMessage) {
            debugPrint('receive IsGenerating: $generating');
            isNeedSaveAiMessage = false;
            // 生成完成时，保存AI回复到数据库
            _saveCurrentAiMessage();
            if (_getTokensTimer != null) {
              _getTokensTimer!.cancel();
            }
          }
        }
      }
    });
    // loadGoModel();
    // streamChatCompletions(content: '阿甘！').listen((event) {
    //   debugPrint('streamChatCompletions event: $event');
    // });
    // 检查是否需要下载模型
    if (!await checkDownloadFile(downloadUrl)) {
      debugPrint('downloadUrl file not exists');
      // 延迟执行，确保 UI 已经构建完成
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = currentContext;
        if (context != null) {
          showDownloadDialog(
            context,
            '需要先下载模型才可以使用角色扮演功能',
            true,
            downloadUrl,
            '',
          );
        } else {
          debugPrint('No context available for showing download dialog');
        }
      });
    } else {
      loadChatModel();
      debugPrint('downloadUrl file exists');
    }
  }

  Future<void> loadChatModel() async {
    if (isModelLoaded) {
      return;
    }
    prefillSpeed.value = 0;
    decodeSpeed.value = 0;

    late String modelPath;

    if (Platform.isAndroid && backend == Backend.qnn) {
      for (final lib in qnnLibList) {
        await fromAssetsToTemp(
          "assets/lib/qnn/$lib",
          targetPath: "assets/lib/$lib",
        );
      }
    }

    final tokenizerPath = await fromAssetsToTemp(
      "assets/config/chat/b_rwkv_vocab_v20230424.txt",
    );

    rmpack = await fromAssetsToTemp(
      "assets/config/chat/rwkv-9-mix_user6500_system1700.rmpack",
    );

    // modelPath = await fromAssetsToTemp(
    //   "assets/model/chat/rwkv7-g1a-0.1b-20250728-ctx4096-Q8_0.gguf",
    // );

    modelPath = await getLocalFilePath(downloadUrl);
    if (!File(modelPath).existsSync()) {
      debugPrint('modelPath not exists');
      return;
    }
    isModelLoaded = true;

    if (Platform.isIOS || Platform.isMacOS) {
      modelPath = await fromAssetsToTemp(
        "assets/model/othello/RWKV-x070-G1-0.1b-20250307-ctx4096.st",
      );
      backend = Backend.webRwkv;
    }

    final rootIsolateToken = RootIsolateToken.instance;

    if (_sendPort != null) {
      send(
        to_rwkv.ReInitRuntime(
          modelPath: modelPath,
          backend: backend,
          tokenizerPath: tokenizerPath,
          latestRuntimeAddress: 0,
        ),
      );
    } else {
      final options = StartOptions(
        modelPath: modelPath,
        tokenizerPath: tokenizerPath,
        backend: backend,
        sendPort: _receivePort.sendPort,
        rootIsolateToken: rootIsolateToken!,
        latestRuntimeAddress: 0,
      );
      await RWKVMobile().runIsolate(options);
    }

    while (_sendPort == null) {
      debugPrint("waiting for sendPort...");
      await Future.delayed(const Duration(milliseconds: 50));
    }
    send(to_rwkv.LoadInitialStates(rmpack));
    send(to_rwkv.GetLatestRuntimeAddress());

    prompt =
        'System: 请你扮演名为${roleName.value}的角色，你的设定是：${roleDescription.value}\n\n';
    // var thinkingToken = '<think>\n</think>';
    // send(to_rwkv.SetThinkingToken(thinkingToken));
    send(to_rwkv.SetPrompt(prompt));
    send(to_rwkv.SetMaxLength(2000));
    send(
      to_rwkv.SetSamplerParams(
        temperature: 1.5,
        topK: 500,
        topP: 0.3,
        presencePenalty: .0,
        frequencyPenalty: 1.0,
        penaltyDecay: .996,
      ),
    );
    // send(to_rwkv.SetGenerationStopToken(0));
    // send(to_rwkv.ClearStates());
  }

  Future<String> fromAssetsToTemp(
    String assetsPath, {
    String? targetPath,
  }) async {
    try {
      // 在插件中加载资源时，先尝试从主应用加载
      ByteData data;
      try {
        data = await rootBundle.load(assetsPath);
      } catch (e) {
        // 如果主应用中没有，则从 flutter_roleplay 包中加载
        debugPrint(
          "Asset not found in main app, loading from package: $assetsPath",
        );
        final packagePath = 'packages/flutter_roleplay/$assetsPath';
        data = await rootBundle.load(packagePath);
      }

      final tempDir = await getTemporaryDirectory();
      final tempFile = File(path.join(tempDir.path, targetPath ?? assetsPath));
      await tempFile.create(recursive: true);
      await tempFile.writeAsBytes(data.buffer.asUint8List());
      return tempFile.path;
    } catch (e) {
      debugPrint("Error loading asset $assetsPath: $e");
      return "";
    }
  }

  Future<void> clearStates() async {
    prefillSpeed.value = 0;
    decodeSpeed.value = 0;

    // 只清空内存中的聊天记录，不删除数据库记录
    // 这样可以保留历史聊天记录
    ChatStateManager().getMessages(roleName.value).clear();

    final sendPort = _sendPort;
    if (sendPort == null) {
      debugPrint("sendPort is null");
      return;
    }
    send(to_rwkv.ClearStates());
    send(to_rwkv.LoadInitialStates(rmpack));
    prompt =
        'System: 请你扮演名为${roleName.value}的角色，你的设定是：${roleDescription.value}\n\n';
    // var thinkingToken = '<think>\n</think>';
    // send(to_rwkv.SetThinkingToken(thinkingToken));
    send(to_rwkv.SetPrompt(prompt));
  }

  // 彻底清空聊天记录（包括数据库）- 用于用户主动清空
  Future<void> clearAllChatHistory() async {
    prefillSpeed.value = 0;
    decodeSpeed.value = 0;

    // 清空数据库中的聊天记录
    if (roleName.value.isNotEmpty) {
      await clearChatHistoryFromDatabase(roleName.value);
    }

    // 清空内存中的聊天记录
    ChatStateManager().getMessages(roleName.value).clear();

    final sendPort = _sendPort;
    if (sendPort == null) {
      debugPrint("sendPort is null");
      return;
    }
    send(to_rwkv.ClearStates());
    send(to_rwkv.LoadInitialStates(rmpack));
    prompt =
        'System: 请你扮演名为${roleName.value}的角色，你的设定是：${roleDescription.value}\n\n';
    send(to_rwkv.SetPrompt(prompt));
  }

  void send(to_rwkv.ToRWKV toRwkv) {
    final sendPort = _sendPort;
    if (sendPort == null) {
      debugPrint("sendPort is null");
      return;
    }
    sendPort.send(toRwkv);
    return;
  }

  Future<void> stop() async => send(to_rwkv.Stop());

  Stream<String> streamLocalChatCompletions({String content = '介绍下自己'}) {
    debugPrint('streamLocalChatCompletions called with content: $content');
    if (localChatController != null) {
      localChatController!.close();
    }
    localChatController = StreamController<String>();
    debugPrint('Created new localChatController');
    generate(content);
    debugPrint('Called generate method');
    return localChatController!.stream;
  }

  /// 清空聊天记录
  void clearChatHistory() {
    if (localChatController != null) {
      localChatController!.close();
      localChatController = null;
    }
    // 通知UI清空聊天记录
    Get.snackbar('提示', '聊天记录已清空，开始新的角色扮演');
  }

  Future<void> reInitRuntime({
    required String modelPath,
    required Backend backend,
    required String tokenizerPath,
  }) async {
    prefillSpeed.value = 0;
    decodeSpeed.value = 0;
    _initRuntimeCompleter = Completer<void>();
    send(
      to_rwkv.ReInitRuntime(
        modelPath: modelPath,
        backend: backend,
        tokenizerPath: tokenizerPath,
        latestRuntimeAddress: 0,
      ),
    );
    return _initRuntimeCompleter.future;
  }

  /// 直接在 ffi+cpp 线程中进行推理工作, 也就是说, 会让 ffi 线程不接受任何新的 event
  Future<void> generate(String prompt) async {
    prefillSpeed.value = 0;
    decodeSpeed.value = 0;
    final sendPort = _sendPort;
    if (sendPort == null) {
      debugPrint("sendPort is null");
      return;
    }

    // // 动态更新角色信息
    // final currentPrompt =
    //     '<EOD>\nSystem: 请你扮演名为${roleName.value}的角色，你的设定是：${roleDescription.value}\n\n';
    // send(to_rwkv.SetPrompt(currentPrompt));

    // debugPrint("to_rwkv.prompt: $prompt");
    // send(
    //   to_rwkv.SetUserRole(
    //     "你叫汉克，来自《阿甘正传》，是阿甘一生最好的朋友。虽然你身体残疾，但你总是以乐观的态度面对生活，并鼓励阿甘勇敢地追求梦想。",
    //   ),
    // );

    // send(to_rwkv.SetPrompt(prompt));

    final messages = ChatStateManager().getMessages(roleName.value);
    debugPrint(
      'Current messages count for ${roleName.value}: ${messages.length}',
    );
    var history = <String>[];
    for (var message in messages) {
      var text = message.content;
      if (text.isNotEmpty) {
        history.add(text);
      }
    }
    debugPrint("to_rwkv.history: $history");
    send(to_rwkv.ChatAsync(history, reasoning: false));
    debugPrint('Sent ChatAsync to RWKV');

    if (_getTokensTimer != null) {
      _getTokensTimer!.cancel();
    }
    isNeedSaveAiMessage = true;
    _getTokensTimer = Timer.periodic(const Duration(milliseconds: 20), (
      timer,
    ) async {
      send(to_rwkv.GetResponseBufferIds());
      send(to_rwkv.GetPrefillAndDecodeSpeed());
      send(to_rwkv.GetResponseBufferContent());
      await Future.delayed(const Duration(milliseconds: 1000));
      send(to_rwkv.GetIsGenerating());
    });
  }

  /// 向后端发起 Chat Completions 请求
  /// 默认请求体按照需求给定，如需变更内容可传入 [content]
  Future<Map<String, dynamic>?> requestChatCompletions({
    String content = 'hello',
  }) async {
    final Uri uri = Uri.parse('http://192.168.0.103:8000/v1/chat/completions');
    final Map<String, dynamic> payload = <String, dynamic>{
      'frequency_penalty': 1,
      'max_tokens': 2000,
      'messages': <Map<String, dynamic>>[
        <String, dynamic>{'content': content, 'role': 'user'},
        <String, dynamic>{
          'content':
              '请你扮演名为汉克的角色，你的设定是：你叫汉克，来自《阿甘正传》，是阿甘一生最好的朋友。虽然你身体残疾，但你总是以乐观的态度面对生活，并鼓励阿甘勇敢地追求梦想。',
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
        debugPrint('Chat completions success: ' + data.toString());
        return data;
      } else {
        debugPrint(
          'Chat completions failed: status=' +
              response.statusCode.toString() +
              ', body=' +
              response.body,
        );
        return null;
      }
    } catch (e) {
      debugPrint('Chat completions error: ' + e.toString());
      return null;
    }
  }

  /// 流式输出：返回一个文本片段的 Stream
  /// 兼容 SSE (以 `data:` 前缀的行) 与纯行分隔的 JSON/文本
  Stream<String> streamChatCompletions({String content = 'hello'}) {
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
            'content':
                '请你扮演名为汉克的角色，你的设定是：你叫汉克，来自《阿甘正传》，是阿甘一生最好的朋友。虽然你身体残疾，但你总是以乐观的态度面对生活，并鼓励阿甘勇敢地追求梦想。',
          },
          <String, dynamic>{'role': 'user', 'content': content},
        ],
        'model': 'rwkv',
        'presence_penalty': 0,
        // 'presystem': true,
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
                // debugPrint('data: $data');
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
                    debugPrint('11streamChatCompletions parsed: $parsed');
                    return;
                  }

                  if (token != null && token.isNotEmpty) {
                    controller.add(token);
                    debugPrint('22streamChatCompletions token: $token');
                  } else {
                    // // 未识别则回退输出原始 data
                    // controller.add(data);
                    // debugPrint('33streamChatCompletions data: $data');
                  }
                } catch (_) {
                  // 非 JSON，直接输出
                  controller.add(data);
                  debugPrint('44streamChatCompletions data: $data');
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

  // 保存用户消息到数据库
  Future<void> saveUserMessage(String content) async {
    try {
      final message = ChatMessage(
        roleName: roleName.value,
        content: content,
        isUser: true,
        timestamp: DateTime.now(),
      );
      await _dbHelper.insertMessage(message);
    } catch (e) {
      debugPrint('Failed to save user message: $e');
    }
  }

  // 保存AI回复到数据库
  Future<void> saveAiMessage(String content) async {
    try {
      final message = ChatMessage(
        roleName: roleName.value,
        content: content,
        isUser: false,
        timestamp: DateTime.now(),
      );
      int result = await _dbHelper.insertMessage(message);
      debugPrint('saveAiMessage result: $result');
    } catch (e) {
      debugPrint('Failed to save AI message: $e');
    }
  }

  // 从数据库加载指定角色的聊天记录
  Future<List<ChatMessage>> loadChatHistory(String roleName) async {
    try {
      return await _dbHelper.getMessagesByRole(roleName);
    } catch (e) {
      debugPrint('Failed to load chat history: $e');
      return [];
    }
  }

  // 清空指定角色的聊天记录
  Future<void> clearChatHistoryFromDatabase(String roleName) async {
    try {
      await _dbHelper.deleteMessagesByRole(roleName);
    } catch (e) {
      debugPrint('Failed to clear chat history: $e');
    }
  }

  // 获取指定角色的消息数量
  Future<int> getMessageCount(String roleName) async {
    try {
      return await _dbHelper.getMessageCountByRole(roleName);
    } catch (e) {
      debugPrint('Failed to get message count: $e');
      return 0;
    }
  }

  // 保存当前AI回复到数据库
  Future<void> _saveCurrentAiMessage() async {
    try {
      // 获取当前角色的最后一条消息
      final messages = ChatStateManager().getMessages(roleName.value);
      if (messages.isNotEmpty && !messages.last.isUser) {
        final aiMessage = messages.last;
        // 只有当消息内容不为空时才保存
        if (aiMessage.content.isNotEmpty) {
          await saveAiMessage(aiMessage.content);
          debugPrint('AI message saved to database: ${aiMessage.content}');
        }
      }
    } catch (e) {
      debugPrint('Failed to save current AI message: $e');
    }
  }
}
