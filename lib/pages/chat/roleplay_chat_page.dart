import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_roleplay/services/role_play_manage.dart';
import 'package:get/get.dart';
import 'dart:async';

import 'package:flutter_roleplay/constant/constant.dart';
import 'package:flutter_roleplay/pages/chat/roleplay_chat_controller.dart';
import 'package:flutter_roleplay/models/chat_message_model.dart';
import 'package:flutter_roleplay/services/chat_state_manager.dart';
import 'package:flutter_roleplay/services/message_branch_manager.dart';
import 'package:flutter_roleplay/services/database_helper.dart';
import 'package:flutter_roleplay/services/model_callback_service.dart';
import 'package:flutter_roleplay/dialog/chat_dialogs.dart';
import 'package:flutter_roleplay/utils/common_util.dart';
import 'package:flutter_roleplay/widgets/global_input_bar.dart';
import 'package:flutter_roleplay/widgets/chat_page_builders.dart';
import 'package:flutter_roleplay/mixins/scroll_management_mixin.dart';
import 'package:flutter_roleplay/pages/new/createrole_page.dart';
import 'package:flutter_roleplay/pages/roles/roles_list_page.dart';
import 'package:flutter_roleplay/pages/params/role_params_page.dart';

class RolePlayChat extends StatefulWidget {
  const RolePlayChat({super.key});

  @override
  State<RolePlayChat> createState() => _RolePlayChatState();
}

class _RolePlayChatState extends State<RolePlayChat>
    with WidgetsBindingObserver, ScrollManagementMixin {
  final ChatStateManager _stateManager = ChatStateManager();
  StreamSubscription<String>? _streamSub;
  final TextEditingController _textController = TextEditingController();
  final PageController _pageController = PageController();

  // 缓存相关
  bool _isControllerInitialized = false;
  bool _isInitializing = false;

  // 防止重复角色切换的标志
  bool _isPageSwitching = false;

  List<ChatMessage> get _messages {
    final messages = _stateManager.getMessages(roleName.value);
    return messages;
  }

  RolePlayChatController? _controller;

  @override
  ScrollController get scrollController =>
      _stateManager.getScrollController(roleName.value);

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

    // 监听角色切换，同步PageView位置并加载聊天历史
    ever(roleName, (String newRoleName) {
      if (newRoleName.isNotEmpty) {
        debugPrint('角色切换到: $newRoleName，加载聊天历史');
        // 加载新角色的聊天历史
        _loadChatHistory();

        // 只有当不是由PageView滑动触发的切换时，才同步PageView位置
        if (usedRoles.isNotEmpty && !_isPageSwitching) {
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
      }
    });

    // 监听 usedRoles 列表变化，如果有新角色添加，跳转到对应页面
    ever(usedRoles, (List<Map<String, dynamic>> newUsedRoles) {
      debugPrint('usedRoles 列表变化: ${newUsedRoles.length} 个角色');
      if (newUsedRoles.isNotEmpty && _pageController.hasClients) {
        // 延迟执行，确保UI已更新
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final currentRoleIndex = newUsedRoles.indexWhere(
            (role) => role['name'] == roleName.value,
          );
          debugPrint('当前角色 ${roleName.value} 在列表中的索引: $currentRoleIndex');
          if (currentRoleIndex != -1) {
            final currentPage = _pageController.page?.round() ?? 0;
            debugPrint(
              'PageController 当前页面: $currentPage, 目标页面: $currentRoleIndex',
            );
            if (currentPage != currentRoleIndex) {
              debugPrint('跳转到页面: $currentRoleIndex');
              _pageController.animateToPage(
                currentRoleIndex,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
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
        debugPrint('默认角色初始化完成，当前角色: ${roleName.value}');

        // 初始化完成后立即加载聊天历史
        if (roleName.value.isNotEmpty) {
          debugPrint('默认角色初始化后加载聊天历史');
          await _loadChatHistory();
        }
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
    if (roleName.value.isEmpty) {
      debugPrint('_loadChatHistory: roleName为空，跳过加载');
      return;
    }

    try {
      debugPrint('_loadChatHistory: 开始为角色 ${roleName.value} 加载聊天历史');
      await _stateManager.loadMessagesFromDatabase(roleName.value);
      final messages = _stateManager.getMessages(roleName.value);
      debugPrint('_loadChatHistory: 加载完成，消息数量: ${messages.length}');

      setState(() {
        // 触发UI更新
      });
      debugPrint(
        'Chat history loaded for role: ${roleName.value}, 消息数量: ${messages.length}',
      );

      // 输出前几条消息内容用于调试
      if (messages.isNotEmpty) {
        debugPrint('前几条消息:');
        for (int i = 0; i < messages.length && i < 3; i++) {
          final msg = messages[i];
          debugPrint(
            '  [$i] ${msg.isUser ? "用户" : "AI"}: ${msg.content.substring(0, msg.content.length > 50 ? 50 : msg.content.length)}...',
          );
        }
      }
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

    // 检查是否需要在发送消息前清空聊天状态
    if (needsClearStatesOnNextSend.value) {
      debugPrint('检测到需要清空聊天状态，正在执行清空操作...');
      await _controller!.clearStates();
      needsClearStatesOnNextSend.value = false; // 重置标记
      debugPrint('聊天状态已清空，标记已重置');
    }
    if (!_controller!.modelService.isModelLoaded) {
      debugPrint('Model not loaded, skipping send');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('model_not_loaded'.tr),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
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

    // 防止重复触发
    if (_isPageSwitching) {
      debugPrint('页面切换已在进行中，跳过页面变化事件: $index');
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

    // 设置切换标志
    _isPageSwitching = true;

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
          // 重置切换标志
          Future.delayed(const Duration(milliseconds: 500), () {
            _isPageSwitching = false;
          });
        });
      } else {
        // 用户取消，回到原来的页面
        _isPageSwitching = false; // 重置标志
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
        // 重置切换标志
        Future.delayed(const Duration(milliseconds: 500), () {
          _isPageSwitching = false;
        });
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
      onNavigateToRoleParams: () async {
        if (await _checkAndStopAiReply()) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RoleParamsPage()),
          );
        }
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
              SnackBar(
                content: Text(
                  'message_count_debug'.trParams({
                    'roleName': currentRoleName,
                    'count': count.toString(),
                  }),
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildChatListView() {
    return buildScrollNotificationListener(
      child: Obx(() {
        // 确保响应式地获取当前角色的消息
        final currentRoleName = roleName.value;
        final messages = _stateManager.getMessages(currentRoleName);

        // debugPrint('_buildChatListView: 当前角色: $currentRoleName, 消息数量: ${messages.length}');

        return ChatPageBuilders.buildChatListView(
          scrollController: scrollController,
          messages: messages,
          roleDescription: roleDescription.value,
          onScrollNotification: (notification) {
            // 处理滚动通知已在 mixin 中处理
            return Container();
          },
          itemBuilder: (context, index) {
            return ChatPageBuilders.buildListItem(
              context: context,
              index: index,
              messages: messages,
              roleDescription: roleDescription.value,
              onCopy: () => _handleCopy(),
              onCreateBranch: (message) => _handleRegenerate(message),
              onSwitchBranch: (message, branchIndex) =>
                  _handleSwitchBranch(message, branchIndex),
            );
          },
        );
      }),
    );
  }

  /// 处理复制操作的回调（在ChatBubble中已处理具体逻辑）
  void _handleCopy() {
    // 复制操作已在ChatBubble组件中处理，这里只是为了保持接口一致性
    debugPrint('消息已复制到剪贴板');
  }

  /// 处理重新生成消息
  void _handleRegenerate(ChatMessage message) async {
    debugPrint('🌿🌿🌿 分叉按钮被点击了！🌿🌿🌿');
    debugPrint('要重新生成的消息: ${message.content.substring(0, 50)}...');
    debugPrint('消息ID: ${message.id}');

    if (_controller == null || _controller!.isGenerating.value) {
      debugPrint('AI正在生成中，无法重新生成');
      return;
    }

    debugPrint('开始重新生成消息...');

    try {
      // 找到对应的用户消息
      final messages = _stateManager.getMessages(roleName.value);
      final messageIndex = messages.indexOf(message);
      if (messageIndex <= 0) {
        debugPrint('未找到对应的用户消息，无法重新生成');
        return;
      }

      final userMessage = messages[messageIndex - 1];
      if (userMessage.isUser) {
        // 在原消息位置显示loading状态，但保留原始数据用于后续处理
        debugPrint('=== 开始重新生成流程 ===');
        debugPrint(
          '原始消息在开始时: ID=${message.id}, branchIds=${message.branchIds}',
        );

        final loadingMessage = message.copyWith(content: '');
        debugPrint(
          'loadingMessage: ID=${loadingMessage.id}, branchIds=${loadingMessage.branchIds}',
        );

        messages[messageIndex] = loadingMessage;
        setState(() {});

        String newContent = '';

        // 执行重新生成
        _streamSub?.cancel();
        _streamSub = _controller!
            .streamLocalChatCompletions(content: userMessage.content)
            .listen(
              (String chunk) {
                if (!mounted) return;

                newContent = chunk;

                // 实时更新显示的内容，但不改变原始消息结构
                final updatedMessage = loadingMessage.copyWith(
                  content: newContent,
                );
                messages[messageIndex] = updatedMessage;

                setState(() {});

                // 每隔一段时间打印一次流式更新状态
                if (newContent.length % 100 == 0) {
                  debugPrint(
                    '流式更新中: 长度=${newContent.length}, ID=${updatedMessage.id}, branchIds=${updatedMessage.branchIds}',
                  );
                }

                if (!isUserScrolling) {
                  scrollToBottom();
                }
              },
              onError: (Object e) {
                debugPrint('重新生成失败: $e');
                // 恢复原消息内容
                messages[messageIndex] = message;
                setState(() {});
              },
              onDone: () async {
                debugPrint('📍📍📍 onDone 回调被执行了！📍📍📍');
                debugPrint('新内容长度: ${newContent.length}');
                debugPrint(
                  '新内容预览: ${newContent.isNotEmpty ? newContent.substring(0, newContent.length > 50 ? 50 : newContent.length) : "空"}',
                );

                // 生成完成后，使用分支管理器创建分支
                if (newContent.isNotEmpty) {
                  debugPrint('重新生成完成，创建分支...');

                  try {
                    debugPrint('=== 开始创建分支 ===');
                    debugPrint('原始消息: ${message.content.substring(0, 50)}...');
                    debugPrint('原始消息ID: ${message.id}');
                    debugPrint('原始消息branchIds: ${message.branchIds}');
                    debugPrint('新内容: ${newContent.substring(0, 50)}...');
                    debugPrint('消息在列表中的索引: $messageIndex');

                    // 检查原始消息是否有ID，如果没有则先保存到数据库
                    ChatMessage messageWithId = message;
                    if (message.id == null) {
                      debugPrint('原始消息没有ID，先保存到数据库...');

                      try {
                        // 先保存原始消息到数据库
                        final dbHelper = DatabaseHelper();
                        debugPrint(
                          '准备保存原始消息到数据库: ${message.content.substring(0, 50)}...',
                        );
                        final messageId = await dbHelper.insertMessage(message);
                        messageWithId = message.copyWith(id: messageId);

                        // 更新消息列表中的消息，确保有ID
                        messages[messageIndex] = messageWithId;
                        setState(() {});

                        debugPrint('原始消息已保存到数据库，ID: $messageId，现在可以创建分支了');
                      } catch (e) {
                        debugPrint('保存原始消息到数据库失败: $e');

                        // 创建一个简单的更新后消息，显示新内容但不创建分支
                        final simpleUpdatedMessage = message.copyWith(
                          content: newContent,
                        );
                        messages[messageIndex] = simpleUpdatedMessage;
                        setState(() {});

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('保存消息失败，无法创建分支: $e'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                        return;
                      }
                    }

                    final branchManager = MessageBranchManager();

                    // 创建分支（返回的是更新后的原始消息，包含新的分支信息）
                    final updatedMessage = await branchManager.createBranch(
                      originalMessage: messageWithId, // 使用有ID的消息
                      newContent: newContent,
                      roleName: roleName.value,
                    );

                    debugPrint('=== 分支创建完成 ===');
                    debugPrint('更新后消息ID: ${updatedMessage.id}');
                    debugPrint('更新后消息branchIds: ${updatedMessage.branchIds}');
                    debugPrint(
                      '更新后消息currentBranchIndex: ${updatedMessage.currentBranchIndex}',
                    );
                    debugPrint(
                      '更新后消息branchCount: ${updatedMessage.branchCount}',
                    );
                    debugPrint(
                      '更新后消息hasBranches: ${updatedMessage.hasBranches}',
                    );

                    // 更新消息列表中的消息
                    messages[messageIndex] = updatedMessage;
                    setState(() {});

                    debugPrint('UI已更新，消息列表长度: ${messages.length}');
                    debugPrint('=== 分支创建流程完成 ===');

                    // 显示成功提示
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '分支创建成功！总计 ${updatedMessage.branchCount} 个回答',
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  } catch (e) {
                    debugPrint('创建分支失败: $e');
                    // 如果创建分支失败，恢复原消息
                    messages[messageIndex] = message;
                    setState(() {});

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('创建分支失败: $e'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                } else {
                  debugPrint('重新生成失败，内容为空，恢复原消息');
                  // 如果生成失败，恢复原消息
                  messages[messageIndex] = message;
                  setState(() {});
                }

                debugPrint('📍📍📍 onDone 回调执行完成！📍📍📍');
              },
            );
      }
    } catch (e) {
      debugPrint('重新生成消息时发生错误: $e');
    }
  }

  /// 处理切换分支
  void _handleSwitchBranch(ChatMessage message, int branchIndex) async {
    debugPrint('切换到分支索引: $branchIndex');

    try {
      final messages = _stateManager.getMessages(roleName.value);
      final messageIndex = messages.indexOf(message);
      if (messageIndex == -1) {
        debugPrint('未找到消息，无法切换分支');
        return;
      }

      final branchManager = MessageBranchManager();

      // 使用分支管理器切换分支
      final updatedMessage = await branchManager.switchToBranch(
        message,
        branchIndex,
        roleName.value,
      );

      // 更新消息列表
      messages[messageIndex] = updatedMessage;
      setState(() {});

      debugPrint('切换到分支索引: $branchIndex 成功');
    } catch (e) {
      debugPrint('切换分支时发生错误: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('切换分支失败: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
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
    return _buildMainContent();
  }

  /// 构建主要内容，使用精确的响应式更新
  Widget _buildMainContent() {
    return Obx(() {
      // 只在 usedRoles 变化时重建页面结构
      final roles = usedRoles;

      if (roles.isEmpty) {
        return ChatPageBuilders.buildSingleChatPage(
          chatScaffold: _buildChatScaffold(),
        );
      } else {
        // 检查当前角色位置并同步 PageController
        _syncPageController(roles);

        return ChatPageBuilders.buildSwipeableChatPages(
          pageController: _pageController,
          usedRoles: roles,
          onPageChanged: _onPageChanged,
          buildPageContent: _buildPageContent,
        );
      }
    });
  }

  /// 同步 PageController 到当前角色位置
  void _syncPageController(List<Map<String, dynamic>> roles) {
    final currentRoleIndex = roles.indexWhere(
      (role) => role['name'] == roleName.value,
    );

    if (currentRoleIndex >= 0 && _pageController.hasClients) {
      final currentPage = _pageController.page?.round() ?? 0;
      if (currentPage != currentRoleIndex) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pageController.hasClients) {
            _pageController.animateToPage(
              currentRoleIndex,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        });
      }
    }
  }
}
