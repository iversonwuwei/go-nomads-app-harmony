import { hilog } from '@kit.PerformanceAnalysisKit';
import { TokenStorageService } from '../services/TokenStorageService';
import { AuthUser, AuthStatus } from '../models/AuthModels';
import { AppStorageKeys } from '../common/constants/AppStorageKeys';
import { AuthStore } from '../state/AuthStore';
import { AuthService } from './AuthService';

const TAG = 'AppInitService';
const DOMAIN = 0x0001;

/**
 * 应用初始化服务 - 对应 Flutter 端 app_init_service.dart
 * 负责初始化全局状态、恢复登录状态
 */
export class AppInitService {
  private static instance: AppInitService | null = null;

  static getInstance(): AppInitService {
    if (!AppInitService.instance) {
      AppInitService.instance = new AppInitService();
    }
    return AppInitService.instance;
  }

  /**
   * 初始化应用 - 恢复登录状态
   */
  async initialize(): Promise<void> {
    hilog.info(DOMAIN, TAG, '🎯 开始应用初始化...');

    // 初始化全局状态默认值
    this.initializeAppStorage();

    // 初始化认证服务（设置全局 401 回调）
    AuthService.getInstance();

    // 尝试恢复登录状态
    await this.restoreAuthState();

    hilog.info(DOMAIN, TAG, '✅ 应用初始化完成');
  }

  /**
   * 初始化 AppStorage 默认值
   */
  private initializeAppStorage(): void {
    AppStorage.setOrCreate(AppStorageKeys.AUTH_STATUS, AuthStatus.Unknown);
    AppStorage.setOrCreate(AppStorageKeys.IS_AUTHENTICATED, false);
    AppStorage.setOrCreate(AppStorageKeys.CURRENT_TAB_INDEX, 0);
    AppStorage.setOrCreate(AppStorageKeys.UNREAD_NOTIFICATION_COUNT, 0);
    AppStorage.setOrCreate(AppStorageKeys.IS_INITIALIZED, false);
    AppStorage.setOrCreate(AppStorageKeys.CURRENT_LOCALE, 'zh-CN');
  }

  /**
   * 恢复认证状态
   */
  private async restoreAuthState(): Promise<void> {
    const tokenService = TokenStorageService.getInstance();

    try {
      const token = tokenService.getAccessToken();
      if (!token) {
        hilog.info(DOMAIN, TAG, '📱 没有保存的 Token，用户未登录');
        AuthStore.getInstance().setUnauthenticated();
        return;
      }

      // 检查 Token 是否过期
      if (tokenService.isTokenExpired()) {
        hilog.info(DOMAIN, TAG, '⏰ Token 已过期，尝试刷新...');
        const refreshed = await AuthService.getInstance().refreshToken();
        if (!refreshed) {
          hilog.info(DOMAIN, TAG, '❌ Token 刷新失败，清除认证');
          await tokenService.clearAll();
          AuthStore.getInstance().setUnauthenticated();
          return;
        }
      }

      // Token 有效，恢复用户信息
      const userId = tokenService.getUserId();
      const userName = tokenService.getUserName();
      const userEmail = tokenService.getUserEmail();
      const userRole = tokenService.getUserRole();

      if (userId && userName && userEmail) {
        const user: AuthUser = {
          id: userId,
          userName: userName,
          email: userEmail,
          role: userRole ?? 'user',
        };
        AuthStore.getInstance().setAuthenticated(user);
        hilog.info(DOMAIN, TAG, '✅ 登录状态恢复成功: %{public}s', userName);
      } else {
        hilog.warn(DOMAIN, TAG, '⚠️ Token 有效但用户信息不完整');
        AuthStore.getInstance().setUnauthenticated();
      }
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ 恢复认证状态失败: %{public}s', JSON.stringify(err));
      AuthStore.getInstance().setUnauthenticated();
    }
  }
}
