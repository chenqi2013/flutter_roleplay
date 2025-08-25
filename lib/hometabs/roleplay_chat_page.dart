import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:flutter_roleplay/constant/constant.dart';
import 'package:flutter_roleplay/hometabs/roleplay_chat_controller.dart';
import 'package:flutter_roleplay/widgets/character_intro.dart';
import 'dart:async';
import 'dart:ui';

import 'package:flutter_roleplay/widgets/global_input_bar.dart';
import 'package:flutter_roleplay/pages/new/createrole_page.dart';
import 'package:flutter_roleplay/pages/roles/roles_list_page.dart';
import 'package:flutter_roleplay/models/chat_message_model.dart';
import 'package:flutter_roleplay/services/database_helper.dart';

BuildContext? currentContext;

class RoleplayManage {
  static Widget createRolePlayChatPage(BuildContext context) {
    currentContext = context;
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
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  static const double inputBarHeight = 56.0;

  final ChatStateManager _stateManager = ChatStateManager();
  StreamSubscription<String>? _streamSub;
  final TextEditingController _textController = TextEditingController();
  final PageController _pageController = PageController();

  // 缓存相关
  bool _isControllerInitialized = false;
  bool _isInitializing = false;

  // 滑动检测相关
  bool _isUserScrolling = false;

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

    // 注册生命周期观察者
    WidgetsBinding.instance.addObserver(this);

    // 异步初始化默认角色和控制器，不阻塞UI
    _initializeAsync();

    // 异步初始化控制器，不阻塞UI
    _initializeController();

    // 添加ScrollController监听器来实时检测滑动
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.addListener(_onScrollPositionChanged);
    });

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

  // 异步初始化默认角色
  void _initializeAsync() {
    // 使用 addPostFrameCallback 确保UI先渲染
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await initializeDefaultRole();
        debugPrint('默认角色初始化完成');
      } catch (e) {
        debugPrint('默认角色初始化失败: $e');
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

  // 检查是否需要停止AI回复并显示确认对话框
  Future<bool> _checkAndStopAiReply() async {
    if (_controller != null && _controller!.isGenerating.value) {
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withOpacity(0.6),
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                          spreadRadius: 0,
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 图标
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.orange.shade300,
                                Colors.orange.shade500,
                              ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.warning_rounded,
                            size: 36,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 标题
                        const Text(
                          '确认操作',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 内容
                        Text(
                          'AI正在回复中，离开页面将中断回复。\n确定要继续吗？',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                            height: 1.5,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // 按钮
                        Row(
                          children: [
                            // 取消按钮
                            Expanded(
                              child: Container(
                                height: 52,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                    width: 1,
                                  ),
                                ),
                                child: TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.grey.shade700,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: const Text(
                                    '取消',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),

                            // 确定按钮
                            Expanded(
                              child: Container(
                                height: 52,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.red.shade400,
                                      Colors.red.shade600,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: const Text(
                                    '确定',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );

      if (confirmed == true) {
        _streamSub?.cancel();
        _streamSub = null;
        _controller!.stop();
        return true;
      }
      return false;
    }
    return true;
  }

  @override
  void dispose() {
    // 取消流订阅
    _streamSub?.cancel();
    _streamSub = null;

    // 如果AI正在生成回复，停止它
    if (_controller != null && _controller!.isGenerating.value) {
      _controller!.stop();
    }

    // 移除生命周期观察者
    WidgetsBinding.instance.removeObserver(this);

    _textController.dispose();
    _pageController.dispose();
    _scrollController.removeListener(_onScrollPositionChanged);
    super.dispose();
  }

  // 当页面被遮挡或不可见时取消AI回复
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _streamSub?.cancel();
      _streamSub = null;
      if (_controller != null && _controller!.isGenerating.value) {
        _controller!.stop();
      }
    }
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

              // 关键修改：只有在用户没有滑动时才自动滚动
              if (!_isUserScrolling) {
                _scrollToBottom();
              } else {
                debugPrint('用户正在滑动，跳过自动滚动');
              }
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

              // 错误时也检查用户是否在滑动
              if (!_isUserScrolling) {
                _scrollToBottom();
              }
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

    // 只有在用户没有主动滑动到上方时才自动滚动
    if (_isUserScrolling) return;

    // 使用 microtask 而不是 addPostFrameCallback 来减少延迟
    Future.microtask(() {
      if (!_scrollController.hasClients || !mounted || _isUserScrolling) return;

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

  // 实时监听滚动位置变化
  void _onScrollPositionChanged() {
    if (!_scrollController.hasClients) return;

    final currentOffset = _scrollController.offset;

    // 进一步降低阈值，让用户更容易滑动
    // 如果用户滚动到距离底部超过10像素，立即停止自动滚动
    if (currentOffset > 10.0) {
      if (!_isUserScrolling) {
        _isUserScrolling = true;
        debugPrint('检测到用户向上滚动，立即停止自动滚动 - offset: $currentOffset');
      }
    } else {
      // 如果用户回到底部附近（10像素内），恢复自动滚动
      if (_isUserScrolling) {
        _isUserScrolling = false;
        debugPrint('用户回到底部，恢复自动滚动 - offset: $currentOffset');
      }
    }
  }

  // 处理用户滑动开始
  void _onUserScrollStart() {
    // 用户一开始滑动就立即停止自动滚动，确保最快响应
    if (!_isUserScrolling) {
      _isUserScrolling = true;
      debugPrint('用户开始滑动，立即停止自动滚动');
    }
  }

  // 处理用户滑动结束
  void _onUserScrollEnd() {
    // 滑动结束后，快速检查位置并决定是否恢复自动滚动
    if (_scrollController.hasClients) {
      final currentOffset = _scrollController.offset;
      debugPrint('滑动结束，当前位置: $currentOffset');

      // 如果在底部附近（10像素内），立即恢复自动滚动
      if (currentOffset <= 10.0) {
        _isUserScrolling = false;
        debugPrint('滑动结束时在底部，立即恢复自动滚动');
      } else {
        // 如果在上方，延迟500毫秒后恢复，给用户更快的响应
        debugPrint('滑动结束时在上方，500毫秒后恢复自动滚动');
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && _scrollController.hasClients) {
            final newOffset = _scrollController.offset;
            // 再次检查位置，如果还在上方就保持停止状态
            if (newOffset <= 10.0) {
              _isUserScrolling = false;
              debugPrint('延迟检查后在底部，恢复自动滚动');
            }
          }
        });
      }
    }
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
      onPageChanged: (index) async {
        final role = usedRoles[index];
        if (role['name'] != roleName.value) {
          // 如果AI正在回复，需要确认
          if (_controller != null && _controller!.isGenerating.value) {
            final confirmed = await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              barrierColor: Colors.black.withOpacity(0.6),
              builder: (BuildContext context) {
                return Dialog(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                                spreadRadius: 0,
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 图标
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.blue.shade300,
                                      Colors.blue.shade500,
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.3),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.swap_horiz_rounded,
                                  size: 36,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // 标题
                              const Text(
                                '切换角色',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1A1A),
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // 内容
                              RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                    height: 1.5,
                                    letterSpacing: 0.2,
                                  ),
                                  children: [
                                    const TextSpan(text: 'AI正在回复中，切换到 '),
                                    TextSpan(
                                      text: '"${role['name']}"',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade600,
                                      ),
                                    ),
                                    const TextSpan(text: ' 将中断回复。\n确定要继续吗？'),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 32),

                              // 按钮
                              Row(
                                children: [
                                  // 取消按钮
                                  Expanded(
                                    child: Container(
                                      height: 52,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.grey.shade200,
                                          width: 1,
                                        ),
                                      ),
                                      child: TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.grey.shade700,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          elevation: 0,
                                        ),
                                        child: const Text(
                                          '取消',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),

                                  // 确定按钮
                                  Expanded(
                                    child: Container(
                                      height: 52,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Colors.blue.shade400,
                                            Colors.blue.shade600,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.blue.withOpacity(0.3),
                                            blurRadius: 12,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          elevation: 0,
                                        ),
                                        child: const Text(
                                          '确定',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );

            if (confirmed == true) {
              _streamSub?.cancel();
              _streamSub = null;
              _controller!.stop();
              // 延迟切换角色，避免界面更新冲突
              WidgetsBinding.instance.addPostFrameCallback((_) {
                switchToRole(role);
              });
            } else {
              // 用户取消，回到原来的页面
              _pageController.animateToPage(
                usedRoles.indexWhere((r) => r['name'] == roleName.value),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          } else {
            // AI没有在回复，直接切换
            WidgetsBinding.instance.addPostFrameCallback((_) {
              switchToRole(role);
            });
          }
        }
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
            errorBuilder: (context, error, stackTrace) => Image.asset(
              'packages/flutter_roleplay/assets/images/common_bg.webp',
              fit: BoxFit.cover,
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
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
              onPressed: () {
                // 取消当前AI回复
                _streamSub?.cancel();
                _streamSub = null;
                if (_controller != null && _controller!.isGenerating.value) {
                  _controller!.stop();
                }

                Navigator.of(currentContext!).pop();
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
              // if (kDebugMode) ...[
              //   // 调试按钮：测试消息发送
              //   IconButton(
              //     icon: const Icon(
              //       Icons.bug_report,
              //       color: Colors.orange,
              //       size: 24,
              //     ),
              //     onPressed: () {
              //       _handleSend('测试消息：你好');
              //     },
              //   ),
              //   // 调试按钮：查看数据库消息数量
              //   IconButton(
              //     icon: const Icon(Icons.storage, color: Colors.blue, size: 24),
              //     onPressed: () async {
              //       final roleName = role['name'] as String;
              //       final count = await _stateManager.getMessageCount(roleName);
              //       if (mounted) {
              //         ScaffoldMessenger.of(context).showSnackBar(
              //           SnackBar(content: Text('数据库中$roleName的消息数: $count')),
              //         );
              //       }
              //     },
              //   ),
              // ],
              // 清空历史记录按钮
              IconButton(
                icon: const Icon(
                  Icons.delete_forever,
                  color: Colors.white,
                  size: 24,
                ),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext context) {
                      return Dialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 16,
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Colors.white, Colors.grey.shade50],
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 图标
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.delete_forever,
                                  size: 32,
                                  color: Colors.red.shade400,
                                ),
                              ),
                              const SizedBox(height: 20),
                              // 标题
                              Text(
                                '确认删除',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              const SizedBox(height: 12),
                              // 内容
                              Text(
                                '确定要删除当前角色的所有聊天记录吗？',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '此操作不可恢复',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.red.shade400,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 32),
                              // 按钮
                              Row(
                                children: [
                                  // 取消按钮
                                  Expanded(
                                    child: Container(
                                      height: 48,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.grey.shade600,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        child: const Text(
                                          '取消',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // 删除按钮
                                  Expanded(
                                    child: Container(
                                      height: 48,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.red.shade400,
                                            Colors.red.shade600,
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.red.shade200,
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        child: const Text(
                                          '删除',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );

                  if (confirmed == true) {
                    await _controller?.clearAllChatHistory();
                    setState(() {
                      // 触发UI更新
                    });
                    if (mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('聊天记录已清空')));
                    }
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.list, color: Colors.white, size: 28),
                onPressed: () async {
                  if (await _checkAndStopAiReply()) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RolesListPage(),
                      ),
                    );
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.add, color: Colors.white, size: 28),
                onPressed: () async {
                  if (await _checkAndStopAiReply()) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateRolePage(),
                      ),
                    );
                  }
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
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (ScrollNotification notification) {
                      if (notification is ScrollStartNotification) {
                        _onUserScrollStart();
                      } else if (notification is ScrollEndNotification) {
                        _onUserScrollEnd();
                      }
                      return false;
                    },
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
                ),
                Obx(
                  () => GlobalInputBar(
                    bottomBarHeight: 0,
                    height: inputBarHeight,
                    inline: true,
                    onSend: _handleSend,
                    controller: _textController,
                    isLoading: _controller?.isGenerating.value ?? false,
                    roleName: roleName.value,
                  ),
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
          onPressed: () async {
            if (await _checkAndStopAiReply()) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RolesListPage()),
              );
            }
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
          ],
          // // 清空历史记录按钮
          // IconButton(
          //   icon: const Icon(Icons.delete_forever, color: Colors.red, size: 24),
          //   onPressed: () async {
          //     await _controller?.clearAllChatHistory();
          //     setState(() {
          //       // 触发UI更新
          //     });
          //     if (mounted) {
          //       ScaffoldMessenger.of(
          //         context,
          //       ).showSnackBar(const SnackBar(content: Text('聊天记录已清空')));
          //     }
          //   },
          // ),
          // IconButton(
          //   icon: const Icon(Icons.add, color: Colors.white, size: 28),
          //   onPressed: () {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(builder: (context) => const CreateRolePage()),
          //     );
          //   },
          // ),
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification notification) {
                  if (notification is ScrollStartNotification) {
                    _onUserScrollStart();
                  } else if (notification is ScrollEndNotification) {
                    _onUserScrollEnd();
                  }
                  return false;
                },
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
                    return RepaintBoundary(
                      child: _buildListItem(context, index),
                    );
                  },
                ),
              ),
            ),
            Obx(
              () => GlobalInputBar(
                bottomBarHeight: 0,
                height: inputBarHeight,
                inline: true,
                onSend: _handleSend,
                controller: _textController,
                isLoading: _controller?.isGenerating.value ?? false,
                roleName: roleName.value,
              ),
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
