/**
 * Meetup 状态枚举
 */
export enum MeetupStatus {
  Draft = 'draft',
  Published = 'published',
  Upcoming = 'upcoming',
  Cancelled = 'cancelled',
  Completed = 'completed',
}

/**
 * Meetup 类型枚举
 */
export enum MeetupType {
  Social = 'social',
  Coworking = 'coworking',
  Workshop = 'workshop',
  Sports = 'sports',
  Cultural = 'cultural',
  Networking = 'networking',
  Other = 'other',
}

/**
 * 城市信息（后端 CityInfo）
 */
export interface MeetupCityInfo {
  id: string;
  name: string;
  country: string;
  region?: string;
  imageUrl?: string;
  timeZone?: string;
}

/**
 * 组织者信息（后端 OrganizerInfo）
 */
export interface MeetupOrganizerInfo {
  id: string;
  name: string;
  email: string;
  avatarUrl?: string;
}

/**
 * 聚会实体 - 对应后端 EventResponse DTO
 */
export interface Meetup {
  id: string;
  title: string;
  description?: string;
  organizerId: string;
  cityId?: string;
  location?: string;
  address?: string;
  imageUrl?: string;
  images?: string[];
  category?: string;
  startTime: string;
  endTime?: string;
  maxParticipants?: number;
  participantCount: number;
  status: string;
  locationType: string;
  meetingLink?: string;
  latitude?: number;
  longitude?: number;
  tags?: string[];
  isFeatured: boolean;
  createdAt: string;
  updatedAt: string;
  isFollowing: boolean;
  isParticipant: boolean;
  isOrganizer: boolean;
  followerCount: number;
  city?: MeetupCityInfo;
  organizer?: MeetupOrganizerInfo;
}

/**
 * Meetup 辅助方法
 */
export class MeetupHelper {
  /** 是否即将开始（24小时内） */
  static isStartingSoon(meetup: Meetup): boolean {
    if (!meetup.startTime) return false;
    const now = new Date();
    const start = new Date(meetup.startTime);
    const diffHours = (start.getTime() - now.getTime()) / (1000 * 60 * 60);
    return diffHours > 0 && diffHours <= 24;
  }

  /** 是否已结束 */
  static isEnded(meetup: Meetup): boolean {
    if (meetup.status === MeetupStatus.Completed || meetup.status === 'completed') return true;
    if (!meetup.startTime) return false;
    return new Date(meetup.startTime) < new Date();
  }

  /** 是否正在进行 */
  static isOngoing(meetup: Meetup): boolean {
    if (!meetup.startTime || !meetup.endTime) return false;
    const now = new Date();
    const start = new Date(meetup.startTime);
    const end = new Date(meetup.endTime);
    return now > start && now < end;
  }

  /** 是否已满员 */
  static isFull(meetup: Meetup): boolean {
    return meetup.maxParticipants !== undefined && meetup.participantCount >= meetup.maxParticipants;
  }

  /** 可否加入 */
  static canJoin(meetup: Meetup): boolean {
    if (MeetupHelper.isEnded(meetup) || MeetupHelper.isOngoing(meetup)) return false;
    if (MeetupHelper.isFull(meetup)) return false;
    if (meetup.isOrganizer) return false;
    if (meetup.isParticipant) return false;
    return true;
  }

  /** 获取显示地点名称 */
  static displayLocation(meetup: Meetup): string {
    return meetup.location || meetup.city?.name || '未知地点';
  }
}
