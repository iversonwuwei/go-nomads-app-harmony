import { hilog } from '@kit.PerformanceAnalysisKit';
import { ApiConfig } from '../common/constants/ApiConfig';
import { User, TravelStats, UserSkillInfo, UserInterestInfo, Badge } from '../models/User';
import { HttpService, RequestOptions } from './HttpService';

const TAG = 'UserService';
const DOMAIN = 0x0001;

/**
 * 用户统计数据
 */
export interface NomadStats {
  countriesVisited: number;
  citiesLived: number;
  daysNomading: number;
  tripsCompleted: number;
  meetupsCreated: number;
  meetupsJoined: number;
  favoriteCitiesCount: number;
}

/**
 * 用户服务 —— 对应 Flutter 端 UserRepository
 * 封装 /users 相关 API
 */
export class UserService {
  private static instance: UserService | null = null;
  private httpService: HttpService;

  private constructor() {
    this.httpService = HttpService.getInstance();
  }

  static getInstance(): UserService {
    if (!UserService.instance) {
      UserService.instance = new UserService();
    }
    return UserService.instance;
  }

  // =====================================================
  // 当前用户
  // =====================================================

  /**
   * 获取当前用户资料
   * GET /users/me
   */
  async getCurrentUser(): Promise<User> {
    try {
      const result = await this.httpService.get<Object>(ApiConfig.USER_ME_ENDPOINT);
      const user = this.parseUser(result as Record<string, Object>);
      hilog.info(DOMAIN, TAG, '✅ getCurrentUser: %{public}s', user.name);
      return user;
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ getCurrentUser failed: %{public}s', (err as Error).message);
      throw new Error((err as Error).message);
    }
  }

  /**
   * 获取当前用户统计
   * GET /users/me/stats
   */
  async getCurrentUserStats(): Promise<NomadStats> {
    try {
      const result = await this.httpService.get<Object>(ApiConfig.USER_ME_STATS_ENDPOINT);
      return this.parseNomadStats(result as Record<string, Object>);
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ getCurrentUserStats failed: %{public}s', (err as Error).message);
      throw new Error((err as Error).message);
    }
  }

  // =====================================================
  // 其他用户
  // =====================================================

  /**
   * 获取用户详情
   * GET /users/{id}
   */
  async getUserById(userId: string): Promise<User> {
    try {
      const result = await this.httpService.get<Object>(
        `${ApiConfig.USERS_ENDPOINT}/${userId}`
      );
      return this.parseUser(result as Record<string, Object>);
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ getUserById failed: %{public}s', (err as Error).message);
      throw new Error((err as Error).message);
    }
  }

  /**
   * 搜索用户
   * GET /users?q=&page=&pageSize=
   */
  async searchUsers(query: string, page: number = 1, pageSize: number = 20): Promise<User[]> {
    try {
      const queryParams: Record<string, string> = {
        'q': query,
        'page': page.toString(),
        'pageSize': pageSize.toString(),
      };

      const result = await this.httpService.get<Object>(
        ApiConfig.USERS_ENDPOINT,
        { queryParams: queryParams } as RequestOptions
      );

      // 可能返回数组或 { data: [...] }
      let items: Object[];
      if (result instanceof Array) {
        items = result as Object[];
      } else {
        const resObj = result as Record<string, Object>;
        if (resObj['data'] && resObj['data'] instanceof Array) {
          items = resObj['data'] as Object[];
        } else {
          items = [];
        }
      }

      return this.parseUserList(items);
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ searchUsers failed: %{public}s', (err as Error).message);
      throw new Error((err as Error).message);
    }
  }

  // =====================================================
  // 更新
  // =====================================================

  /**
   * 更新当前用户资料
   * PUT /users/{id}
   */
  async updateUser(userId: string, updates: Record<string, Object>): Promise<User> {
    try {
      const result = await this.httpService.put<Object>(
        `${ApiConfig.USERS_ENDPOINT}/${userId}`,
        updates
      );
      const user = this.parseUser(result as Record<string, Object>);
      hilog.info(DOMAIN, TAG, '✅ updateUser: %{public}s', user.name);
      return user;
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ updateUser failed: %{public}s', (err as Error).message);
      throw new Error((err as Error).message);
    }
  }

  /**
   * 更新用户统计
   * PUT /users/me/stats
   */
  async updateCurrentUserStats(stats: NomadStats): Promise<NomadStats> {
    try {
      const data: Record<string, Object> = {};
      data['countriesVisited'] = stats.countriesVisited;
      data['citiesLived'] = stats.citiesLived;
      data['daysNomading'] = stats.daysNomading;
      data['tripsCompleted'] = stats.tripsCompleted;

      const result = await this.httpService.put<Object>(
        ApiConfig.USER_ME_STATS_ENDPOINT,
        data
      );
      return this.parseNomadStats(result as Record<string, Object>);
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ updateCurrentUserStats failed: %{public}s', (err as Error).message);
      throw new Error((err as Error).message);
    }
  }

  // =====================================================
  // 解析
  // =====================================================

  private parseUserList(items: Object[]): User[] {
    const users: User[] = [];
    for (let i = 0; i < items.length; i++) {
      try {
        users.push(this.parseUser(items[i] as Record<string, Object>));
      } catch (e) {
        hilog.warn(DOMAIN, TAG, '⚠️ parseUser failed at index %{public}d', i);
      }
    }
    return users;
  }

  private parseUser(json: Record<string, Object>): User {
    let stats: TravelStats = {
      countriesVisited: 0,
      citiesVisited: 0,
      totalDays: 0,
      totalTrips: 0,
    };

    // Stats 可能内嵌也可能是独立字段
    const statsData = json['stats'] as Record<string, Object> | undefined;
    if (statsData) {
      stats = {
        countriesVisited: (statsData['countriesVisited'] as number) ?? 0,
        citiesVisited: (statsData['citiesVisited'] as number) ?? (statsData['citiesLived'] as number) ?? 0,
        totalDays: (statsData['daysNomading'] as number) ?? (statsData['totalDays'] as number) ?? 0,
        totalTrips: (statsData['tripsCompleted'] as number) ?? (statsData['totalTrips'] as number) ?? 0,
      };
    }

    // Social links
    let socialLinks: Record<string, string> = {};
    const linksData = json['socialLinks'] as Record<string, string> | undefined;
    if (linksData) {
      socialLinks = linksData;
    }

    return {
      id: (json['id'] as string) ?? '',
      name: (json['name'] as string) ?? (json['userName'] as string) ?? '',
      username: (json['userName'] as string) ?? (json['username'] as string) ?? '',
      email: json['email'] as string | undefined,
      bio: json['bio'] as string | undefined,
      avatarUrl: (json['avatarUrl'] as string | undefined) ?? (json['avatar'] as string | undefined),
      currentCity: json['currentCity'] as string | undefined,
      currentCountry: json['currentCountry'] as string | undefined,
      skills: this.parseSkills(json['skills'] as Object),
      interests: this.parseInterests(json['interests'] as Object),
      socialLinks: socialLinks,
      badges: this.parseBadges(json['badges'] as Object),
      stats: stats,
      joinedDate: (json['createdAt'] as string) ?? '',
      isVerified: (json['isVerified'] as boolean) ?? false,
    } as User;
  }

  private parseSkills(val: Object | undefined): UserSkillInfo[] {
    if (!val || !(val instanceof Array)) {
      return [];
    }
    const arr: UserSkillInfo[] = [];
    const objArr = val as Object[];
    for (let i = 0; i < objArr.length; i++) {
      const item = objArr[i] as Record<string, Object>;
      const skill: UserSkillInfo = {
        id: (item['id'] as string) ?? i.toString(),
        name: (item['name'] as string) ?? '',
        category: item['category'] as string | undefined,
      };
      arr.push(skill);
    }
    return arr;
  }

  private parseInterests(val: Object | undefined): UserInterestInfo[] {
    if (!val || !(val instanceof Array)) {
      return [];
    }
    const arr: UserInterestInfo[] = [];
    const objArr = val as Object[];
    for (let i = 0; i < objArr.length; i++) {
      const item = objArr[i] as Record<string, Object>;
      const interest: UserInterestInfo = {
        id: (item['id'] as string) ?? i.toString(),
        name: (item['name'] as string) ?? '',
        category: item['category'] as string | undefined,
      };
      arr.push(interest);
    }

    private parseBadges(val: Object | undefined): Badge[] {
      if (!val || !(val instanceof Array)) {
        return [];
      }
      const arr: Badge[] = [];
      const objArr = val as Object[];
      for (let i = 0; i < objArr.length; i++) {
        const item = objArr[i] as Record<string, Object>;
        const badge: Badge = {
          id: (item['id'] as string) ?? i.toString(),
          name: (item['name'] as string) ?? '',
          description: item['description'] as string | undefined,
          icon: item['icon'] as string | undefined,
        };
        arr.push(badge);
      }
      return arr;
    }
    return arr;
  }

  private parseNomadStats(json: Record<string, Object>): NomadStats {
    return {
      countriesVisited: (json['countriesVisited'] as number) ?? 0,
      citiesLived: (json['citiesLived'] as number) ?? 0,
      daysNomading: (json['daysNomading'] as number) ?? 0,
      tripsCompleted: (json['tripsCompleted'] as number) ?? 0,
      meetupsCreated: (json['meetupsCreated'] as number) ?? 0,
      meetupsJoined: (json['meetupsJoined'] as number) ?? 0,
      favoriteCitiesCount: (json['favoriteCitiesCount'] as number) ?? 0,
    };
  }
}
