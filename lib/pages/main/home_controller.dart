import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeController extends GetxController with GetSingleTickerProviderStateMixin {
  late TabController tabController;
  
  // 当前选中的tab索引
  final currentIndex = 0.obs;
  
  @override
  void onInit() {
    super.onInit();
    // 初始化TabController,3个tab
    tabController = TabController(length: 3, vsync: this);
    
    // 监听tab切换
    tabController.addListener(() {
      if (!tabController.indexIsChanging) {
        currentIndex.value = tabController.index;
      }
    });
  }
  
  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }
  
  // 切换到指定tab
  void switchTab(int index) {
    if (index >= 0 && index < 3) {
      tabController.animateTo(index);
    }
  }
}
