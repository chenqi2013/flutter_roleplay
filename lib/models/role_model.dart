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

  RoleModel({
    required this.id,
    required this.name,
    required this.description,
    required this.image,
  });

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    return RoleModel(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      image: json['image'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'description': description, 'image': image};
  }

  // 转换为 constant.dart 中使用的格式
  Map<String, dynamic> toMap() {
    return {'name': name, 'description': description, 'image': image};
  }
}
