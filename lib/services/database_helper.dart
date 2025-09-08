import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter_roleplay/models/chat_message_model.dart';
import 'package:flutter_roleplay/models/role_model.dart';
import 'package:flutter_roleplay/models/model_info.dart';
import 'package:rwkv_mobile_flutter/types.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'flutter_roleplay.db');
    return await openDatabase(
      path,
      version: 4, // 升级版本以添加 language 字段
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 创建聊天消息表
    await db.execute('''
      CREATE TABLE chat_messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        role_name TEXT NOT NULL,
        content TEXT NOT NULL,
        is_user INTEGER NOT NULL,
        timestamp INTEGER NOT NULL
      )
    ''');

    // 创建角色表
    await db.execute('''
      CREATE TABLE roles (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        image TEXT NOT NULL,
        language TEXT NOT NULL DEFAULT 'zh-CN',
        is_custom INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // 创建缓存元数据表
    await db.execute('''
      CREATE TABLE cache_metadata (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // 创建模型信息表
    await db.execute('''
      CREATE TABLE model_info (
        id TEXT PRIMARY KEY,
        model_path TEXT NOT NULL,
        state_path TEXT NOT NULL,
        backend TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // 创建索引以提高查询性能
    await db.execute('''
      CREATE INDEX idx_role_name ON chat_messages (role_name)
    ''');

    await db.execute('''
      CREATE INDEX idx_timestamp ON chat_messages (timestamp)
    ''');

    await db.execute('''
      CREATE INDEX idx_roles_name ON roles (name)
    ''');

    await db.execute('''
      CREATE INDEX idx_roles_is_custom ON roles (is_custom)
    ''');

    await db.execute('''
      CREATE INDEX idx_model_info_is_active ON model_info (is_active)
    ''');

    debugPrint('数据库表创建完成');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('数据库升级: $oldVersion -> $newVersion');

    if (oldVersion < 2) {
      // 从版本1升级到版本2: 添加角色表和缓存元数据表
      await db.execute('''
        CREATE TABLE roles (
          id INTEGER PRIMARY KEY,
          name TEXT NOT NULL,
          description TEXT NOT NULL,
          image TEXT NOT NULL,
          language TEXT NOT NULL DEFAULT 'zh-CN',
          is_custom INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE cache_metadata (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');

      await db.execute('CREATE INDEX idx_roles_name ON roles (name)');
      await db.execute('CREATE INDEX idx_roles_is_custom ON roles (is_custom)');

      debugPrint('已添加角色表和相关索引');
    }

    if (oldVersion < 3) {
      // 从版本2升级到版本3: 添加模型信息表
      await db.execute('''
        CREATE TABLE model_info (
          id TEXT PRIMARY KEY,
          model_path TEXT NOT NULL,
          state_path TEXT NOT NULL,
          backend TEXT NOT NULL,
          is_active INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');

      await db.execute(
        'CREATE INDEX idx_model_info_is_active ON model_info (is_active)',
      );

      debugPrint('已添加模型信息表和相关索引');
    }

    if (oldVersion < 4) {
      // 从版本3升级到版本4: 为 roles 表添加 language 字段
      await db.execute('''
        ALTER TABLE roles ADD COLUMN language TEXT NOT NULL DEFAULT 'zh-CN'
      ''');

      debugPrint('已为 roles 表添加 language 字段');
    }
  }

  // 插入聊天消息
  Future<int> insertMessage(ChatMessage message) async {
    final db = await database;
    debugPrint('insertMessage: ${message.toMap()}');
    return await db.insert('chat_messages', message.toMap());
  }

  // 批量插入消息
  Future<void> insertMessages(List<ChatMessage> messages) async {
    final db = await database;
    final batch = db.batch();

    for (final message in messages) {
      batch.insert('chat_messages', message.toMap());
    }

    await batch.commit(noResult: true);
  }

  // 获取指定角色的所有聊天消息
  Future<List<ChatMessage>> getMessagesByRole(String roleName) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chat_messages',
      where: 'role_name = ?',
      whereArgs: [roleName],
      orderBy: 'timestamp ASC',
    );

    return List.generate(maps.length, (i) {
      return ChatMessage.fromMap(maps[i]);
    });
  }

  // 获取指定角色的最新N条消息
  Future<List<ChatMessage>> getLatestMessagesByRole(
    String roleName,
    int limit,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chat_messages',
      where: 'role_name = ?',
      whereArgs: [roleName],
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    // 反转列表以保持时间顺序
    final reversedMaps = maps.reversed.toList();
    return List.generate(reversedMaps.length, (i) {
      return ChatMessage.fromMap(reversedMaps[i]);
    });
  }

  // 删除指定角色的所有聊天记录
  Future<int> deleteMessagesByRole(String roleName) async {
    final db = await database;
    return await db.delete(
      'chat_messages',
      where: 'role_name = ?',
      whereArgs: [roleName],
    );
  }

  // 删除指定角色的最新N条消息
  Future<int> deleteLatestMessagesByRole(String roleName, int count) async {
    final db = await database;

    // 获取要删除的消息ID
    final List<Map<String, dynamic>> maps = await db.query(
      'chat_messages',
      columns: ['id'],
      where: 'role_name = ?',
      whereArgs: [roleName],
      orderBy: 'timestamp DESC',
      limit: count,
    );

    if (maps.isEmpty) return 0;

    final ids = maps.map((map) => map['id'] as int).toList();
    return await db.delete(
      'chat_messages',
      where: 'id IN (${List.filled(ids.length, '?').join(',')})',
      whereArgs: ids,
    );
  }

  // 获取所有角色名称
  Future<List<String>> getAllRoleNames() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT DISTINCT role_name FROM chat_messages ORDER BY role_name',
    );

    return maps.map((map) => map['role_name'] as String).toList();
  }

  // 获取最近聊天的角色（按最后聊天时间排序）
  Future<String?> getLastChatRole() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT role_name, MAX(timestamp) as last_chat_time 
      FROM chat_messages 
      GROUP BY role_name 
      ORDER BY last_chat_time DESC 
      LIMIT 1
    ''');

    if (maps.isNotEmpty) {
      return maps.first['role_name'] as String;
    }
    return null;
  }

  // 获取最近聊天的角色列表（按最后聊天时间排序）
  Future<List<String>> getRecentChatRoles({int limit = 10}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT role_name, MAX(timestamp) as last_chat_time 
      FROM chat_messages 
      GROUP BY role_name 
      ORDER BY last_chat_time DESC 
      LIMIT ?
    ''',
      [limit],
    );

    return maps.map((map) => map['role_name'] as String).toList();
  }

  // 获取指定角色的消息数量
  Future<int> getMessageCountByRole(String roleName) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM chat_messages WHERE role_name = ?',
      [roleName],
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  // 清理旧消息（保留每个角色最新的N条）
  Future<void> cleanupOldMessages(int keepCount) async {
    await database;
    final roleNames = await getAllRoleNames();

    for (final roleName in roleNames) {
      final messageCount = await getMessageCountByRole(roleName);
      if (messageCount > keepCount) {
        await deleteLatestMessagesByRole(roleName, messageCount - keepCount);
      }
    }
  }

  // ==================== 角色存储相关方法 ====================

  /// 保存API角色列表到本地 (会清空现有的API角色，保留自定义角色)
  Future<void> saveRoles(List<RoleModel> roles) async {
    try {
      final db = await database;
      final batch = db.batch();

      // 只清空API角色，保留自定义角色
      batch.delete('roles', where: 'is_custom = ?', whereArgs: [0]);

      // 插入新的API角色数据
      final now = DateTime.now().millisecondsSinceEpoch;
      for (final role in roles) {
        batch.insert('roles', {
          'id': role.id,
          'name': role.name,
          'description': role.description,
          'image': role.image,
          'language': role.language,
          'is_custom': role.isCustom ? 1 : 0,
          'created_at': now,
          'updated_at': now,
        });
      }

      // 更新缓存元数据
      batch.insert('cache_metadata', {
        'key': 'roles_last_update',
        'value': now.toString(),
        'updated_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      await batch.commit();
      debugPrint('成功保存 ${roles.length} 个角色到本地数据库');
    } catch (e) {
      debugPrint('保存角色到本地数据库失败: $e');
      rethrow;
    }
  }

  /// 从本地获取角色列表 (自定义角色排在前面)
  Future<List<RoleModel>> getRoles() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'roles',
        orderBy: 'is_custom DESC', // 自定义角色在前
      );

      final roles = List.generate(maps.length, (i) {
        return RoleModel.fromDbMap(maps[i]);
      });

      debugPrint(
        '从本地数据库加载了 ${roles.length} 个角色 (自定义: ${roles.where((r) => r.isCustom).length}, API: ${roles.where((r) => !r.isCustom).length})',
      );
      return roles;
    } catch (e) {
      debugPrint('从本地数据库加载角色失败: $e');
      return [];
    }
  }

  /// 获取缓存的最后更新时间
  Future<DateTime?> getLastUpdateTime() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> result = await db.query(
        'cache_metadata',
        where: 'key = ?',
        whereArgs: ['roles_last_update'],
      );

      if (result.isNotEmpty) {
        final timestamp = int.parse(result.first['value']);
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
      return null;
    } catch (e) {
      debugPrint('获取最后更新时间失败: $e');
      return null;
    }
  }

  /// 检查本地是否有角色数据
  Future<bool> hasLocalRoleData() async {
    try {
      final roles = await getRoles();
      return roles.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// 清空本地角色数据
  Future<void> clearRoles() async {
    try {
      final db = await database;
      await db.delete('roles');
      await db.delete(
        'cache_metadata',
        where: 'key = ?',
        whereArgs: ['roles_last_update'],
      );
      debugPrint('已清空本地角色数据');
    } catch (e) {
      debugPrint('清空本地角色数据失败: $e');
    }
  }

  /// 保存单个自定义角色
  Future<int> saveCustomRole(RoleModel role) async {
    try {
      final db = await database;

      // 生成新的自定义角色ID (负数，避免与API角色冲突)
      final customRoleId = await _generateCustomRoleId();

      // 创建带有正确ID的角色实例，保持原有的image路径
      final roleWithId = RoleModel(
        id: customRoleId,
        name: role.name,
        description: role.description,
        image: role.image, // 保持原有的图片路径，不使用默认值
        language: role.language,
        isCustom: true,
      );

      await db.insert('roles', roleWithId.toDbMap());
      debugPrint(
        '成功保存自定义角色: ${roleWithId.name} (ID: $customRoleId, Image: ${roleWithId.image})',
      );
      return customRoleId;
    } catch (e) {
      debugPrint('保存自定义角色失败: $e');
      rethrow;
    }
  }

  /// 生成自定义角色ID (使用负数避免与API角色冲突)
  Future<int> _generateCustomRoleId() async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        'SELECT MIN(id) as min_id FROM roles WHERE is_custom = 1',
      );

      final minId = result.first['min_id'] as int?;
      if (minId == null) {
        return -1; // 第一个自定义角色
      } else {
        return minId - 1; // 递减生成新ID
      }
    } catch (e) {
      debugPrint('生成自定义角色ID失败: $e');
      return -DateTime.now().millisecondsSinceEpoch; // 使用时间戳作为备用ID
    }
  }

  /// 更新自定义角色
  Future<void> updateCustomRole(RoleModel role) async {
    try {
      final db = await database;
      final now = DateTime.now().millisecondsSinceEpoch;

      final count = await db.update(
        'roles',
        {
          'name': role.name,
          'description': role.description,
          'image': role.image,
          'language': role.language,
          'updated_at': now,
        },
        where: 'id = ? AND is_custom = 1',
        whereArgs: [role.id],
      );

      if (count > 0) {
        debugPrint('成功更新自定义角色: ${role.name} (ID: ${role.id})');
      } else {
        debugPrint('未找到要更新的自定义角色 (ID: ${role.id})');
      }
    } catch (e) {
      debugPrint('更新自定义角色失败: $e');
      rethrow;
    }
  }

  /// 删除自定义角色
  Future<void> deleteCustomRole(int roleId) async {
    try {
      final db = await database;
      final count = await db.delete(
        'roles',
        where: 'id = ? AND is_custom = 1',
        whereArgs: [roleId],
      );

      if (count > 0) {
        debugPrint('成功删除自定义角色 (ID: $roleId)');
      } else {
        debugPrint('未找到要删除的自定义角色 (ID: $roleId)');
      }
    } catch (e) {
      debugPrint('删除自定义角色失败: $e');
      rethrow;
    }
  }

  /// 获取所有自定义角色
  Future<List<RoleModel>> getCustomRoles() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'roles',
        where: 'is_custom = 1',
        orderBy: 'created_at DESC', // 按创建时间倒序
      );

      final roles = List.generate(maps.length, (i) {
        return RoleModel.fromDbMap(maps[i]);
      });

      debugPrint('获取到 ${roles.length} 个自定义角色');
      return roles;
    } catch (e) {
      debugPrint('获取自定义角色失败: $e');
      return [];
    }
  }

  /// 获取角色数量
  Future<int> getRoleCount() async {
    try {
      final db = await database;
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM roles');
      return result.first['count'] as int;
    } catch (e) {
      debugPrint('获取角色数量失败: $e');
      return 0;
    }
  }

  /// 获取自定义角色数量
  Future<int> getCustomRoleCount() async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM roles WHERE is_custom = 1',
      );
      return result.first['count'] as int;
    } catch (e) {
      debugPrint('获取自定义角色数量失败: $e');
      return 0;
    }
  }

  // ==================== 模型信息存储相关方法 ====================

  /// 保存模型信息到本地
  Future<void> saveModelInfo(ModelInfo modelInfo) async {
    try {
      final db = await database;
      final now = DateTime.now().millisecondsSinceEpoch;

      // // 首先将所有模型设置为非活跃状态
      // await db.update('model_info', {'is_active': 0, 'updated_at': now});

      ///数据库里只保存一条模型信息，把之前的记录先删除
      await clearAllModelInfo();

      // 保存新的模型信息并设置为活跃状态
      await db.insert('model_info', {
        'id': modelInfo.id,
        'model_path': modelInfo.modelPath,
        'state_path': modelInfo.statePath,
        'backend': modelInfo.backend.name,
        'is_active': 1,
        'created_at': now,
        'updated_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      debugPrint('成功保存模型信息: ${modelInfo.id}');
    } catch (e) {
      debugPrint('保存模型信息失败: $e');
      rethrow;
    }
  }

  /// 获取当前活跃的模型信息
  Future<ModelInfo?> getActiveModelInfo() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'model_info',
        where: 'is_active = ?',
        whereArgs: [1],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        final map = maps.first;
        final modelInfo = ModelInfo(
          id: map['id'],
          modelPath: map['model_path'],
          statePath: map['state_path'],
          backend: Backend.values.firstWhere(
            (b) => b.name == map['backend'],
            orElse: () => Backend.llamacpp,
          ),
        );
        debugPrint('获取到活跃模型信息: ${modelInfo.id}');
        return modelInfo;
      }

      debugPrint('没有找到活跃的模型信息');
      return null;
    } catch (e) {
      debugPrint('获取活跃模型信息失败: $e');
      return null;
    }
  }

  /// 获取所有模型信息
  Future<List<ModelInfo>> getAllModelInfo() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'model_info',
        orderBy: 'updated_at DESC',
      );

      final modelInfoList = maps
          .map(
            (map) => ModelInfo(
              id: map['id'],
              modelPath: map['model_path'],
              statePath: map['state_path'],
              backend: Backend.values.firstWhere(
                (b) => b.name == map['backend'],
                orElse: () => Backend.llamacpp,
              ),
            ),
          )
          .toList();

      debugPrint('获取到 ${modelInfoList.length} 个模型信息');
      return modelInfoList;
    } catch (e) {
      debugPrint('获取所有模型信息失败: $e');
      return [];
    }
  }

  /// 删除模型信息
  Future<void> deleteModelInfo(String modelId) async {
    try {
      final db = await database;
      final count = await db.delete(
        'model_info',
        where: 'id = ?',
        whereArgs: [modelId],
      );

      if (count > 0) {
        debugPrint('成功删除模型信息: $modelId');
      } else {
        debugPrint('未找到要删除的模型信息: $modelId');
      }
    } catch (e) {
      debugPrint('删除模型信息失败: $e');
      rethrow;
    }
  }

  /// 清空所有模型信息
  Future<void> clearAllModelInfo() async {
    try {
      final db = await database;
      await db.delete('model_info');
      debugPrint('已清空所有模型信息');
    } catch (e) {
      debugPrint('清空模型信息失败: $e');
      rethrow;
    }
  }

  // 关闭数据库
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
