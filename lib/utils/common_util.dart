import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_roleplay/constant/constant.dart';
import 'package:flutter_roleplay/hometabs/roleplay_chat_controller.dart';
import 'package:flutter_roleplay/services/chat_state_manager.dart';
import 'package:flutter_roleplay/services/database_helper.dart';
import 'package:flutter_roleplay/services/role_api_service.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class CommonUtil {
  // 初始化默认角色
  static Future<void> initializeDefaultRole() async {
    // 如果已经有角色，不需要重复初始化
    if (roleName.value.isNotEmpty) {
      debugPrint('角色已初始化: ${roleName.value}');
      return;
    }

    try {
      debugPrint('开始初始化默认角色...');

      // 1. 先尝试从本地存储获取角色
      final dbHelper = DatabaseHelper();
      final localRoles = await dbHelper.getRoles();

      if (localRoles.isNotEmpty) {
        debugPrint('从本地存储找到 ${localRoles.length} 个角色，使用第一个作为默认角色');
        final defaultRole = localRoles.first;
        switchToRole(defaultRole.toMap());
        return;
      }

      debugPrint('本地存储无角色，尝试从网络获取...');

      // 2. 本地没有角色，从网络获取
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
      'isCustom': false,
    };

    switchToRole(fallbackRole);
  }

  // 切换角色
  static void switchToRole(Map<String, dynamic> role) {
    roleName.value = role['name'] as String;
    roleDescription.value = role['description'] as String;
    roleImage.value = role['image'] as String;
    // debugPrint(
    //   'switchToRole: ${role['name']},${role['description']},${role['image']}',
    // );

    // 检查角色是否已经在列表中
    final existingIndex = usedRoles.indexWhere(
      (usedRole) => usedRole['name'] == role['name'],
    );

    if (existingIndex == -1) {
      // 如果角色不在列表中，添加到末尾
      usedRoles.add(Map<String, dynamic>.from(role));

      // // 限制已使用角色列表的长度（最多保存10个）
      // if (usedRoles.length > 10) {
      //   usedRoles.removeAt(0); // 移除最早的角色
      // }
    }
    // 如果角色已存在，不需要重新添加，只更新当前状态
    RolePlayChatController? controller;
    if (Get.isRegistered<RolePlayChatController>()) {
      controller = Get.find<RolePlayChatController>();
    } else {
      controller = Get.put(RolePlayChatController());
    }

    // 清空当前状态（只清空内存，不删除数据库记录）
    controller?.clearStates();

    // 异步加载该角色的聊天历史记录
    Future.microtask(() async {
      try {
        final chatStateManager = ChatStateManager();
        await chatStateManager.loadMessagesFromDatabase(role['name'] as String);
        debugPrint(
          'Loaded chat history for ${role['name']}, message count: ${chatStateManager.getMessages(role['name'] as String).length}',
        );

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
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(path.join(tempDir.path, targetPath ?? assetsPath));
      if (tempFile.existsSync()) {
        debugPrint("file exists: ${tempFile.path}");
        return tempFile.path;
      }
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

      await tempFile.create(recursive: true);
      await tempFile.writeAsBytes(data.buffer.asUint8List());
      return tempFile.path;
    } catch (e) {
      debugPrint("Error loading asset $assetsPath: $e");
      return "";
    }
  }
}
