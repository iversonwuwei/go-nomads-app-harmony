import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { ApiConfig } from '../common/constants/ApiConfig';

const TAG = 'TokenStorageService';
const DOMAIN = 0x0001;
const PREFERENCES_NAME = 'go_nomads_auth';

/**
 * Token 持久化存储服务 - 对应 Flutter 端 token_storage_service.dart
 * 使用鸿蒙 Preferences 实现 token 和用户信息的持久化
 */
export class TokenStorageService {
  private static instance: TokenStorageService | null = null;
  private prefs: preferences.Preferences | null = null;
  private context: common.UIAbilityContext | null = null;

  // Keys
  private static readonly USER_ROLE_KEY = 'user_role';
  private static readonly USER_ID_KEY = 'user_id';
  private static readonly USER_NAME_KEY = 'user_name';
  private static readonly USER_EMAIL_KEY = 'user_email';
  private static readonly TOKEN_EXPIRES_AT_KEY = 'token_expires_at';
  private static readonly REMEMBER_ME_KEY = 'remember_me';
  private static readonly SAVED_EMAIL_KEY = 'saved_email';

  private constructor() {
  }

  /** 获取单例 */
  static getInstance(): TokenStorageService {
    if (!TokenStorageService.instance) {
      TokenStorageService.instance = new TokenStorageService();
    }
    return TokenStorageService.instance;
  }

  /** 绑定上下文（不立即初始化，用于懒加载） */
  bindContext(context: common.UIAbilityContext): void {
    this.context = context;
  }

  /** 是否已完成初始化 */
  isInitialized(): boolean {
    return this.prefs !== null;
  }

  /**
   * 初始化 Preferences（需在 Ability 中调用）
   */
  async init(context: common.UIAbilityContext): Promise<void> {
    this.bindContext(context);
    try {
      this.prefs = preferences.getPreferencesSync(context, { name: PREFERENCES_NAME });
      hilog.info(DOMAIN, TAG, 'Preferences initialized successfully');
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to init preferences: %{public}s', JSON.stringify(err));
      throw new Error('TokenStorageService init failed');
    }
  }

  private ensureInitialized(): void {
    if (this.prefs) {
      return;
    }

    if (!this.context) {
      throw new Error('TokenStorageService context not bound. Call init()/bindContext() first.');
    }

    try {
      this.prefs = preferences.getPreferencesSync(this.context, { name: PREFERENCES_NAME });
      hilog.info(DOMAIN, TAG, 'Preferences lazy-initialized successfully');
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to lazy-init preferences: %{public}s', JSON.stringify(err));
      throw new Error('TokenStorageService lazy init failed');
    }
  }

  private getPrefs(): preferences.Preferences {
    this.ensureInitialized();
    if (!this.prefs) {
      throw new Error('TokenStorageService preferences unavailable after init.');
    }
    return this.prefs;
  }

  // ============================================================
  // Token 操作
  // ============================================================

  /** 保存访问令牌和刷新令牌 */
  async saveTokens(accessToken: string, refreshToken?: string, expiresAt?: Date): Promise<void> {
    let prefs: preferences.Preferences;
    try {
      prefs = this.getPrefs();
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'saveTokens skipped, prefs unavailable: %{public}s', JSON.stringify(err));
      return;
    }
    prefs.putSync(ApiConfig.AUTH_TOKEN_KEY, accessToken);

    if (refreshToken) {
      prefs.putSync(ApiConfig.REFRESH_TOKEN_KEY, refreshToken);
    } else {
      prefs.deleteSync(ApiConfig.REFRESH_TOKEN_KEY);
    }

    if (expiresAt) {
      prefs.putSync(TokenStorageService.TOKEN_EXPIRES_AT_KEY, expiresAt.toISOString());
    } else {
      prefs.deleteSync(TokenStorageService.TOKEN_EXPIRES_AT_KEY);
    }

    await prefs.flush();
    hilog.info(DOMAIN, TAG, 'Tokens saved');
  }

  /** 保存用户信息 */
  async saveUserInfo(userId: string, userName: string, userEmail: string, userRole: string): Promise<void> {
    let prefs: preferences.Preferences;
    try {
      prefs = this.getPrefs();
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'saveUserInfo skipped, prefs unavailable: %{public}s', JSON.stringify(err));
      return;
    }
    prefs.putSync(TokenStorageService.USER_ID_KEY, userId);
    prefs.putSync(TokenStorageService.USER_NAME_KEY, userName);
    prefs.putSync(TokenStorageService.USER_EMAIL_KEY, userEmail);
    prefs.putSync(TokenStorageService.USER_ROLE_KEY, userRole);
    await prefs.flush();
    hilog.info(DOMAIN, TAG, 'User info saved');
  }

  /** 读取访问令牌 */
  getAccessToken(): string | null {
    try {
      const token = this.getPrefs().getSync(ApiConfig.AUTH_TOKEN_KEY, '') as string;
      return token || null;
    } catch {
      return null;
    }
  }

  /** 读取刷新令牌 */
  getRefreshToken(): string | null {
    try {
      const token = this.getPrefs().getSync(ApiConfig.REFRESH_TOKEN_KEY, '') as string;
      return token || null;
    } catch {
      return null;
    }
  }

  /** 读取用户 ID */
  getUserId(): string | null {
    try {
      const id = this.getPrefs().getSync(TokenStorageService.USER_ID_KEY, '') as string;
      return id || null;
    } catch {
      return null;
    }
  }

  /** 读取用户名称 */
  getUserName(): string | null {
    try {
      const name = this.getPrefs().getSync(TokenStorageService.USER_NAME_KEY, '') as string;
      return name || null;
    } catch {
      return null;
    }
  }

  /** 读取用户邮箱 */
  getUserEmail(): string | null {
    try {
      const email = this.getPrefs().getSync(TokenStorageService.USER_EMAIL_KEY, '') as string;
      return email || null;
    } catch {
      return null;
    }
  }

  /** 读取用户角色 */
  getUserRole(): string | null {
    try {
      const role = this.getPrefs().getSync(TokenStorageService.USER_ROLE_KEY, '') as string;
      return role || null;
    } catch {
      return null;
    }
  }

  /** 读取 Token 过期时间 */
  getTokenExpiresAt(): Date | null {
    try {
      const expiresAtStr = this.getPrefs().getSync(TokenStorageService.TOKEN_EXPIRES_AT_KEY, '') as string;
      return expiresAtStr ? new Date(expiresAtStr) : null;
    } catch {
      return null;
    }
  }

  /** 检查 Token 是否已过期 */
  isTokenExpired(): boolean {
    const expiresAt = this.getTokenExpiresAt();
    if (!expiresAt) {
      return true;
    }
    return new Date() >= expiresAt;
  }

  /** 检查是否有有效的认证信息 */
  hasValidAuth(): boolean {
    const token = this.getAccessToken();
    return token !== null && !this.isTokenExpired();
  }

  // ============================================================
  // 记住我
  // ============================================================

  /** 保存记住我设置 */
  async saveRememberMe(email: string, remember: boolean): Promise<void> {
    let prefs: preferences.Preferences;
    try {
      prefs = this.getPrefs();
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'saveRememberMe skipped, prefs unavailable: %{public}s', JSON.stringify(err));
      return;
    }
    prefs.putSync(TokenStorageService.REMEMBER_ME_KEY, remember);
    if (remember) {
      prefs.putSync(TokenStorageService.SAVED_EMAIL_KEY, email);
    } else {
      prefs.deleteSync(TokenStorageService.SAVED_EMAIL_KEY);
    }
    await prefs.flush();
  }

  /** 获取已保存的邮箱 */
  getSavedEmail(): string | null {
    try {
      const email = this.getPrefs().getSync(TokenStorageService.SAVED_EMAIL_KEY, '') as string;
      return email || null;
    } catch {
      return null;
    }
  }

  /** 是否记住我 */
  isRememberMe(): boolean {
    try {
      return this.getPrefs().getSync(TokenStorageService.REMEMBER_ME_KEY, false) as boolean;
    } catch {
      return false;
    }
  }

  // ============================================================
  // 清除
  // ============================================================

  /** 清除所有认证信息 */
  async clearAll(): Promise<void> {
    let prefs: preferences.Preferences;
    try {
      prefs = this.getPrefs();
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'clearAll skipped, prefs unavailable: %{public}s', JSON.stringify(err));
      return;
    }
    // 保留记住我设置
    const rememberMe = this.isRememberMe();
    const savedEmail = this.getSavedEmail();

    prefs.deleteSync(ApiConfig.AUTH_TOKEN_KEY);
    prefs.deleteSync(ApiConfig.REFRESH_TOKEN_KEY);
    prefs.deleteSync(TokenStorageService.USER_ID_KEY);
    prefs.deleteSync(TokenStorageService.USER_NAME_KEY);
    prefs.deleteSync(TokenStorageService.USER_EMAIL_KEY);
    prefs.deleteSync(TokenStorageService.USER_ROLE_KEY);
    prefs.deleteSync(TokenStorageService.TOKEN_EXPIRES_AT_KEY);

    // 恢复记住我设置
    if (rememberMe && savedEmail) {
      prefs.putSync(TokenStorageService.REMEMBER_ME_KEY, true);
      prefs.putSync(TokenStorageService.SAVED_EMAIL_KEY, savedEmail);
    }

    await prefs.flush();
    hilog.info(DOMAIN, TAG, 'Auth data cleared');
  }
}
