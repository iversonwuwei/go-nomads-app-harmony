/**
 * 后端部署环境类型
 */
export enum DeploymentEnvironment {
  /** Docker Compose / 本地容器部署 */
  Docker,
  /** Kubernetes 部署 */
  Kubernetes,
}

/**
 * 部署环境端口配置
 */
class DeploymentConfig {
  gatewayPort: number;
  messageServicePort: number;
  coworkingServicePort: number;

  constructor(gatewayPort: number, messageServicePort: number, coworkingServicePort: number) {
    this.gatewayPort = gatewayPort;
    this.messageServicePort = messageServicePort;
    this.coworkingServicePort = coworkingServicePort;
  }

  /** Docker 部署配置 */
  static readonly DOCKER = new DeploymentConfig(80, 5005, 8006);

  /** Kubernetes 部署配置 */
  static readonly KUBERNETES = new DeploymentConfig(30080, 8010, 8003);
}

/**
 * API 配置 - 对应 Flutter 端 api_config.dart
 */
export class ApiConfig {
  // ============================================================
  // 环境配置
  // ============================================================
  static readonly IS_PRODUCTION: boolean = true;

  // ============================================================
  // 部署环境配置
  // ============================================================
  static readonly DEPLOYMENT_ENVIRONMENT: DeploymentEnvironment = DeploymentEnvironment.Docker;

  private static get deploymentConfig(): DeploymentConfig {
    switch (ApiConfig.DEPLOYMENT_ENVIRONMENT) {
      case DeploymentEnvironment.Docker:
        return DeploymentConfig.DOCKER;
      case DeploymentEnvironment.Kubernetes:
        return DeploymentConfig.KUBERNETES;
    }
  }

  // ============================================================
  // 端口配置
  // ============================================================
  static get gatewayPort(): number {
    return ApiConfig.deploymentConfig.gatewayPort;
  }

  static get messageServicePort(): number {
    return ApiConfig.deploymentConfig.messageServicePort;
  }

  // ============================================================
  // 主机地址配置
  // ============================================================
  /** 生产环境主机 */
  static readonly PRODUCTION_HOST: string = 'api.go-nomads.com';

  /** 真机测试主机 - 局域网 IP */
  static readonly PHYSICAL_DEVICE_HOST: string = '192.168.110.67';

  /** 鸿蒙设备使用局域网 IP 访问宿主机 */
  static readonly USE_PHYSICAL_DEVICE: boolean = true;

  /** 是否启用 HTTP 方法重写 */
  static readonly USE_HTTP_METHOD_OVERRIDE: boolean = true;

  // ============================================================
  // URL 组装
  // ============================================================
  static get currentHost(): string {
    if (ApiConfig.IS_PRODUCTION) {
      return ApiConfig.PRODUCTION_HOST;
    }
    return ApiConfig.USE_PHYSICAL_DEVICE ? ApiConfig.PHYSICAL_DEVICE_HOST : 'localhost';
  }

  static get baseUrl(): string {
    if (ApiConfig.IS_PRODUCTION) {
      return `http://${ApiConfig.PRODUCTION_HOST}`;
    }
    const host = ApiConfig.USE_PHYSICAL_DEVICE ? ApiConfig.PHYSICAL_DEVICE_HOST : 'localhost';
    return `http://${host}:${ApiConfig.gatewayPort}`;
  }

  static get messageServiceBaseUrl(): string {
    if (ApiConfig.IS_PRODUCTION) {
      return `http://${ApiConfig.PRODUCTION_HOST}`;
    }
    return ApiConfig.baseUrl;
  }

  // API 版本
  static readonly API_VERSION: string = '/api/v1';

  // 完整的 API 基础路径
  static get apiBaseUrl(): string {
    return `${ApiConfig.currentBaseUrl}${ApiConfig.API_VERSION}`;
  }

  // 超时配置 (毫秒)
  static readonly CONNECT_TIMEOUT: number = 30000;
  static readonly RECEIVE_TIMEOUT: number = 60000;
  static readonly SEND_TIMEOUT: number = 30000;

  // 认证相关 Key
  static readonly AUTH_TOKEN_KEY: string = 'auth_token';
  static readonly REFRESH_TOKEN_KEY: string = 'refresh_token';

  // 第三方平台配置
  static readonly ALIPAY_APP_ID: string = '2021006115624759';
  static readonly QQ_APP_ID: string = '102822014';

  // ============================================================
  // Authentication Endpoints - /api/v1/auth
  // ============================================================
  static readonly LOGIN_ENDPOINT: string = '/auth/login';
  static readonly REGISTER_ENDPOINT: string = '/auth/register';
  static readonly LOGOUT_ENDPOINT: string = '/auth/logout';
  static readonly REFRESH_TOKEN_ENDPOINT: string = '/auth/refresh';
  static readonly CHANGE_PASSWORD_ENDPOINT: string = '/auth/change-password';
  static readonly SOCIAL_LOGIN_ENDPOINT: string = '/auth/social-login';

  // ============================================================
  // User Endpoints - /api/v1/users
  // ============================================================
  static readonly USERS_ENDPOINT: string = '/users';
  static readonly USER_ME_ENDPOINT: string = '/users/me';
  static readonly USER_PROFILE_ENDPOINT: string = '/users';
  static readonly USER_ME_STATS_ENDPOINT: string = '/users/me/stats';
  static readonly USER_BATCH_ENDPOINT: string = '/users/batch';

  // 首页相关
  static readonly HOME_DATA_ENDPOINT: string = '/home/data';
  static readonly HOME_BANNERS_ENDPOINT: string = '/home/banners';

  // ============================================================
  // City Endpoints - /api/v1/cities
  // ============================================================
  static readonly CITIES_ENDPOINT: string = '/cities';
  static readonly CITY_LIST_ENDPOINT: string = '/cities/list';
  static readonly CITY_RECOMMENDED_ENDPOINT: string = '/cities/recommended';
  static readonly CITY_DETAIL_ENDPOINT: string = '/cities';
  static readonly CITY_SEARCH_ENDPOINT: string = '/cities/search';
  static readonly CITY_GROUPED_BY_COUNTRY_ENDPOINT: string = '/cities/grouped-by-country';
  static readonly CITY_COUNTRIES_ENDPOINT: string = '/cities/countries';

  // ============================================================
  // City User Content Endpoints
  // ============================================================
  static readonly MY_PHOTOS_ENDPOINT: string = '/user/city-content/photos';
  static readonly MY_EXPENSES_ENDPOINT: string = '/user/city-content/expenses';

  // ============================================================
  // Cache Service Endpoints
  // ============================================================
  static readonly CITY_COST_BATCH_ENDPOINT: string = '/cache/costs/city/batch';
  static readonly CITY_SCORE_BATCH_ENDPOINT: string = '/cache/scores/city/batch';
  static readonly COWORKING_SCORE_BATCH_ENDPOINT: string = '/cache/scores/coworking/batch';

  // ============================================================
  // Coworking Space Endpoints
  // ============================================================
  static readonly COWORKING_SPACES_ENDPOINT: string = '/coworking-spaces';

  // ============================================================
  // Innovation Project Endpoints
  // ============================================================
  static readonly INNOVATION_PROJECTS_ENDPOINT: string = '/innovation-projects';

  // ============================================================
  // Event / Meetup Endpoints
  // ============================================================
  static readonly EVENTS_ENDPOINT: string = '/events';
  static readonly MEETUPS_ENDPOINT: string = '/meetups';

  // ============================================================
  // SignalR Hub Endpoints
  // ============================================================
  static get chatHubUrl(): string {
    return `${ApiConfig.baseUrl}/hubs/chat`;
  }

  static get meetupHubUrl(): string {
    return `${ApiConfig.baseUrl}/hubs/meetup`;
  }

  static get notificationHubUrl(): string {
    return `${ApiConfig.baseUrl}/hubs/notification`;
  }

  // ============================================================
  // Chat Endpoints
  // ============================================================
  static readonly CHATS_ENDPOINT: string = '/chats';

  // ============================================================
  // Notification Endpoints
  // ============================================================
  static readonly NOTIFICATIONS_ENDPOINT: string = '/notifications';
  static readonly NOTIFICATION_UNREAD_COUNT_ENDPOINT: string = '/notifications/unread/count';

  // ============================================================
  // AI Chat Endpoints
  // ============================================================
  static readonly AI_CONVERSATIONS_ENDPOINT: string = '/ai/conversations';
  static readonly AI_CHAT_ENDPOINT: string = '/ai/chat';

  // ============================================================
  // Travel Plan Endpoints
  // ============================================================
  static readonly TRAVEL_PLANS_ENDPOINT: string = '/travel-plans';

  // ============================================================
  // Favorites Endpoints
  // ============================================================
  static readonly FAVORITES_ENDPOINT: string = '/favorites';

  // ============================================================
  // Travel History Endpoints
  // ============================================================
  static readonly TRAVEL_HISTORY_ENDPOINT: string = '/travel-history';

  // ============================================================
  // 运行时自定义基础 URL
  // ============================================================
  private static customBaseUrl: string | null = null;

  static setCustomBaseUrl(url: string): void {
    ApiConfig.customBaseUrl = url;
  }

  static clearCustomBaseUrl(): void {
    ApiConfig.customBaseUrl = null;
  }

  static get currentBaseUrl(): string {
    return ApiConfig.customBaseUrl ?? ApiConfig.baseUrl;
  }

  static get currentApiBaseUrl(): string {
    return `${ApiConfig.currentBaseUrl}${ApiConfig.API_VERSION}`;
  }

  // ============================================================
  // Helper Methods
  // ============================================================

  /**
   * 构建完整的端点 URL
   * @param endpoint 端点路径，如 '/cities/{id}'
   * @param params 路径参数，如 { id: '123' }
   */
  static buildUrl(endpoint: string, params?: Record<string, string>): string {
    let url = endpoint;
    if (params) {
      for (const key of Object.keys(params)) {
        url = url.replace(`{${key}}`, params[key]);
      }
    }
    return `${ApiConfig.currentApiBaseUrl}${url}`;
  }

  /**
   * 构建带查询参数的 URL
   */
  static buildUrlWithQuery(endpoint: string, queryParams: Record<string, string>): string {
    const base = `${ApiConfig.currentApiBaseUrl}${endpoint}`;
    const queryString = Object.keys(queryParams)
      .map(key => `${encodeURIComponent(key)}=${encodeURIComponent(queryParams[key])}`)
      .join('&');
    return queryString ? `${base}?${queryString}` : base;
  }
}
