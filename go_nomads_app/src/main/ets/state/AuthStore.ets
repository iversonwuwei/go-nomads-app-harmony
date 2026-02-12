import { AuthStatus, AuthUser } from '../models/AuthModels';
import { AppStorageKeys } from '../common/constants/AppStorageKeys';

/**
 * 统一封装基于 AppStorage 的全局认证状态读写。
 * 避免各页面重复设置，便于后续扩展（如发事件刷新 UI）。
 */
export class AuthStore {
  private static instance: AuthStore | null = null;

  private constructor() {
  }

  static getInstance(): AuthStore {
    if (!AuthStore.instance) {
      AuthStore.instance = new AuthStore();
    }
    return AuthStore.instance;
  }

  // =====================
  // 读取
  // =====================

  get authStatus(): AuthStatus {
    const status = AppStorage.get<number>(AppStorageKeys.AUTH_STATUS);
    if (status === undefined || status === null) {
      return AuthStatus.Unknown;
    }
    return status as AuthStatus;
  }

  get isAuthenticated(): boolean {
    const value = AppStorage.get<boolean>(AppStorageKeys.IS_AUTHENTICATED);
    return value === true;
  }

  get currentUser(): AuthUser | null {
    const user = AppStorage.get<AuthUser>(AppStorageKeys.CURRENT_USER);
    return user ? user as AuthUser : null;
  }

  // =====================
  // 设置
  // =====================

  setAuthStatus(status: AuthStatus): void {
    AppStorage.set(AppStorageKeys.AUTH_STATUS, status);
    AppStorage.set(AppStorageKeys.IS_AUTHENTICATED, status === AuthStatus.Authenticated);
  }

  setCurrentUser(user: AuthUser | null): void {
    AppStorage.set(AppStorageKeys.CURRENT_USER, user);
  }

  markInitialized(): void {
    AppStorage.set(AppStorageKeys.IS_INITIALIZED, true);
  }

  setCurrentLocale(locale: string): void {
    AppStorage.set(AppStorageKeys.CURRENT_LOCALE, locale);
  }

  setCurrentTab(index: number): void {
    AppStorage.set(AppStorageKeys.CURRENT_TAB_INDEX, index);
  }

  setUnreadNotificationCount(count: number): void {
    AppStorage.set(AppStorageKeys.UNREAD_NOTIFICATION_COUNT, count);
  }

  // =====================
  // 快捷动作
  // =====================

  setAuthenticated(user: AuthUser): void {
    this.setCurrentUser(user);
    this.setAuthStatus(AuthStatus.Authenticated);
  }

  setUnauthenticated(): void {
    this.setCurrentUser(null);
    this.setAuthStatus(AuthStatus.Unauthenticated);
  }
}
