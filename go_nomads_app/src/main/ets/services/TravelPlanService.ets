import { ApiConfig } from '../common/constants/ApiConfig';
import { HttpService, RequestOptions } from './HttpService';
import { TravelPlanSummary, parseTravelPlanSummary } from '../models/TravelPlanSummary';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'TravelPlanService';
const DOMAIN = 0x0001;
const AI_TRAVEL_PLAN_ENDPOINT = '/ai/travel-plan';
const AI_TRAVEL_PLAN_ASYNC_ENDPOINT = '/ai/travel-plan/async';

/**
 * 旅行计划服务 - 获取用户最近的计划摘要
 */
export class TravelPlanService {
  private static instance: TravelPlanService | null = null;
  private httpService: HttpService;

  private constructor() {
    this.httpService = HttpService.getInstance();
  }

  static getInstance(): TravelPlanService {
    if (!TravelPlanService.instance) {
      TravelPlanService.instance = new TravelPlanService();
    }
    return TravelPlanService.instance;
  }

  /** 获取最近计划 (pageSize=1) */
  async getLatest(): Promise<TravelPlanSummary | null> {
    try {
      const items = await this.getRawList(1, 1);
      if (items.length === 0) {
        return null;
      }
      return parseTravelPlanSummary(items[0] as Record<string, Object>);
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ getLatest travel plan failed: %{public}s', (err as Error).message);
      return null;
    }
  }

  async getList(page: number = 1, pageSize: number = 20): Promise<TravelPlanSummary[]> {
    try {
      const items = await this.getRawList(page, pageSize);
      const result: TravelPlanSummary[] = [];
      for (const item of items) {
        const parsed = parseTravelPlanSummary(item as Record<string, Object>);
        if (parsed) {
          result.push(parsed);
        }
      }
      return result;
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ getList failed: %{public}s', (err as Error).message);
      return [];
    }
  }

  async getDetail(planId: string): Promise<Record<string, Object> | null> {
    if (!planId) {
      return null;
    }
    const candidateEndpoints: string[] = [
      `${ApiConfig.TRAVEL_PLANS_ENDPOINT}/${planId}`,
      `/ai/travel-plans/${planId}`,
      `/ai/travel-plans/${planId}/detail`,
    ];

    for (const endpoint of candidateEndpoints) {
      try {
        const result = await this.httpService.get<Object>(endpoint);
        const unwrapped = this.unwrapAsRecord(result);
        if (unwrapped) {
          return unwrapped;
        }
      } catch (err) {
        hilog.warn(DOMAIN, TAG, '⚠️ getDetail fallback endpoint failed: %{public}s', (err as Error).message);
      }
    }

    hilog.error(DOMAIN, TAG, '❌ getDetail failed for all endpoints: %{public}s', planId);
    return null;
  }

  async createPlan(payload: Record<string, Object>): Promise<Record<string, Object> | null> {
    try {
      const result = await this.httpService.post<Object>(ApiConfig.TRAVEL_PLANS_ENDPOINT, payload);
      const obj = this.tryRecord(result);
      if (!obj) {
        return null;
      }
      const data = this.tryRecord(obj['data']);
      return data ?? obj;
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ createPlan failed: %{public}s', (err as Error).message);
      return null;
    }
  }

  async createPlanFromPreferences(
    cityId: string,
    cityName: string,
    duration: number,
    budget: string,
    travelStyle: string,
    interests: string[],
    departureLocation: string,
    departureDate: string,
    customBudget?: string,
    currency?: string,
    selectedAttractions?: string[],
    onProgress?: (progress: number, message: string) => void,
  ): Promise<Record<string, Object> | null> {
    const normalizedTravelStyle = this.normalizeTravelStyle(travelStyle);
    const payload: Record<string, Object> = {
      cityId,
      cityName,
      cityImage: '',
      duration,
      budget,
      travelStyle: normalizedTravelStyle,
      interests: interests as Object,
      departureLocation: departureLocation || undefined,
      departureDate: departureDate || undefined,
      customBudget: customBudget || undefined,
      currency: currency || 'USD',
      selectedAttractions: (selectedAttractions && selectedAttractions.length > 0)
        ? selectedAttractions as Object
        : undefined,
    };

    const directCreated = await this.createPlan(payload);
    if (directCreated && this.readString(directCreated, 'id').length > 0) {
      return directCreated;
    }

    try {
      onProgress?.(8, '任务已创建，准备生成旅行计划...');
      const taskResp = await this.httpService.post<Object>(AI_TRAVEL_PLAN_ASYNC_ENDPOINT, payload);
      const taskObj = this.tryRecord(taskResp);
      const taskId = this.readString(taskObj, 'taskId');
      if (!taskId) {
        const syncResp = await this.httpService.post<Object>(AI_TRAVEL_PLAN_ENDPOINT, payload);
        return this.unwrapAsRecord(syncResp);
      }
      return await this.pollTaskResult(taskId, onProgress);
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ createPlanFromPreferences async failed: %{public}s', (err as Error).message);
      try {
        const syncResp = await this.httpService.post<Object>(AI_TRAVEL_PLAN_ENDPOINT, payload);
        return this.unwrapAsRecord(syncResp);
      } catch (syncErr) {
        hilog.error(DOMAIN, TAG, '❌ createPlanFromPreferences sync failed: %{public}s', (syncErr as Error).message);
        return null;
      }
    }
  }

  private async getRawList(page: number, pageSize: number): Promise<Object[]> {
    const options: RequestOptions = {
      queryParams: {
        'page': String(page),
        'pageSize': String(pageSize),
      },
    };
    const result = await this.httpService.get<Object>(ApiConfig.TRAVEL_PLANS_ENDPOINT, options);
    if (result instanceof Array) {
      return result as Object[];
    }
    const obj = this.tryRecord(result);
    if (!obj) {
      return [];
    }
    const data = this.tryRecord(obj['data']);
    if (obj['data'] instanceof Array) {
      return obj['data'] as Object[];
    }
    const dataItems = data?.['items'];
    if (dataItems instanceof Array) {
      return dataItems as Object[];
    }
    const rootItems = obj['items'];
    if (rootItems instanceof Array) {
      return rootItems as Object[];
    }
    return [];
  }

  private tryRecord(value: Object | undefined): Record<string, Object> | null {
    if (!value) {
      return null;
    }
    const record = value as Record<string, Object>;
    return record ?? null;
  }

  private readString(source: Record<string, Object> | null, key: string): string {
    if (!source) return '';
    const value = source[key];
    if (typeof value === 'string') {
      return value;
    }
    if (typeof value === 'number') {
      return String(value);
    }
    return '';
  }

  private readNumber(source: Record<string, Object> | null, key: string, fallback: number = 0): number {
    if (!source) return fallback;
    const value = source[key];
    if (typeof value === 'number') {
      return value;
    }
    if (typeof value === 'string') {
      const parsed = Number(value);
      return Number.isFinite(parsed) ? parsed : fallback;
    }
    return fallback;
  }

  private unwrapAsRecord(response: Object): Record<string, Object> | null {
    const obj = this.tryRecord(response);
    if (!obj) {
      return null;
    }
    const data = this.tryRecord(obj['data']);
    return data ?? obj;
  }

  private normalizeTravelStyle(style: string): string {
    const normalized = (style || '').toLowerCase();
    if (normalized === 'adventure' || normalized === 'relaxation' || normalized === 'culture' || normalized === 'nightlife') {
      return normalized;
    }
    if (normalized === 'foodie') {
      return 'nightlife';
    }
    if (normalized === 'nature') {
      return 'adventure';
    }
    if (normalized === 'shopping') {
      return 'relaxation';
    }
    return 'culture';
  }

  private async pollTaskResult(
    taskId: string,
    onProgress?: (progress: number, message: string) => void,
  ): Promise<Record<string, Object> | null> {
    const maxAttempts = 80;
    for (let index = 0; index < maxAttempts; index++) {
      const statusResp = await this.httpService.get<Object>(`${AI_TRAVEL_PLAN_ENDPOINT}/tasks/${taskId}`);
      const status = this.tryRecord(statusResp);
      const taskStatus = this.readString(status, 'status').toLowerCase();
      const progress = this.readNumber(status, 'progress', Math.min(95, 12 + index));
      const progressMessage = this.readString(status, 'progressMessage') || '正在生成旅行计划...';
      onProgress?.(progress, progressMessage);

      if (taskStatus === 'completed') {
        const planId = this.readString(status, 'planId');
        if (planId.length > 0) {
          const detail = await this.getDetail(planId);
          if (detail) {
            return detail;
          }
        }
        const result = this.tryRecord(status?.['result'] as Object | undefined);
        return result;
      }

      if (taskStatus === 'failed') {
        const err = this.readString(status, 'error') || 'AI 任务执行失败';
        throw new Error(err);
      }

      await this.delay(1500);
    }

    throw new Error('旅行计划生成超时，请稍后重试');
  }

  private delay(ms: number): Promise<void> {
    return new Promise<void>((resolve: () => void) => {
      setTimeout(() => {
        resolve();
      }, ms);
    });
  }
}
