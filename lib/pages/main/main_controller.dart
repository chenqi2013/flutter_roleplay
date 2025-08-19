import 'package:get/get.dart';
import 'package:flutter_roleplay/constant/constant.dart';
import 'package:flutter_roleplay/download_dialog.dart';

class MainPageController extends GetxController {
  final RxInt currentIndex = 0.obs;
  final RxInt homeTabIndex = 0.obs; // 跟踪首页内部的Tab索引

  void switchTab(int index) {
    if (index == currentIndex.value) return;
    currentIndex.value = index;
  }

  void setHomeTabIndex(int index) {
    homeTabIndex.value = index;
  }

  // 检查是否应该显示输入框（首页 && 精选Tab）
  bool get shouldShowInput =>
      currentIndex.value == 0 && homeTabIndex.value == 3;

  @override
  void onInit() async {
    // TODO: implement onInit
    super.onInit();
    // 检查是否需要下载模型
    if (!await checkDownloadFile(downloadUrl)) {
      showDownloadDialog(
        Get.context!,
        '需要先下载模型才可以使用角色扮演功能',
        true,
        downloadUrl,
        '',
      );
    }
  }
}
