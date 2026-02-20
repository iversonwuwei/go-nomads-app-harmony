import { AppColors } from '../common/constants/AppColors';
import { AppStorageKeys } from '../common/constants/AppStorageKeys';
import { NotificationService } from '../services/NotificationService';
import { AppNotification } from '../models/Notification';
import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'NotificationsPage';
const DOMAIN = 0x0001;

/**
 * 通知页面 — 对应 Flutter notifications_page.dart
 */
@Entry
@Component
struct NotificationsPage {
  @State notifications: AppNotification[] = [];
  @State isLoading: boolean = true;

  aboutToAppear(): void { this.loadNotifications(); }

  async loadNotifications(): Promise<void> {
    this.isLoading = true;
    try {
      const svc = NotificationService.getInstance();
      this.notifications = await svc.getAll();
      AppStorage.set(AppStorageKeys.UNREAD_NOTIFICATION_COUNT, 0);
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ %{public}s', JSON.stringify(err));
    } finally { this.isLoading = false; }
  }

  markAllRead(): void {
    this.notifications = this.notifications.map((n) => ({ ...n, isRead: true }));
    AppStorage.set(AppStorageKeys.UNREAD_NOTIFICATION_COUNT, 0);
  }

  build() {
    Column() {
      Row() {
        SymbolGlyph($r('sys.symbol.arrow_left'))
          .fontSize(24).fontColor([AppColors.TEXT_PRIMARY]).onClick(() => { router.back(); })
        Text('通知').fontSize(18).fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT_PRIMARY).layoutWeight(1).textAlign(TextAlign.Center)
        Text('全部已读').fontSize(14).fontColor(AppColors.PRIMARY)
          .onClick(() => { this.markAllRead(); })
      }
      .width('100%').height(56).padding({ left: 16, right: 16 })
      .backgroundColor(AppColors.CARD_BACKGROUND)

      if (this.isLoading) {
        Column() { LoadingProgress().width(40).height(40) }
          .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else if (this.notifications.length === 0) {
        Column({ space: 12 }) {
          Text('🔔').fontSize(48)
          Text('暂无通知').fontSize(16).fontColor(AppColors.TEXT_SECONDARY)
        }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        List() {
          ForEach(this.notifications, (n: AppNotification) => {
            ListItem() { this.NotificationItem(n) }
          }, (n: AppNotification) => n.id)
        }
        .layoutWeight(1)
        .divider({ strokeWidth: 0.5, color: AppColors.DIVIDER, startMargin: 56, endMargin: 16 })
      }
    }
    .width('100%').height('100%').backgroundColor(AppColors.BACKGROUND)
  }

  @Builder
  NotificationItem(n: AppNotification) {
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
    const d = new Date(iso);
    const now = new Date();
    const diff = Math.floor((now.getTime() - d.getTime()) / 60000);
    if (diff < 1) return '刚刚';
    if (diff < 60) return `${diff}分钟前`;
    if (diff < 1440) return `${Math.floor(diff / 60)}小时前`;
    return d.toLocaleDateString('zh-CN', { month: 'short', day: 'numeric' });
  }
}
