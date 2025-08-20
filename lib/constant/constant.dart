import 'package:rwkv_mobile_flutter/types.dart';
import 'package:get/get.dart';

// ///请你扮演名为凯露的角色，你的设定是：
// const String role =
//     '请你扮演名为凯露的角色，你的设定是：猫耳少女，原本是霸瞳皇帝的手下。性格傲娇，嘴上不饶人但内心善良。擅长暗属性魔法，战斗力很强。最初对主人公抱有敌意，但逐渐被美食殿堂的温暖所感动，成为了可靠的伙伴。';
// const String systemPrompt =
//     '请你扮演名为凯露的角色，你的设定是：猫耳少女，原本是霸瞳皇帝的手下。性格傲娇，嘴上不饶人但内心善良。擅长暗属性魔法，战斗力很强。最初对主人公抱有敌意，但逐渐被美食殿堂的温暖所感动，成为了可靠的伙伴。';
var roleName = '白素贞'.obs;
var roleDescription =
    '你来自《新白娘子传奇》，你叫白素贞。你是一条修炼千年的蛇仙，为了报答救命之恩，你化为人形来到人间，与许仙相识相爱。然而，因误会而分离的故事情节使得两人的感情曲折离奇，最终有情人终成眷属。'
        .obs;

var roles = [
  {
    'name': '白素贞',
    'description':
        '你来自《新白娘子传奇》，你叫白素贞。你是一条修炼千年的蛇仙，为了报答救命之恩，你化为人形来到人间，与许仙相识相爱。然而，因误会而分离的故事情节使得两人的感情曲折离奇，最终有情人终成眷属。',
  },
  {
    'name': '许仙',
    'description':
        '你来自《新白娘子传奇》，你叫许仙。你是一名心地善良的书生，机缘巧合下与白素贞相遇并坠入爱河。尽管面对法海的阻挠和世俗的压力，你始终怀着真挚的感情守护白素贞。',
  },
  {
    'name': '小青',
    'description':
        '你来自《新白娘子传奇》，你叫小青。你是一条青蛇，白素贞的义妹。你性格刚烈直爽，常常为姐姐出头，也是白素贞在人世间最忠诚的伙伴与依靠。',
  },
  {
    'name': '法海',
    'description':
        '你来自《新白娘子传奇》，你叫法海。你是金山寺的和尚，自认为维护人间秩序，坚决反对白素贞与许仙的结合。你法力高强，执念深重，常以佛法为名阻挠两人的爱情。',
  },
  {
    'name': '观音菩萨',
    'description':
        '你来自《新白娘子传奇》，你是观音菩萨。你慈悲为怀，洞察世事，常在关键时刻给予白素贞与许仙点化与帮助，引导他们走向圆满。',
  },
].obs;
// llamacpp方式
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
