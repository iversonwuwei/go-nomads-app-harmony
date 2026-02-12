import { hilog } from '@kit.PerformanceAnalysisKit';
import { router } from '@kit.ArkUI';
import { ApiConfig } from '../common/constants/ApiConfig';
import { AuthStatus, AuthUser } from '../models/AuthModels';
import { HttpService } from './HttpService';
import { TokenStorageService } from './TokenStorageService';
import { AuthStore } from '../state/AuthStore';

const TAG = 'AuthService';
const DOMAIN = 0x0001;

interface LoginResponseUser {
  id: string;
  userName: string;
  email: string;
  role: string;
  avatar?: string;
}

interface LoginResponse {
  token: string;
  refreshToken?: string;
  expiresAt?: string;
  user: LoginResponseUser;
}

class LoginRequestBody {
  email: string = '';
  password: string = '';
}

interface RegisterResponseUser {
  id: string;
  userName: string;
  email: string;
  role: string;
}

interface RegisterResponse {
  token: string;
  refreshToken?: string;
  expiresAt?: string;
  user: RegisterResponseUser;
}

class RegisterRequestBody {
  userName: string = '';
  email: string = '';
  password: string = '';
}

interface RefreshTokenResponse {
  accessToken: string;
  refreshToken?: string;
  expiresAt?: string;
  user?: LoginResponseUser;
}

class RefreshTokenRequest {
  refreshToken: string = '';
}

interface MeResponse {
  id: string;
  userName: string;
  email: string;
  role: string;
  avatar?: string;
}

/**
 * 认证服务：集中处理登录/注册/退出/刷新与全局状态同步。
 */
export class AuthService {
  private static instance: AuthService | null = null;
  private httpService: HttpService;
  private tokenService: TokenStorageService;
  private store: AuthStore;

  private constructor() {
    this.httpService = HttpService.getInstance();
    this.tokenService = TokenStorageService.getInstance();
    this.store = AuthStore.getInstance();

    // 全局 401 回调：清理状态并跳转登录
    this.httpService.onUnauthorized = () => {
      this.clearAuthState();
      router.replaceUrl({ url: `pages/login` });
    };
  }

  static getInstance(): AuthService {
    if (!AuthService.instance) {
      AuthService.instance = new AuthService();
    }
    return AuthService.instance;
  }

  // =====================
  // 登录 / 注册
  // =====================

  async login(email: string, password: string, rememberMe: boolean): Promise<AuthUser> {
    const body = new LoginRequestBody();
    body.email = email;
    body.password = password;

    const result = await this.httpService.post<LoginResponse>(ApiConfig.LOGIN_ENDPOINT, body);
    const user = this.mapUser(result.user);

    await this.handleAuthSuccess(result.token, result.refreshToken, result.expiresAt, user, rememberMe ? email : null);
    hilog.info(DOMAIN, TAG, '✅ 登录成功: %{public}s', user.userName);
    return user;
  }

  async register(userName: string, email: string, password: string): Promise<AuthUser> {
    const body = new RegisterRequestBody();
    body.userName = userName;
    body.email = email;
    body.password = password;

    const result = await this.httpService.post<RegisterResponse>(ApiConfig.REGISTER_ENDPOINT, body);
    const user = this.mapUser(result.user);

    await this.handleAuthSuccess(result.token, result.refreshToken, result.expiresAt, user, null);
    hilog.info(DOMAIN, TAG, '✅ 注册成功: %{public}s', user.userName);
    return user;
  }

  // =====================
  // 退出 / 刷新 / 获取个人信息
  // =====================

  async logout(): Promise<void> {
    try {
      await this.httpService.post<object>(ApiConfig.LOGOUT_ENDPOINT);
    } catch (err) {
      // 退出失败不阻断本地清理
      hilog.warn(DOMAIN, TAG, '⚠️ 退出接口调用失败: %{public}s', JSON.stringify(err));
    }
    await this.clearAuthState();
  }

  async refreshToken(): Promise<boolean> {
    const refreshToken = this.tokenService.getRefreshToken();
    if (!refreshToken) {
      return false;
    }

    const body = new RefreshTokenRequest();
    body.refreshToken = refreshToken;

    try {
      const result = await this.httpService.post<RefreshTokenResponse>(ApiConfig.REFRESH_TOKEN_ENDPOINT, body);
      const user = result.user ? this.mapUser(result.user) : this.store.currentUser;
      await this.handleAuthSuccess(result.accessToken, result.refreshToken, result.expiresAt, user, null);
      hilog.info(DOMAIN, TAG, '✅ Token 刷新成功');
      return true;
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ Token 刷新失败: %{public}s', JSON.stringify(err));
      await this.clearAuthState();
      return false;
    }
  }

  async fetchMe(): Promise<AuthUser | null> {
    try {
      const me = await this.httpService.get<MeResponse>(ApiConfig.USER_ME_ENDPOINT);
      const user = this.mapUser(me);
      this.store.setCurrentUser(user);
      return user;
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ 获取个人信息失败: %{public}s', JSON.stringify(err));
      return null;
    }
  }

  // =====================
  // 内部工具
  // =====================

  private async handleAuthSuccess(
    accessToken: string,
    refreshToken: string | undefined,
    expiresAt: string | undefined,
    user: AuthUser | null,
    rememberEmail: string | null
  ): Promise<void> {
    await this.tokenService.saveTokens(
      accessToken,
      refreshToken,
      expiresAt ? new Date(expiresAt) : undefined
    );

    if (user) {
      await this.tokenService.saveUserInfo(user.id, user.userName, user.email, user.role);
      this.store.setAuthenticated(user);
    } else {
      this.store.setUnauthenticated();
    }

    if (rememberEmail !== null) {
      await this.tokenService.saveRememberMe(rememberEmail, true);
    }
  }

  private async clearAuthState(): Promise<void> {
    await this.tokenService.clearAll();
    this.store.setUnauthenticated();
  }

  private mapUser(user: LoginResponseUser | RegisterResponseUser | MeResponse): AuthUser {
    const mapped: AuthUser = {
      id: user.id,
      userName: user.userName,
      email: user.email,
      role: user.role,
    };
    if ((user as LoginResponseUser).avatar !== undefined) {
      mapped.avatar = (user as LoginResponseUser).avatar;
    }
    return mapped;
  }
}
