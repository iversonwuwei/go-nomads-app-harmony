import { AppColors } from '../../common/constants/AppColors';
import { AppStorageKeys } from '../../common/constants/AppStorageKeys';
import { RouteConstants } from '../../common/constants/RouteConstants';
import { ChatService, ChatRoom } from '../../services/ChatService';
import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'ConversationListTab';
const DOMAIN = 0x0001;

/**
 * 消息/会话列表 Tab - 对应 Flutter 端 ConversationListPage
 */
@Component
export struct ConversationListTab {
  @State conversations: ChatRoom[] = [];
  @State isLoading: boolean = true;
  @State hasError: boolean = false;
  @State errorMsg: string = '';
  @State isRefreshing: boolean = false;
  @StorageProp(AppStorageKeys.IS_AUTHENTICATED) isAuthenticated: boolean = false;

  aboutToAppear(): void {
    if (this.isAuthenticated) {
      this.loadConversations();
    }
  }

  async loadConversations(): Promise<void> {
    this.isLoading = true;
    this.hasError = false;
    try {
      const chatService = ChatService.getInstance();
      const rooms = await chatService.getChatRooms();
      this.conversations = rooms;
      hilog.info(DOMAIN, TAG, '✅ 加载 %{public}d 个会话', rooms.length);
    } catch (err) {
      this.hasError = true;
      this.errorMsg = (err instanceof Error) ? err.message : '加载失败';
      hilog.error(DOMAIN, TAG, '❌ 加载会话失败: %{public}s', this.errorMsg);
    } finally {
      this.isLoading = false;
      this.isRefreshing = false;
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
      } else if (this.isLoading && !this.isRefreshing) {
        Column() {
          LoadingProgress().width(40).height(40)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.hasError) {
        Column({ space: 12 }) {
          Text('😞').fontSize(48)
          Text('加载失败').fontSize(16).fontColor(AppColors.TEXT_SECONDARY)
          Button('重试')
            .height(36)
            .fontSize(14)
            .borderRadius(18)
            .backgroundColor(AppColors.PRIMARY)
            .fontColor('#FFFFFF')
            .onClick(() => {
              this.loadConversations();
            })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.conversations.length === 0) {
        this.EmptyState()
      } else {
        Refresh({ refreshing: $$this.isRefreshing }) {
          this.ConversationList()
        }
        .layoutWeight(1)
        .onRefreshing(() => {
          this.loadConversations();
        })
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
      ForEach(this.conversations, (conv: ChatRoom) => {
        ListItem() {
          this.ConversationItem(conv)
        }
      }, (conv: ChatRoom) => conv.id)
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
  ConversationItem(conv: ChatRoom) {
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
          Text(this.getConversationIcon(conv.type ?? 'group'))
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
          Text(conv.name)
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
        params: { chatId: conv.id, chatTitle: conv.name },
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
