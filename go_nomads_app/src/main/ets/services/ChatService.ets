import { hilog } from '@kit.PerformanceAnalysisKit';
import { ApiConfig } from '../common/constants/ApiConfig';
import { HttpService, RequestOptions } from './HttpService';

const TAG = 'ChatService';
const DOMAIN = 0x0001;

/**
 * 聊天室
 */
export interface ChatRoom {
  id: string;
  name: string;
  type: string;
  lastMessage?: string;
  lastMessageTime?: string;
  unreadCount: number;
  avatarUrl?: string;
  participantCount?: number;
  meetupId?: string;
}

/**
 * 聊天消息
 */
export interface ChatMessage {
  id: string;
  roomId: string;
  senderId: string;
  senderName: string;
  senderAvatar?: string;
  content: string;
  createdAt: string;
  replyToId?: string;
  isDeleted: boolean;
}

/**
 * 发送消息请求
 */
class SendMessageBody {
  message: string = '';
  replyToId: string = '';
}

/**
 * 创建私聊请求
 */
class CreateDirectChatBody {
  targetUserId: string = '';
  targetUserName: string = '';
}

/**
 * 创建 Meetup 聊天室请求
 */
class CreateMeetupChatBody {
  meetupId: string = '';
  meetupTitle: string = '';
}

/**
 * 聊天服务 —— 对应 Flutter 端 ChatRepository
 */
export class ChatService {
  private static instance: ChatService | null = null;
  private httpService: HttpService;

  private constructor() {
    this.httpService = HttpService.getInstance();
  }

  static getInstance(): ChatService {
    if (!ChatService.instance) {
      ChatService.instance = new ChatService();
    }
    return ChatService.instance;
  }

  // =====================================================
  // 聊天室管理
  // =====================================================

  /**
   * 获取聊天室列表
   * GET /chats
   */
  async getChatRooms(): Promise<ChatRoom[]> {
    try {
      const result = await this.httpService.get<Object>(ApiConfig.CHATS_ENDPOINT);
      const items = this.unwrapArray(result);

      const rooms = this.parseChatRoomList(items);
      hilog.info(DOMAIN, TAG, '✅ getChatRooms: %{public}d rooms', rooms.length);
      return rooms;
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ getChatRooms failed: %{public}s', (err as Error).message);
      throw new Error((err as Error).message);
    }
  }

  /**
   * 获取聊天室详情
   * GET /chats/{id}
   */
  async getChatRoomById(roomId: string): Promise<ChatRoom> {
    try {
      const result = await this.httpService.get<Object>(
        `${ApiConfig.CHATS_ENDPOINT}/${roomId}`
      );
      const payload = this.unwrapRecord(result);
      return this.parseChatRoom(payload ?? (result as Record<string, Object>));
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ getChatRoomById failed: %{public}s', (err as Error).message);
      throw new Error((err as Error).message);
    }
  }

  /**
   * 加入聊天室
   * POST /chats/{id}/join
   */
  async joinChatRoom(roomId: string): Promise<void> {
    try {
      const body = new JoinBody();
      await this.httpService.post<Object>(`${ApiConfig.CHATS_ENDPOINT}/${roomId}/join`, body);
      hilog.info(DOMAIN, TAG, '✅ joinChatRoom: %{public}s', roomId);
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ joinChatRoom failed: %{public}s', (err as Error).message);
      throw new Error((err as Error).message);
    }
  }

  /**
   * 离开聊天室
   * POST /chats/{id}/leave
   */
  async leaveChatRoom(roomId: string): Promise<void> {
    try {
      const body = new JoinBody();
      await this.httpService.post<Object>(`${ApiConfig.CHATS_ENDPOINT}/${roomId}/leave`, body);
      hilog.info(DOMAIN, TAG, '✅ leaveChatRoom: %{public}s', roomId);
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ leaveChatRoom failed: %{public}s', (err as Error).message);
      throw new Error((err as Error).message);
    }
  }

  /**
   * 创建或获取私聊
   * POST /chats/direct
   */
  async getOrCreateDirectChat(targetUserId: string, targetUserName: string): Promise<ChatRoom> {
    try {
      const body = new CreateDirectChatBody();
      body.targetUserId = targetUserId;
      body.targetUserName = targetUserName;

      const result = await this.httpService.post<Object>(
        `${ApiConfig.CHATS_ENDPOINT}/direct`,
        body
      );
      const payload = this.unwrapRecord(result);
      return this.parseChatRoom(payload ?? (result as Record<string, Object>));
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ getOrCreateDirectChat failed: %{public}s', (err as Error).message);
      throw new Error((err as Error).message);
    }
  }

  /**
   * 创建或获取 Meetup 聊天室
   * POST /chats/meetup
   */
  async getOrCreateMeetupChat(meetupId: string, meetupTitle: string): Promise<ChatRoom> {
    try {
      const body = new CreateMeetupChatBody();
      body.meetupId = meetupId;
      body.meetupTitle = meetupTitle;

      const result = await this.httpService.post<Object>(
        `${ApiConfig.CHATS_ENDPOINT}/meetup`,
        body
      );
      const payload = this.unwrapRecord(result);
      return this.parseChatRoom(payload ?? (result as Record<string, Object>));
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ getOrCreateMeetupChat failed: %{public}s', (err as Error).message);
      throw new Error((err as Error).message);
    }
  }

  // =====================================================
  // 消息管理
  // =====================================================

  /**
   * 获取消息列表
   * GET /chats/{id}/messages?page=&pageSize=
   */
  async getMessages(roomId: string, page: number = 1, pageSize: number = 20): Promise<ChatMessage[]> {
    try {
      const queryParams: Record<string, string> = {
        'page': page.toString(),
        'pageSize': pageSize.toString(),
      };

      const result = await this.httpService.get<Object>(
        `${ApiConfig.CHATS_ENDPOINT}/${roomId}/messages`,
        { queryParams: queryParams } as RequestOptions
      );

      const items = this.unwrapArray(result);

      const messages = this.parseMessageList(items);
      hilog.info(DOMAIN, TAG, '✅ getMessages: %{public}d messages', messages.length);
      return messages;
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ getMessages failed: %{public}s', (err as Error).message);
      throw new Error((err as Error).message);
    }
  }

  /**
   * 发送消息
   * POST /chats/{id}/messages
   */
  async sendMessage(roomId: string, message: string, replyToId?: string): Promise<ChatMessage> {
    try {
      const body = new SendMessageBody();
      body.message = message;
      if (replyToId) {
        body.replyToId = replyToId;
      }

      const result = await this.httpService.post<Object>(
        `${ApiConfig.CHATS_ENDPOINT}/${roomId}/messages`,
        body
      );
      const payload = this.unwrapRecord(result);
      return this.parseMessage(payload ?? (result as Record<string, Object>));
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ sendMessage failed: %{public}s', (err as Error).message);
      throw new Error((err as Error).message);
    }
  }

  /**
   * 删除消息
   * DELETE /chats/{id}/messages/{messageId}
   */
  async deleteMessage(roomId: string, messageId: string): Promise<void> {
    try {
      await this.httpService.delete<Object>(
        `${ApiConfig.CHATS_ENDPOINT}/${roomId}/messages/${messageId}`
      );
      hilog.info(DOMAIN, TAG, '✅ deleteMessage: %{public}s', messageId);
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ deleteMessage failed: %{public}s', (err as Error).message);
      throw new Error((err as Error).message);
    }
  }

  // =====================================================
  // 解析
  // =====================================================

  private parseChatRoomList(items: Object[]): ChatRoom[] {
    const rooms: ChatRoom[] = [];
    for (let i = 0; i < items.length; i++) {
      try {
        rooms.push(this.parseChatRoom(items[i] as Record<string, Object>));
      } catch (e) {
        hilog.warn(DOMAIN, TAG, '⚠️ parseChatRoom failed at index %{public}d', i);
      }
    }
    return rooms;
  }

  private parseChatRoom(json: Record<string, Object>): ChatRoom {
    const lastMessageRaw = this.readString(json, 'lastMessage') || this.readString(json, 'lastContent');
    const lastTimeRaw = this.readString(json, 'lastMessageTime') || this.readString(json, 'lastMessageAt');
    return {
      id: this.readString(json, 'id'),
      name: this.readString(json, 'name') || this.readString(json, 'title') || '聊天',
      type: this.readString(json, 'type') || 'group',
      lastMessage: lastMessageRaw.length > 0 ? lastMessageRaw : undefined,
      lastMessageTime: lastTimeRaw.length > 0 ? lastTimeRaw : undefined,
      unreadCount: this.readNumber(json, 'unreadCount', 0),
      avatarUrl: this.readString(json, 'avatarUrl') || this.readString(json, 'avatar') || undefined,
      participantCount: this.readNumber(json, 'participantCount', 0) || undefined,
      meetupId: this.readString(json, 'meetupId') || undefined,
    } as ChatRoom;
  }

  private parseMessageList(items: Object[]): ChatMessage[] {
    const messages: ChatMessage[] = [];
    for (let i = 0; i < items.length; i++) {
      try {
        messages.push(this.parseMessage(items[i] as Record<string, Object>));
      } catch (e) {
        hilog.warn(DOMAIN, TAG, '⚠️ parseMessage failed at index %{public}d', i);
      }
    }
    return messages;
  }

  private parseMessage(json: Record<string, Object>): ChatMessage {
    const createdAt = this.readString(json, 'createdAt') || this.readString(json, 'sentAt') || new Date().toISOString();
    return {
      id: this.readString(json, 'id') || `msg_${Date.now()}`,
      roomId: this.readString(json, 'roomId') || this.readString(json, 'chatRoomId'),
      senderId: this.readString(json, 'senderId') || this.readString(json, 'userId'),
      senderName: this.readString(json, 'senderName') || this.readString(json, 'userName') || '用户',
      senderAvatar: this.readString(json, 'senderAvatar') || this.readString(json, 'avatarUrl') || undefined,
      content: this.readString(json, 'content') || this.readString(json, 'message'),
      createdAt: createdAt,
      replyToId: this.readString(json, 'replyToId') || undefined,
      isDeleted: this.readBoolean(json, 'isDeleted', false),
    } as ChatMessage;
  }

  private readString(source: Record<string, Object> | null, key: string): string {
    if (!source) return '';
    const value = source[key];
    if (typeof value === 'string') return value;
    if (typeof value === 'number') return String(value);
    return '';
  }

  private readNumber(source: Record<string, Object> | null, key: string, fallback: number): number {
    if (!source) return fallback;
    const value = source[key];
    if (typeof value === 'number') return value;
    if (typeof value === 'string') {
      const parsed = Number(value);
      return Number.isFinite(parsed) ? parsed : fallback;
    }
    return fallback;
  }

  private readBoolean(source: Record<string, Object> | null, key: string, fallback: boolean): boolean {
    if (!source) return fallback;
    const value = source[key];
    if (typeof value === 'boolean') return value;
    if (typeof value === 'string') return value.toLowerCase() === 'true';
    return fallback;
  }

  private tryRecord(value: Object | undefined): Record<string, Object> | null {
    if (!value) return null;
    const obj = value as Record<string, Object>;
    return obj ?? null;
  }

  private tryArray(value: Object | undefined): Object[] {
    if (value instanceof Array) {
      return value as Object[];
    }
    return [];
  }

  private unwrapRecord(payload: Object): Record<string, Object> | null {
    const root = this.tryRecord(payload);
    if (!root) return null;
    const data = root['data'];
    if (data) {
      const dataRecord = this.tryRecord(data as Object);
      if (dataRecord) return dataRecord;
    }
    const result = root['result'];
    if (result) {
      const resultRecord = this.tryRecord(result as Object);
      if (resultRecord) return resultRecord;
    }
    return root;
  }

  private unwrapArray(payload: Object): Object[] {
    if (payload instanceof Array) {
      return payload as Object[];
    }
    const root = this.tryRecord(payload);
    if (!root) return [];

    const fromDataDirect = this.tryArray(root['data'] as Object | undefined);
    if (fromDataDirect.length > 0) return fromDataDirect;

    const data = this.tryRecord(root['data'] as Object | undefined);
    const dataItems = this.tryArray(data?.['items'] as Object | undefined);
    if (dataItems.length > 0) return dataItems;
    const dataList = this.tryArray(data?.['list'] as Object | undefined);
    if (dataList.length > 0) return dataList;

    const rootItems = this.tryArray(root['items'] as Object | undefined);
    if (rootItems.length > 0) return rootItems;
    const rootList = this.tryArray(root['list'] as Object | undefined);
    if (rootList.length > 0) return rootList;

    return [];
  }
}

class JoinBody {
  placeholder: string = '';
}
