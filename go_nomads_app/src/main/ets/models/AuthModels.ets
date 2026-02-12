/**
 * 用户认证信息模型
 */
export interface AuthUser {
  id: string;
  userName: string;
  email: string;
  role: string;
  avatar?: string;
}

/**
 * 认证令牌模型
 */
export interface AuthToken {
  accessToken: string;
  refreshToken?: string;
  expiresAt?: string;
}

/**
 * 认证状态类型
 */
export enum AuthStatus {
  /** 未知状态（初始化中） */
  Unknown,
  /** 已认证 */
  Authenticated,
  /** 未认证 */
  Unauthenticated,
}
