import { hilog } from '@kit.PerformanceAnalysisKit';
import { TokenStorageService } from '../services/TokenStorageService';
import { HttpService } from '../services/HttpService';
import { ApiConfig } from '../common/constants/ApiConfig';
import { AuthUser, AuthStatus } from '../models/AuthModels';
import { AppStorageKeys } from '../common/constants/AppStorageKeys';

const TAG = 'AppInitService';
const DOMAIN = 0x0001;

/**
 * Token 刷新响应
 */
interface RefreshTokenResponse {
  accessToken: string;
  refreshToken?: string;
  expiresAt?: string;
}

/**
 * Token 刷新请求体
 */
class RefreshTokenRequest {
  refreshToken: string = '';
}

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
        AppStorage.set(AppStorageKeys.AUTH_STATUS, AuthStatus.Unauthenticated);
        return;
      }

      // 检查 Token 是否过期
      if (tokenService.isTokenExpired()) {
        hilog.info(DOMAIN, TAG, '⏰ Token 已过期，尝试刷新...');
        const refreshed = await this.tryRefreshToken();
        if (!refreshed) {
          hilog.info(DOMAIN, TAG, '❌ Token 刷新失败，清除认证');
          await tokenService.clearAll();
          AppStorage.set(AppStorageKeys.AUTH_STATUS, AuthStatus.Unauthenticated);
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
        AppStorage.set(AppStorageKeys.CURRENT_USER, user);
        AppStorage.set(AppStorageKeys.IS_AUTHENTICATED, true);
        AppStorage.set(AppStorageKeys.AUTH_STATUS, AuthStatus.Authenticated);
        hilog.info(DOMAIN, TAG, '✅ 登录状态恢复成功: %{public}s', userName);
      } else {
        hilog.warn(DOMAIN, TAG, '⚠️ Token 有效但用户信息不完整');
        AppStorage.set(AppStorageKeys.AUTH_STATUS, AuthStatus.Unauthenticated);
      }
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ 恢复认证状态失败: %{public}s', JSON.stringify(err));
      AppStorage.set(AppStorageKeys.AUTH_STATUS, AuthStatus.Unauthenticated);
    }
  }

  /**
   * 尝试刷新 Token
   */
  private async tryRefreshToken(): Promise<boolean> {
    const tokenService = TokenStorageService.getInstance();
    const refreshToken = tokenService.getRefreshToken();

    if (!refreshToken) {
      return false;
    }

    try {
      const httpService = HttpService.getInstance();
      const reqBody = new RefreshTokenRequest();
      reqBody.refreshToken = refreshToken;
      const result = await httpService.post<RefreshTokenResponse>(
        ApiConfig.REFRESH_TOKEN_ENDPOINT, reqBody);

      if (result.accessToken) {
        await tokenService.saveTokens(
          result.accessToken,
          result.refreshToken,
          result.expiresAt ? new Date(result.expiresAt) : undefined
        );
        hilog.info(DOMAIN, TAG, '✅ Token 刷新成功');
        return true;
      }
      return false;
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ Token 刷新失败: %{public}s', JSON.stringify(err));
      return false;
    }
  }
}
