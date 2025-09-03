import 'package:get/get.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'zh_CN': {
      // CreateRolePage 相关翻译
      'create_role_title': '创建新角色',
      'role_name_label': '新角色名称',
      'role_name_hint': '请输入新角色名称',
      'role_language_label': '角色语言',
      'role_language_hint': '此设置会影响角色扮演时输出的语言',
      'role_image_label': '角色头像',
      'role_image_hint': '选择一张图片作为角色头像（可选）',
      'role_description_label': '新角色设定',
      'role_description_hint': '请详细描述新角色的背景、性格、说话方式与边界...',
      'create_role_button': '创建角色',
      'language_chinese': '中文',
      'language_english': 'English',
      'add_image': '添加图片',
      'select_image': '选择图片',
      'remove_image': '移除图片',
      'tap_to_add': '点击添加',
      'image_upload_tips': '点击左侧区域选择一张图片作为角色头像',
      'image_format_support': '支持 JPG、PNG 格式',
      'image_selected': '图片已选择',
      'tap_to_change_or_remove': '点击图片更换，或点击下方按钮移除',

      // 提示信息
      'tip_title': '提示',
      'incomplete_info': '请完整填写角色名称与设定',
      'description_too_long': '角色设定过长，建议精炼至 @count 字以内',
      'language_switch_chinese': '请确认角色名称和角色设定也是使用的中文输入，否则会影响角色扮演效果',
      'language_switch_english': '请确认角色名称和角色设定也是使用的英文输入，否则会影响角色扮演效果',
      'create_success_title': '创建成功',
      'create_success_message': '新角色"@name"已创建并保存到本地',
      'create_failed_title': '创建失败',
      'create_failed_message': '角色创建失败: @error',
      'image_selected_success': '图片选择成功',
      'image_select_failed': '图片选择失败: @error',

      // RolesListPage 相关翻译
      'roles_list_title': '角色列表',
      'loading_roles': '加载中...',
      'load_failed': '加载失败',
      'retry_button': '重试',
      'tap_to_select': '点击选择',
      'offline_mode': '离线模式',
      'cache_loaded': '已从本地缓存加载 @count 个角色',
      'network_failed_cache': '网络连接失败，且本地无缓存数据',

      // RolePlayChat 相关翻译
      'chat_history_cleared': '聊天记录已清空',
      'role_switch_dialog_title': '切换角色',
      'role_switch_dialog_message': 'AI正在回复中，确定要切换到"@name"吗？',
      'confirm': '确定',
      'cancel': '取消',
      'clear_history': '清空历史',
      'change_model': '切换模型',
      'create_role': '创建角色',
      'role_list': '角色列表',

      // 对话框相关翻译
      'confirm_operation': '确认操作',
      'ai_interruption_message': 'AI正在回复中，离开页面将中断回复。\n确定要继续吗？',
      'role_switch_confirm_message': 'AI正在回复中，切换到 "@name" 将中断回复。\n确定要继续吗？',
      'delete_history_title': '确认删除',
      'delete_history_message': '确定要删除当前角色的所有聊天记录吗？',
      'delete_irreversible': '此操作不可恢复',
      'delete': '删除',
    },
    'en_US': {
      // CreateRolePage related translations
      'create_role_title': 'Create New Role',
      'role_name_label': 'Role Name',
      'role_name_hint': 'Please enter role name',
      'role_language_label': 'Role Language',
      'role_language_hint':
          'This setting affects the language output during role-playing',
      'role_image_label': 'Role Avatar',
      'role_image_hint': 'Select an image as role avatar (optional)',
      'role_description_label': 'Role Description',
      'role_description_hint':
          'Please describe the role\'s background, personality, speaking style and boundaries in detail...',
      'create_role_button': 'Create Role',
      'language_chinese': '中文',
      'language_english': 'English',
      'add_image': 'Add Image',
      'select_image': 'Select Image',
      'remove_image': 'Remove Image',
      'tap_to_add': 'Tap to Add',
      'image_upload_tips': 'Tap the left area to select an image as role avatar',
      'image_format_support': 'Supports JPG, PNG formats',
      'image_selected': 'Image Selected',
      'tap_to_change_or_remove': 'Tap image to change, or tap button below to remove',

      // Tips and messages
      'tip_title': 'Tip',
      'incomplete_info': 'Please complete the role name and description',
      'description_too_long':
          'Role description is too long, recommend refining to within @count characters',
      'language_switch_chinese':
          'Please confirm that the role name and description are also in Chinese, otherwise it will affect the role-playing effect',
      'language_switch_english':
          'Please confirm that the role name and description are also in English, otherwise it will affect the role-playing effect',
      'create_success_title': 'Created Successfully',
      'create_success_message':
          'New role "@name" has been created and saved locally',
      'create_failed_title': 'Creation Failed',
      'create_failed_message': 'Role creation failed: @error',
      'image_selected_success': 'Image selected successfully',
      'image_select_failed': 'Image selection failed: @error',

      // RolesListPage related translations
      'roles_list_title': 'Role List',
      'loading_roles': 'Loading...',
      'load_failed': 'Load Failed',
      'retry_button': 'Retry',
      'tap_to_select': 'Tap to Select',
      'offline_mode': 'Offline Mode',
      'cache_loaded': 'Loaded @count roles from local cache',
      'network_failed_cache':
          'Network connection failed and no local cache available',

      // RolePlayChat related translations
      'chat_history_cleared': 'Chat history cleared',
      'role_switch_dialog_title': 'Switch Role',
      'role_switch_dialog_message':
          'AI is replying, are you sure to switch to "@name"?',
      'confirm': 'Confirm',
      'cancel': 'Cancel',
      'clear_history': 'Clear History',
      'change_model': 'Change Model',
      'create_role': 'Create Role',
      'role_list': 'Role List',

      // Dialog related translations
      'confirm_operation': 'Confirm Operation',
      'ai_interruption_message':
          'AI is replying, leaving the page will interrupt the reply.\nAre you sure to continue?',
      'role_switch_confirm_message':
          'AI is replying, switching to "@name" will interrupt the reply.\nAre you sure to continue?',
      'delete_history_title': 'Confirm Delete',
      'delete_history_message':
          'Are you sure to delete all chat records of the current role?',
      'delete_irreversible': 'This operation cannot be undone',
      'delete': 'Delete',
    },
  };
}
