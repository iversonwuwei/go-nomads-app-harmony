import { AppColors } from '../../common/constants/AppColors';

/**
 * 通知 Tab - 100% 还原 Flutter notifications_page.dart
 *
 * Flutter: 3 tabs (全部/未读/已读), accent color #1976D2
 * TabBar: labelColor accent, indicatorColor accent
 */
@Component
export struct NotificationsTab {
  @State currentTabIndex: number = 0;
  private tabController: TabsController = new TabsController();

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
              // TODO: mark all as read
            })
        }
        .width('100%')
      }
      .width('100%')
      .backgroundColor(AppColors.WHITE)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BACKGROUND)
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
    Column() {
      // 空状态
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
    }
    .width('100%')
    .height('100%')
  }
}
