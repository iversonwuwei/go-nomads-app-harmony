import { hilog } from '@kit.PerformanceAnalysisKit';
import { HttpService } from './HttpService';
import { MembershipPlan, UserMembership, parseMembership, parseMembershipPlan } from '../models/Membership';

const TAG = 'MembershipService';
const DOMAIN = 0x0001;

interface UpgradeMembershipRequest {
  level: number;
  durationDays: number;
}

export class MembershipService {
  private static instance: MembershipService | null = null;
  private httpService: HttpService;

  private constructor() {
    this.httpService = HttpService.getInstance();
  }

  static getInstance(): MembershipService {
    if (!MembershipService.instance) {
      MembershipService.instance = new MembershipService();
    }
    return MembershipService.instance;
  }

  async getMembership(): Promise<UserMembership> {
    const result = await this.httpService.get<Object>('/membership');
    return parseMembership(result as Record<string, Object>);
  }

  async getPlans(): Promise<MembershipPlan[]> {
    const result = await this.httpService.get<Object>('/membership/plans');
    if (!(result instanceof Array)) {
      return [];
    }
    const items = result as Object[];
    const plans: MembershipPlan[] = [];
    for (let i = 0; i < items.length; i++) {
      plans.push(parseMembershipPlan(items[i] as Record<string, Object>));
    }
    return plans;
  }

  async upgradeMembership(level: number, durationDays: number = 365): Promise<UserMembership> {
    const body: UpgradeMembershipRequest = {
      level,
      durationDays,
    };
    try {
      const result = await this.httpService.post<Object>('/membership/upgrade', body as Object);
      return parseMembership(result as Record<string, Object>);
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ upgradeMembership failed: %{public}s', (err as Error).message);
      throw new Error((err as Error).message);
    }
  }
}
