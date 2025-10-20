import 'package:rwkv_mobile_flutter/types.dart';
import 'package:get/get.dart';

var roleName = ''.obs;
var roleDescription = ''.obs;
var roleImage = ''.obs;
var roleLanguage = ''.obs;

// 聊天状态管理标记
var needsClearStatesOnNextSend = false.obs; // 标记是否需要在下次发送消息时清空聊天状态

// 用户使用过的角色列表（按使用顺序）
var usedRoles = <Map<String, dynamic>>[].obs;

var roles = [].obs;

var downloadUrltest =
    'https://download.rwkvos.com/rwkvmusic/downloads/1.0/test_app.apk';

var downloadUrl =
    'https://hf-mirror.com/mollysama/rwkv-mobile-models/resolve/main/gguf/rwkv7-g1-2.9b-20250519-ctx4096-Q6_K.gguf?download=true';

var downloadUrl11 =
    'https://hf-mirror.com/mollysama/rwkv-mobile-models/resolve/main/qnn/2.35-250705/rwkv7-g1-2.9b-20250519-ctx4096-a16w4-omniquant-8gen3_combined.bin?download=true';

const String pageKey = 'jingxuan_chat';

Backend backend = Backend.llamacpp;

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
