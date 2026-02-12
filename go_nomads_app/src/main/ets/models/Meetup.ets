/**
 * Meetup 状态枚举
 */
export enum MeetupStatus {
  Draft = 'draft',
  Published = 'published',
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
 * 聚会组织者
 */
export interface MeetupOrganizer {
  id: string;
  name: string;
  avatar?: string;
}

/**
 * 聚会地点
 */
export interface MeetupVenue {
  name: string;
  address?: string;
  latitude?: number;
  longitude?: number;
}

/**
 * 聚会时间
 */
export interface MeetupSchedule {
  startTime: string;
  endTime?: string;
}

/**
 * 聚会容量
 */
export interface MeetupCapacity {
  min?: number;
  max?: number;
  current: number;
}

/**
 * 聚会实体 - 对应 Flutter 端 Meetup domain entity
 */
export interface Meetup {
  id: string;
  title: string;
  type: MeetupType;
  description: string;
  cityId?: string;
  cityName?: string;
  venue: MeetupVenue;
  schedule: MeetupSchedule;
  capacity: MeetupCapacity;
  organizer: MeetupOrganizer;
  images: string[];
  attendeeIds: string[];
  status: MeetupStatus;
  createdAt: string;
  isJoined?: boolean;
  isOrganizer?: boolean;
}

/**
 * Meetup 辅助方法
 */
export class MeetupHelper {
  /** 是否即将开始（24小时内） */
  static isStartingSoon(meetup: Meetup): boolean {
    const now = new Date();
    const start = new Date(meetup.schedule.startTime);
    const diffHours = (start.getTime() - now.getTime()) / (1000 * 60 * 60);
    return diffHours > 0 && diffHours <= 24;
  }

  /** 是否已结束 */
  static isEnded(meetup: Meetup): boolean {
    if (meetup.status === MeetupStatus.Completed) return true;
    return new Date(meetup.schedule.startTime) < new Date();
  }

  /** 是否正在进行 */
  static isOngoing(meetup: Meetup): boolean {
    const now = new Date();
    const start = new Date(meetup.schedule.startTime);
    if (!meetup.schedule.endTime) return false;
    const end = new Date(meetup.schedule.endTime);
    return now > start && now < end;
  }

  /** 是否已满员 */
  static isFull(meetup: Meetup): boolean {
    return meetup.capacity.max !== undefined && meetup.capacity.current >= meetup.capacity.max;
  }

  /** 可否加入 */
  static canJoin(meetup: Meetup): boolean {
    if (MeetupHelper.isEnded(meetup) || MeetupHelper.isOngoing(meetup)) return false;
    if (MeetupHelper.isFull(meetup)) return false;
    if (meetup.isOrganizer) return false;
    if (meetup.isJoined) return false;
    return true;
  }
}
