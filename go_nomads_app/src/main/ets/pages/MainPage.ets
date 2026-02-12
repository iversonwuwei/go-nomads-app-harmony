import { AppColors } from '../common/constants/AppColors';
import { AppStorageKeys } from '../common/constants/AppStorageKeys';
import { HomeTab } from './tabs/HomeTab';
import { CityListTab } from './tabs/CityListTab';
import { MeetupListTab } from './tabs/MeetupListTab';
import { ConversationListTab } from './tabs/ConversationListTab';
import { ProfileTab } from './tabs/ProfileTab';

/**
 * 主页面框架 - 底部导航 + Tab 页
 * 对应 Flutter 端 BottomNavLayout
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
    Column() {
      Tabs({ barPosition: BarPosition.End, controller: this.tabController, index: this.selectedIndex }) {
        // Tab 1: 首页
        TabContent() {
          HomeTab()
        }
        .tabBar(this.TabBarItem(0, '首页', $r('sys.symbol.house')))

        // Tab 2: 城市
        TabContent() {
          CityListTab()
        }
        .tabBar(this.TabBarItem(1, '城市', $r('sys.symbol.compass')))

        // Tab 3: 聚会
        TabContent() {
          MeetupListTab()
        }
        .tabBar(this.TabBarItem(2, '聚会', $r('sys.symbol.person_3')))

        // Tab 4: 消息
        TabContent() {
          ConversationListTab()
        }
        .tabBar(this.TabBarItem(3, '消息', $r('sys.symbol.message')))

        // Tab 5: 我的
        TabContent() {
          ProfileTab()
        }
        .tabBar(this.TabBarItem(4, '我的', $r('sys.symbol.person')))
      }
      .barMode(BarMode.Fixed)
      .onChange((index: number) => {
        this.selectedIndex = index;
        AppStorage.set(AppStorageKeys.CURRENT_TAB_INDEX, index);
      })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  TabBarItem(index: number, title: string, icon: Resource) {
    Column() {
      SymbolGlyph(icon)
        .fontSize(24)
        .fontColor([this.selectedIndex === index ? AppColors.PRIMARY : AppColors.TEXT_TERTIARY])

      Text(title)
        .fontSize(10)
        .fontColor(this.selectedIndex === index ? AppColors.PRIMARY : AppColors.TEXT_TERTIARY)
        .margin({ top: 2 })
    }
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .height(56)
  }
}
