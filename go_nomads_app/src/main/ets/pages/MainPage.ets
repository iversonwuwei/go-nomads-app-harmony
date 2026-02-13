import { AppColors } from '../common/constants/AppColors';
import { AppStorageKeys } from '../common/constants/AppStorageKeys';
import { HomeTab } from './tabs/HomeTab';
import { ConversationListTab } from './tabs/ConversationListTab';
import { ProfileTab } from './tabs/ProfileTab';
import { NotificationsTab } from './tabs/NotificationsTab';

/**
 * 主页面框架 - 100% 还原 Flutter BottomNavLayout
 *
 * Flutter 底部导航:
 *   4 tabs: Home(house) / Messages(commentDots) / Profile(user) / Notifications(bell)
 *   毛玻璃胶囊: backdrop blur 56, white alpha 0.36, radius 36
 *   margin: 14 horizontal, 18 bottom
 *   选中: #2196F3 蓝色, 未选中: #8E8E93 灰色
 *   Badge: #FF4458 红色圆, white border 1.5
 *   只显示图标，不显示文字标签
 */
@Entry
@Component
struct MainPage {
  @StorageProp(AppStorageKeys.CURRENT_TAB_INDEX) @Watch('onTabChange') currentTabIndex: number = 0;
  @StorageProp(AppStorageKeys.UNREAD_NOTIFICATION_COUNT) unreadCount: number = 0;
  @State selectedIndex: number = 0;

  private tabController: TabsController = new TabsController();

  onTabChange(): void {
    this.selectedIndex = this.currentTabIndex;
    this.tabController.changeIndex(this.selectedIndex);
  }

  build() {
    Stack() {
      // 主内容区域
      Tabs({ controller: this.tabController, index: this.selectedIndex }) {
        // Tab 1: 首页
        TabContent() {
          HomeTab()
        }

        // Tab 2: 消息
        TabContent() {
          ConversationListTab()
        }

        // Tab 3: 我的
        TabContent() {
          ProfileTab()
        }

        // Tab 4: 通知
        TabContent() {
          NotificationsTab()
        }
      }
      .barHeight(0) // 隐藏默认tabBar，使用自定义底部导航
      .onChange((index: number) => {
        this.selectedIndex = index;
        AppStorage.set(AppStorageKeys.CURRENT_TAB_INDEX, index);
      })

      // 自定义底部导航栏 - 毛玻璃胶囊风格
      Column() {
        Row() {
          // Home
          this.NavItem(0, $r('sys.symbol.house'), 0)
          // Messages
          this.NavItem(1, $r('sys.symbol.message'), 0)
          // Profile
          this.NavItem(2, $r('sys.symbol.person'), 0)
          // Notifications
          this.NavItem(3, $r('sys.symbol.bell'), this.unreadCount)
        }
        .width('100%')
        .height(48)
        .justifyContent(FlexAlign.SpaceAround)
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .margin({ left: 14, right: 14, bottom: 18 })
      .padding({ left: 8, right: 8 })
      .borderRadius(36)
      .backgroundColor('#5CFFFFFF') // white alpha 0.36
      .backdropBlur(56) // 毛玻璃模糊
      .border({ width: 0.5, color: '#80FFFFFF' }) // white alpha 0.5
      .shadow({
        radius: 48,
        color: '#2E000000', // black alpha 0.18
        offsetX: 0,
        offsetY: 12
      })
      .position({ bottom: 0 })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  NavItem(index: number, icon: Resource, badge: number) {
    Column() {
      Stack() {
        SymbolGlyph(icon)
          .fontSize(30)
          .fontColor([this.selectedIndex === index ? AppColors.NAV_SELECTED : AppColors.NAV_UNSELECTED])

        // Badge
        if (badge > 0) {
          Text(badge > 99 ? '99+' : badge.toString())
            .fontSize(10)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.WHITE)
            .textAlign(TextAlign.Center)
            .minFontSize(8)
            .padding(4)
            .constraintSize({ minWidth: 18, minHeight: 18 })
            .borderRadius(9)
            .backgroundColor(AppColors.PRIMARY)
            .border({ width: 1.5, color: AppColors.WHITE })
            .position({ right: -6, top: -6 })
        }
      }
      .width(44)
      .height(44)
      .alignContent(Alignment.Center)
    }
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .height('100%')
    .onClick(() => {
      this.selectedIndex = index;
      this.tabController.changeIndex(index);
      AppStorage.set(AppStorageKeys.CURRENT_TAB_INDEX, index);
    })
  }
}
