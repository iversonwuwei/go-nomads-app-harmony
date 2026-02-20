import { ApiConfig } from '../common/constants/ApiConfig';
import { HttpService } from './HttpService';
import { AppNotification, parseNotification } from '../models/Notification';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'NotificationService';
const DOMAIN = 0x0001;

export class NotificationService {
  private static instance: NotificationService | null = null;
  private httpService: HttpService;

  private constructor() {
    this.httpService = HttpService.getInstance();
  }

  static getInstance(): NotificationService {
    if (!NotificationService.instance) {
      NotificationService.instance = new NotificationService();
    }
    return NotificationService.instance;
  }

  async getAll(): Promise<AppNotification[]> {
    try {
      const result = await this.httpService.get<Object>(ApiConfig.NOTIFICATIONS_ENDPOINT);
      let items: Object[] = [];
      if (result instanceof Array) {
        items = result as Object[];
      } else {
        const obj = result as Record<string, Object>;
        const data = obj['data'] as Object[] | undefined;
        if (data && data instanceof Array) {
          items = data;
        }
      }
      const parsed: AppNotification[] = [];
      for (let i = 0; i < items.length; i++) {
        const n = parseNotification(items[i] as Record<string, Object>);
        if (n) parsed.push(n);
      }
      return parsed;
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ getAll failed: %{public}s', (err as Error).message);
      return [];
    }
  }
}
