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
  name: string;
  email: string;
  phone?: string;
  avatarUrl?: string;
  bio?: string;
  role: string;
}

interface LoginResponse {
  accessToken: string;
  refreshToken?: string;
  tokenType?: string;
  expiresIn?: number;
  user: LoginResponseUser;
}

class LoginRequestBody {
  email: string = '';
  password: string = '';
}

class SendSmsCodeRequestBody {
  phoneNumber: string = '';
  purpose: string = 'login';
}

class PhoneLoginRequestBody {
  phoneNumber: string = '';
  code: string = '';
}

class SocialLoginRequestBody {
  provider: string = '';
  code?: string;
  accessToken?: string;
  openId?: string;
}

interface SendSmsCodeResponse {
  success: boolean;
  message: string;
  expiresInSeconds?: number;
  requestId?: string;
}

interface RegisterResponseUser {
  id: string;
  name: string;
  email: string;
  role: string;
}

interface RegisterResponse {
  accessToken: string;
  refreshToken?: string;
  tokenType?: string;
  expiresIn?: number;
  user: RegisterResponseUser;
}

class RegisterRequestBody {
  name: string = '';
  email: string = '';
  password: string = '';
}

interface RefreshTokenResponse {
  accessToken: string;
  refreshToken?: string;
  tokenType?: string;
  expiresIn?: number;
  user?: LoginResponseUser;
}

class RefreshTokenRequest {
  refreshToken: string = '';
}

interface MeResponse {
  id: string;
  name: string;
  userName?: string;
  email: string;
  role: string;
  avatarUrl?: string;
  bio?: string;
  phone?: string;
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
    hilog.info(DOMAIN, TAG, '📦 登录响应: accessToken=%{public}s, user.name=%{public}s',
      result.accessToken ? 'YES' : 'NO', result.user?.name ?? 'null');

    const user = this.mapUser(result.user);

    // expiresIn 是秒数，转换为过期时间
    let expiresAt: Date | undefined = undefined;
    if (result.expiresIn) {
      expiresAt = new Date(Date.now() + result.expiresIn * 1000);
    }

    await this.handleAuthSuccess(result.accessToken, result.refreshToken, expiresAt, user, rememberMe ? email : null);
    if (!rememberMe) {
      await this.tokenService.saveRememberMe('', false);
    }
    hilog.info(DOMAIN, TAG, '✅ 登录成功: %{public}s', user.userName);
    return user;
  }

  async sendSmsCode(phoneNumber: string, purpose: string = 'login'): Promise<SendSmsCodeResponse> {
    const body = new SendSmsCodeRequestBody();
    body.phoneNumber = phoneNumber;
    body.purpose = purpose;

    return await this.httpService.post<SendSmsCodeResponse>(ApiConfig.SMS_SEND_CODE_ENDPOINT, body);
  }

  async loginWithPhone(phoneNumber: string, code: string): Promise<AuthUser> {
    const body = new PhoneLoginRequestBody();
    body.phoneNumber = phoneNumber;
    body.code = code;

    const result = await this.httpService.post<LoginResponse>(ApiConfig.PHONE_LOGIN_ENDPOINT, body);
    const user = this.mapUser(result.user);

    let expiresAt: Date | undefined = undefined;
    if (result.expiresIn) {
      expiresAt = new Date(Date.now() + result.expiresIn * 1000);
    }

    await this.handleAuthSuccess(result.accessToken, result.refreshToken, expiresAt, user, null);
    hilog.info(DOMAIN, TAG, '✅ 手机号登录成功: %{public}s', user.userName);
    return user;
  }

  async socialLogin(
    provider: string,
    code?: string,
    accessToken?: string,
    openId?: string
  ): Promise<AuthUser> {
    const body = new SocialLoginRequestBody();
    body.provider = provider;
    if (code) {
      body.code = code;
    }
    if (accessToken) {
      body.accessToken = accessToken;
    }
    if (openId) {
      body.openId = openId;
    }

    const result = await this.httpService.post<LoginResponse>(ApiConfig.SOCIAL_LOGIN_ENDPOINT, body);
    const user = this.mapUser(result.user);

    let expiresAt: Date | undefined = undefined;
    if (result.expiresIn) {
      expiresAt = new Date(Date.now() + result.expiresIn * 1000);
    }

    await this.handleAuthSuccess(result.accessToken, result.refreshToken, expiresAt, user, null);
    hilog.info(DOMAIN, TAG, '✅ 社交登录成功: provider=%{public}s, user=%{public}s', provider, user.userName);
    return user;
  }

  async register(userName: string, email: string, password: string): Promise<AuthUser> {
    const body = new RegisterRequestBody();
    body.name = userName;
    body.email = email;
    body.password = password;

    const result = await this.httpService.post<RegisterResponse>(ApiConfig.REGISTER_ENDPOINT, body);
    const user = this.mapUser(result.user);

    let expiresAt: Date | undefined = undefined;
    if (result.expiresIn) {
      expiresAt = new Date(Date.now() + result.expiresIn * 1000);
    }

    await this.handleAuthSuccess(result.accessToken, result.refreshToken, expiresAt, user, null);
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

      let expiresAt: Date | undefined = undefined;
      if (result.expiresIn) {
        expiresAt = new Date(Date.now() + result.expiresIn * 1000);
      }

      await this.handleAuthSuccess(result.accessToken, result.refreshToken, expiresAt, user, null);
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
    expiresAt: Date | undefined,
    user: AuthUser | null,
    rememberEmail: string | null
  ): Promise<void> {
    await this.tokenService.saveTokens(
      accessToken,
      refreshToken,
      expiresAt
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
    // 后端返回 name 字段，需兼容 userName
    const userName = (user as LoginResponseUser).name ??
      (user as MeResponse).userName ?? '';
    const avatarUrl = (user as LoginResponseUser).avatarUrl ?? undefined;

    const mapped: AuthUser = {
      id: user.id,
      userName: userName,
      email: user.email,
      role: user.role,
    };
    if (avatarUrl) {
      mapped.avatar = avatarUrl;
    }
    return mapped;
  }
}
