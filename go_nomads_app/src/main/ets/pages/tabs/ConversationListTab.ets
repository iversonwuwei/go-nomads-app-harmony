import { AppColors } from '../../common/constants/AppColors';
import { AppStorageKeys } from '../../common/constants/AppStorageKeys';
import { RouteConstants } from '../../common/constants/RouteConstants';
import { HttpService } from '../../services/HttpService';
import { ApiConfig } from '../../common/constants/ApiConfig';
import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'ConversationListTab';
const DOMAIN = 0x0001;

/**
 * 会话信息
 */
interface Conversation {
  id: string;
  type: string; // 'direct' | 'group' | 'city_chat'
  title: string;
  lastMessage?: string;
  lastMessageTime?: string;
  unreadCount: number;
  avatarUrl?: string;
  participantCount?: number;
}

/**
 * 消息/会话列表 Tab - 对应 Flutter 端 ConversationListPage
 */
@Component
export struct ConversationListTab {
  @State conversations: Conversation[] = [];
  @State isLoading: boolean = true;
  @StorageProp(AppStorageKeys.IS_AUTHENTICATED) isAuthenticated: boolean = false;

  aboutToAppear(): void {
    if (this.isAuthenticated) {
      this.loadConversations();
    }
  }

  async loadConversations(): Promise<void> {
    this.isLoading = true;
    try {
      const httpService = HttpService.getInstance();
      const result = await httpService.get<Conversation[]>(ApiConfig.CHATS_ENDPOINT);
      this.conversations = result;
      hilog.info(DOMAIN, TAG, '✅ 加载 %{public}d 个会话', result.length);
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ 加载会话失败: %{public}s', JSON.stringify(err));
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Column() {
      // 标题
      Row() {
        Text('消息')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })

      if (!this.isAuthenticated) {
        this.LoginPrompt()
      } else if (this.isLoading) {
        Column() {
          LoadingProgress().width(40).height(40)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.conversations.length === 0) {
        this.EmptyState()
      } else {
        this.ConversationList()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BACKGROUND)
  }

  @Builder
  LoginPrompt() {
    Column({ space: 16 }) {
      Text('💬').fontSize(48)
      Text('登录后查看消息')
        .fontSize(16)
        .fontColor(AppColors.TEXT_SECONDARY)
      Button('去登录')
        .width(120)
        .height(40)
        .borderRadius(20)
        .backgroundColor(AppColors.PRIMARY)
        .fontColor('#FFFFFF')
        .onClick(() => {
          router.pushUrl({ url: `pages/${RouteConstants.LOGIN}` });
        })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  EmptyState() {
    Column({ space: 12 }) {
      Text('💬').fontSize(48)
      Text('暂无消息')
        .fontSize(16)
        .fontColor(AppColors.TEXT_SECONDARY)
      Text('加入聚会或城市聊天室开始交流吧')
        .fontSize(14)
        .fontColor(AppColors.TEXT_TERTIARY)
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  ConversationList() {
    List() {
      ForEach(this.conversations, (conv: Conversation) => {
        ListItem() {
          this.ConversationItem(conv)
        }
      }, (conv: Conversation) => conv.id)
    }
    .layoutWeight(1)
    .divider({
      strokeWidth: 0.5,
      color: AppColors.DIVIDER,
      startMargin: 72,
      endMargin: 16,
    })
  }

  @Builder
  ConversationItem(conv: Conversation) {
    Row() {
      // 头像
      Stack() {
        if (conv.avatarUrl) {
          Image(conv.avatarUrl)
            .width(48)
            .height(48)
            .borderRadius(24)
            .objectFit(ImageFit.Cover)
        } else {
          Text(this.getConversationIcon(conv.type))
            .fontSize(24)
            .width(48)
            .height(48)
            .textAlign(TextAlign.Center)
            .backgroundColor('#F1F5F9')
            .borderRadius(24)
        }

        // 未读标记
        if (conv.unreadCount > 0) {
          Text(conv.unreadCount > 99 ? '99+' : conv.unreadCount.toString())
            .fontSize(10)
            .fontColor('#FFFFFF')
            .backgroundColor(AppColors.ERROR)
            .borderRadius(9)
            .width(conv.unreadCount > 9 ? 22 : 18)
            .height(18)
            .textAlign(TextAlign.Center)
            .position({ x: 32, y: 0 })
        }
      }
      .width(56)

      // 内容
      Column({ space: 4 }) {
        Row() {
          Text(conv.title)
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.TEXT_PRIMARY)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)

          if (conv.lastMessageTime) {
            Text(this.formatTime(conv.lastMessageTime))
              .fontSize(12)
              .fontColor(AppColors.TEXT_TERTIARY)
          }
        }
        .width('100%')

        if (conv.lastMessage) {
          Text(conv.lastMessage)
            .fontSize(13)
            .fontColor(AppColors.TEXT_TERTIARY)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .layoutWeight(1)
      .padding({ left: 12 })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .onClick(() => {
      router.pushUrl({
        url: `pages/${RouteConstants.DIRECT_CHAT}`,
        params: { chatId: conv.id, chatTitle: conv.title },
      });
    })
  }

  getConversationIcon(type: string): string {
    switch (type) {
      case 'direct': return '👤';
      case 'group': return '👥';
      case 'city_chat': return '🏙️';
      default: return '💬';
    }
  }

  formatTime(isoString: string): string {
    const date = new Date(isoString);
    const now = new Date();
    const diffMs = now.getTime() - date.getTime();
    const diffMin = Math.floor(diffMs / 60000);

    if (diffMin < 1) return '刚刚';
    if (diffMin < 60) return `${diffMin}分钟前`;
    if (diffMin < 1440) return `${Math.floor(diffMin / 60)}小时前`;
    if (diffMin < 10080) return `${Math.floor(diffMin / 1440)}天前`;
    return date.toLocaleDateString('zh-CN', { month: 'short', day: 'numeric' });
  }
}
