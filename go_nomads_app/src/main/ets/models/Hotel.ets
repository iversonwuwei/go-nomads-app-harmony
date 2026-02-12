/**
 * 酒店模型 — 对应 Flutter hotel.dart
 */
export interface Hotel {
  id: string;
  name: string;
  cityId: string;
  cityName: string;
  country?: string;
  address: string;
  latitude: number;
  longitude: number;
  rating: number;
  reviewCount: number;
  description?: string;
  amenities?: string[];
  images?: string[];
  category?: string;
  starRating?: number;
  pricePerNight: number;
  currency?: string;
  isFeatured?: boolean;
  createdBy?: string;
  // 数字游民特性
  wifiSpeed?: number;
  hasWifi?: boolean;
  hasWorkDesk?: boolean;
  hasCoworkingSpace?: boolean;
  hasAirConditioning?: boolean;
  hasKitchen?: boolean;
  hasLaundry?: boolean;
  hasParking?: boolean;
  hasPool?: boolean;
  hasGym?: boolean;
  has24HReception?: boolean;
  hasLongStayDiscount?: boolean;
  longStayDiscountPercent?: number;
  isPetFriendly?: boolean;
  nomadScore?: number;
  phone?: string;
  email?: string;
  website?: string;
}

export class HotelHelper {
  static starText(h: Hotel): string {
    if (!h.starRating) return '';
    return '★'.repeat(h.starRating);
  }

  static priceLabel(h: Hotel): string {
    const curr = h.currency ?? '¥';
    return `${curr}${h.pricePerNight}/晚`;
  }

  static nomadFeatures(h: Hotel): string[] {
    const features: string[] = [];
    if (h.hasWifi) features.push('WiFi');
    if (h.hasWorkDesk) features.push('办公桌');
    if (h.hasCoworkingSpace) features.push('共享办公');
    if (h.hasKitchen) features.push('厨房');
    if (h.hasLaundry) features.push('洗衣');
    if (h.hasPool) features.push('泳池');
    if (h.hasGym) features.push('健身房');
    if (h.hasParking) features.push('停车');
    if (h.has24HReception) features.push('24h前台');
    if (h.hasLongStayDiscount) features.push(`长住折扣 ${h.longStayDiscountPercent ?? ''}%`);
    if (h.isPetFriendly) features.push('允许宠物');
    return features;
  }

  static imageUrl(h: Hotel): string | undefined {
    return h.images && h.images.length > 0 ? h.images[0] : undefined;
  }
}
