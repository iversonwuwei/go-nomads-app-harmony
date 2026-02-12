import { AppColors } from '../../common/constants/AppColors';
import { AppStorageKeys } from '../../common/constants/AppStorageKeys';
import { RouteConstants } from '../../common/constants/RouteConstants';
import { AuthService } from '../../services/AuthService';
import { UserService } from '../../services/UserService';
import { AuthUser } from '../../models/AuthModels';
import { User, UserHelper } from '../../models/User';
import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'ProfileTab';
const DOMAIN = 0x0001;

/**
 * 个人中心 Tab - 对应 Flutter 端 ProfilePage
 */
@Component
export struct ProfileTab {
  @StorageProp(AppStorageKeys.IS_AUTHENTICATED) isAuthenticated: boolean = false;
  @StorageProp(AppStorageKeys.CURRENT_USER) currentUser: AuthUser | null = null;
  @State userDetail: User | null = null;
  @State isLoading: boolean = false;
  @State hasError: boolean = false;

  aboutToAppear(): void {
    if (this.isAuthenticated) {
      this.loadUserProfile();
    }
  }

  async loadUserProfile(): Promise<void> {
    this.isLoading = true;
    this.hasError = false;
    try {
      const userService = UserService.getInstance();
      const user = await userService.getCurrentUser();
      this.userDetail = user;
      hilog.info(DOMAIN, TAG, '✅ 用户信息加载成功');
    } catch (err) {
      this.hasError = true;
      hilog.error(DOMAIN, TAG, '❌ 加载用户信息失败: %{public}s', (err as Error).message);
    } finally {
      this.isLoading = false;
    }
  }

  async logout(): Promise<void> {
    try {
      const authService = AuthService.getInstance();
      await authService.logout();
    } catch (err) {
      hilog.warn(DOMAIN, TAG, '⚠️ 退出登录异常: %{public}s', (err as Error).message);
    }
    router.replaceUrl({ url: `pages/${RouteConstants.LOGIN}` });
  }

  build() {
    Scroll() {
      Column() {
        if (!this.isAuthenticated) {
          this.LoginPrompt()
        } else {
          // 用户头像和信息
          this.UserInfoSection()

          // 旅行统计
          if (this.userDetail) {
            this.StatsSection()
          }

          // 功能菜单
          this.MenuSection()

          // 退出登录
          Button('退出登录')
            .width('90%')
            .height(48)
            .borderRadius(10)
            .backgroundColor('#FEE2E2')
            .fontColor(AppColors.ERROR)
            .fontSize(16)
            .margin({ top: 24, bottom: 40 })
            .onClick(() => {
              this.logout();
            })
        }
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
    .backgroundColor(AppColors.BACKGROUND)
  }

  @Builder
  LoginPrompt() {
    Column({ space: 16 }) {
      Text('👤').fontSize(56)
      Text('登录后享受完整功能')
        .fontSize(16)
        .fontColor(AppColors.TEXT_SECONDARY)
      Button('登录 / 注册')
        .width(160)
        .height(44)
        .borderRadius(22)
        .backgroundColor(AppColors.PRIMARY)
        .fontColor('#FFFFFF')
        .fontSize(16)
        .onClick(() => {
          router.pushUrl({ url: `pages/${RouteConstants.LOGIN}` });
        })
    }
    .width('100%')
    .height('60%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  UserInfoSection() {
    Column({ space: 8 }) {
      // 头像
      if (this.userDetail?.avatarUrl) {
        Image(this.userDetail.avatarUrl)
          .width(80)
          .height(80)
          .borderRadius(40)
          .objectFit(ImageFit.Cover)
      } else {
        Text('👤')
          .fontSize(40)
          .width(80)
          .height(80)
          .textAlign(TextAlign.Center)
          .backgroundColor('#F1F5F9')
          .borderRadius(40)
      }

      // 用户名
      Text(this.userDetail?.name || this.currentUser?.userName || '用户')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.TEXT_PRIMARY)

      // 简介
      if (this.userDetail?.bio) {
        Text(this.userDetail.bio)
          .fontSize(14)
          .fontColor(AppColors.TEXT_SECONDARY)
          .textAlign(TextAlign.Center)
          .maxLines(2)
          .padding({ left: 32, right: 32 })
      }

      // 当前城市
      if (this.userDetail?.currentCity) {
        Row({ space: 4 }) {
          Text('📍')
            .fontSize(14)
          Text(`${this.userDetail.currentCity}${this.userDetail.currentCountry ? ', ' + this.userDetail.currentCountry : ''}`)
            .fontSize(14)
            .fontColor(AppColors.TEXT_SECONDARY)
        }
      }

      // 编辑按钮
      Button('编辑资料')
        .height(34)
        .fontSize(14)
        .borderRadius(17)
        .backgroundColor('transparent')
        .fontColor(AppColors.PRIMARY)
        .borderWidth(1)
        .borderColor(AppColors.PRIMARY)
        .margin({ top: 4 })
        .onClick(() => {
          router.pushUrl({ url: `pages/${RouteConstants.PROFILE_EDIT}` });
        })
    }
    .width('100%')
    .padding({ top: 32, bottom: 20 })
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  StatsSection() {
    Row() {
      this.StatItem(this.userDetail!.stats.countriesVisited.toString(), '国家')
      Divider().vertical(true).height(32).color(AppColors.DIVIDER)
      this.StatItem(this.userDetail!.stats.citiesVisited.toString(), '城市')
      Divider().vertical(true).height(32).color(AppColors.DIVIDER)
      this.StatItem(this.userDetail!.stats.totalTrips.toString(), '行程')
      Divider().vertical(true).height(32).color(AppColors.DIVIDER)
      this.StatItem(this.userDetail!.stats.totalDays.toString(), '天数')
    }
    .width('100%')
    .padding({ top: 16, bottom: 16 })
    .margin({ left: 16, right: 16, bottom: 16 })
    .backgroundColor(AppColors.CARD_BACKGROUND)
    .borderRadius(12)
    .justifyContent(FlexAlign.SpaceEvenly)
  }

  @Builder
  StatItem(value: string, label: string) {
    Column({ space: 4 }) {
      Text(value)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.PRIMARY)
      Text(label)
        .fontSize(12)
        .fontColor(AppColors.TEXT_SECONDARY)
    }
  }

  @Builder
  MenuSection() {
    Column() {
      this.MenuItem('📋', '我的旅行计划', () => {
        router.pushUrl({ url: `pages/${RouteConstants.TRAVEL_PLAN}` });
      })
      this.MenuItem('🎉', '我的聚会', () => {
        router.pushUrl({ url: `pages/${RouteConstants.MY_MEETUPS}` });
      })
      this.MenuItem('❤️', '收藏', () => {
        router.pushUrl({ url: `pages/${RouteConstants.FAVORITES}` });
      })
      this.MenuItem('🎯', '技能与兴趣', () => {
        router.pushUrl({ url: `pages/${RouteConstants.EDIT_SKILLS}` });
      })
      this.MenuItem('🔗', '社交链接', () => {
        router.pushUrl({ url: `pages/${RouteConstants.EDIT_SOCIAL_LINKS}` });
      })
      this.MenuItem('🔔', '通知设置', () => {
        router.pushUrl({ url: `pages/${RouteConstants.NOTIFICATIONS}` });
      })
      this.MenuItem('📄', '服务条款', () => {
        router.pushUrl({ url: `pages/${RouteConstants.TERMS_OF_SERVICE}` });
      })
      this.MenuItem('📖', '社区准则', () => {
        router.pushUrl({ url: `pages/${RouteConstants.COMMUNITY_GUIDELINES}` });
      })
    }
    .width('100%')
    .padding({ left: 16, right: 16 })
    .backgroundColor(AppColors.CARD_BACKGROUND)
    .borderRadius(12)
    .margin({ left: 16, right: 16 })
  }

  @Builder
  MenuItem(icon: string, title: string, onClick: () => void) {
    Row() {
      Text(icon)
        .fontSize(20)
        .width(36)
      Text(title)
        .fontSize(15)
        .fontColor(AppColors.TEXT_PRIMARY)
        .layoutWeight(1)
      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(16)
        .fontColor([AppColors.TEXT_TERTIARY])
    }
    .width('100%')
    .height(52)
    .padding({ left: 12, right: 12 })
    .onClick(onClick)
  }
}
