import 'package:flutter/material.dart';
import 'package:flutter_roleplay/hometabs/roleplay_chat_controller.dart';
import 'package:flutter_roleplay/hometabs/roleplay_chat_page.dart';
import 'package:rwkv_mobile_flutter/types.dart';
import 'package:get/get.dart';

// ///请你扮演名为凯露的角色，你的设定是：
// const String role =
//     '请你扮演名为凯露的角色，你的设定是：猫耳少女，原本是霸瞳皇帝的手下。性格傲娇，嘴上不饶人但内心善良。擅长暗属性魔法，战斗力很强。最初对主人公抱有敌意，但逐渐被美食殿堂的温暖所感动，成为了可靠的伙伴。';
// const String systemPrompt =
//     '请你扮演名为凯露的角色，你的设定是：猫耳少女，原本是霸瞳皇帝的手下。性格傲娇，嘴上不饶人但内心善良。擅长暗属性魔法，战斗力很强。最初对主人公抱有敌意，但逐渐被美食殿堂的温暖所感动，成为了可靠的伙伴。';
// 当前角色信息
var roleName = ''.obs;
var roleDescription = ''.obs;
var roleImage = ''.obs;

// 用户使用过的角色列表（按使用顺序）
var usedRoles = <Map<String, dynamic>>[].obs;

// 初始化默认角色
void initializeDefaultRole() {
  if (roles.isNotEmpty && roleName.value.isEmpty) {
    switchToRole(roles.first);
  }
}

// 切换角色
void switchToRole(Map<String, dynamic> role) {
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
  RolePlayChatController? _controller;
  if (Get.isRegistered<RolePlayChatController>()) {
    _controller = Get.find<RolePlayChatController>();
  } else {
    _controller = Get.put(RolePlayChatController());
  }

  // 清空当前状态（只清空内存，不删除数据库记录）
  _controller?.clearStates();

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

var roles = [
  {
    'name': '白素贞',
    'description':
        '你来自《新白娘子传奇》，你叫白素贞。你是一条修炼千年的蛇仙，为了报答救命之恩，你化为人形来到人间，与许仙相识相爱。然而，因误会而分离的故事情节使得两人的感情曲折离奇，最终有情人终成眷属。',
    'image': 'https://download.rwkvos.com/rwkvmusic/downloads/1.0/role_bg.png',
  },
  {
    'name': '许仙',
    'description':
        '你来自《新白娘子传奇》，你叫许仙。你是一名心地善良的书生，机缘巧合下与白素贞相遇并坠入爱河。尽管面对法海的阻挠和世俗的压力，你始终怀着真挚的感情守护白素贞。',
    'image':
        'https://download.rwkvos.com/rwkvmusic/downloads/1.0/common_bg.png',
  },
  {
    'name': '小青',
    'description':
        '你来自《新白娘子传奇》，你叫小青。你是一条青蛇，白素贞的义妹。你性格刚烈直爽，常常为姐姐出头，也是白素贞在人世间最忠诚的伙伴与依靠。',
    'image':
        'https://download.rwkvos.com/rwkvmusic/downloads/1.0/common_bg.png',
  },
  {
    'name': '法海',
    'description':
        '你来自《新白娘子传奇》，你叫法海。你是金山寺的和尚，自认为维护人间秩序，坚决反对白素贞与许仙的结合。你法力高强，执念深重，常以佛法为名阻挠两人的爱情。',
    'image':
        'https://download.rwkvos.com/rwkvmusic/downloads/1.0/common_bg.png',
  },
  {
    'name': '观音菩萨',
    'description':
        '你来自《新白娘子传奇》，你是观音菩萨。你慈悲为怀，洞察世事，常在关键时刻给予白素贞与许仙点化与帮助，引导他们走向圆满。',
    'image':
        'https://download.rwkvos.com/rwkvmusic/downloads/1.0/common_bg.png',
  },
].obs;
// llamacpp方式

var downloadUrltest =
    'https://download.rwkvos.com/rwkvmusic/downloads/1.0/test_app.apk';

var downloadUrl =
    'https://hf-mirror.com/mollysama/rwkv-mobile-models/resolve/main/gguf/rwkv7-g1-2.9b-20250519-ctx4096-Q6_K.gguf?download=true';

var downloadUrl11 =
    'https://hf-mirror.com/mollysama/rwkv-mobile-models/resolve/main/qnn/2.35-250705/rwkv7-g1-2.9b-20250519-ctx4096-a16w4-omniquant-8gen3_combined.bin?download=true';

const String pageKey = 'jingxuan_chat';

Backend backend =
    Backend.llamacpp; // Restore QNN backend since model is QNN format

final qnnLibList = {
  "libQnnHtp.so",
  "libQnnHtpNetRunExtensions.so",
  "libQnnHtpV68Stub.so",
  "libQnnHtpV69Stub.so",
  "libQnnHtpV73Stub.so",
  "libQnnHtpV75Stub.so",
  "libQnnHtpV79Stub.so",
  "libQnnHtpV68Skel.so",
  "libQnnHtpV69Skel.so",
  "libQnnHtpV73Skel.so",
  "libQnnHtpV75Skel.so",
  "libQnnHtpV79Skel.so",
  "libQnnHtpPrepare.so",
  "libQnnSystem.so",
  "libQnnRwkvWkvOpPackageV68.so",
  "libQnnRwkvWkvOpPackageV69.so",
  "libQnnRwkvWkvOpPackageV73.so",
  "libQnnRwkvWkvOpPackageV75.so",
  "libQnnRwkvWkvOpPackageV79.so",
};
