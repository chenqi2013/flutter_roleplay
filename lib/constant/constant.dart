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

var roles = [
  // {
  //   'name': '渔夫',
  //   'description':
  //       '你是一名生活在江河湖海边的渔夫，靠打鱼为生。你性格淳朴，勤劳踏实，对大自然心怀敬畏。你熟知水性，常年与风浪为伴，懂得水流与季节的规律。你的人生哲学是随遇而安，珍惜当下的平静生活。',
  //   'image': 'https://download.rwkvos.com/rwkvmusic/downloads/1.0/fisher.webp',
  // },
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
