import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_roleplay/services/role_play_manage.dart';
import 'package:get/get.dart';
import 'dart:async';

import 'package:flutter_roleplay/constant/constant.dart';
import 'package:flutter_roleplay/hometabs/roleplay_chat_controller.dart';
import 'package:flutter_roleplay/models/chat_message_model.dart';
import 'package:flutter_roleplay/services/chat_state_manager.dart';
import 'package:flutter_roleplay/services/model_callback_service.dart';
import 'package:flutter_roleplay/utils/chat_dialogs.dart';
import 'package:flutter_roleplay/utils/common_util.dart';
import 'package:flutter_roleplay/widgets/global_input_bar.dart';
import 'package:flutter_roleplay/widgets/chat_page_builders.dart';
import 'package:flutter_roleplay/mixins/scroll_management_mixin.dart';
import 'package:flutter_roleplay/pages/new/createrole_page.dart';
import 'package:flutter_roleplay/pages/roles/roles_list_page.dart';

class RolePlayChat extends StatefulWidget {
  const RolePlayChat({super.key});

  @override
  State<RolePlayChat> createState() => _RolePlayChatState();
}

class _RolePlayChatState extends State<RolePlayChat>
    with
        AutomaticKeepAliveClientMixin,
        WidgetsBindingObserver,
        ScrollManagementMixin {
  final ChatStateManager _stateManager = ChatStateManager();
  StreamSubscription<String>? _streamSub;
  final TextEditingController _textController = TextEditingController();
  final PageController _pageController = PageController();

  // 缓存相关
  bool _isControllerInitialized = false;
  bool _isInitializing = false;

  List<ChatMessage> get _messages {
    final messages = _stateManager.getMessages(roleName.value);
    return messages;
  }

  RolePlayChatController? _controller;

  @override
  ScrollController get scrollController =>
      _stateManager.getScrollController(roleName.value);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    debugPrint('RolePlayChat initState');
    // 注册生命周期观察者
    WidgetsBinding.instance.addObserver(this);

    // 异步初始化默认角色和控制器，不阻塞UI
    _initializeAsync();

    // 异步初始化控制器，不阻塞UI
    _initializeController();

    // 初始化滚动管理
    initScrollListener();

    // 监听角色信息变化，当角色信息更新时自动清空聊天记录
    ever(roleDescription, (String newDesc) {
      if (_messages.isNotEmpty) {
        setState(() {
          _messages.clear();
        });
        scrollToBottom();
      }
    });

    // 监听角色切换，同步PageView位置
    ever(roleName, (String newRoleName) {
      if (newRoleName.isNotEmpty && usedRoles.isNotEmpty) {
        final index = usedRoles.indexWhere(
          (role) => role['name'] == newRoleName,
        );
        if (index != -1 && _pageController.hasClients) {
          // 检查当前页面是否已经是目标页面，避免不必要的动画
          final currentPage = _pageController.page?.round() ?? 0;
          if (currentPage != index) {
            debugPrint('同步PageView到角色: $newRoleName (页面 $index)');
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
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

    if (Get.isRegistered<RolePlayChatController>()) {
      _controller = Get.find<RolePlayChatController>();
    } else {
      _controller = Get.put(RolePlayChatController());
    }
    _controller?.changeLanguage();
  }

  // 异步初始化默认角色
  void _initializeAsync() {
    // 使用 addPostFrameCallback 确保UI先渲染
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await CommonUtil.initializeDefaultRole();
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
      final confirmed = await ChatDialogs.showAiInterruptionDialog(context);

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
    disposeScrollListener();
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

    scrollToBottom();

    _streamSub?.cancel();
    _streamSub = _controller!
        .streamLocalChatCompletions(content: content)
        .listen(
          (String chunk) {
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

              // 关键修改：只有在用户没有滑动时才自动滚动
              if (!isUserScrolling) {
                scrollToBottom();
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
              if (!isUserScrolling) {
                scrollToBottom();
              }
            }
          },
        );
  }

  // 页面切换处理
  void _onPageChanged(int index) async {
    if (index < 0 || index >= usedRoles.length) {
      debugPrint('页面索引超出范围: $index');
      return;
    }

    final role = usedRoles[index];
    final targetRoleName = role['name'] as String;

    // 检查是否真的需要切换角色
    if (targetRoleName == roleName.value) {
      debugPrint('PageView切换到相同角色，跳过: $targetRoleName');
      return;
    }

    debugPrint('PageView切换角色: ${roleName.value} -> $targetRoleName');

    // 如果AI正在回复，需要确认
    if (_controller != null && _controller!.isGenerating.value) {
      final confirmed = await ChatDialogs.showRoleSwitchDialog(
        context,
        targetRoleName,
      );

      if (confirmed == true) {
        _streamSub?.cancel();
        _streamSub = null;
        _controller!.stop();
        // 延迟切换角色，避免界面更新冲突
        WidgetsBinding.instance.addPostFrameCallback((_) {
          CommonUtil.switchToRole(role);
        });
      } else {
        // 用户取消，回到原来的页面
        final currentRoleIndex = usedRoles.indexWhere(
          (r) => r['name'] == roleName.value,
        );
        if (currentRoleIndex != -1) {
          _pageController.animateToPage(
            currentRoleIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      }
    } else {
      // AI没有在回复，直接切换
      WidgetsBinding.instance.addPostFrameCallback((_) {
        CommonUtil.switchToRole(role);
      });
    }
  }

  Widget _buildPageContent(int index) {
    return ChatPageBuilders.buildPageContent(
      index: index,
      usedRoles: usedRoles,
      context: context,
      onBackPressed: () {
        // 取消当前AI回复
        _streamSub?.cancel();
        _streamSub = null;
        if (_controller != null && _controller!.isGenerating.value) {
          _controller!.stop();
        }
        Navigator.of(currentContext!).pop();
      },
      onClearHistory: () async {
        await _controller?.clearAllChatHistory();
        setState(() {});
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('chat_history_cleared'.tr)));
        }
      },
      onNavigateToRolesList: () async {
        if (await _checkAndStopAiReply()) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RolesListPage()),
          );
        }
      },
      onNavigateToCreateRole: () async {
        if (await _checkAndStopAiReply()) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateRolePage()),
          );
        }
      },
      onNavigateToChangeModel: () async {
        debugPrint('onNavigateToChangeModel');
        notifyModelChangeRequired();
      },
      chatListView: _buildChatListView(),
      inputBar: _buildInputBar(),
    );
  }

  Widget _buildChatScaffold() {
    return Obx(
      () => ChatPageBuilders.buildChatScaffold(
        context: context,
        roleName: roleName.value,
        onNavigateToRolesList: () async {
          if (await _checkAndStopAiReply()) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RolesListPage()),
            );
          }
        },
        chatListView: _buildChatListView(),
        inputBar: _buildInputBar(),
        showDebugButtons: kDebugMode,
        onDebugSend: () => _handleSend('测试消息：你好'),
        onDebugCheckDatabase: () async {
          final currentRoleName = roleName.value;
          final count = await _stateManager.getMessageCount(currentRoleName);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('数据库中$currentRoleName的消息数: $count')),
            );
          }
        },
      ),
    );
  }

  Widget _buildChatListView() {
    return buildScrollNotificationListener(
      child: ChatPageBuilders.buildChatListView(
        scrollController: scrollController,
        messages: _messages,
        roleDescription: roleDescription.value,
        onScrollNotification: (notification) {
          // 处理滚动通知已在 mixin 中处理
          return Container();
        },
        itemBuilder: (context, index) {
          return Obx(
            () => ChatPageBuilders.buildListItem(
              context: context,
              index: index,
              messages: _messages,
              roleDescription: roleDescription.value,
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputBar() {
    return Obx(
      () => GlobalInputBar(
        bottomBarHeight: 0,
        height: ChatPageBuilders.inputBarHeight,
        inline: true,
        onSend: _handleSend,
        controller: _textController,
        isLoading: _controller?.isGenerating.value ?? false,
        roleName: roleName.value,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // 必须调用，因为使用了 AutomaticKeepAliveClientMixin
    return Obx(
      () => usedRoles.isEmpty
          ? ChatPageBuilders.buildSingleChatPage(
              chatScaffold: _buildChatScaffold(),
            )
          : ChatPageBuilders.buildSwipeableChatPages(
              pageController: _pageController,
              usedRoles: usedRoles,
              onPageChanged: _onPageChanged,
              buildPageContent: _buildPageContent,
            ),
    );
  }
}
