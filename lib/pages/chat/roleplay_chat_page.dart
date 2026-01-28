import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_roleplay/pages/params/model_params_page.dart';
import 'package:flutter_roleplay/services/role_play_manage.dart';
import 'package:flutter_roleplay/services/database_helper.dart';
import 'package:flutter_roleplay/utils/common_util.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_roleplay/constant/constant.dart';
import 'package:flutter_roleplay/pages/chat/roleplay_chat_controller.dart';
import 'package:flutter_roleplay/models/chat_message_model.dart';
import 'package:flutter_roleplay/services/chat_state_manager.dart';
import 'package:flutter_roleplay/services/model_callback_service.dart';
import 'package:flutter_roleplay/dialog/chat_dialogs.dart';
import 'package:flutter_roleplay/widgets/global_input_bar.dart';
import 'package:flutter_roleplay/widgets/chat_page_builders.dart';
import 'package:flutter_roleplay/mixins/scroll_management_mixin.dart';
import 'package:flutter_roleplay/pages/new/createrole_page.dart';
import 'package:flutter_roleplay/pages/roles/roles_list_page.dart';
import 'package:flutter_roleplay/pages/audio/audio_list_page.dart';

class RolePlayChat extends StatefulWidget {
  const RolePlayChat({super.key, this.roleName});
  final String? roleName;
  @override
  State<RolePlayChat> createState() => _RolePlayChatState();
}

class _RolePlayChatState extends State<RolePlayChat>
    with
        WidgetsBindingObserver,
        ScrollManagementMixin,
        AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final ChatStateManager _stateManager = ChatStateManager();
  StreamSubscription<String>? _streamSub;
  final TextEditingController _textController = TextEditingController();

  // 缓存相关
  bool _isControllerInitialized = false;
  bool _isInitializing = false;

  // 防止组件销毁后继续执行操作
  bool _isDisposed = false;

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

    // 监听角色切换，自动加载新角色的聊天历史
    ever(roleName, (String newRoleName) {
      if (newRoleName.isNotEmpty && !_isDisposed && mounted) {
        debugPrint('角色切换到: $newRoleName，加载聊天历史');
        _loadChatHistory();
      }
    });

    if (Get.isRegistered<RolePlayChatController>()) {
      _controller = Get.find<RolePlayChatController>();
    } else {
      _controller = Get.put(RolePlayChatController());
    }
    _controller?.changeLanguage();
    // 点击模型名称打开模型切换
    Future.delayed(const Duration(milliseconds: 500), () {
      if (chatmodelPath.value.isEmpty) {
        notifyModelDownloadRequired(RoleplayManageModelType.chat);
      }
    });
  }

  // 异步初始化默认角色
  void _initializeAsync() {
    // 使用 addPostFrameCallback 确保UI先渲染
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 检查组件是否仍然挂载
      if (!mounted || _isDisposed) {
        debugPrint('组件已销毁，跳过角色初始化');
        return;
      }

      try {
        // 如果传入了特定的roleName，则直接设置该角色
        if (widget.roleName != null && widget.roleName!.isNotEmpty) {
          debugPrint('设置特定角色: ${widget.roleName}');

          // 从数据库查找角色的完整信息并设置
          await _setSpecificRole(widget.roleName!);

          // 再次检查组件状态
          if (!mounted || _isDisposed) {
            debugPrint('组件已销毁，跳过聊天历史加载');
            return;
          }

          // 加载该角色的聊天历史
          await _loadChatHistory();
        } else {
          // 否则使用默认角色初始化逻辑
          await CommonUtil.initializeDefaultRole();
          debugPrint('默认角色初始化完成，当前角色: ${roleName.value}');

          // 再次检查组件状态
          if (!mounted || _isDisposed) {
            debugPrint('组件已销毁，跳过聊天历史加载');
            return;
          }

          // 初始化完成后立即加载聊天历史
          if (roleName.value.isNotEmpty) {
            debugPrint('默认角色初始化后加载聊天历史');
            await _loadChatHistory();
          }
        }
      } catch (e) {
        debugPrint('角色初始化失败: $e');
      }
    });
  }

  /// 根据音色文件名设置 TTS 音色
  /// 设置角色音色
  ///
  /// [voiceFileName] 音色文件名，如 "Chinese(PRC)_Aventurine_4.wav"
  /// [voiceTxt] 音色文本，如 "…我们到了。"
  Future<void> _setRoleVoice(String voiceFileName, String voiceTxt) async {
    try {
      debugPrint('设置角色音色: $voiceFileName -> $voiceTxt');

      // 保存到 SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(ttsAudioNameKey, voiceFileName);
      await prefs.setString(ttsAudioTxtKey, voiceTxt);

      // 更新全局变量
      ttsAudioName = voiceFileName;
      ttsAudioTxt = voiceTxt;

      debugPrint('角色音色设置完成');
    } catch (e) {
      debugPrint('设置角色音色失败: $e');
    }
  }

  /// 设置特定角色的完整信息
  Future<void> _setSpecificRole(String targetRoleName) async {
    try {
      // 检查组件是否仍然挂载
      if (!mounted) {
        debugPrint('组件已销毁，跳过角色设置');
        return;
      }

      final dbHelper = DatabaseHelper();
      final localRoles = await dbHelper.getRoles();
      final matchedRole = localRoles
          .where((role) => role.name == targetRoleName)
          .firstOrNull;

      if (matchedRole != null) {
        debugPrint('找到角色信息: ${matchedRole.name}');
        debugPrint('  - 角色描述: ${matchedRole.description}');
        debugPrint('  - 角色图片: ${matchedRole.image}');
        debugPrint('  - 角色音色: ${matchedRole.voice}');

        // 检查组件是否仍然挂载
        if (!mounted || _isDisposed) {
          debugPrint('组件已销毁，跳过角色切换');
          return;
        }

        // 直接设置角色信息，避免使用 CommonUtil.switchToRole 的异步操作
        roleName.value = matchedRole.name;
        roleDescription.value = matchedRole.description;
        roleImage.value = matchedRole.image;
        roleLanguage.value = matchedRole.language;

        // 如果角色有指定音色，自动设置 TTS 音色
        if (matchedRole.voice != null &&
            matchedRole.voice!.isNotEmpty &&
            matchedRole.voiceTxt != null &&
            matchedRole.voiceTxt!.isNotEmpty) {
          await _setRoleVoice(matchedRole.voice!, matchedRole.voiceTxt!);
        }

        // 清理图片缓存，确保背景图片能正确更新
        ChatPageBuilders.clearMemoryCache();

        debugPrint('特定角色设置完成: ${roleName.value}');
      } else {
        debugPrint('未找到角色信息: $targetRoleName');
        // 如果找不到角色，不进行任何操作，避免触发异步操作
        debugPrint('跳过角色初始化，避免组件销毁后的异步操作');
      }
    } catch (e) {
      debugPrint('设置特定角色失败: $e');
      // 如果出错，不进行任何操作，避免触发异步操作
      debugPrint('跳过错误处理，避免组件销毁后的异步操作');
    }
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

        // // 加载聊天历史记录
        // if (roleName.value.isNotEmpty) {
        //   _loadChatHistory();
        // }
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

    // 检查组件是否仍然挂载
    if (!mounted) {
      debugPrint('_loadChatHistory: 组件已销毁，跳过加载');
      return;
    }

    try {
      debugPrint('_loadChatHistory: 开始为角色 ${roleName.value} 加载聊天历史（支持分支）');
      if (_controller != null) {
        await _controller!.loadChatHistoryWithBranches(roleName.value);
        final messages = _stateManager.getMessages(roleName.value);
        debugPrint('_loadChatHistory: 分支历史加载完成，消息数量: ${messages.length}');
      } else {
        debugPrint('_loadChatHistory: 控制器未初始化，使用传统加载方式');
        await _stateManager.loadMessagesFromDatabase(roleName.value);
        final messages = _stateManager.getMessages(roleName.value);
        debugPrint('_loadChatHistory: 传统加载完成，消息数量: ${messages.length}');
      }

      // 获取最终的消息列表用于调试
      final messages = _stateManager.getMessages(roleName.value);

      if (mounted && !_isDisposed) {
        setState(() {
          // 触发UI更新
        });
      }
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
    // 设置销毁标志，防止后续操作
    _isDisposed = true;

    // 取消流订阅
    _streamSub?.cancel();
    _streamSub = null;

    // 如果AI正在生成回复，停止它
    if (_controller != null && _controller!.isGenerating.value) {
      _controller!.stop();
    }
    // Future.delayed(const Duration(seconds: 2), () {
    //   _controller!.killIsolate();
    // });
    // // 移除生命周期观察者
    // WidgetsBinding.instance.removeObserver(this);

    _textController.dispose();
    disposeScrollListener();
    _controller?.modelService.stop();
    _controller?.modelService.releaseModel();
    _controller?.modelService.ttsService?.releaseTTSModel();
    _controller?.modelService.ttsService?.stopPlayer();
    RoleplayManage.isRolePlayMessage = false;
    super.dispose();
    debugPrint('RolePlayChat dispose');
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
      debugPrint('needsClearStatesOnNextSend.value: true');
      await _controller!.clearStates();
      needsClearStatesOnNextSend.value = false; // 重置标记
    }
    if (!_controller!.modelService.isModelLoaded) {
      debugPrint('Model not loaded, skipping send');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('model_not_loaded'.tr),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 1),
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

    // 暂不保存用户消息到数据库，先添加到内存，等AI生成完成后再一起保存
    debugPrint(
      'Adding user message to memory (will save after AI generation): ${userMessage.content}',
    );
    _stateManager.getMessages(roleName.value).add(userMessage);

    // 设置待保存的用户消息
    _controller!.setPendingUserMessage(userMessage);
    debugPrint('Set pending user message in controller');

    // 添加AI占位消息到内存（不保存到数据库，因为内容为空）
    _stateManager.getMessages(roleName.value).add(aiMessage);

    if (mounted && !_isDisposed) {
      setState(() {
        // 触发UI更新
      });
    }

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

              if (mounted && !_isDisposed) {
                setState(() {
                  // 触发UI更新
                });
              }

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

              // 清空待保存的用户消息，因为生成失败
              _controller?.clearPendingUserMessage();

              if (mounted && !_isDisposed) {
                setState(() {
                  // 触发UI更新
                });
              }

              // 错误时也检查用户是否在滑动
              if (!isUserScrolling) {
                scrollToBottom();
              }
            }
          },
        );
  }

  Widget _buildChatListView() {
    return buildScrollNotificationListener(
      child: Obx(() {
        // 确保响应式地获取当前角色的消息
        final currentRoleName = roleName.value;
        final messages = _stateManager.getMessages(currentRoleName);

        // 检查最后一条AI消息的音频信息
        if (messages.isNotEmpty && !messages.last.isUser) {
          debugPrint(
            '🔄 Obx rebuild - Last AI audioFile: ${messages.last.audioFileName}',
          );
        }

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
              onRegeneratePressed: (message) =>
                  _handleRegeneratePressed(message),
              onBranchChanged: (message, branchIndex) =>
                  _handleBranchChanged(message, branchIndex),
            );
          },
        );
      }),
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
    super.build(context); // 必须调用以保持状态
    return _buildMainContent();
  }

  /// 构建主要内容，直接显示当前角色的聊天页面
  Widget _buildMainContent() {
    return Obx(() {
      // 响应式获取当前角色名称
      final currentRoleName = roleName.value;

      if (currentRoleName.isEmpty) {
        debugPrint('roleName为空');
        return SizedBox.shrink();
      }

      debugPrint('构建聊天页面: $currentRoleName');
      return _buildSingleChatPage();
    });
  }

  /// 构建单一聊天页面
  Widget _buildSingleChatPage() {
    return ChatPageBuilders.buildPageContent(
      index: 0, // 不再使用索引
      usedRoles: usedRoles,
      context: context,
      onBackPressed: () {
        // 取消当前AI回复
        _streamSub?.cancel();
        _streamSub = null;
        if (_controller != null && _controller!.isGenerating.value) {
          _controller!.stop();
        }
        notifyUpdateRolePlaySessionRequired();
        Navigator.of(currentContext!).pop();
      },
      onClearHistory: () async {
        await _controller?.clearAllChatHistory();
        if (mounted && !_isDisposed) {
          setState(() {});
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('chat_history_cleared'.tr),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      },
      onNavigateToRolesList: () async {
        if (await _checkAndStopAiReply()) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => RolesListPage()),
          );
        }
      },
      onNavigateToCreateRole: () async {
        if (await _checkAndStopAiReply()) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreateRolePage()),
          );
        }
      },
      onNavigateToChangeModel:
          (RoleplayManageModelType roleplayManageModelType) async {
            debugPrint('onNavigateToChangeModel: $roleplayManageModelType');
            notifyModelDownloadRequired(roleplayManageModelType);
          },
      onNavigateToRoleParams: () async {
        if (await _checkAndStopAiReply()) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ModelParamsPage(),
            ), //RoleParamsPage
          );
        }
      },
      onNavigateToAudioList: () async {
        if (await _checkAndStopAiReply()) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AudioListPage()),
          );
        }
      },
      chatListView: _buildChatListView(),
      inputBar: _buildInputBar(),
      showBackground: false, // 不显示背景，由HomePage统一管理
    );
  }

  // ===== 分支管理处理函数 =====

  /// 处理重新生成按钮点击
  void _handleRegeneratePressed(ChatMessage message) {
    debugPrint(
      '_handleRegeneratePressed called for message: ${message.content.substring(0, math.min(50, message.content.length))}...',
    );

    if (_controller == null) {
      debugPrint('Controller is null, cannot regenerate');
      return;
    }

    // 检查模型是否已加载
    if (!_controller!.modelService.isModelLoaded) {
      debugPrint('Model not loaded, skipping regenerate');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('model_not_loaded'.tr),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 1),
        ),
      );
      return;
    }

    // 简化逻辑：直接查找前一条用户消息
    final userMessage = _findPreviousUserMessage(message);
    debugPrint('Found previous user message: ${userMessage?.content}');

    if (userMessage != null) {
      debugPrint('Calling regenerateResponse...');
      _controller!.regenerateResponse(userMessage);
    } else {
      debugPrint('No user message found');
      _showNoUserMessageDialog();
    }
  }

  /// 处理分支切换
  void _handleBranchChanged(ChatMessage message, int branchIndex) async {
    if (_controller == null) return;

    // 使用控制器计算消息层级
    final messageLevel = await _controller!.calculateMessageLevel(message);
    _controller!.switchBranch(messageLevel, branchIndex);
  }

  /// 查找AI消息前面的用户消息
  ChatMessage? _findPreviousUserMessage(ChatMessage aiMessage) {
    final index = _messages.indexOf(aiMessage);
    if (index == -1) return null;

    // 向前查找最近的用户消息
    for (int i = index - 1; i >= 0; i--) {
      if (_messages[i].isUser) {
        return _messages[i];
      }
    }
    return null;
  }

  /// 显示无法找到用户消息的对话框
  void _showNoUserMessageDialog() {
    if (mounted) {
      showDialog(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.6),
        builder: (BuildContext dialogContext) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.grey.shade900.withValues(alpha: 0.95),
                  Colors.black.withValues(alpha: 0.98),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.orange.withValues(alpha: 0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 警告图标
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.orange.withValues(alpha: 0.2),
                        Colors.orange.withValues(alpha: 0.3),
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.info_outline_rounded,
                    color: Colors.orange.shade400,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 20),
                // 标题
                Text(
                  'unable_to_regenerate'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                // 内容
                Text(
                  'cannot_find_user_message'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                // 确认按钮
                GestureDetector(
                  onTap: () => Navigator.of(dialogContext).pop(),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.orange.shade600, Colors.orange.shade700],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'confirm_button'.tr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}
