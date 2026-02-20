import { AppColors } from '../../common/constants/AppColors';
import { AppNotification } from '../../models/Notification';
import { NotificationService } from '../../services/NotificationService';
import { AppStorageKeys } from '../../common/constants/AppStorageKeys';

/**
 * 通知 Tab - 100% 还原 Flutter notifications_page.dart
 *
 * Flutter: 3 tabs (全部/未读/已读), accent color #1976D2
 * TabBar: labelColor accent, indicatorColor accent
 */
@Component
export struct NotificationsTab {
  @State notifications: AppNotification[] = [];
  @State isLoading: boolean = true;
  @State isRefreshing: boolean = false;
  @State currentTabIndex: number = 0;
  private tabController: TabsController = new TabsController();

  aboutToAppear(): void {
    this.loadNotifications();
  }

  async loadNotifications(): Promise<void> {
    if (!this.isRefreshing) {
      this.isLoading = true;
    }
    try {
      const svc = NotificationService.getInstance();
      const list = await svc.getAll();
      this.notifications = list;
      const unread = list.filter((n) => !n.isRead).length;
      AppStorage.set(AppStorageKeys.UNREAD_NOTIFICATION_COUNT, unread);
    } finally {
      this.isLoading = false;
      this.isRefreshing = false;
    }
  }

  markAllRead(): void {
    const updated: AppNotification[] = [];
    for (let i = 0; i < this.notifications.length; i++) {
      const n = this.notifications[i];
      const item: AppNotification = {
        id: n.id,
        type: n.type,
        title: n.title,
        body: n.body,
        isRead: true,
        createdAt: n.createdAt,
        actionUrl: n.actionUrl,
      };
      updated.push(item);
    }
    this.notifications = updated;
    AppStorage.set(AppStorageKeys.UNREAD_NOTIFICATION_COUNT, 0);
  }

  private getFilteredNotifications(type: string): AppNotification[] {
    return this.notifications.filter((n: AppNotification) => {
      if (type === 'unread') return !n.isRead;
      if (type === 'read') return n.isRead;
      return true;
    });
  }

  build() {
    Column() {
      // TabBar 区域 - 白色背景
      Column() {
        Row() {
          // 3个 Tab
          Tabs({ barPosition: BarPosition.Start, controller: this.tabController }) {
            TabContent() {
              this.NotificationList('all')
            }
            .tabBar(this.TabItem('全部', 0))

            TabContent() {
              this.NotificationList('unread')
            }
            .tabBar(this.TabItem('未读', 1))

            TabContent() {
              this.NotificationList('read')
            }
            .tabBar(this.TabItem('已读', 2))
          }
          .barMode(BarMode.Fixed)
          .barWidth('75%')
          .barHeight(48)
          .onChange((index: number) => {
            this.currentTabIndex = index;
          })
          .layoutWeight(1)

          // 全部标记为已读按钮
          SymbolGlyph($r('sys.symbol.checkmark'))
            .fontSize(20)
            .fontColor([AppColors.TEXT_SECONDARY])
            .width(48)
            .height(48)
            .onClick(() => {
              this.markAllRead();
            })
        }
        .width('100%')
      }
      .width('100%')
      .backgroundColor(AppColors.WHITE)

      if (this.isLoading && !this.isRefreshing) {
        Column() { LoadingProgress().width(36).height(36) }
          .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        Refresh({ refreshing: $$this.isRefreshing }) {
          this.NotificationList(this.currentFilter())
        }
        .layoutWeight(1)
        .onRefreshing(() => {
          this.isRefreshing = true;
          this.loadNotifications();
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BACKGROUND)
  }

  currentFilter(): string {
    if (this.currentTabIndex === 1) return 'unread';
    if (this.currentTabIndex === 2) return 'read';
    return 'all';
  }

  @Builder
  TabItem(title: string, index: number) {
    Text(title)
      .fontSize(14)
      .fontWeight(this.currentTabIndex === index ? FontWeight.Bold : FontWeight.Normal)
      .fontColor(this.currentTabIndex === index ? AppColors.ACCENT : AppColors.TEXT_SECONDARY)
  }

  @Builder
  NotificationList(type: string) {
    if (this.getFilteredNotifications(type).length === 0) {
      Column() {
        SymbolGlyph($r('sys.symbol.bell'))
          .fontSize(48)
          .fontColor([AppColors.TEXT_TERTIARY])
        Text('暂无通知')
          .fontSize(16)
          .fontColor(AppColors.TEXT_TERTIARY)
          .margin({ top: 16 })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    } else {
      List() {
        ForEach(this.getFilteredNotifications(type), (n: AppNotification) => {
          ListItem() {
            this.NotificationRow(n)
          }
        }, (n: AppNotification) => n.id)
      }
      .divider({ strokeWidth: 0.5, color: AppColors.DIVIDER, startMargin: 56, endMargin: 16 })
      .layoutWeight(1)
    }
  }

  @Builder
  NotificationRow(n: AppNotification) {
    Row() {
      Text(this.typeIcon(n.type))
        .fontSize(22).width(40).height(40).textAlign(TextAlign.Center)
        .backgroundColor(n.isRead ? '#F1F5F9' : '#F0F9FF').borderRadius(20)

      Column({ space: 3 }) {
        Text(n.title)
          .fontSize(15).fontWeight(n.isRead ? FontWeight.Normal : FontWeight.Medium)
          .fontColor(AppColors.TEXT_PRIMARY).maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(n.body)
          .fontSize(13).fontColor(AppColors.TEXT_SECONDARY).maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.formatTime(n.createdAt))
          .fontSize(12).fontColor(AppColors.TEXT_TERTIARY)
      }
      .layoutWeight(1).padding({ left: 12 }).alignItems(HorizontalAlign.Start)

      if (!n.isRead) {
        Circle().width(8).height(8).fill(AppColors.PRIMARY)
      }
    }
    .width('100%').padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor(n.isRead ? 'transparent' : '#FAFEFF')
  }

  typeIcon(type: string): string {
    switch (type) {
      case 'meetup': return '🎉';
      case 'message': return '💬';
      case 'review': return '⭐';
      case 'follow': return '👤';
      default: return '🔔';
    }
  }

  formatTime(iso: string): string {
    if (!iso) return '';
    const d = new Date(iso);
    const now = new Date();
    const diff = Math.floor((now.getTime() - d.getTime()) / 60000);
    if (diff < 1) return '刚刚';
    if (diff < 60) return `${diff}分钟前`;
    if (diff < 1440) return `${Math.floor(diff / 60)}小时前`;
    return d.toLocaleDateString('zh-CN', { month: 'short', day: 'numeric' });
  }
}
