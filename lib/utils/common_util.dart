import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_roleplay/constant/constant.dart';
import 'package:flutter_roleplay/pages/chat/roleplay_chat_controller.dart';
import 'package:flutter_roleplay/services/chat_state_manager.dart';
import 'package:flutter_roleplay/services/database_helper.dart';
import 'package:flutter_roleplay/services/role_api_service.dart';
import 'package:flutter_roleplay/widgets/chat_page_builders.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class CommonUtil {
  // 初始化默认角色
  static Future<void> initializeDefaultRole() async {
    // 如果已经有角色，不需要重复初始化
    if (roleName.value.isNotEmpty) {
      debugPrint(
        'initializeDefaultRole: 角色已初始化: ${roleName.value}, 图片: ${roleImage.value}',
      );
      return;
    }

    debugPrint('initializeDefaultRole: 开始初始化默认角色');

    // 初始化时标记需要清空聊天状态
    needsClearStatesOnNextSend.value = true;
    debugPrint('initializeDefaultRole: 标记需要在首次发送消息时清空聊天状态');

    try {
      debugPrint('开始初始化默认角色...');

      // 1. 首先尝试从聊天历史中获取最近聊天的角色
      final dbHelper = DatabaseHelper();
      final lastChatRole = await dbHelper.getLastChatRole();

      if (lastChatRole != null) {
        debugPrint('找到最近聊天的角色: $lastChatRole');

        // 从角色列表中查找对应的角色信息
        final localRoles = await dbHelper.getRoles();
        final matchedRole = localRoles
            .where((role) => role.name == lastChatRole)
            .firstOrNull;

        if (matchedRole != null) {
          debugPrint('成功加载最近聊天的角色: ${matchedRole.name}');
          debugPrint('  - 角色图片: ${matchedRole.image}');
          final roleMap = matchedRole.toMap();
          debugPrint('  - toMap()结果图片: ${roleMap['image']}');
          switchToRole(roleMap);
          return;
        } else {
          debugPrint('最近聊天的角色在角色列表中未找到，使用默认角色');
        }
      }

      // 2. 如果没有聊天历史，从本地存储获取角色
      final localRoles = await dbHelper.getRoles();

      if (localRoles.isNotEmpty) {
        debugPrint('从本地存储找到 ${localRoles.length} 个角色，使用第一个作为默认角色');
        final defaultRole = localRoles.first;
        debugPrint('  - 默认角色: ${defaultRole.name}');
        debugPrint('  - 默认角色图片: ${defaultRole.image}');
        final roleMap = defaultRole.toMap();
        debugPrint('  - toMap()结果图片: ${roleMap['image']}');
        switchToRole(roleMap);
        return;
      }

      debugPrint('本地存储无角色，尝试从网络获取...');

      // 3. 本地没有角色，从网络获取
      final apiRoles = await RoleApiService.getRoles();

      if (apiRoles.isNotEmpty) {
        debugPrint('从网络获取到 ${apiRoles.length} 个角色，使用第一个作为默认角色');

        // 保存到本地存储
        await dbHelper.saveRoles(apiRoles);
        debugPrint('角色已保存到本地存储');

        // 使用第一个角色作为默认角色
        final defaultRole = apiRoles.first;
        switchToRole(defaultRole.toMap());
        return;
      }

      debugPrint('网络和本地都没有找到角色数据');
    } catch (e) {
      debugPrint('初始化默认角色失败: $e');
      // 如果所有方式都失败了，可以设置一个兜底的默认角色
      _setFallbackRole();
    }
  }

  // 设置兜底的默认角色
  static void _setFallbackRole() {
    debugPrint('使用兜底默认角色');
    final fallbackRole = {
      'name': '梁王',
      'description':
          '你是一名手握重权的王爷。你为人正直，爱民如子，拥有很高的社会地位。你深知权力所带来的责任，也渴望能治理好自己的封地，让百姓安居乐业。你正在寻找能帮助你实现抱负的贤才。',
      'image':
          'https://download.rwkvos.com/rwkvmusic/downloads/1.0/liangwang.webp',
      'language': 'zh-CN', // 默认中文
      'isCustom': false,
    };

    switchToRole(fallbackRole);
  }

  // 防止重复切换的标志
  static bool _isSwitching = false;

  // 切换角色
  static void switchToRole(Map<String, dynamic> role) {
    final newRoleName = role['name'] as String;

    // 防止重复切换到同一个角色，但允许从空角色切换到新角色
    if (_isSwitching) {
      debugPrint('角色切换已在进行中，跳过: $newRoleName');
      return;
    }

    // 只有当前角色不为空且与新角色相同时才跳过
    if (roleName.value.isNotEmpty && roleName.value == newRoleName) {
      debugPrint('角色相同，跳过切换: $newRoleName');
      return;
    }

    _isSwitching = true;
    debugPrint(
      '开始切换角色: ${roleName.value.isEmpty ? "空" : roleName.value} -> $newRoleName',
    );

    try {
      debugPrint('CommonUtil.switchToRole: 开始更新全局变量');
      debugPrint('  - 更新前 roleName.value: ${roleName.value}');
      debugPrint('  - 更新前 roleImage.value: ${roleImage.value}');

      // 保存更新前的图片路径用于比较
      final oldImagePath = roleImage.value;
      final newImagePath = role['image'] as String;

      // 原子性更新所有角色状态
      roleName.value = newRoleName;
      roleDescription.value = role['description'] as String;
      roleImage.value = newImagePath;
      roleLanguage.value = (role['language'] as String?) ?? 'zh-CN';

      debugPrint('CommonUtil.switchToRole: 更新后详细信息');
      debugPrint('  - 角色名称: $newRoleName');
      debugPrint('  - 角色描述: ${role['description']}');
      debugPrint('  - 传入的角色图片: $newImagePath');
      debugPrint('  - 更新后 roleImage.value: ${roleImage.value}');
      debugPrint('  - 图片是否发生变化: ${oldImagePath != newImagePath}');
      if (oldImagePath != newImagePath) {
        debugPrint('  - 图片路径从 "$oldImagePath" 变更为 "$newImagePath"');
      }

      // 验证图片文件
      final imageUrl = role['image'] as String;
      if (imageUrl.isNotEmpty &&
          (imageUrl.startsWith('/') || imageUrl.startsWith('file://'))) {
        final file = File(imageUrl.replaceFirst('file://', ''));
        debugPrint('  - 本地图片文件存在: ${file.existsSync()}');
        debugPrint('  - 文件路径: ${file.path}');
      }

      // 检查角色是否已经在列表中
      final existingIndex = usedRoles.indexWhere(
        (usedRole) => usedRole['name'] == newRoleName,
      );

      if (existingIndex == -1) {
        // 如果角色不在列表中，添加到末尾
        usedRoles.add(Map<String, dynamic>.from(role));
        debugPrint('  - 角色已添加到usedRoles列表');
      } else {
        // 如果角色已存在，更新其信息
        usedRoles[existingIndex] = Map<String, dynamic>.from(role);
        debugPrint('  - 角色信息已更新在usedRoles列表中');
      }

      debugPrint('  - usedRoles列表长度: ${usedRoles.length}');
      for (int i = 0; i < usedRoles.length; i++) {
        final r = usedRoles[i];
        debugPrint('    [$i] ${r['name']}: ${r['image']}');
      }

      // 获取或创建控制器
      RolePlayChatController? controller;
      if (Get.isRegistered<RolePlayChatController>()) {
        controller = Get.find<RolePlayChatController>();
      } else {
        controller = Get.put(RolePlayChatController());
      }

      // 标记需要在下次发送消息时清空聊天状态
      needsClearStatesOnNextSend.value = true;
      debugPrint('标记需要在下次发送消息时清空聊天状态');

      // 清空图片组件缓存，确保背景图片能正确更新
      ChatPageBuilders.clearMemoryCache();

      // // 清空当前状态（只清空内存，不删除数据库记录）
      // controller?.clearStates();

      // 同步加载聊天历史记录（避免异步时序问题）
      _loadChatHistorySync(newRoleName, controller);

      debugPrint('角色切换完成: $newRoleName');
    } catch (e) {
      debugPrint('角色切换失败: $e');
    } finally {
      // 延迟重置标志，避免过快的重复切换
      Future.delayed(const Duration(milliseconds: 300), () {
        _isSwitching = false;
      });
    }
  }

  // 同步加载聊天历史记录（支持消息分叉）
  static void _loadChatHistorySync(
    String roleName,
    RolePlayChatController? controller,
  ) {
    Future.microtask(() async {
      try {
        debugPrint('_loadChatHistorySync: 开始为角色 $roleName 加载聊天历史（支持分支）');

        if (controller != null) {
          // 使用控制器的新分支加载方法
          await controller.loadChatHistoryWithBranches(roleName);
          final messages = ChatStateManager().getMessages(roleName);
          debugPrint('_loadChatHistorySync: 分支历史加载完成，消息数量: ${messages.length}');
        } else {
          // 控制器未初始化，使用传统加载方式
          debugPrint('_loadChatHistorySync: 控制器未初始化，使用传统加载方式');
          final chatStateManager = ChatStateManager();
          await chatStateManager.loadMessagesFromDatabase(roleName);
          final messages = chatStateManager.getMessages(roleName);
          debugPrint('_loadChatHistorySync: 传统加载完成，消息数量: ${messages.length}');
        }

        // 获取最终的消息列表用于调试
        final messages = ChatStateManager().getMessages(roleName);
        debugPrint(
          'Chat history loaded for role: $roleName, 消息数量: ${messages.length}',
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

        // 通知UI更新
        if (Get.isRegistered<RolePlayChatController>()) {
          Get.find<RolePlayChatController>().update();
        }
      } catch (e) {
        debugPrint('Failed to load chat history in switchToRole: $e');
      }
    });
  }

  /// 从资源文件复制到临时目录
  static Future<String> fromAssetsToTemp(
    String assetsPath, {
    String? targetPath,
  }) async {
    try {
      // 在插件中加载资源时，先尝试从主应用加载
      ByteData data;
      try {
        data = await rootBundle.load(assetsPath);
        debugPrint('fromAssetsToTemp: load $assetsPath');
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

  static Future<String> getFileDocumentPath(String filePath) async {
    String tempFilePath = filePath;
    if (Platform.isIOS) {
      Directory tempDir = await getApplicationDocumentsDirectory();
      var tempDirPath = tempDir.path;
      var name = Uri.parse(filePath).pathSegments.last;
      tempFilePath = '$tempDirPath${Platform.pathSeparator}$name';
    }
    return tempFilePath;
  }

  static Future<String> getFilePath(String name) async {
    Directory tempDir = await getApplicationDocumentsDirectory();
    var tempDirPath = tempDir.path;
    var tempFilePath = '$tempDirPath${Platform.pathSeparator}$name';
    return tempFilePath;
  }
}
