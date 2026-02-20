import { AppColors } from '../../common/constants/AppColors';
import { AppStorageKeys } from '../../common/constants/AppStorageKeys';
import { RouteConstants } from '../../common/constants/RouteConstants';
import { ChatService, ChatRoom } from '../../services/ChatService';
import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'ConversationListTab';
const DOMAIN = 0x0001;

/**
 * 消息/会话列表 Tab - 100% 还原 Flutter ConversationListPage
 *
 * Flutter 微信风格设计:
 *   背景: #EDEDED
 *   AppBar: "消息" 18px w600 black, bg #EDEDED, centerTitle
 *   头像: 48x48, borderRadius 6 (方形圆角, 非圆形!)
 *   默认头像: #07C160 15% bg, person icon #07C160
 *   未读角标: #FA5151 bg, white 1.5 border, borderRadius 10, fontSize 11 bold
 *   名字: 16px w500, #1A1A1A
 *   时间: 12px, #B2B2B2
 *   消息预览: 14px, #999999
 *   分隔线: #E8E8E8, 0.5px
 *   滑动删除: 红色背景 + 删除图标
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
      // Flutter AppBar: "消息" 18px w600 black, centered, bg #EDEDED
      Row() {
        Text('消息')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#000000')
      }
      .width('100%')
      .height(56)
      .justifyContent(FlexAlign.Center)
      .backgroundColor(AppColors.CHAT_BACKGROUND) // #EDEDED

      if (!this.isAuthenticated) {
        this.LoginPrompt()
      } else if (this.isLoading && !this.isRefreshing) {
        // Flutter _LoadingView: 8 skeleton items
        this.LoadingSkeleton()
      } else if (this.hasError) {
        this.ErrorView()
      } else if (this.conversations.length === 0) {
        this.EmptyView()
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
    .backgroundColor(AppColors.CHAT_BACKGROUND) // #EDEDED 微信风格背景
  }

  // ===== 未登录 =====
  @Builder
  LoginPrompt() {
    Column({ space: 16 }) {
      SymbolGlyph($r('sys.symbol.message'))
        .fontSize(48)
        .fontColor(['#C0C0C0'])
      Text('登录后查看消息')
        .fontSize(16)
        .fontColor(AppColors.TEXT_SECONDARY)
      Button('去登录')
        .width(120)
        .height(40)
        .borderRadius(20)
        .backgroundColor('#07C160') // 微信绿
        .fontColor(AppColors.WHITE)
        .onClick(() => {
          router.pushUrl({ url: `pages/${RouteConstants.LOGIN}` });
        })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  // ===== Flutter _EmptyView: commentDots icon 64px, grey 30% =====
  @Builder
  EmptyView() {
    Column({ space: 16 }) {
      SymbolGlyph($r('sys.symbol.message'))
        .fontSize(64)
        .fontColor(['#C0C0C0']) // grey 30%

      Text('暂无消息')
        .fontSize(16)
        .fontColor('#999999') // grey 60%

      Text('去城市或活动页面开始聊天吧')
        .fontSize(14)
        .fontColor('#C0C0C0') // grey 40%
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  // ===== Flutter _ErrorView =====
  @Builder
  ErrorView() {
    Column({ space: 16 }) {
      Text('⚠️')
        .fontSize(48)

      Text(this.errorMsg)
        .fontSize(16)
        .fontColor('#999999')
        .textAlign(TextAlign.Center)

      Button('重试')
        .height(40)
        .fontSize(14)
        .borderRadius(20)
        .backgroundColor('#07C160') // 微信绿
        .fontColor(AppColors.WHITE)
        .onClick(async () => {
          await this.loadConversations();
        })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  // ===== Flutter _LoadingView: 8 skeleton items =====
  @Builder
  LoadingSkeleton() {
    List() {
      ForEach([1, 2, 3, 4, 5, 6, 7, 8], (item: number) => {
        ListItem() {
          Row() {
            // 头像骨架: 48x48 radius 6
            Column()
              .width(48)
              .height(48)
              .borderRadius(6)
              .backgroundColor('#E5E5E5')

            Column({ space: 8 }) {
              Column()
                .width(120)
                .height(16)
                .borderRadius(4)
                .backgroundColor('#E5E5E5')
              Column()
                .width(200)
                .height(14)
                .borderRadius(4)
                .backgroundColor('#EFEFEF')
            }
            .alignItems(HorizontalAlign.Start)
            .margin({ left: 12 })
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 12, bottom: 12 })
          .backgroundColor(AppColors.WHITE)
        }
      }, (item: number) => item.toString())
    }
    .layoutWeight(1)
  }

  // ===== 会话列表 =====
  @Builder
  ConversationList() {
    List() {
      ForEach(this.conversations, (conv: ChatRoom) => {
        ListItem() {
          this.ConversationTile(conv)
        }
        .swipeAction({
          end: {
            builder: () => { this.SwipeDeleteButton(conv) }
          }
        })
      }, (conv: ChatRoom) => conv.id)
    }
    .layoutWeight(1)
  }

  // ===== Flutter _ConversationTile: 白色背景,  border bottom #E8E8E8 0.5px =====
  @Builder
  ConversationTile(conv: ChatRoom) {
    Row() {
      // 头像 + 未读角标
      this.AvatarWithBadge(conv)

      // 名字 + 最后消息
      Column({ space: 4 }) {
        Row() {
          Text(conv.name)
            .fontSize(16) // Flutter: 16px
            .fontWeight(FontWeight.Medium) // Flutter: w500
            .fontColor(AppColors.CHAT_NAME) // #1A1A1A
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)

          if (conv.lastMessageTime) {
            Text(this.formatTime(conv.lastMessageTime))
              .fontSize(12) // Flutter: 12px
              .fontColor('#B2B2B2') // Flutter exact color
          }
        }
        .width('100%')

        if (conv.lastMessage) {
          Text(conv.lastMessage)
            .fontSize(14) // Flutter: 14px
            .fontColor('#999999') // Flutter exact color
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        } else {
          Text(this.previewText(conv))
            .fontSize(14)
            .fontColor('#B2B2B2')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .layoutWeight(1)
      .margin({ left: 12 }) // Flutter: SizedBox(width: 12)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 }) // Flutter: h16 v12
    .backgroundColor(AppColors.WHITE)
    .border({ width: { bottom: 0.5 }, color: { bottom: '#E8E8E8' } }) // Flutter: Border bottom
    .onClick(() => {
      const roomType = (conv.type || '').toLowerCase();
      const isGroupRoom = roomType === 'group' || roomType === 'city' || roomType === 'meetup';
      if (isGroupRoom) {
        router.pushUrl({
          url: `pages/${RouteConstants.CITY_CHAT}`,
          params: {
            chatId: conv.id,
            cityId: conv.id,
            cityName: conv.name,
            chatTitle: conv.name,
          },
        });
      } else {
        router.pushUrl({
          url: `pages/${RouteConstants.DIRECT_CHAT}`,
          params: { chatId: conv.id, chatTitle: conv.name },
        });
      }
    })
  }

  // ===== Flutter _buildAvatar: 48x48 radius 6 (微信方形圆角!) + 未读角标 =====
  @Builder
  AvatarWithBadge(conv: ChatRoom) {
    Stack({ alignContent: Alignment.TopEnd }) {
      // 头像: 48x48 borderRadius 6 (微信方形圆角,非圆形!)
      if (conv.avatarUrl) {
        Image(conv.avatarUrl)
          .width(48)
          .height(48)
          .borderRadius(6) // Flutter: BorderRadius.circular(6) 微信风格
          .objectFit(ImageFit.Cover)
      } else {
        // Flutter _defaultAvatar: #07C160 15% bg, person icon #07C160
        Column() {
          SymbolGlyph($r('sys.symbol.person'))
            .fontSize(22)
            .fontColor(['#07C160'])
        }
        .width(48)
        .height(48)
        .borderRadius(6)
        .backgroundColor('#1A07C160') // #07C160 with ~10% alpha
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }

      // 未读角标: Flutter - #FA5151 bg, white 1.5px border, min 20x20, fontSize 11 bold
      if (conv.unreadCount > 0) {
        Text(conv.unreadCount > 99 ? '99+' : conv.unreadCount.toString())
          .fontSize(11)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.WHITE)
          .textAlign(TextAlign.Center)
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .constraintSize({ minWidth: 20, minHeight: 20 })
          .backgroundColor(AppColors.CHAT_BADGE) // #FA5151
          .borderRadius(10)
          .border({ width: 1.5, color: AppColors.WHITE })
          .translate({ x: 6, y: -6 }) // Flutter: Positioned(right: -6, top: -6)
      }
    }
  }

  // ===== 滑动删除按钮 =====
  @Builder
  SwipeDeleteButton(conv: ChatRoom) {
    Row() {
      SymbolGlyph($r('sys.symbol.xmark'))
        .fontSize(24)
        .fontColor([AppColors.WHITE])
    }
    .width(80)
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#FF3B30')
    .onClick(async () => {
      try {
        await ChatService.getInstance().leaveChatRoom(conv.id);
      } catch (err) {
        hilog.warn(DOMAIN, TAG, '离开会话失败，继续本地移除: %{public}s', (err as Error).message);
      }
      this.conversations = this.conversations.filter((c) => c.id !== conv.id);
      hilog.info(DOMAIN, TAG, '已移除会话: %{public}s', conv.id);
    })
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

  private previewText(conv: ChatRoom): string {
    const roomType = (conv.type || '').toLowerCase();
    if (roomType === 'group' || roomType === 'city') {
      return '加入群聊，和本地游民实时交流';
    }
    if (roomType === 'meetup') {
      return '聚会群已创建，点击进入聊天';
    }
    return '点击开始聊天';
  }
}
