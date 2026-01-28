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
      'duplicate_role_name': '角色名称已存在，请使用不同的名称',

      // RolesListPage 相关翻译
      'roles_list_title': '角色列表',
      'loading_roles': '加载中...',
      'load_failed': '加载失败',
      'retry_button': '重试',
      'tap_to_select': '点击选择',
      'offline_mode': '离线模式',
      'cache_loaded': '已从本地缓存加载 @count 个角色',
      'network_failed_cache': '网络连接失败，且本地无缓存数据',
      'expand': '展开',
      'collapse': '收起',
      'search_roles_hint': '搜索角色名称或描述',
      'no_search_results': '未找到匹配的角色',
      'search_query_hint': '没有找到包含"@query"的角色',
      'clear_search': '清空搜索',

      // RolePlayChat 相关翻译
      'chat_history_cleared': '聊天记录已清空',
      'role_switch_dialog_title': '切换角色',
      'role_switch_dialog_message': 'AI正在回复中，确定要切换到"@name"吗？',
      'confirm': '确定',
      'cancel': '取消',
      'clear_history': '清空历史',
      'change_model': '切换聊天模型',
      'change_tts_model': '切换语音模型',
      'create_role': '创建角色',
      'role_list': '角色列表',

      // 输入框相关翻译
      'ai_replying': 'AI正在回复中...',
      'send_message_to': '发送消息给@name',
      'send_message_to_ai': '发送消息给AI',
      'thinking': '请稍候...',

      // 角色介绍相关翻译
      'introduction': '简介',
      'ai_generated_content': 'AI生成内容，请遵守社区公约',

      // 下载对话框相关翻译
      'downloading': '正在下载中...',
      'download_model': '下载模型文件',
      'download_patience': '文件比较大，请耐心等待下载完成',
      'start_download': '开始下载',

      // 默认聊天内容
      'introduce_yourself': '介绍下自己',

      // 调试信息（虽然用户通常看不到，但为了完整性）
      'message_count_debug': '数据库中@roleName的消息数: @count',

      // 对话框相关翻译
      'confirm_operation': '确认操作',
      'ai_interruption_message': 'AI正在回复中，离开页面将中断回复。\n确定要继续吗？',
      'role_switch_confirm_message': 'AI正在回复中，切换到 "@name" 将中断回复。\n确定要继续吗？',
      'delete_history_title': '确认删除',
      'delete_history_message': '确定要删除当前角色的所有聊天记录吗？',
      'delete_irreversible': '此操作不可恢复',
      'delete': '删除',

      // 删除角色相关翻译
      'delete_confirm_title': '确认删除',
      'delete_role_confirm': '确定要删除角色"@name"吗？\n此操作不可恢复。',
      'delete_success_title': '删除成功',
      'role_deleted_success': '角色"@name"已删除',
      'delete_failed_title': '删除失败',
      'delete_failed_message': '删除失败: @error',
      'cannot_delete_api_role': '无法删除API角色，只能删除自定义角色',
      'cannot_delete_current_role': '无法删除当前正在使用的角色',

      // Role parameters related translations
      'role_params': '角色参数设置',
      'role_params_title': '角色参数设置',
      'reset': '重置',
      'params_info_title': '参数说明',
      'params_info_desc': '调整这些参数可以影响AI角色的回复风格和内容质量。建议根据实际使用效果进行微调。',
      'temperature': '温度 (Temperature)',
      'temperature_desc': '控制回复的随机性和创造性。值越高越随机，值越低越确定。',
      'top_p': 'Top-P',
      'top_p_desc': '控制候选词的累积概率。值越小回复越保守，值越大回复越多样。',
      'presence_penalty': '存在惩罚',
      'presence_penalty_desc': '惩罚重复出现的词汇。值越高越避免重复。',
      'frequency_penalty': '频率惩罚',
      'frequency_penalty_desc': '惩罚高频出现的词汇。值越高越避免重复。',
      'penalty_decay': '惩罚衰减',
      'penalty_decay_desc': '控制惩罚的衰减速度。值越高惩罚衰减越慢。',
      'reset_params_title': '重置参数',
      'reset_params_desc': '确定要将所有参数重置为默认值吗？',
      'params_reset_success': '参数已重置为默认值',
      'apply': '应用',
      'success': '成功',
      'error': '错误',
      'params_applied_success': '参数设置已应用',
      'params_apply_failed': '参数应用失败',
      'model_not_loaded': '模型未加载',
      'edit_role_title': '编辑角色',
      'edit_success_message': '角色"@name"已更新',

      // HomePage 相关翻译
      'chat_tab': '聊天',
      'role_tab': '角色',
      'model_tab': '模型',

      // CreateRolePage 新增翻译
      'role_voice': '角色音色',
      'role_voice_description': '选择角色专属的语音音色（可选）',
      'tap_to_select_voice': '点击选择音色',
      'update_role': '更新角色',

      // RolesListPage 新增翻译
      'roleplay': '扮演',
      'roleplay_description': '请选择你想对话的角色或创建角色。',
      'create_my_role': '创建我的角色',
      'custom': '自定义',
      'edit': '编辑',
      'delete_role_title': '删除角色',
      'delete_role_confirm_text': '确定要删除角色',
      'this_cannot_be_undone': '此操作无法撤销',

      // AudioListPage 相关翻译
      'what_voice_do_you_want': '你希望拥有什么样的声音',
      'no_audio': '暂无音频',

      // AudioListController 相关翻译
      'chinese': '中文',
      'english_lang': '英文',
      'japanese': '日语',
      'error_title': '错误',
      'load_audio_data_failed': '加载音频数据失败',
      'play_audio_failed': '播放音频失败',

      // ModelParamsPage 相关翻译
      'select_chat_model': '选择聊天模型',
      'select_tts_model': '选择语音模型',
      'adjust_here': '在此处调整',
      'model_params_suffix': '模型参数。',
      'not_configured': '未配置',
      'tts_language_label': 'TTS语言',
      'decoding_params': '解码参数',
      'gear_mode': '档位模式',
      'detailed_params': '详细参数',
      'temperature_label': '温度',
      'top_p_label': 'Top P',
      'presence_penalty_label': '存在惩罚',
      'frequency_penalty_label': '频率惩罚',
      'penalty_decay_label': '惩罚衰减',
      'select_voice_timbre': '选择音色',
      'save_configuration': '保存以上配置',

      // ModelParamsController 相关翻译
      'save_success_title': '保存成功',
      'model_params_saved': '模型参数配置已保存',
      'save_failed_title': '保存失败',
      'unable_to_save_config': '无法保存配置',
      'load_failed_title': '加载失败',
      'unable_to_load_model_info': '无法加载模型信息',
      'preset_crazy': '狂想曲',
      'preset_boiling': '沸腾',
      'preset_daily': '日常',
      'preset_restrained': '克制',
      'preset_blank': '留白',
      'style_boring': '无聊的',
      'style_crazy': '疯狂的',
      'style_normal': '正常人类',

      // RolePlayChatPage 相关翻译
      'unable_to_regenerate': '无法重新生成',
      'cannot_find_user_message': '找不到对应的用户消息，无法重新生成回复。',
      'confirm_button': '确定',

      // RolesListController 相关翻译
      'no_local_cache': '无本地缓存',
      'just_now': '刚刚',
      'cache_cleared': '已清空本地角色缓存',
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
      'image_upload_tips':
          'Tap the left area to select an image as role avatar',
      'image_format_support': 'Supports JPG, PNG formats',
      'image_selected': 'Image Selected',
      'tap_to_change_or_remove':
          'Tap image to change, or tap button below to remove',

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
      'duplicate_role_name':
          'Role name already exists, please use a different name',

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
      'expand': 'Expand',
      'collapse': 'Collapse',
      'search_roles_hint': 'Search role name or description',
      'no_search_results': 'No matching roles found',
      'search_query_hint': 'No roles found containing "@query"',
      'clear_search': 'Clear Search',

      // RolePlayChat related translations
      'chat_history_cleared': 'Chat history cleared',
      'role_switch_dialog_title': 'Switch Role',
      'role_switch_dialog_message':
          'AI is replying, are you sure to switch to "@name"?',
      'confirm': 'Confirm',
      'cancel': 'Cancel',
      'clear_history': 'Clear History',
      'change_model': 'Change Chat Model',
      'change_tts_model': 'Change TTS Model',
      'create_role': 'Create Role',
      'role_list': 'Role List',

      // Input bar related translations
      'ai_replying': 'AI is replying...',
      'send_message_to': 'Send message to @name',
      'send_message_to_ai': 'Send message to AI',
      'thinking': 'Waiting...',

      // Character introduction related translations
      'introduction': 'Introduction',
      'ai_generated_content':
          'AI generated content, please follow community guidelines',

      // Download dialog related translations
      'downloading': 'Downloading...',
      'download_model': 'Download Model File',
      'download_patience':
          'File is large, please wait patiently for download to complete',
      'start_download': 'Start Download',

      // Default chat content
      'introduce_yourself': 'Introduce yourself',

      // Debug info (though users usually don't see it, for completeness)
      'message_count_debug': 'Message count for @roleName in database: @count',

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

      // Delete role related translations
      'delete_confirm_title': 'Confirm Delete',
      'delete_role_confirm':
          'Are you sure to delete role "@name"?\nThis operation cannot be undone.',
      'delete_success_title': 'Delete Successful',
      'role_deleted_success': 'Role "@name" has been deleted',
      'delete_failed_title': 'Delete Failed',
      'delete_failed_message': 'Delete failed: @error',
      'cannot_delete_api_role':
          'Cannot delete API roles, only custom roles can be deleted',
      'cannot_delete_current_role': 'Cannot delete the role currently in use',

      // Role parameters related translations
      'role_params': 'Role Parameters',
      'role_params_title': 'Role Parameters',
      'reset': 'Reset',
      'params_info_title': 'Parameter Info',
      'params_info_desc':
          'Adjusting these parameters can affect the AI role\'s response style and content quality. It is recommended to fine-tune based on actual usage effects.',
      'temperature': 'Temperature',
      'temperature_desc':
          'Controls the randomness and creativity of responses. Higher values are more random, lower values are more deterministic.',
      'top_p': 'Top-P',
      'top_p_desc':
          'Controls the cumulative probability of candidate words. Smaller values make responses more conservative, larger values make responses more diverse.',
      'presence_penalty': 'Presence Penalty',
      'presence_penalty_desc':
          'Penalizes repeated words. Higher values avoid more repetition.',
      'frequency_penalty': 'Frequency Penalty',
      'frequency_penalty_desc':
          'Penalizes frequently occurring words. Higher values avoid more repetition.',
      'penalty_decay': 'Penalty Decay',
      'penalty_decay_desc':
          'Controls the decay rate of penalties. Higher values make penalties decay slower.',
      'reset_params_title': 'Reset Parameters',
      'reset_params_desc':
          'Are you sure you want to reset all parameters to default values?',
      'params_reset_success': 'Parameters have been reset to default values',
      'apply': 'Apply',
      'success': 'Success',
      'error': 'Error',
      'params_applied_success': 'Parameters have been applied successfully',
      'params_apply_failed': 'Failed to apply parameters',
      'model_not_loaded': 'Model not loaded',
      'edit_role_title': 'Edit Role',
      'edit_success_message': 'Role "@name" has been updated',

      // HomePage related translations
      'chat_tab': 'Chat',
      'role_tab': 'Role',
      'model_tab': 'Model',

      // CreateRolePage new translations
      'role_voice': 'Role Voice',
      'role_voice_description':
          'Select a voice timbre for this role (optional)',
      'tap_to_select_voice': 'Tap to select voice',
      'update_role': 'Update Role',

      // RolesListPage new translations
      'roleplay': 'Roleplay',
      'roleplay_description':
          'Please select a role to chat with or create a new role.',
      'create_my_role': 'Create My Role',
      'custom': 'Custom',
      'edit': 'Edit',
      'delete_role_title': 'Delete Role',
      'delete_role_confirm_text': 'Are you sure to delete role',
      'this_cannot_be_undone': 'This operation cannot be undone',

      // AudioListPage related translations
      'what_voice_do_you_want': 'What kind of voice do you want',
      'no_audio': 'No audio available',

      // AudioListController related translations
      'chinese': 'Chinese',
      'english_lang': 'English',
      'japanese': 'Japanese',
      'error_title': 'Error',
      'load_audio_data_failed': 'Failed to load audio data',
      'play_audio_failed': 'Failed to play audio',

      // ModelParamsPage related translations
      'select_chat_model': 'Select Chat Model',
      'select_tts_model': 'Select TTS Model',
      'adjust_here': 'Adjust here',
      'model_params_suffix': 'model parameters.',
      'not_configured': 'Not configured',
      'tts_language_label': 'TTS Language',
      'decoding_params': 'Decoding Parameters',
      'gear_mode': 'Gear Mode',
      'detailed_params': 'Detailed Parameters',
      'temperature_label': 'Temperature',
      'top_p_label': 'Top P',
      'presence_penalty_label': 'Presence Penalty',
      'frequency_penalty_label': 'Frequency Penalty',
      'penalty_decay_label': 'Penalty Decay',
      'select_voice_timbre': 'Select Voice',
      'save_configuration': 'Save Configuration',

      // ModelParamsController related translations
      'save_success_title': 'Save Successful',
      'model_params_saved': 'Model parameters configuration has been saved',
      'save_failed_title': 'Save Failed',
      'unable_to_save_config': 'Unable to save configuration',
      'load_failed_title': 'Load Failed',
      'unable_to_load_model_info': 'Unable to load model information',
      'preset_crazy': 'Rhapsody',
      'preset_boiling': 'Boiling',
      'preset_daily': 'Daily',
      'preset_restrained': 'Restrained',
      'preset_blank': 'Blank',
      'style_boring': 'Boring',
      'style_crazy': 'Crazy',
      'style_normal': 'Normal',

      // RolePlayChatPage related translations
      'unable_to_regenerate': 'Unable to Regenerate',
      'cannot_find_user_message':
          'Cannot find the corresponding user message, unable to regenerate response.',
      'confirm_button': 'Confirm',

      // RolesListController related translations
      'no_local_cache': 'No local cache',
      'just_now': 'Just now',
      'cache_cleared': 'Local role cache has been cleared',
    },
  };
}
