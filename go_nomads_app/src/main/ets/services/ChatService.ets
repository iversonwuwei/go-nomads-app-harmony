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
      const result = await this.httpService.get<Object[]>(ApiConfig.CHATS_ENDPOINT);

      // 结果可能直接是数组或在 data 中
      let items: Object[];
      if (result instanceof Array) {
        items = result as Object[];
      } else {
        items = [];
      }

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
      return this.parseChatRoom(result as Record<string, Object>);
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
      return this.parseChatRoom(result as Record<string, Object>);
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
      return this.parseChatRoom(result as Record<string, Object>);
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

      const result = await this.httpService.get<Object[]>(
        `${ApiConfig.CHATS_ENDPOINT}/${roomId}/messages`,
        { queryParams: queryParams } as RequestOptions
      );

      let items: Object[];
      if (result instanceof Array) {
        items = result as Object[];
      } else {
        items = [];
      }

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
      return this.parseMessage(result as Record<string, Object>);
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
    return {
      id: (json['id'] as string) ?? '',
      name: (json['name'] as string) ?? (json['title'] as string) ?? '',
      type: (json['type'] as string) ?? 'group',
      lastMessage: json['lastMessage'] as string | undefined,
      lastMessageTime: json['lastMessageTime'] as string | undefined,
      unreadCount: (json['unreadCount'] as number) ?? 0,
      avatarUrl: json['avatarUrl'] as string | undefined,
      participantCount: json['participantCount'] as number | undefined,
      meetupId: json['meetupId'] as string | undefined,
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
    return {
      id: (json['id'] as string) ?? '',
      roomId: (json['roomId'] as string) ?? (json['chatRoomId'] as string) ?? '',
      senderId: (json['senderId'] as string) ?? (json['userId'] as string) ?? '',
      senderName: (json['senderName'] as string) ?? (json['userName'] as string) ?? '',
      senderAvatar: json['senderAvatar'] as string | undefined,
      content: (json['content'] as string) ?? (json['message'] as string) ?? '',
      createdAt: (json['createdAt'] as string) ?? '',
      replyToId: json['replyToId'] as string | undefined,
      isDeleted: (json['isDeleted'] as boolean) ?? false,
    } as ChatMessage;
  }
}

class JoinBody {
  placeholder: string = '';
}
