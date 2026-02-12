/**
 * 共享办公空间模型 — 对应 Flutter coworking_space.dart
 */
export interface CoworkingSpace {
  id: string;
  name: string;
  cityId?: string;
  cityName?: string;
  country?: string;
  address?: string;
  latitude?: number;
  longitude?: number;
  description?: string;
  imageUrl?: string;
  images?: string[];
  rating: number;
  reviewCount: number;
  isVerified: boolean;
  verificationVotes: number;
  createdBy?: string;
  creatorName?: string;
  // 价格
  hourlyRate?: number;
  dailyRate?: number;
  weeklyRate?: number;
  monthlyRate?: number;
  currency?: string;
  hasFreeTrial?: boolean;
  // 设施
  hasWifi?: boolean;
  hasMeetingRoom?: boolean;
  hasPhoneBooth?: boolean;
  hasPrinter?: boolean;
  hasFreeParking?: boolean;
  hasCoffee?: boolean;
  hasKitchen?: boolean;
  has24HourAccess?: boolean;
  hasLocker?: boolean;
  hasShower?: boolean;
  hasAirConditioning?: boolean;
  // 规格
  wifiSpeed?: number;
  totalDesks?: number;
  availableDesks?: number;
  // 运营时间
  openTime?: string;
  closeTime?: string;
  openDays?: string[];
  // 联系方式
  phone?: string;
  email?: string;
  website?: string;
}

export class CoworkingHelper {
  static lowestPrice(cs: CoworkingSpace): number {
    const prices: number[] = [];
    if (cs.hourlyRate) prices.push(cs.hourlyRate);
    if (cs.dailyRate) prices.push(cs.dailyRate);
    if (cs.weeklyRate) prices.push(cs.weeklyRate);
    if (cs.monthlyRate) prices.push(cs.monthlyRate);
    if (prices.length === 0) return 0;
    return Math.min(...prices);
  }

  static priceLabel(cs: CoworkingSpace): string {
    if (cs.dailyRate) return `¥${cs.dailyRate}/天`;
    if (cs.monthlyRate) return `¥${cs.monthlyRate}/月`;
    if (cs.hourlyRate) return `¥${cs.hourlyRate}/小时`;
    return '价格面议';
  }

  static isHighlyRated(cs: CoworkingSpace): boolean {
    return cs.rating >= 4.0;
  }

  static hasHighSpeedInternet(cs: CoworkingSpace): boolean {
    return (cs.wifiSpeed ?? 0) >= 50;
  }

  static amenitiesList(cs: CoworkingSpace): string[] {
    const list: string[] = [];
    if (cs.hasWifi) list.push('WiFi');
    if (cs.hasMeetingRoom) list.push('会议室');
    if (cs.hasCoffee) list.push('免费咖啡');
    if (cs.has24HourAccess) list.push('24小时');
    if (cs.hasPrinter) list.push('打印机');
    if (cs.hasKitchen) list.push('厨房');
    if (cs.hasFreeParking) list.push('免费停车');
    if (cs.hasShower) list.push('淋浴');
    if (cs.hasAirConditioning) list.push('空调');
    return list;
  }
}
