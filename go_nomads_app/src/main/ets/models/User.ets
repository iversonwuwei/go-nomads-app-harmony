/**
 * 用户技能
 */
export interface UserSkillInfo {
  id: string;
  name: string;
  category?: string;
}

/**
 * 用户兴趣
 */
export interface UserInterestInfo {
  id: string;
  name: string;
  category?: string;
}

/**
 * 旅行统计
 */
export interface TravelStats {
  countriesVisited: number;
  citiesVisited: number;
  totalDays: number;
  totalTrips: number;
}

/**
 * 用户徽章
 */
export interface Badge {
  id: string;
  name: string;
  description?: string;
  icon?: string;
}

/**
 * 用户实体 - 对应 Flutter 端 User domain entity
 */
export interface User {
  id: string;
  name: string;
  username: string;
  email?: string;
  bio?: string;
  avatarUrl?: string;
  currentCity?: string;
  currentCountry?: string;
  skills: UserSkillInfo[];
  interests: UserInterestInfo[];
  socialLinks: Record<string, string>;
  badges: Badge[];
  stats: TravelStats;
  joinedDate: string;
  isVerified: boolean;
}

/**
 * 用户辅助方法
 */
export class UserHelper {
  /** 是否已完善资料 */
  static hasCompletedProfile(user: User): boolean {
    return !!user.bio && !!user.avatarUrl && !!user.currentCity;
  }

  /** 是否活跃游民 */
  static isActiveNomad(user: User): boolean {
    return user.stats.citiesVisited > 0;
  }

  /** 经验等级 */
  static experienceLevel(user: User): number {
    const visited = user.stats.citiesVisited;
    if (visited >= 50) return 5;
    if (visited >= 20) return 4;
    if (visited >= 10) return 3;
    if (visited >= 5) return 2;
    return 1;
  }

  /** 经验等级名称 */
  static experienceLevelName(user: User): string {
    switch (UserHelper.experienceLevel(user)) {
      case 5: return 'Expert';
      case 4: return 'Advanced';
      case 3: return 'Intermediate';
      case 2: return 'Beginner';
      default: return 'Newbie';
    }
  }
}
