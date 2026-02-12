/**
 * 城市实体 - 对应 Flutter 端 City domain entity
 */
export interface City {
  id: string;
  name: string;
  nameEn?: string;
  country?: string;
  region?: string;
  imageUrl?: string;
  portraitImageUrl?: string;
  landscapeImageUrls?: string[];
  description?: string;
  timezone?: string;
  population?: string;
  currency?: string;

  // 天气
  temperature?: number;
  feelsLike?: number;
  weather?: string;
  humidity?: number;
  airQualityIndex?: number;

  // 评分
  overallScore?: number;
  costScore?: number;
  internetScore?: number;
  safetyScore?: number;
  likedScore?: number;
  communityScore?: number;
  weatherScore?: number;
  funScore?: number;
  healthScore?: number;
  walkabilityScore?: number;

  // 消费 & 天气补充
  costLevel?: string;
  weatherEmoji?: string;
  airQuality?: string;

  // 标签
  tags?: string[];

  // 统计
  meetupCount?: number;
  reviewCount?: number;
  coworkingCount?: number;
  averageCost?: number;

  // 地理
  latitude?: number;
  longitude?: number;

  // 用户交互
  isFavorite?: boolean;

  // 版主
  moderatorId?: string;
}

/**
 * 城市相关辅助方法
 */
export class CityHelper {
  /** 获取显示名称 */
  static displayName(city: City): string {
    return city.nameEn || city.name;
  }

  /** 获取完整位置 */
  static fullLocation(city: City): string {
    return city.country ? `${city.name}, ${city.country}` : city.name;
  }

  /** 获取显示图片 URL */
  static displayImageUrl(city: City): string {
    return city.portraitImageUrl || city.imageUrl || '';
  }

  /** 获取横屏图 */
  static landscapeImageUrl(city: City): string {
    if (city.landscapeImageUrls && city.landscapeImageUrls.length > 0) {
      return city.landscapeImageUrls[0];
    }
    return city.imageUrl || '';
  }

  /** 安全获取评分 */
  static displayOverallScore(city: City): number {
    return city.overallScore ?? 0;
  }

  /** 安全获取温度 */
  static displayTemperature(city: City): number {
    return city.temperature ?? 25;
  }

  /** 安全获取天气描述 */
  static displayWeather(city: City): string {
    return city.weather ?? 'Sunny';
  }

  /** 是否高质量城市 */
  static isHighQuality(city: City): boolean {
    return (city.overallScore ?? 0) >= 4.0;
  }

  /** 从 JSON 构建 */
  static fromJson(json: Record<string, Object>): City {
    return {
      id: json['id'] as string,
      name: json['name'] as string,
      nameEn: json['nameEn'] as string | undefined,
      country: json['country'] as string | undefined,
      region: json['region'] as string | undefined,
      imageUrl: json['imageUrl'] as string | undefined,
      portraitImageUrl: json['portraitImageUrl'] as string | undefined,
      landscapeImageUrls: json['landscapeImageUrls'] as string[] | undefined,
      description: json['description'] as string | undefined,
      timezone: json['timezone'] as string | undefined,
      temperature: json['temperature'] as number | undefined,
      feelsLike: json['feelsLike'] as number | undefined,
      weather: json['weather'] as string | undefined,
      humidity: json['humidity'] as number | undefined,
      overallScore: json['overallScore'] as number | undefined,
      costScore: json['costScore'] as number | undefined,
      internetScore: json['internetScore'] as number | undefined,
      safetyScore: json['safetyScore'] as number | undefined,
      likedScore: json['likedScore'] as number | undefined,
      tags: json['tags'] as string[] | undefined,
      meetupCount: json['meetupCount'] as number | undefined,
      reviewCount: json['reviewCount'] as number | undefined,
      coworkingCount: json['coworkingCount'] as number | undefined,
      averageCost: json['averageCost'] as number | undefined,
      latitude: json['latitude'] as number | undefined,
      longitude: json['longitude'] as number | undefined,
      isFavorite: json['isFavorite'] as boolean | undefined,
    } as City;
  }
}
