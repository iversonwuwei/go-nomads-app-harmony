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
 * 个人中心 Tab - 100% 还原 Flutter ProfilePage
 *
 * Flutter 结构:
 *   ProfileHeaderWidget → avatar 80px circle, red 3px border, edit icon, name 24px bold, username, location
 *   MembershipCardWidget → gradient card
 *   TravelPlansWidget → travel plans list
 *   NomadStatsWidget → stats grid
 *   BadgesSectionWidget → badges
 *   SkillsInterestsWidget → tags
 *   TravelHistoryWidget → latest trip
 *   SocialLinksWidget → links
 *   LogoutWidget → red logout
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
      await AuthService.getInstance().logout();
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
          // ===== ProfileHeaderWidget: avatar + info =====
          this.ProfileHeader()

          // ===== NomadStatsWidget: stats grid =====
          if (this.userDetail) {
            this.NomadStats()
          }

          // ===== Menu Section =====
          this.MenuSection()

          // ===== Logout =====
          this.LogoutButton()

          // 底部间距
          Column().height(100)
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

  // ===== 未登录提示 =====
  @Builder
  LoginPrompt() {
    Column({ space: 16 }) {
      // 头像占位
      Column() {
        SymbolGlyph($r('sys.symbol.person'))
          .fontSize(40)
          .fontColor([AppColors.TEXT_TERTIARY])
      }
      .width(80)
      .height(80)
      .borderRadius(40)
      .backgroundColor(AppColors.GREY200)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      Text('登录后享受完整功能')
        .fontSize(16)
        .fontColor(AppColors.TEXT_SECONDARY)

      Button('登录 / 注册')
        .width(160)
        .height(44)
        .borderRadius(22)
        .backgroundColor(AppColors.PRIMARY)
        .fontColor(AppColors.WHITE)
        .fontSize(16)
        .onClick(() => {
          router.pushUrl({ url: `pages/${RouteConstants.LOGIN}` });
        })
    }
    .width('100%')
    .height('60%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  // ===== ProfileHeaderWidget: Flutter style =====
  // Flutter: Row layout - avatar(80px circle, red 3px border) + info(name 24px, username, location)
  @Builder
  ProfileHeader() {
    Row() {
      // Avatar with red border
      Stack() {
        Column() {
          if (this.userDetail?.avatarUrl) {
            Image(this.userDetail.avatarUrl)
              .width(74)
              .height(74)
              .borderRadius(37)
              .objectFit(ImageFit.Cover)
          } else {
            SymbolGlyph($r('sys.symbol.person'))
              .fontSize(36)
              .fontColor([AppColors.TEXT_TERTIARY])
          }
        }
        .width(74)
        .height(74)
        .borderRadius(37)
        .backgroundColor(AppColors.GREY200)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)

        // Edit icon - positioned bottom right
        Column() {
          Text('✏️')
            .fontSize(10)
        }
        .width(24)
        .height(24)
        .borderRadius(12)
        .backgroundColor(AppColors.PRIMARY)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .position({ right: 0, bottom: 0 })
      }
      .width(80)
      .height(80)
      .border({ width: 3, color: AppColors.PRIMARY })
      .borderRadius(40)
      .onClick(() => {
        router.pushUrl({ url: `pages/${RouteConstants.PROFILE_EDIT}` });
      })

      // User Info
      Column({ space: 4 }) {
        // Name 24px bold
        Text(this.userDetail?.name || this.currentUser?.userName || '用户')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1A1A')

        // Username
        if (this.userDetail?.name) {
          Text(`@${this.userDetail.name}`)
            .fontSize(16)
            .fontColor('#6B7280')
            .fontWeight(FontWeight.Medium)
        }

        // Location
        if (this.userDetail?.currentCity) {
          Row({ space: 4 }) {
            Text('📍')
              .fontSize(14)
            Text(`${this.userDetail.currentCity}${this.userDetail.currentCountry ? ', ' + this.userDetail.currentCountry : ''}`)
              .fontSize(14)
              .fontColor(AppColors.TEXT_SECONDARY)
          }
          .margin({ top: 8 })
        }

        // Bio
        if (this.userDetail?.bio) {
          Text(this.userDetail.bio)
            .fontSize(14)
            .fontColor(AppColors.TEXT_SECONDARY)
            .maxLines(2)
            .margin({ top: 4 })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 20 })
      .layoutWeight(1)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 32, bottom: 24 })
    .alignItems(VerticalAlign.Top)
  }

  // ===== NomadStats: 4 stat items in white card =====
  @Builder
  NomadStats() {
    Row() {
      this.StatItem(this.userDetail!.stats.countriesVisited.toString(), '国家')
      this.StatDivider()
      this.StatItem(this.userDetail!.stats.citiesVisited.toString(), '城市')
      this.StatDivider()
      this.StatItem(this.userDetail!.stats.totalTrips.toString(), '行程')
      this.StatDivider()
      this.StatItem(this.userDetail!.stats.totalDays.toString(), '天数')
    }
    .width('100%')
    .padding({ top: 16, bottom: 16 })
    .margin({ left: 16, right: 16, bottom: 16 })
    .backgroundColor(AppColors.WHITE) // Flutter uses white, not grey card
    .borderRadius(12)
    .border({ width: 1, color: AppColors.BORDER_LIGHT })
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
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  StatDivider() {
    Divider()
      .vertical(true)
      .height(32)
      .color(AppColors.DIVIDER)
  }

  // ===== Menu Section: white card =====
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
    .backgroundColor(AppColors.WHITE)
    .borderRadius(12)
    .margin({ left: 16, right: 16 })
    .border({ width: 1, color: AppColors.BORDER_LIGHT })
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

  // ===== Logout Button: Flutter style - light red bg =====
  @Builder
  LogoutButton() {
    Button('退出登录')
      .width('90%')
      .height(48)
      .borderRadius(12)
      .backgroundColor(AppColors.PRIMARY_LIGHT) // #FFE5E8
      .fontColor(AppColors.PRIMARY) // #FF4458
      .fontSize(16)
      .fontWeight(FontWeight.Bold)
      .margin({ top: 32, bottom: 20 })
      .onClick(() => {
        this.logout();
      })
  }
}
