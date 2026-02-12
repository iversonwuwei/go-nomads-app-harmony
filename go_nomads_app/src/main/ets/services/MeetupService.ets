import { hilog } from '@kit.PerformanceAnalysisKit';
import { ApiConfig } from '../common/constants/ApiConfig';
import { Meetup, MeetupType } from '../models/Meetup';
import { HttpService, RequestOptions } from './HttpService';

const TAG = 'MeetupService';
const DOMAIN = 0x0001;

/**
 * 分页聚会响应
 */
interface PaginatedMeetupResponse {
  items: Object[];
  totalCount: number;
}

/**
 * 创建聚会请求体
 */
class CreateMeetupBody {
  title: string = '';
  description: string = '';
  location: string = '';
  address: string = '';
  category: string = '';
  startTime: string = '';
  endTime: string = '';
  maxParticipants: number = 0;
  locationType: string = 'physical';
  cityId: string = '';
  imageUrl: string = '';
}

/**
 * 聚会服务 —— 对应 Flutter 端 MeetupRepository
 * 封装所有 /events API 调用
 */
export class MeetupService {
  private static instance: MeetupService | null = null;
  private httpService: HttpService;

  private constructor() {
    this.httpService = HttpService.getInstance();
  }

  static getInstance(): MeetupService {
    if (!MeetupService.instance) {
      MeetupService.instance = new MeetupService();
    }
    return MeetupService.instance;
  }

  // =====================================================
  // 聚会列表
  // =====================================================

  /**
   * 获取聚会列表
   * GET /events?status=upcoming&page=1&pageSize=20&cityId=
   */
  async getMeetups(status: string = 'upcoming', page: number = 1, pageSize: number = 20, cityId?: string): Promise<Meetup[]> {
    try {
      const queryParams: Record<string, string> = {
        'status': status,
        'page': page.toString(),
        'pageSize': pageSize.toString(),
      };
      if (cityId && cityId.length > 0) {
        queryParams['cityId'] = cityId;
      }

      const result = await this.httpService.get<PaginatedMeetupResponse>(
        ApiConfig.EVENTS_ENDPOINT,
        { queryParams: queryParams } as RequestOptions
      );

      const items = result.items as Object[];
      const meetups = this.parseMeetupList(items);
      hilog.info(DOMAIN, TAG, '✅ getMeetups: %{public}d meetups (status=%{public}s)', meetups.length, status);
      return meetups;
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ getMeetups failed: %{public}s', (err as Error).message);
      throw new Error((err as Error).message);
    }
  }

  /**
   * 获取已加入的聚会
   * GET /events/joined?page=&pageSize=
   */
  async getJoinedMeetups(page: number = 1, pageSize: number = 20): Promise<Meetup[]> {
    try {
      const queryParams: Record<string, string> = {
        'page': page.toString(),
        'pageSize': pageSize.toString(),
      };

      const result = await this.httpService.get<PaginatedMeetupResponse>(
        `${ApiConfig.EVENTS_ENDPOINT}/joined`,
        { queryParams: queryParams } as RequestOptions
      );

      return this.parseMeetupList(result.items as Object[]);
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ getJoinedMeetups failed: %{public}s', (err as Error).message);
      throw new Error((err as Error).message);
    }
  }

  /**
   * 获取我创建的聚会
   * GET /events/me/created
   */
  async getMyCreatedMeetups(): Promise<Meetup[]> {
    try {
      const result = await this.httpService.get<Object>(
        `${ApiConfig.EVENTS_ENDPOINT}/me/created`
      );

      // 可能返回 { data: [...] } 或 { items: [...] } 或直接是数组
      let items: Object[];
      if (result instanceof Array) {
        items = result as Object[];
      } else {
        const resObj = result as Record<string, Object>;
        if (resObj['data'] && resObj['data'] instanceof Array) {
          items = resObj['data'] as Object[];
        } else if (resObj['items'] && resObj['items'] instanceof Array) {
          items = resObj['items'] as Object[];
        } else {
          items = [];
        }
      }

      return this.parseMeetupList(items);
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ getMyCreatedMeetups failed: %{public}s', (err as Error).message);
      throw new Error((err as Error).message);
    }
  }

  // =====================================================
  // 聚会详情
  // =====================================================

  /**
   * 获取聚会详情
   * GET /events/{id}
   */
  async getMeetupById(meetupId: string): Promise<Meetup> {
    try {
      const result = await this.httpService.get<Object>(
        `${ApiConfig.EVENTS_ENDPOINT}/${meetupId}`
      );

      const meetup = this.parseMeetup(result as Record<string, Object>);
      hilog.info(DOMAIN, TAG, '✅ getMeetupById: %{public}s', meetup.title);
      return meetup;
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ getMeetupById failed: %{public}s', (err as Error).message);
      throw new Error((err as Error).message);
    }
  }

  // =====================================================
  // 创建 / 更新 / 取消
  // =====================================================

  /**
   * 创建聚会
   * POST /events
   */
  async createMeetup(
    title: string,
    description: string,
    venue: string,
    address: string,
    type: MeetupType,
    startTime: string,
    endTime: string,
    maxAttendees: number,
    cityId?: string,
    imageUrl?: string
  ): Promise<Meetup> {
    try {
      const body = new CreateMeetupBody();
      body.title = title;
      body.description = description;
      body.location = venue;
      body.address = address;
      body.category = type as string;
      body.startTime = startTime;
      body.endTime = endTime;
      body.maxParticipants = maxAttendees;
      if (cityId) {
        body.cityId = cityId;
      }
      if (imageUrl) {
        body.imageUrl = imageUrl;
      }

      const result = await this.httpService.post<Object>(ApiConfig.EVENTS_ENDPOINT, body);
      const meetup = this.parseMeetup(result as Record<string, Object>);
      hilog.info(DOMAIN, TAG, '✅ createMeetup: %{public}s', meetup.title);
      return meetup;
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ createMeetup failed: %{public}s', (err as Error).message);
      throw new Error((err as Error).message);
    }
  }

  /**
   * 更新聚会
   * PUT /events/{id}
   */
  async updateMeetup(meetupId: string, updates: Record<string, Object>): Promise<Meetup> {
    try {
      const result = await this.httpService.put<Object>(
        `${ApiConfig.EVENTS_ENDPOINT}/${meetupId}`,
        updates
      );

      // 后端可能包装在 data 中
      let eventData: Record<string, Object>;
      const resObj = result as Record<string, Object>;
      if (resObj['data']) {
        eventData = resObj['data'] as Record<string, Object>;
      } else {
        eventData = resObj;
      }

      return this.parseMeetup(eventData);
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ updateMeetup failed: %{public}s', (err as Error).message);
      throw new Error((err as Error).message);
    }
  }

  /**
   * 取消聚会
   * POST /events/{id}/cancel
   */
  async cancelMeetup(meetupId: string): Promise<void> {
    try {
      await this.httpService.post<Object>(`${ApiConfig.EVENTS_ENDPOINT}/${meetupId}/cancel`);
      hilog.info(DOMAIN, TAG, '✅ cancelMeetup: %{public}s', meetupId);
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ cancelMeetup failed: %{public}s', (err as Error).message);
      throw new Error((err as Error).message);
    }
  }

  // =====================================================
  // RSVP / 退出
  // =====================================================

  /**
   * 加入聚会
   * POST /events/{id}/join
   */
  async joinMeetup(meetupId: string): Promise<void> {
    try {
      const body = new EmptyBody();
      await this.httpService.post<Object>(`${ApiConfig.EVENTS_ENDPOINT}/${meetupId}/join`, body);
      hilog.info(DOMAIN, TAG, '✅ joinMeetup: %{public}s', meetupId);
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ joinMeetup failed: %{public}s', (err as Error).message);
      throw new Error((err as Error).message);
    }
  }

  /**
   * 退出聚会
   * DELETE /events/{id}/join
   */
  async leaveMeetup(meetupId: string): Promise<void> {
    try {
      await this.httpService.delete<Object>(`${ApiConfig.EVENTS_ENDPOINT}/${meetupId}/join`);
      hilog.info(DOMAIN, TAG, '✅ leaveMeetup: %{public}s', meetupId);
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ leaveMeetup failed: %{public}s', (err as Error).message);
      throw new Error((err as Error).message);
    }
  }

  // =====================================================
  // 解析
  // =====================================================

  private parseMeetupList(items: Object[]): Meetup[] {
    const meetups: Meetup[] = [];
    for (let i = 0; i < items.length; i++) {
      try {
        const meetup = this.parseMeetup(items[i] as Record<string, Object>);
        meetups.push(meetup);
      } catch (e) {
        hilog.warn(DOMAIN, TAG, '⚠️ Parse meetup failed at index %{public}d', i);
      }
    }
    return meetups;
  }

  private parseMeetup(json: Record<string, Object>): Meetup {
    return {
      id: (json['id'] as string) ?? '',
      title: (json['title'] as string) ?? '',
      type: this.parseMeetupType(json['category'] as string),
      description: (json['description'] as string) ?? '',
      cityId: json['cityId'] as string | undefined,
      cityName: json['cityName'] as string | undefined,
      venue: {
        name: (json['location'] as string) ?? '',
        address: json['address'] as string | undefined,
        latitude: json['latitude'] as number | undefined,
        longitude: json['longitude'] as number | undefined,
      },
      schedule: {
        startTime: (json['startTime'] as string) ?? new Date().toISOString(),
        endTime: json['endTime'] as string | undefined,
      },
      capacity: {
        max: json['maxParticipants'] as number | undefined,
        current: (json['participantCount'] as number) ?? 0,
      },
      organizer: {
        id: (json['organizerId'] as string) ?? '',
        name: this.parseOrganizerName(json),
        avatar: this.parseOrganizerAvatar(json),
      },
      images: this.parseStringArray(json['images'] as Object),
      attendeeIds: this.parseStringArray(json['attendeeIds'] as Object),
      status: this.parseMeetupStatus(json['status'] as string),
      createdAt: (json['createdAt'] as string) ?? '',
      isJoined: json['isParticipant'] as boolean | undefined,
      isOrganizer: json['isOrganizer'] as boolean | undefined,
    } as Meetup;
  }

  private parseOrganizerName(json: Record<string, Object>): string {
    const organizer = json['organizer'] as Record<string, Object> | undefined;
    if (organizer) {
      return (organizer['userName'] as string) ?? (organizer['name'] as string) ?? '';
    }
    return '';
  }

  private parseOrganizerAvatar(json: Record<string, Object>): string | undefined {
    const organizer = json['organizer'] as Record<string, Object> | undefined;
    if (organizer) {
      return organizer['avatar'] as string | undefined;
    }
    return undefined;
  }

  private parseMeetupType(category: string | undefined): MeetupType {
    if (!category) {
      return MeetupType.Other;
    }
    switch (category.toLowerCase()) {
      case 'social': return MeetupType.Social;
      case 'coworking': return MeetupType.Coworking;
      case 'workshop': return MeetupType.Workshop;
      case 'sports': return MeetupType.Sports;
      case 'cultural': return MeetupType.Cultural;
      case 'networking': return MeetupType.Networking;
      default: return MeetupType.Other;
    }
  }

  private parseMeetupStatus(status: string | undefined): string {
    return status ?? 'published';
  }

  private parseStringArray(val: Object | undefined): string[] {
    if (!val || !(val instanceof Array)) {
      return [];
    }
    const arr: string[] = [];
    const objArr = val as Object[];
    for (let i = 0; i < objArr.length; i++) {
      arr.push(objArr[i] as string);
    }
    return arr;
  }
}

class EmptyBody {
  placeholder: string = '';
}
