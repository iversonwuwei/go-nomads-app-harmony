import { http } from '@kit.NetworkKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { ApiConfig } from '../common/constants/ApiConfig';
import { TokenStorageService } from './TokenStorageService';

const TAG = 'HttpService';
const DOMAIN = 0x0001;

/**
 * API 响应元数据
 */
export interface ApiResponseMeta {
  success: boolean;
  message: string;
  errors: string[];
  statusCode?: number;
}

/**
 * API 统一响应包装
 */
export interface ApiResponse<T = object> {
  success: boolean;
  message: string;
  data: T;
  errors?: string[];
}

/**
 * HTTP 请求配置
 */
export interface RequestOptions {
  /** 请求头 */
  headers?: Record<string, string>;
  /** 查询参数 */
  queryParams?: Record<string, string>;
  /** 是否禁用 API 响应解包 */
  disableUnwrap?: boolean;
  /** 超时时间(毫秒) */
  timeout?: number;
}

/**
 * HTTP 服务 - 对应 Flutter 端 http_service.dart
 * 基于鸿蒙 @kit.NetworkKit 封装
 */
export class HttpService {
  private static instance: HttpService | null = null;
  private isRedirectingToLogin: boolean = false;

  /** 401 事件回调，由外部设置以处理跳转登录等逻辑 */
  onUnauthorized: (() => void) | null = null;

  private constructor() {
  }

  static getInstance(): HttpService {
    if (!HttpService.instance) {
      HttpService.instance = new HttpService();
    }
    return HttpService.instance;
  }

  // ============================================================
  // 公共请求方法
  // ============================================================

  /** GET 请求 */
  async get<T>(endpoint: string, options?: RequestOptions): Promise<T> {
    return this.request<T>('GET', endpoint, undefined, options);
  }

  /** POST 请求 */
  async post<T>(endpoint: string, data?: object, options?: RequestOptions): Promise<T> {
    return this.request<T>('POST', endpoint, data, options);
  }

  /** PUT 请求 */
  async put<T>(endpoint: string, data?: object, options?: RequestOptions): Promise<T> {
    return this.request<T>('PUT', endpoint, data, options);
  }

  /** DELETE 请求 */
  async delete<T>(endpoint: string, options?: RequestOptions): Promise<T> {
    return this.request<T>('DELETE', endpoint, undefined, options);
  }

  /** PATCH 请求 */
  async patch<T>(endpoint: string, data?: object, options?: RequestOptions): Promise<T> {
    return this.request<T>('PATCH', endpoint, data, options);
  }

  // ============================================================
  // 核心请求实现
  // ============================================================

  private async request<T>(
    method: string,
    endpoint: string,
    data?: object,
    options?: RequestOptions
  ): Promise<T> {
    const startTime = Date.now();
    const url = this.buildFullUrl(endpoint, options?.queryParams);

    // 构建请求头 (ArkTS 不支持 spread 运算符)
    let headers: Record<string, string> = {};
    headers['Content-Type'] = 'application/json';
    headers['Accept'] = 'application/json';
    if (options?.headers) {
      const headerKeys = Object.keys(options.headers);
      for (let i = 0; i < headerKeys.length; i++) {
        headers[headerKeys[i]] = options.headers[headerKeys[i]];
      }
    }

    // 添加认证 Token
    const tokenService = TokenStorageService.getInstance();
    const token = tokenService.getAccessToken();
    if (token) {
      headers['Authorization'] = `Bearer ${token}`;
    }

    // 添加用户 ID
    const userId = tokenService.getUserId();
    if (userId) {
      headers['X-User-Id'] = userId;
    }

    // HTTP 方法重写
    let actualMethod = method;
    if (ApiConfig.USE_HTTP_METHOD_OVERRIDE) {
      const upperMethod = method.toUpperCase();
      if (upperMethod === 'PUT' || upperMethod === 'DELETE' || upperMethod === 'PATCH') {
        hilog.debug(DOMAIN, TAG, 'HTTP Method Override: %{public}s -> POST', method);
        headers['X-HTTP-Method-Override'] = upperMethod;
        actualMethod = 'POST';
      }
    }

    hilog.info(DOMAIN, TAG, '🚀 REQUEST[%{public}s] => %{public}s', method, url);

    let httpRequest = http.createHttp();
    try {
      const httpMethod = this.mapHttpMethod(actualMethod);

      const response = await httpRequest.request(url, {
        method: httpMethod,
        header: headers,
        extraData: data ? JSON.stringify(data) : undefined,
        connectTimeout: options?.timeout ?? ApiConfig.CONNECT_TIMEOUT,
        readTimeout: options?.timeout ?? ApiConfig.RECEIVE_TIMEOUT,
      });

      const duration = Date.now() - startTime;
      hilog.info(DOMAIN, TAG, '✅ RESPONSE[%{public}d] (%{public}dms) => %{public}s',
        response.responseCode, duration, url);

      // 处理 HTTP 状态码
      if (response.responseCode === 401) {
        await this.handleUnauthorized();
        throw new Error('Unauthorized: Token expired or invalid');
      }

      if (response.responseCode >= 400) {
        const errorBody = typeof response.result === 'string'
          ? response.result : JSON.stringify(response.result);
        hilog.error(DOMAIN, TAG, '❌ HTTP Error %{public}d: %{public}s',
          response.responseCode, errorBody);
        throw new Error(`HTTP Error ${response.responseCode}: ${errorBody}`);
      }

      // 解析响应
      let responseData: Object;
      if (typeof response.result === 'string') {
        responseData = JSON.parse(response.result as string) as Object;
      } else {
        responseData = response.result as Object;
      }

      // API 响应解包
      if (!options?.disableUnwrap && responseData && typeof responseData === 'object') {
        const envelope = responseData as ApiResponse<T>;
        if (envelope.success !== undefined) {
          if (envelope.success) {
            return envelope.data;
          } else {
            const errorMsg = envelope.message || 'Request failed';
            hilog.error(DOMAIN, TAG, '❌ API Error: %{public}s', errorMsg);
            throw new Error(errorMsg);
          }
        }
      }

      return responseData as T;
    } catch (err) {
      const duration = Date.now() - startTime;
      const errorMsg = (err instanceof Error) ? err.message : JSON.stringify(err);
      hilog.error(DOMAIN, TAG, '❌ REQUEST FAILED (%{public}dms) %{public}s: %{public}s',
        duration, url, errorMsg);
      if (err instanceof Error) {
        throw err;
      }
      throw new Error(errorMsg);
    } finally {
      httpRequest.destroy();
    }
  }

  // ============================================================
  // URL 构建
  // ============================================================

  private buildFullUrl(endpoint: string, queryParams?: Record<string, string>): string {
    // 如果 endpoint 已经是完整 URL
    if (endpoint.startsWith('http://') || endpoint.startsWith('https://')) {
      return endpoint;
    }

    const baseUrl = ApiConfig.currentApiBaseUrl;
    let url = `${baseUrl}${endpoint}`;

    if (queryParams) {
      const queryString = Object.keys(queryParams)
        .filter(key => queryParams[key] !== undefined && queryParams[key] !== null)
        .map(key => `${encodeURIComponent(key)}=${encodeURIComponent(queryParams[key])}`)
        .join('&');
      if (queryString) {
        url = `${url}?${queryString}`;
      }
    }

    return url;
  }

  /**
   * 替换路径参数
   * 如 '/cities/{id}' + { id: '123' } => '/cities/123'
   */
  static replacePathParams(endpoint: string, params: Record<string, string>): string {
    let url = endpoint;
    for (const key of Object.keys(params)) {
      url = url.replace(`{${key}}`, params[key]);
    }
    return url;
  }

  // ============================================================
  // HTTP 方法映射
  // ============================================================

  private mapHttpMethod(method: string): http.RequestMethod {
    switch (method.toUpperCase()) {
      case 'GET':
        return http.RequestMethod.GET;
      case 'POST':
        return http.RequestMethod.POST;
      case 'PUT':
        return http.RequestMethod.PUT;
      case 'DELETE':
        return http.RequestMethod.DELETE;
      default:
        // PATCH 等方法通过 POST + X-HTTP-Method-Override 处理
        return http.RequestMethod.POST;
    }
  }

  // ============================================================
  // 401 处理
  // ============================================================

  private async handleUnauthorized(): Promise<void> {
    if (this.isRedirectingToLogin) {
      return;
    }
    this.isRedirectingToLogin = true;

    hilog.warn(DOMAIN, TAG, '🔥 Token expired or invalid, clearing auth...');

    // 清除 Token
    await TokenStorageService.getInstance().clearAll();

    // 触发外部回调（跳转登录页等）
    if (this.onUnauthorized) {
      this.onUnauthorized();
    }

    // 1秒后重置标志
    setTimeout(() => {
      this.isRedirectingToLogin = false;
    }, 1000);
  }
}
