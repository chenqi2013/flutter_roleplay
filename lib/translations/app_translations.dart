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
      'role_description_label': '新角色设定',
      'role_description_hint': '请详细描述新角色的背景、性格、说话方式与边界...',
      'create_role_button': '创建角色',
      'language_chinese': '中文',
      'language_english': 'English',

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
    },
    'en_US': {
      // CreateRolePage related translations
      'create_role_title': 'Create New Role',
      'role_name_label': 'Role Name',
      'role_name_hint': 'Please enter role name',
      'role_language_label': 'Role Language',
      'role_language_hint':
          'This setting affects the language output during role-playing',
      'role_description_label': 'Role Description',
      'role_description_hint':
          'Please describe the role\'s background, personality, speaking style and boundaries in detail...',
      'create_role_button': 'Create Role',
      'language_chinese': '中文',
      'language_english': 'English',

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
    },
  };
}
