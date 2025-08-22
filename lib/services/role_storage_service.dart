import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter_roleplay/models/role_model.dart';

class RoleStorageService {
  static final RoleStorageService _instance = RoleStorageService._internal();
  factory RoleStorageService() => _instance;
  RoleStorageService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'role_storage.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 创建角色表
    await db.execute('''
      CREATE TABLE roles (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        image TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // 创建索引
    await db.execute('''
      CREATE INDEX idx_role_name ON roles (name)
    ''');

    // 创建缓存元数据表，记录最后更新时间等信息
    await db.execute('''
      CREATE TABLE cache_metadata (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    debugPrint('角色存储数据库表创建完成');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 未来版本升级时的处理
    if (oldVersion < newVersion) {
      // 可以在这里添加新的表或修改现有表结构
    }
  }

  /// 保存角色列表到本地
  Future<void> saveRoles(List<RoleModel> roles) async {
    try {
      final db = await database;
      final batch = db.batch();

      // 清空现有数据
      batch.delete('roles');

      // 插入新数据
      final now = DateTime.now().millisecondsSinceEpoch;
      for (final role in roles) {
        batch.insert('roles', {
          'id': role.id,
          'name': role.name,
          'description': role.description,
          'image': role.image,
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

  /// 从本地获取角色列表
  Future<List<RoleModel>> getRoles() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'roles',
        orderBy: 'id ASC',
      );

      final roles = List.generate(maps.length, (i) {
        return RoleModel.fromJson({
          'id': maps[i]['id'],
          'name': maps[i]['name'],
          'description': maps[i]['description'],
          'image': maps[i]['image'],
        });
      });

      debugPrint('从本地数据库加载了 ${roles.length} 个角色');
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
  Future<bool> hasLocalData() async {
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
}
