/**
 * 应用颜色常量 - 100% 对应 Flutter 端 app_colors.dart
 * 极简性冷淡风格，浅灰色系，避免纯黑色
 */
export class AppColors {
  // ============ 主色调 ============
  /** 背景色 - 极浅灰 #FAFAFA */
  static readonly BACKGROUND: string = '#FAFAFA';
  /** 白色背景 */
  static readonly WHITE: string = '#FFFFFF';
  /** 表面色 */
  static readonly SURFACE: string = '#FFFFFF';
  /** 卡片背景 - 中蓝灰(加深) */
  static readonly CARD_BACKGROUND: string = '#90A4AE';

  // ============ 文本颜色 ============
  /** 深灰色文本 - 主要文本 #616161 */
  static readonly TEXT_PRIMARY: string = '#616161';
  /** 中灰色文本 - 强调文本 #757575 */
  static readonly TEXT_SECONDARY: string = '#757575';
  /** 浅灰色文本 - 次要文本 #9E9E9E */
  static readonly TEXT_TERTIARY: string = '#9E9E9E';
  /** 白色文本 */
  static readonly TEXT_WHITE: string = '#FFFFFF';
  /** 黑色87% - 用于标题 */
  static readonly TEXT_BLACK87: string = '#DD000000';

  // ============ 边框颜色 ============
  /** 主边框颜色 #E0E0E0 */
  static readonly BORDER: string = '#E0E0E0';
  /** 浅边框颜色 #EEEEEE */
  static readonly BORDER_LIGHT: string = '#EEEEEE';

  // ============ 分割线颜色 ============
  /** 主分割线 #EEEEEE */
  static readonly DIVIDER: string = '#EEEEEE';
  /** 浅分割线 #BDBDBD */
  static readonly DIVIDER_LIGHT: string = '#BDBDBD';

  // ============ 强调色 ============
  /** 蓝色强调色 - 选中/激活状态 #1976D2 */
  static readonly ACCENT: string = '#1976D2';

  // ============ City 主题色 / 品牌色 - 红色系 ============
  /** 主色调 = City主色调 - 热情的红色 #FF4458 */
  static readonly PRIMARY: string = '#FF4458';
  /** City 深色 - 按下状态 #E63946 */
  static readonly PRIMARY_DARK: string = '#E63946';
  /** City 浅色 - 背景/次要 #FFE5E8 */
  static readonly PRIMARY_LIGHT: string = '#FFE5E8';
  /** 渐变起始色 #FF4458 */
  static readonly GRADIENT_START: string = '#FF4458';
  /** 渐变结束色 #FF6B7A */
  static readonly GRADIENT_END: string = '#FF6B7A';

  // ============ 图标颜色 ============
  /** 主图标颜色 #757575 */
  static readonly ICON: string = '#757575';
  /** 次要图标颜色 #9E9E9E */
  static readonly ICON_SECONDARY: string = '#9E9E9E';
  /** 浅图标颜色 #BDBDBD */
  static readonly ICON_LIGHT: string = '#BDBDBD';

  // ============ 容器背景色 ============
  /** 深灰容器背景 */
  static readonly CONTAINER_DARK: string = '#757575';
  /** 中灰容器背景 */
  static readonly CONTAINER_MEDIUM: string = '#9E9E9E';
  /** 浅蓝灰容器背景 */
  static readonly CONTAINER_BLUE_GREY: string = '#90A4AE';
  /** 极浅灰容器背景 */
  static readonly CONTAINER_LIGHT: string = '#FAFAFA';

  // ============ 状态色 ============
  /** 成功色 */
  static readonly SUCCESS: string = '#10B981';
  /** 警告色 */
  static readonly WARNING: string = '#F59E0B';
  /** 错误色 */
  static readonly ERROR: string = '#EF4444';
  /** 信息色 */
  static readonly INFO: string = '#3B82F6';

  // ============ 社交登录颜色 ============
  /** 微信绿 #09BB07 */
  static readonly WECHAT_GREEN: string = '#09BB07';
  /** QQ蓝 #12B7F5 */
  static readonly QQ_BLUE: string = '#12B7F5';
  /** 手机绿 #4CAF50 */
  static readonly PHONE_GREEN: string = '#4CAF50';
  /** Google红 #DB4437 */
  static readonly GOOGLE_RED: string = '#DB4437';
  /** Facebook蓝 #1877F2 */
  static readonly FACEBOOK_BLUE: string = '#1877F2';

  // ============ 底部导航 ============
  /** 选中态蓝色 #2196F3 */
  static readonly NAV_SELECTED: string = '#2196F3';
  /** 未选中态灰色 #8E8E93 */
  static readonly NAV_UNSELECTED: string = '#8E8E93';

  // ============ Home 页面特殊色 ============
  /** Hero渐变 暗1 #1a1a2e */
  static readonly HERO_DARK1: string = '#1a1a2e';
  /** Hero渐变 暗2 #16213e */
  static readonly HERO_DARK2: string = '#16213e';
  /** Cities 红 #FF4458 */
  static readonly HOME_CITIES: string = '#FF4458';
  /** Coworks 靛 #6366F1 */
  static readonly HOME_COWORKS: string = '#6366F1';
  /** Meetups 绿 #10B981 */
  static readonly HOME_MEETUPS: string = '#10B981';
  /** Innovation 紫 #8B5CF6 */
  static readonly HOME_INNOVATION: string = '#8B5CF6';
  /** AI卡渐变1 #0F172A */
  static readonly AI_GRADIENT1: string = '#0F172A';
  /** AI卡渐变2 #1E293B */
  static readonly AI_GRADIENT2: string = '#1E293B';
  /** AI卡渐变3 #0EA5E9 */
  static readonly AI_GRADIENT3: string = '#0EA5E9';

  // ============ 聊天颜色(WeChat风格) ============
  /** 聊天背景 #EDEDED */
  static readonly CHAT_BACKGROUND: string = '#EDEDED';
  /** 聊天徽章 #FA5151 */
  static readonly CHAT_BADGE: string = '#FA5151';
  /** 聊天名称 #1A1A1A */
  static readonly CHAT_NAME: string = '#1A1A1A';
  /** 聊天时间 #B2B2B2 */
  static readonly CHAT_TIME: string = '#B2B2B2';
  /** 聊天消息 #999999 */
  static readonly CHAT_MESSAGE: string = '#999999';

  // ============ 输入框灰色 ============
  /** grey.shade50 */
  static readonly GREY50: string = '#FAFAFA';
  /** grey.shade200 */
  static readonly GREY200: string = '#EEEEEE';
  /** grey.shade300 */
  static readonly GREY300: string = '#E0E0E0';
  /** grey.shade600 */
  static readonly GREY600: string = '#757575';
  /** grey.shade700 */
  static readonly GREY700: string = '#616161';

  /** 启动页背景色 */
  static readonly SPLASH_BACKGROUND: string = '#FF4458';
}
