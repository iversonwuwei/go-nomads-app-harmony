export interface UserMembership {
  id: string;
  userId: string;
  level: number;
  levelName: string;
  startDate?: string;
  expiryDate?: string;
  autoRenew: boolean;
  aiUsageThisMonth: number;
  aiUsageLimit: number;
  moderatorDeposit?: number;
  isActive: boolean;
  isExpired: boolean;
  remainingDays: number;
  isExpiringSoon: boolean;
  canUseAI: boolean;
  canApplyModerator: boolean;
}

export interface MembershipPlan {
  id: string;
  level: number;
  name: string;
  description?: string;
  priceYearly: number;
  priceMonthly: number;
  currency: string;
  icon?: string;
  color?: string;
  features: string[];
  aiUsageLimit: number;
  canUseAI: boolean;
  canApplyModerator: boolean;
  moderatorDeposit: number;
}

export function parseMembership(json: Record<string, Object>): UserMembership {
  return {
    id: (json['id'] as string) ?? '',
    userId: (json['userId'] as string) ?? '',
    level: (json['level'] as number) ?? 0,
    levelName: (json['levelName'] as string) ?? 'Free',
    startDate: json['startDate'] as string | undefined,
    expiryDate: json['expiryDate'] as string | undefined,
    autoRenew: (json['autoRenew'] as boolean) ?? false,
    aiUsageThisMonth: (json['aiUsageThisMonth'] as number) ?? 0,
    aiUsageLimit: (json['aiUsageLimit'] as number) ?? 0,
    moderatorDeposit: json['moderatorDeposit'] as number | undefined,
    isActive: (json['isActive'] as boolean) ?? false,
    isExpired: (json['isExpired'] as boolean) ?? false,
    remainingDays: (json['remainingDays'] as number) ?? 0,
    isExpiringSoon: (json['isExpiringSoon'] as boolean) ?? false,
    canUseAI: (json['canUseAI'] as boolean) ?? false,
    canApplyModerator: (json['canApplyModerator'] as boolean) ?? false,
  } as UserMembership;
}

export function parseMembershipPlan(json: Record<string, Object>): MembershipPlan {
  return {
    id: (json['id'] as string) ?? '',
    level: (json['level'] as number) ?? 0,
    name: (json['name'] as string) ?? '',
    description: json['description'] as string | undefined,
    priceYearly: (json['priceYearly'] as number) ?? 0,
    priceMonthly: (json['priceMonthly'] as number) ?? 0,
    currency: (json['currency'] as string) ?? 'USD',
    icon: json['icon'] as string | undefined,
    color: json['color'] as string | undefined,
    features: parseStringArray(json['features'] as Object),
    aiUsageLimit: (json['aiUsageLimit'] as number) ?? 0,
    canUseAI: (json['canUseAI'] as boolean) ?? false,
    canApplyModerator: (json['canApplyModerator'] as boolean) ?? false,
    moderatorDeposit: (json['moderatorDeposit'] as number) ?? 0,
  } as MembershipPlan;
}

function parseStringArray(val: Object | undefined): string[] {
  if (!val || !(val instanceof Array)) {
    return [];
  }
  const arr = val as Object[];
  const result: string[] = [];
  for (let i = 0; i < arr.length; i++) {
    result.push(arr[i] as string);
  }
  return result;
}
