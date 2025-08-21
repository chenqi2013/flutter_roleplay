import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:flutter_roleplay/constant/constant.dart';
import 'package:flutter_roleplay/hometabs/roleplay_chat_controller.dart';
import 'package:flutter_roleplay/widgets/character_intro.dart';
import 'dart:async';

import 'package:flutter_roleplay/widgets/global_input_bar.dart';
import 'package:flutter_roleplay/pages/new/createrole_page.dart';
import 'package:flutter_roleplay/pages/roles/roles_list_page.dart';
import 'package:flutter_roleplay/models/chat_message_model.dart';
import 'package:flutter_roleplay/services/database_helper.dart';

class RoleplayManage {
  static Widget createRolePlayChatPage() {
    return GetMaterialApp(home: RolePlayChat());
  }
}

// 全局聊天状态管理
class ChatStateManager {
  static final ChatStateManager _instance = ChatStateManager._internal();
  factory ChatStateManager() => _instance;
  ChatStateManager._internal();

  final Map<String, List<ChatMessage>> _chatCache = {};
  final Map<String, ScrollController> _scrollControllers = {};
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<ChatMessage> getMessages(String pageKey) {
    return _chatCache[pageKey] ??= [];
  }

  ScrollController getScrollController(String pageKey) {
    return _scrollControllers[pageKey] ??= ScrollController();
  }

  // 添加消息到内存缓存和数据库
  Future<void> addMessage(String pageKey, ChatMessage message) async {
    getMessages(pageKey).add(message);

    // 保存到数据库
    try {
      final result = await _dbHelper.insertMessage(message);
      debugPrint(
        'User message saved to database: $result, content: ${message.content}',
      );
    } catch (e) {
      debugPrint('Failed to save message to database: $e');
    }
  }

  // 更新最后一条消息（仅更新内存，不立即保存到数据库）
  void updateLastMessageInMemory(String pageKey, ChatMessage message) {
    final messages = getMessages(pageKey);
    if (messages.isNotEmpty) {
      messages[messages.length - 1] = message;
    }
  }

  // 更新最后一条消息并保存到数据库
  Future<void> updateLastMessage(String pageKey, ChatMessage message) async {
    final messages = getMessages(pageKey);
    if (messages.isNotEmpty) {
      messages[messages.length - 1] = message;

      // 更新数据库中的最后一条消息
      try {
        // 删除最后一条消息并插入新的
        await _dbHelper.deleteLatestMessagesByRole(message.roleName, 1);
        await _dbHelper.insertMessage(message);
      } catch (e) {
        debugPrint('Failed to update message in database: $e');
      }
    }
  }

  // 清空指定角色的聊天记录
  Future<void> clearMessages(String pageKey) async {
    _chatCache[pageKey]?.clear();

    // 从数据库中也删除该角色的所有消息
    try {
      await _dbHelper.deleteMessagesByRole(pageKey);
    } catch (e) {
      debugPrint('Failed to clear messages from database: $e');
    }
  }

  // 从数据库加载指定角色的聊天记录
  Future<void> loadMessagesFromDatabase(String roleName) async {
    try {
      final messages = await _dbHelper.getMessagesByRole(roleName);
      _chatCache[roleName] = messages;
    } catch (e) {
      debugPrint('Failed to load messages from database: $e');
      debugPrint('Failed to load messages from database: $e');
      _chatCache[roleName] = [];
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

  void dispose() {
    for (var controller in _scrollControllers.values) {
      controller.dispose();
    }
    _scrollControllers.clear();
  }
}

class RolePlayChat extends StatefulWidget {
  const RolePlayChat({super.key});

  @override
  State<RolePlayChat> createState() => _RolePlayChatState();
}

class _RolePlayChatState extends State<RolePlayChat>
    with AutomaticKeepAliveClientMixin {
  static const double inputBarHeight = 56.0;

  final ChatStateManager _stateManager = ChatStateManager();
  StreamSubscription<String>? _streamSub;
  final TextEditingController _textController = TextEditingController();
  final PageController _pageController = PageController();

  // 缓存相关
  bool _isControllerInitialized = false;
  bool _isInitializing = false;

  List<ChatMessage> get _messages {
    final messages = _stateManager.getMessages(roleName.value);
    // debugPrint(
    //   'Getting messages for ${roleName.value}: ${messages.length} messages',
    // );
    return messages;
  }

  ScrollController get _scrollController =>
      _stateManager.getScrollController(roleName.value);
  RolePlayChatController? _controller;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    // 初始化默认角色
    initializeDefaultRole();

    // 异步初始化控制器，不阻塞UI
    _initializeController();

    // 监听角色信息变化，当角色信息更新时自动清空聊天记录
    ever(roleDescription, (String newDesc) {
      if (_messages.isNotEmpty) {
        setState(() {
          _messages.clear();
        });
        _scrollToBottom();
      }
    });

    // 监听角色切换，同步PageView位置并加载历史记录
    ever(roleName, (String newRoleName) {
      if (newRoleName.isNotEmpty) {
        // 加载新角色的聊天历史记录
        Future.microtask(() async {
          await _stateManager.loadMessagesFromDatabase(newRoleName);
          setState(() {
            // 触发UI更新以显示历史记录
          });
          debugPrint('Loaded chat history for role change: $newRoleName');
        });
      }

      if (usedRoles.isNotEmpty) {
        final index = usedRoles.indexWhere(
          (role) => role['name'] == newRoleName,
        );
        if (index != -1 && _pageController.hasClients) {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      }
    });

    // 监听 usedRoles 列表变化，如果有新角色添加，跳转到最后一页
    ever(usedRoles, (List<Map<String, dynamic>> newUsedRoles) {
      if (newUsedRoles.isNotEmpty && _pageController.hasClients) {
        // 延迟执行，确保UI已更新
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final currentRoleIndex = newUsedRoles.indexWhere(
            (role) => role['name'] == roleName.value,
          );
          if (currentRoleIndex != -1) {
            _pageController.animateToPage(
              currentRoleIndex,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        });
      }
    });
  }

  void _initializeController() {
    // 使用 addPostFrameCallback 确保UI先渲染
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_isControllerInitialized || _isInitializing) return;

      _isInitializing = true;

      try {
        if (Get.isRegistered<RolePlayChatController>()) {
          _controller = Get.find<RolePlayChatController>();
        } else {
          _controller = Get.put(RolePlayChatController());
        }
        // 设置 context 以便控制器可以显示对话框
        _controller?.setContext(context);
        _isControllerInitialized = true;
        debugPrint('Controller initialized successfully');

        // 加载聊天历史记录
        if (roleName.value.isNotEmpty) {
          _loadChatHistory();
        }
      } catch (e) {
        debugPrint('Controller initialization error: $e');
      } finally {
        _isInitializing = false;
      }
    });
  }

  // 加载聊天历史记录
  Future<void> _loadChatHistory() async {
    if (roleName.value.isEmpty) return;

    try {
      await _stateManager.loadMessagesFromDatabase(roleName.value);
      setState(() {
        // 触发UI更新
      });
      debugPrint('Chat history loaded for role: ${roleName.value}');
    } catch (e) {
      debugPrint('Failed to load chat history: $e');
    }
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    _textController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handleSend(String text) async {
    final String content = text.trim();
    if (content.isEmpty) return;

    // 等待控制器初始化完成
    if (!_isControllerInitialized) {
      // 等待控制器初始化
      int attempts = 0;
      while (!_isControllerInitialized && attempts < 50) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }
      if (_controller == null) {
        debugPrint('Controller not available after waiting');
        return;
      }
    }

    // 创建用户消息
    final userMessage = ChatMessage(
      roleName: roleName.value,
      content: content,
      isUser: true,
      timestamp: DateTime.now(),
    );

    // 创建AI回复占位消息
    final aiMessage = ChatMessage(
      roleName: roleName.value,
      content: '',
      isUser: false,
      timestamp: DateTime.now(),
    );

    // 添加用户消息到状态管理器（会自动保存到数据库）
    debugPrint('Saving user message: ${userMessage.content}');
    await _stateManager.addMessage(roleName.value, userMessage);
    debugPrint('User message added to state manager');

    // 添加AI占位消息到内存（不保存到数据库，因为内容为空）
    _stateManager.getMessages(roleName.value).add(aiMessage);

    setState(() {
      // 触发UI更新
    });

    _scrollToBottom();

    _streamSub?.cancel();
    _streamSub = _controller!
        .streamLocalChatCompletions(content: content)
        .listen(
          (String chunk) {
            // debugPrint('Received chunk: $chunk, length: ${chunk.length}');
            if (_messages.isEmpty || !mounted) return;
            if (!_messages.last.isUser) {
              // 流式更新期间只更新内存，不保存到数据库
              final updatedMessage = _messages.last.copyWith(content: chunk);
              _stateManager.updateLastMessageInMemory(
                roleName.value,
                updatedMessage,
              );

              setState(() {
                // 触发UI更新
              });
              // debugPrint(
              //   'Updated message with chunk, content length: ${chunk.length}',
              // );
              _scrollToBottom();
            }
          },
          onError: (Object e) {
            if (_messages.isEmpty || !mounted) return;
            if (!_messages.last.isUser) {
              // 错误情况下立即保存到数据库
              final updatedMessage = _messages.last.copyWith(
                content: '${_messages.last.content}\n[错误] $e',
              );
              _stateManager.updateLastMessage(roleName.value, updatedMessage);

              setState(() {
                // 触发UI更新
              });
              _scrollToBottom();
            }
          },
        );
  }

  bool _shouldShowExpandIcon(String text) {
    // 简化计算逻辑，使用字符数估算
    final int charCount = text.length;
    final int estimatedLines = (charCount / 25).ceil(); // 假设每行约25个字符

    return estimatedLines > 4;
  }

  Widget _buildListItem(BuildContext context, int index) {
    // 如果没有消息，显示角色介绍
    if (_messages.isEmpty) {
      return Obx(
        () => CharacterIntro(
          title: '简介',
          description: roleDescription.value,
          firstMessage: '',
          maxLines: 4,
          showExpandIcon: _shouldShowExpandIcon(roleDescription.value),
        ),
      );
    }

    if (index < _messages.length) {
      final int reversedIdx = _messages.length - 1 - index;
      final ChatMessage msg = _messages[reversedIdx];
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _ChatBubble(
          key: ValueKey('${msg.isUser}_${msg.content.hashCode}'),
          message: msg,
        ),
      );
    }

    // 列表最上方显示角色介绍
    return Obx(
      () => CharacterIntro(
        title: '简介',
        description: roleDescription.value,
        firstMessage: '',
        maxLines: 4,
        showExpandIcon: _shouldShowExpandIcon(roleDescription.value),
      ),
    );
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients || !mounted) return;

    // 使用 microtask 而不是 addPostFrameCallback 来减少延迟
    Future.microtask(() {
      if (!_scrollController.hasClients || !mounted) return;

      final double currentOffset = _scrollController.offset;
      const double bottomOffset = 0.0;

      if (currentOffset > bottomOffset) {
        _scrollController.animateTo(
          bottomOffset,
          duration: const Duration(milliseconds: 200), // 减少动画时间
          curve: Curves.easeOut, // 使用更快的曲线
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // 必须调用，因为使用了 AutomaticKeepAliveClientMixin
    return Obx(
      () => usedRoles.isEmpty
          ? _buildSingleChatPage()
          : _buildSwipeableChatPages(),
    );
  }

  Widget _buildSingleChatPage() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 动态背景图片
        Positioned.fill(
          child: Obx(
            () => roleImage.value.isEmpty
                ? Container(color: Colors.grey.shade300)
                : Image.network(
                    roleImage.value,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey.shade300,
                      child: const Center(
                        child: Icon(Icons.error, color: Colors.grey),
                      ),
                    ),
                  ),
          ),
        ),

        // 前景内容
        _buildChatScaffold(),
      ],
    );
  }

  Widget _buildSwipeableChatPages() {
    return PageView.builder(
      controller: _pageController,
      itemCount: usedRoles.length,
      itemBuilder: (context, index) {
        return _buildPageContent(index);
      },
      onPageChanged: (index) {
        // 延迟切换角色，避免界面更新冲突
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // debugPrint('onPageChanged: $index,description:${usedRoles}');
          final role = usedRoles[index];
          if (role['name'] != roleName.value) {
            switchToRole(role);
          }
        });
      },
    );
  }

  Widget _buildPageContent(int index) {
    final role = usedRoles[index];

    return Stack(
      fit: StackFit.expand,
      children: [
        // 背景图片 - 使用当前页面的角色图片
        Positioned.fill(
          child: Image.network(
            role['image'] as String,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.grey.shade300,
              child: const Center(child: Icon(Icons.error, color: Colors.grey)),
            ),
          ),
        ),

        // 前景内容 - 使用固定的角色信息
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.list, color: Colors.white, size: 28),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RolesListPage(),
                  ),
                );
              },
            ),
            title: Text(
              role['name'] as String,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            actions: [
              // Debug模式下的调试按钮
              if (kDebugMode) ...[
                // 调试按钮：测试消息发送
                IconButton(
                  icon: const Icon(
                    Icons.bug_report,
                    color: Colors.orange,
                    size: 24,
                  ),
                  onPressed: () {
                    _handleSend('测试消息：你好');
                  },
                ),
                // 调试按钮：查看数据库消息数量
                IconButton(
                  icon: const Icon(Icons.storage, color: Colors.blue, size: 24),
                  onPressed: () async {
                    final roleName = role['name'] as String;
                    final count = await _stateManager.getMessageCount(roleName);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('数据库中$roleName的消息数: $count')),
                      );
                    }
                  },
                ),
                // 清空历史记录按钮
                IconButton(
                  icon: const Icon(
                    Icons.delete_forever,
                    color: Colors.red,
                    size: 24,
                  ),
                  onPressed: () async {
                    await _controller?.clearAllChatHistory();
                    setState(() {
                      // 触发UI更新
                    });
                    if (mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('聊天记录已清空')));
                    }
                  },
                ),
              ],
              IconButton(
                icon: const Icon(Icons.add, color: Colors.white, size: 28),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateRolePage(),
                    ),
                  );
                },
              ),
            ],
          ),
          body: SafeArea(
            top: false,
            bottom: false,
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    itemCount: _messages.length + 1,
                    cacheExtent: 1000,
                    addAutomaticKeepAlives: true,
                    addRepaintBoundaries: true,
                    addSemanticIndexes: false,
                    itemBuilder: (context, index) {
                      return RepaintBoundary(
                        child: _buildListItem(context, index),
                      );
                    },
                  ),
                ),
                GlobalInputBar(
                  bottomBarHeight: 0,
                  height: inputBarHeight,
                  inline: true,
                  onSend: _handleSend,
                  controller: _textController,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChatScaffold() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.list, color: Colors.white, size: 28),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RolesListPage()),
            );
          },
        ),
        title: Obx(
          () => Text(
            roleName.value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          // Debug模式下的调试按钮
          if (kDebugMode) ...[
            // 调试按钮：测试消息发送
            IconButton(
              icon: const Icon(
                Icons.bug_report,
                color: Colors.orange,
                size: 24,
              ),
              onPressed: () {
                _handleSend('测试消息：你好');
              },
            ),
            // 调试按钮：查看数据库消息数量
            IconButton(
              icon: const Icon(Icons.storage, color: Colors.blue, size: 24),
              onPressed: () async {
                final currentRoleName = roleName.value;
                final count = await _stateManager.getMessageCount(
                  currentRoleName,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('数据库中$currentRoleName的消息数: $count')),
                  );
                }
              },
            ),
            // 清空历史记录按钮
            IconButton(
              icon: const Icon(
                Icons.delete_forever,
                color: Colors.red,
                size: 24,
              ),
              onPressed: () async {
                await _controller?.clearAllChatHistory();
                setState(() {
                  // 触发UI更新
                });
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('聊天记录已清空')));
                }
              },
            ),
          ],
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white, size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateRolePage()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                reverse: true,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                itemCount: _messages.length + 1,
                cacheExtent: 1000, // 增加缓存范围
                addAutomaticKeepAlives: true,
                addRepaintBoundaries: true, // 添加重绘边界
                addSemanticIndexes: false, // 禁用语义索引以提升性能
                itemBuilder: (context, index) {
                  return RepaintBoundary(child: _buildListItem(context, index));
                },
              ),
            ),
            GlobalInputBar(
              bottomBarHeight: 0,
              height: inputBarHeight,
              inline: true,
              onSend: _handleSend,
              controller: _textController,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({super.key, required this.message});

  final ChatMessage message;

  /// 解析文本，分离括号内容和普通内容
  List<_TextSegment> _parseText(String text) {
    final List<_TextSegment> segments = [];
    // 匹配英文括号 () 和中文括号 （）
    final RegExp regex = RegExp(r'[\(（]([^\)）]*)[\)）]');
    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      // 添加括号前的普通文本
      if (match.start > lastEnd) {
        final normalText = text.substring(lastEnd, match.start).trim();
        if (normalText.isNotEmpty) {
          segments.add(_TextSegment(text: normalText, isAction: false));
        }
      }

      // 添加括号内的动作描述，保留原始括号
      final fullMatch = match.group(0) ?? ''; // 完整匹配包括括号
      if (fullMatch.isNotEmpty) {
        segments.add(_TextSegment(text: fullMatch, isAction: true));
      }

      lastEnd = match.end;
    }

    // 添加最后剩余的普通文本
    if (lastEnd < text.length) {
      final normalText = text.substring(lastEnd).trim();
      if (normalText.isNotEmpty) {
        segments.add(_TextSegment(text: normalText, isAction: false));
      }
    }

    // 如果没有匹配到任何括号，将整个文本作为普通文本
    if (segments.isEmpty && text.trim().isNotEmpty) {
      segments.add(_TextSegment(text: text.trim(), isAction: false));
    }

    return segments;
  }

  Widget _buildUserBubble(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        child: Container(
          margin: const EdgeInsets.only(left: 50),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: const BoxDecoration(
            color: Color(0xFFFFC107),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Text(
            message.content.trim(),
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 15,
              height: 1.35,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAiBubble(BuildContext context) {
    final segments = _parseText(message.content);

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Container(
          margin: const EdgeInsets.only(right: 40),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(6),
              bottomRight: Radius.circular(20),
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: segments.map((segment) {
              if (segment.isAction) {
                // 动作描述：斜体、更亮的灰色、较小字号
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    segment.text, // 已经包含原始括号（英文或中文）
                    style: const TextStyle(
                      color: Color(0xFFCCCCCC), // 更亮的灰色
                      fontSize: 15,
                      height: 1.4,
                      fontStyle: FontStyle.italic, // 斜体
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                );
              } else {
                // 普通对话：正常样式
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1),
                  child: Text(
                    segment.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.4,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                );
              }
            }).toList(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return message.isUser ? _buildUserBubble(context) : _buildAiBubble(context);
  }
}

/// 文本片段，用于区分普通对话和动作描述
class _TextSegment {
  const _TextSegment({required this.text, required this.isAction});

  final String text;
  final bool isAction; // true表示括号内的动作描述，false表示普通对话
}
