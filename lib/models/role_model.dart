class RoleResponse {
  final int code;
  final String message;
  final List<RoleModel> data;
  final int timestamp;

  RoleResponse({
    required this.code,
    required this.message,
    required this.data,
    required this.timestamp,
  });

  factory RoleResponse.fromJson(Map<String, dynamic> json) {
    return RoleResponse(
      code: json['code'] as int,
      message: json['message'] as String,
      data: (json['data'] as List)
          .map((item) => RoleModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      timestamp: json['timestamp'] as int,
    );
  }
}

class RoleModel {
  final int id;
  final String name;
  final String description;
  final String image;
  final String language;
  final bool isCustom; // true: 用户自定义角色, false: API获取的角色

  RoleModel({
    required this.id,
    required this.name,
    required this.description,
    required this.image,
    required this.language,
    this.isCustom = false, // 默认为API角色
  });

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    return RoleModel(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      image: json['image'] as String,
      language: json['language'] as String? ?? 'zh-CN', // 默认中文
      isCustom: json['isCustom'] as bool? ?? false, // API数据默认为false
    );
  }

  // 创建自定义角色的工厂方法
  factory RoleModel.createCustom({
    required int id,
    required String name,
    required String description,
    String? image,
    String? language,
  }) {
    return RoleModel(
      id: id,
      name: name,
      description: description,
      image:
          image ??
          'https://via.placeholder.com/300x400/4A90E2/FFFFFF?text=${Uri.encodeComponent(name)}', // 默认占位图
      language: language ?? 'zh-CN', // 默认中文
      isCustom: true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image': image,
      'language': language,
      'isCustom': isCustom,
    };
  }

  // 转换为 constant.dart 中使用的格式
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'image': image,
      'language': language,
      'isCustom': isCustom,
    };
  }

  // 数据库存储格式
  Map<String, dynamic> toDbMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image': image,
      'language': language,
      'is_custom': isCustom ? 1 : 0, // SQLite使用整数表示布尔值
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    };
  }

  // 从数据库格式创建
  factory RoleModel.fromDbMap(Map<String, dynamic> map) {
    return RoleModel(
      id: map['id'] as int,
      name: map['name'] as String,
      description: map['description'] as String,
      image: map['image'] as String,
      language: map['language'] as String? ?? 'zh-CN', // 默认中文，兼容旧数据
      isCustom: (map['is_custom'] as int) == 1,
    );
  }
}
