import { hilog } from '@kit.PerformanceAnalysisKit';
import { ApiConfig } from '../common/constants/ApiConfig';
import { City, CityHelper } from '../models/City';
import { HttpService, RequestOptions } from './HttpService';

const TAG = 'CityService';
const DOMAIN = 0x0001;

/**
 * 分页响应
 */
interface PaginatedResponse {
  items: Object[];
  totalCount: number;
}

/**
 * 收藏状态
 */
interface FavoriteCheckResult {
  isFavorited: boolean;
}

/**
 * 城市服务 —— 对应 Flutter 端 CityRepository
 * 封装所有城市相关 API 调用并做 JSON → City 转换
 */
export class CityService {
  private static instance: CityService | null = null;
  private httpService: HttpService;

  private constructor() {
    this.httpService = HttpService.getInstance();
  }

  static getInstance(): CityService {
    if (!CityService.instance) {
      CityService.instance = new CityService();
    }
    return CityService.instance;
  }

  // =====================================================
  // 城市列表
  // =====================================================

  /**
   * 获取城市列表（轻量级，不含天气）
   * GET /cities/list?pageNumber=&pageSize=&search=&countryId=
   */
  async getCities(page: number = 1, pageSize: number = 20, search?: string, countryId?: string): Promise<City[]> {
    try {
      const queryParams: Record<string, string> = {
        'pageNumber': page.toString(),
        'pageSize': pageSize.toString(),
      };
      if (search && search.length > 0) {
        queryParams['search'] = search;
      }
      if (countryId && countryId.length > 0) {
        queryParams['countryId'] = countryId;
      }

      const result = await this.httpService.get<PaginatedResponse>(
        ApiConfig.CITY_LIST_ENDPOINT,
        { queryParams: queryParams } as RequestOptions
      );

      // HttpService 自动解包 ApiResponse.data，拿到 { items, totalCount }
      const items = result.items as Object[];
      const cities = this.parseCityList(items);
      hilog.info(DOMAIN, TAG, '✅ getCities: %{public}d cities (page %{public}d)', cities.length, page);
      return cities;
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ getCities failed: %{public}s', (err as Error).message);
      throw new Error((err as Error).message);
    }
  }

  /**
   * 搜索城市
   * GET /cities/search?name=&page=&pageSize=
   */
  async searchCities(name: string, page: number = 1, pageSize: number = 20): Promise<City[]> {
    try {
      const queryParams: Record<string, string> = {
        'name': name,
        'page': page.toString(),
        'pageSize': pageSize.toString(),
      };

      const result = await this.httpService.get<Object>(
        ApiConfig.CITY_SEARCH_ENDPOINT,
        { queryParams: queryParams } as RequestOptions
      );

      // 搜索 API 可能直接返回数组或包在 items/data 中
      let items: Object[];
      if (result instanceof Array) {
        items = result as Object[];
      } else {
        const resultObj = result as Record<string, Object>;
        if (resultObj['items']) {
          items = resultObj['items'] as Object[];
        } else if (resultObj['data']) {
          items = resultObj['data'] as Object[];
        } else {
          items = [];
        }
      }

      return this.parseCityList(items);
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ searchCities failed: %{public}s', (err as Error).message);
      throw new Error((err as Error).message);
    }
  }

  /**
   * 获取推荐城市
   * GET /cities/recommended?count=&countryId=
   */
  async getRecommendedCities(limit: number = 10, countryId?: string): Promise<City[]> {
    try {
      const queryParams: Record<string, string> = {
        'count': limit.toString(),
      };
      if (countryId && countryId.length > 0) {
        queryParams['countryId'] = countryId;
      }

      const result = await this.httpService.get<Object[]>(
        ApiConfig.CITY_RECOMMENDED_ENDPOINT,
        { queryParams: queryParams } as RequestOptions
      );

      return this.parseCityList(result as Object[]);
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ getRecommendedCities failed: %{public}s', (err as Error).message);
      throw new Error((err as Error).message);
    }
  }

  // =====================================================
  // 城市详情
  // =====================================================

  /**
   * 获取城市详情
   * GET /cities/{id}
   */
  async getCityById(cityId: string): Promise<City> {
    try {
      const result = await this.httpService.get<Object>(
        `${ApiConfig.CITY_DETAIL_ENDPOINT}/${cityId}`
      );

      const city = CityHelper.fromJson(result as Record<string, Object>);
      hilog.info(DOMAIN, TAG, '✅ getCityById: %{public}s', city.name);
      return city;
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ getCityById failed: %{public}s', (err as Error).message);
      throw new Error((err as Error).message);
    }
  }

  // =====================================================
  // 收藏
  // =====================================================

  /**
   * 检查是否已收藏
   * GET /user-favorite-cities/check/{cityId}
   */
  async isCityFavorited(cityId: string): Promise<boolean> {
    try {
      const result = await this.httpService.get<FavoriteCheckResult>(
        `/user-favorite-cities/check/${cityId}`
      );
      return result.isFavorited;
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ isCityFavorited failed: %{public}s', (err as Error).message);
      return false;
    }
  }

  /**
   * 收藏城市
   * POST /user-favorite-cities
   */
  async favoriteCity(cityId: string): Promise<void> {
    try {
      const body = new FavoriteCityBody();
      body.cityId = cityId;
      await this.httpService.post<Object>('/user-favorite-cities', body);
      hilog.info(DOMAIN, TAG, '✅ favoriteCity: %{public}s', cityId);
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ favoriteCity failed: %{public}s', (err as Error).message);
      throw new Error((err as Error).message);
    }
  }

  /**
   * 取消收藏
   * POST /user-favorite-cities/{cityId}/remove
   */
  async unfavoriteCity(cityId: string): Promise<void> {
    try {
      await this.httpService.post<Object>(`/user-favorite-cities/${cityId}/remove`);
      hilog.info(DOMAIN, TAG, '✅ unfavoriteCity: %{public}s', cityId);
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ unfavoriteCity failed: %{public}s', (err as Error).message);
      throw new Error((err as Error).message);
    }
  }

  /**
   * 获取收藏城市列表
   * GET /user-favorite-cities/details?page=1&pageSize=100
   */
  async getFavoriteCities(): Promise<City[]> {
    try {
      const result = await this.httpService.get<PaginatedResponse>(
        '/user-favorite-cities/details',
        { queryParams: { 'page': '1', 'pageSize': '100' } } as RequestOptions
      );
      return this.parseCityList(result.items as Object[]);
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ getFavoriteCities failed: %{public}s', (err as Error).message);
      return [];
    }
  }

  /**
   * 获取收藏城市 ID 列表
   * GET /user-favorite-cities/ids
   */
  async getUserFavoriteCityIds(): Promise<string[]> {
    try {
      const result = await this.httpService.get<string[]>('/user-favorite-cities/ids');
      return result;
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ getUserFavoriteCityIds failed: %{public}s', (err as Error).message);
      return [];
    }
  }

  // =====================================================
  // 辅助方法
  // =====================================================

  private parseCityList(items: Object[]): City[] {
    const cities: City[] = [];
    for (let i = 0; i < items.length; i++) {
      try {
        const city = CityHelper.fromJson(items[i] as Record<string, Object>);
        cities.push(city);
      } catch (e) {
        hilog.warn(DOMAIN, TAG, '⚠️ Parse city failed at index %{public}d', i);
      }
    }
    return cities;
  }
}

class FavoriteCityBody {
  cityId: string = '';
}
