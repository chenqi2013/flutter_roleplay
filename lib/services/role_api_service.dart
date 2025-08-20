import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_roleplay/models/role_model.dart';

class RoleApiService {
  static const String baseUrl = 'https://api.codecrack.cn/api/v1';

  static Future<List<RoleModel>> getRoles() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/role'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final roleResponse = RoleResponse.fromJson(jsonData);

        if (roleResponse.code == 200) {
          return roleResponse.data;
        } else {
          throw Exception('API Error: ${roleResponse.message}');
        }
      } else {
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load roles: $e');
    }
  }
}
