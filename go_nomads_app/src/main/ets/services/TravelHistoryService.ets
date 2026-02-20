import { ApiConfig } from '../common/constants/ApiConfig';
import { HttpService, RequestOptions } from './HttpService';
import { TravelHistory, parseTravelHistory } from '../models/TravelHistory';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'TravelHistoryService';
const DOMAIN = 0x0001;

/**
 * 旅行历史服务 - 获取当前用户的最新旅行记录
 */
export class TravelHistoryService {
  private static instance: TravelHistoryService | null = null;
  private httpService: HttpService;

  private constructor() {
    this.httpService = HttpService.getInstance();
  }

  static getInstance(): TravelHistoryService {
    if (!TravelHistoryService.instance) {
      TravelHistoryService.instance = new TravelHistoryService();
    }
    return TravelHistoryService.instance;
  }

  private unwrapListPayload(result: Object): Object[] {
    if (result instanceof Array) {
      return result as Object[];
    }

    const root = result as Record<string, Object>;
    const data = root['data'] as Object | undefined;

    if (data instanceof Array) {
      return data as Object[];
    }

    if (data && typeof data === 'object') {
      const dataObj = data as Record<string, Object>;
      const items = dataObj['items'];
      const list = dataObj['list'];
      const resultList = dataObj['result'];
      if (items instanceof Array) return items as Object[];
      if (list instanceof Array) return list as Object[];
      if (resultList instanceof Array) return resultList as Object[];
    }

    const rootItems = root['items'];
    const rootList = root['list'];
    const rootResult = root['result'];
    if (rootItems instanceof Array) return rootItems as Object[];
    if (rootList instanceof Array) return rootList as Object[];
    if (rootResult instanceof Array) return rootResult as Object[];

    return [];
  }

  /**
   * 获取最新一条旅行历史 (pageSize=1)
   */
  async getLatest(): Promise<TravelHistory | null> {
    try {
      const options: RequestOptions = {
        queryParams: {
          'page': '1',
          'pageSize': '1',
        },
      };
      const result = await this.httpService.get<Object>(ApiConfig.TRAVEL_HISTORY_ENDPOINT, options);
      const items = this.unwrapListPayload(result);
      if (items.length === 0) {
        return null;
      }
      const parsed = parseTravelHistory(items[0] as Record<string, Object>);
      return parsed;
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ getLatest failed: %{public}s', (err as Error).message);
      return null;
    }
  }

  /**
   * 获取旅行历史列表
   */
  async getList(page: number = 1, pageSize: number = 20): Promise<TravelHistory[]> {
    try {
      const options: RequestOptions = {
        queryParams: {
          'page': page.toString(),
          'pageSize': pageSize.toString(),
        },
      };
      const result = await this.httpService.get<Object>(ApiConfig.TRAVEL_HISTORY_ENDPOINT, options);
      const items = this.unwrapListPayload(result);

      const list: TravelHistory[] = [];
      for (let i = 0; i < items.length; i++) {
        const parsed = parseTravelHistory(items[i] as Record<string, Object>);
        if (parsed) {
          list.push(parsed);
        }
      }
      return list;
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ getList failed: %{public}s', (err as Error).message);
      return [];
    }
  }
}
