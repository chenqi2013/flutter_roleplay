import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'hometabs/roleplay_chat_page.dart';

class Roleplay {
  static Widget createRolePlayChatPage() {
    return GetMaterialApp(home: RolePlayChat());
  }
}
