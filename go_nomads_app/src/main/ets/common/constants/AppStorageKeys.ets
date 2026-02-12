/**
 * 全局状态 Key 常量
 * 使用 AppStorage 进行全局状态管理 - 对应 Flutter 端 GetX 的全局状态
 */
export class AppStorageKeys {
  /** 认证状态: AuthStatus */
  static readonly AUTH_STATUS: string = 'authStatus';
  /** 当前用户: AuthUser | null */
  static readonly CURRENT_USER: string = 'currentUser';
  /** 是否已认证: boolean */
  static readonly IS_AUTHENTICATED: string = 'isAuthenticated';
  /** 当前语言: string */
  static readonly CURRENT_LOCALE: string = 'currentLocale';
  /** 当前 Tab 索引: number */
  static readonly CURRENT_TAB_INDEX: string = 'currentTabIndex';
  /** 未读通知数: number */
  static readonly UNREAD_NOTIFICATION_COUNT: string = 'unreadNotificationCount';
  /** 是否初始化完成: boolean */
  static readonly IS_INITIALIZED: string = 'isInitialized';
}
