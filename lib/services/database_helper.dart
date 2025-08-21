import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter_roleplay/models/chat_message_model.dart';

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
    String path = join(await getDatabasesPath(), 'chat_history.db');
    return await openDatabase(
      path,
      version: 1,
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

    // 创建索引以提高查询性能
    await db.execute('''
      CREATE INDEX idx_role_name ON chat_messages (role_name)
    ''');

    await db.execute('''
      CREATE INDEX idx_timestamp ON chat_messages (timestamp)
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 未来版本升级时的处理
    if (oldVersion < newVersion) {
      // 可以在这里添加新的表或修改现有表结构
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

  // 关闭数据库
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
