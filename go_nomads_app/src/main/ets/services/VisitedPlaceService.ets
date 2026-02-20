import { HttpService } from './HttpService';
import {
  PaginatedVisitedPlaces,
  VisitedPlace,
  VisitedPlacesCitySummary,
  parsePaginatedVisitedPlaces,
  parseVisitedPlace,
  parseVisitedPlacesCitySummary,
} from '../models/VisitedPlace';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'VisitedPlaceService';
const DOMAIN = 0x0001;

export class VisitedPlaceService {
  private static instance: VisitedPlaceService | null = null;
  private httpService: HttpService;

  private constructor() {
    this.httpService = HttpService.getInstance();
  }

  static getInstance(): VisitedPlaceService {
    if (!VisitedPlaceService.instance) {
      VisitedPlaceService.instance = new VisitedPlaceService();
    }
    return VisitedPlaceService.instance;
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

    const items = root['items'];
    const list = root['list'];
    const resultList = root['result'];
    if (items instanceof Array) return items as Object[];
    if (list instanceof Array) return list as Object[];
    if (resultList instanceof Array) return resultList as Object[];

    return [];
  }

  private unwrapObjectPayload(result: Object): Record<string, Object> | null {
    if (result && typeof result === 'object') {
      const root = result as Record<string, Object>;
      const data = root['data'] as Object | undefined;
      if (data && typeof data === 'object' && !(data instanceof Array)) {
        return data as Record<string, Object>;
      }
      return root;
    }
    return null;
  }

  async getByTravelHistoryId(travelHistoryId: string): Promise<VisitedPlace[]> {
    if (!travelHistoryId) {
      return [];
    }

    try {
      const endpoint = `/visited-places/by-travel-history/${encodeURIComponent(travelHistoryId)}`;
      const result = await this.httpService.get<Object>(endpoint);
      const rawList = this.unwrapListPayload(result);

      const list: VisitedPlace[] = [];
      for (let i = 0; i < rawList.length; i++) {
        const parsed = parseVisitedPlace(rawList[i] as Record<string, Object>);
        if (parsed) {
          list.push(parsed);
        }
      }
      return list;
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ getByTravelHistoryId failed: %{public}s', (err as Error).message);
      return [];
    }
  }

  async getCitySummary(cityId: string, page: number = 1, pageSize: number = 20): Promise<VisitedPlacesCitySummary | null> {
    if (!cityId) {
      return null;
    }
    try {
      const endpoint = `/visited-places/city-summary/${encodeURIComponent(cityId)}`;
      const result = await this.httpService.get<Object>(endpoint, {
        queryParams: {
          page: page.toString(),
          pageSize: pageSize.toString(),
        },
      });
      const obj = this.unwrapObjectPayload(result);
      if (!obj) {
        return null;
      }
      return parseVisitedPlacesCitySummary(obj);
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ getCitySummary failed: %{public}s', (err as Error).message);
      return null;
    }
  }

  async getCityVisitedPlaces(cityId: string, page: number = 1, pageSize: number = 20): Promise<PaginatedVisitedPlaces> {
    const emptyResult: PaginatedVisitedPlaces = {
      items: [],
      totalCount: 0,
      page: 1,
      pageSize,
    };

    if (!cityId) {
      return emptyResult;
    }

    try {
      const endpoint = `/visited-places/city-summary/${encodeURIComponent(cityId)}`;
      const result = await this.httpService.get<Object>(endpoint, {
        queryParams: {
          page: page.toString(),
          pageSize: pageSize.toString(),
        },
      });
      const obj = this.unwrapObjectPayload(result);
      if (!obj) {
        return emptyResult;
      }
      const visitedPlaces = obj['visitedPlaces'] as Record<string, Object> | undefined;
      return parsePaginatedVisitedPlaces(visitedPlaces);
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ getCityVisitedPlaces failed: %{public}s', (err as Error).message);
      return emptyResult;
    }
  }

  async toggleHighlight(placeId: string, isHighlight: boolean): Promise<boolean> {
    if (!placeId) {
      return false;
    }
    try {
      await this.httpService.patch<Object>(`/visited-places/${encodeURIComponent(placeId)}/highlight`, {
        isHighlight,
      });
      return true;
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ toggleHighlight failed: %{public}s', (err as Error).message);
      return false;
    }
  }
}
