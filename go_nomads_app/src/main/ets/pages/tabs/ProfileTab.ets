import { AppColors } from '../../common/constants/AppColors';
import { AppStorageKeys } from '../../common/constants/AppStorageKeys';
import { RouteConstants } from '../../common/constants/RouteConstants';
import { AuthService } from '../../services/AuthService';
import { UserService } from '../../services/UserService';
import { AuthUser } from '../../models/AuthModels';
import { User, UserHelper } from '../../models/User';
import { TravelHistory } from '../../models/TravelHistory';
import { TravelPlanSummary } from '../../models/TravelPlanSummary';
import { TravelHistoryService } from '../../services/TravelHistoryService';
import { TravelPlanService } from '../../services/TravelPlanService';
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
  @State isRefreshing: boolean = false;
  @State latestTravelHistory: TravelHistory | null = null;
  @State latestTravelPlan: TravelPlanSummary | null = null;

  aboutToAppear(): void {
    if (this.isAuthenticated) {
      this.loadUserProfile();
    }
  }

  async loadUserProfile(): Promise<void> {
    if (!this.isRefreshing) {
      this.isLoading = true;
    }
    this.hasError = false;
    try {
      const userService = UserService.getInstance();
      const user = await userService.getCurrentUser();
      this.userDetail = user;
      hilog.info(DOMAIN, TAG, '✅ 用户信息加载成功');

      const travelHistorySvc = TravelHistoryService.getInstance();
      const planSvc = TravelPlanService.getInstance();
      const [history, plan] = await Promise.all([
        travelHistorySvc.getLatest(),
        planSvc.getLatest(),
      ]);
      this.latestTravelHistory = history;
      this.latestTravelPlan = plan;
    } catch (err) {
      this.hasError = true;
      hilog.error(DOMAIN, TAG, '❌ 加载用户信息失败: %{public}s', (err as Error).message);
    } finally {
      this.isLoading = false;
      this.isRefreshing = false;
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
    Column() {
      if (this.isLoading && !this.isRefreshing) {
        this.LoadingSkeleton()
      } else if (this.hasError) {
        this.ErrorState()
      } else if (!this.isAuthenticated) {
        this.LoginPrompt()
      } else {
        Refresh({ refreshing: $$this.isRefreshing }) {
          Scroll() {
            Column() {
              this.ProfileHeader()
              if (this.userDetail) {
                this.MembershipCard()
                this.TravelPlansCard()
                this.NomadStats()
                this.BadgesSection()
                this.SkillsInterests()
                this.TravelHistory()
                this.SocialLinks()
              }
              this.HelpSupport()
              this.MenuSection()
              this.LogoutButton()
              Column().height(80)
            }
            .width('100%')
          }
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Spring)
        }
        .onRefreshing(() => {
          this.isRefreshing = true;
          this.loadUserProfile();
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BACKGROUND)
  }

  @Builder
  LoadingSkeleton() {
    Column({ space: 16 }) {
      Column().width(80).height(80).borderRadius(40).backgroundColor(AppColors.GREY200)
      Column().width('70%').height(16).backgroundColor(AppColors.GREY200)
      Column().width('50%').height(14).backgroundColor(AppColors.GREY200)
      Column().width('90%').height(200).backgroundColor(AppColors.GREY200).borderRadius(12)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  ErrorState() {
    Column({ space: 16 }) {
      Text('加载失败，请重试')
        .fontSize(16)
        .fontColor(AppColors.TEXT_SECONDARY)
      Button('重新加载')
        .width(160)
        .height(44)
        .borderRadius(22)
        .backgroundColor(AppColors.PRIMARY)
        .fontColor(AppColors.WHITE)
        .onClick(async () => { await this.loadUserProfile(); })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
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

  @Builder
  MembershipCard() {
    Column({ space: 8 }) {
      Text('Nomad Membership')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.WHITE)
      Text('解锁高级功能，结识更多游民伙伴')
        .fontSize(13)
        .fontColor(AppColors.WHITE)
        .opacity(0.8)
      Row({ space: 8 }) {
        Button('立即升级')
          .height(40)
          .borderRadius(10)
          .backgroundColor(AppColors.WHITE)
          .fontColor(AppColors.PRIMARY)
          .fontSize(14)
          .onClick(() => {
            router.pushUrl({ url: `pages/${RouteConstants.MEMBERSHIP_PLAN}` });
          })
        Text('当前：免费版')
          .fontSize(13)
          .fontColor(AppColors.WHITE)
          .opacity(0.9)
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 20, bottom: 20 })
    .margin({ left: 16, right: 16, bottom: 16 })
    .borderRadius(16)
    .backgroundColor('#FF6B6B')
  }

  @Builder
  TravelPlansCard() {
    Column({ space: 8 }) {
      Row({ space: 8 }) {
        Text('✈️')
        Text('我的旅行计划')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
      }
      if (this.latestTravelPlan) {
        Text(`${this.latestTravelPlan.cityName ?? '旅行计划'} · ${this.latestTravelPlan.durationDays ?? '--'} 天 · ${this.latestTravelPlan.destinationsCount ?? 1} 站`)
          .fontSize(13)
          .fontColor(AppColors.TEXT_SECONDARY)
        Button('查看计划')
          .height(40)
          .borderRadius(10)
          .backgroundColor(AppColors.PRIMARY)
          .fontColor(AppColors.WHITE)
          .onClick(() => {
            router.pushUrl({
              url: `pages/${RouteConstants.TRAVEL_PLAN}`,
              params: { planId: this.latestTravelPlan?.id },
            });
          })
      } else {
        Text('创建行程计划，分享给好友或社区。')
          .fontSize(13)
          .fontColor(AppColors.TEXT_SECONDARY)
        Button('创建计划')
          .height(40)
          .borderRadius(10)
          .backgroundColor(AppColors.PRIMARY)
          .fontColor(AppColors.WHITE)
          .onClick(() => { router.pushUrl({ url: `pages/${RouteConstants.CREATE_TRAVEL_PLAN}` }); })
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .margin({ left: 16, right: 16, bottom: 16 })
    .backgroundColor(AppColors.WHITE)
    .borderRadius(12)
    .border({ width: 1, color: AppColors.BORDER_LIGHT })
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
  BadgesSection() {
    Column({ space: 10 }) {
      Text('徽章')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.TEXT_PRIMARY)
      if (this.userDetail && this.userDetail.badges.length > 0) {
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.userDetail!.badges, (badge) => {
            Row({ space: 6 }) {
              Text(badge.icon ?? '🏅')
              Column({ space: 2 }) {
                Text(badge.name).fontSize(13).fontWeight(FontWeight.Medium).fontColor(AppColors.TEXT_PRIMARY)
                if (badge.description) {
                  Text(badge.description!).fontSize(12).fontColor(AppColors.TEXT_SECONDARY).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                }
              }
            }
            .padding({ left: 10, right: 10, top: 8, bottom: 8 })
            .backgroundColor('#F8FAFC')
            .borderRadius(12)
            .border({ width: 1, color: AppColors.BORDER_LIGHT })
            .margin({ right: 8, bottom: 8 })
          }, (badge) => badge.id)
        }
      } else {
        Text('还没有徽章，参加活动或完成行程解锁奖励。')
          .fontSize(13)
          .fontColor(AppColors.TEXT_SECONDARY)
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .margin({ left: 16, right: 16, bottom: 16 })
    .backgroundColor(AppColors.WHITE)
    .borderRadius(12)
    .border({ width: 1, color: AppColors.BORDER_LIGHT })
  }

  @Builder
  SkillsInterests() {
    Column({ space: 10 }) {
      Text('技能与兴趣')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.TEXT_PRIMARY)
      if (this.userDetail && (this.userDetail.skills.length > 0 || this.userDetail.interests.length > 0)) {
        Flex({ wrap: FlexWrap.Wrap }) {
          const tags: string[] = [];
          this.userDetail!.skills.forEach((s) => tags.push(s.name));
          this.userDetail!.interests.forEach((i) => tags.push(i.name));
          ForEach(tags, (tag) => {
            Text(tag)
              .fontSize(13)
              .fontColor(AppColors.TEXT_SECONDARY)
              .backgroundColor('#F1F5F9')
              .borderRadius(14)
              .padding({ left: 12, right: 12, top: 6, bottom: 6 })
              .margin({ right: 8, bottom: 8 })
          }, (tag) => tag)
        }
      } else {
        Text('添加技能和兴趣，匹配志同道合的伙伴。')
          .fontSize(13)
          .fontColor(AppColors.TEXT_SECONDARY)
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .margin({ left: 16, right: 16, bottom: 16 })
    .backgroundColor(AppColors.WHITE)
    .borderRadius(12)
    .border({ width: 1, color: AppColors.BORDER_LIGHT })
  }

  @Builder
  TravelHistory() {
    Column({ space: 10 }) {
      Row({ space: 8 }) {
        Text('🧳')
        Text('旅行历史')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
        Column().layoutWeight(1)
        SymbolGlyph($r('sys.symbol.chevron_right'))
          .fontSize(16)
          .fontColor([AppColors.TEXT_TERTIARY])
      }
      if (this.latestTravelHistory) {
        const trip = this.latestTravelHistory;
        Column({ space: 6 }) {
          Text(`${trip.city}${trip.country ? ' · ' + trip.country : ''}`)
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.TEXT_PRIMARY)
          Text(trip.isOngoing ? '进行中' : '已完成')
            .fontSize(12)
            .fontColor(trip.isOngoing ? AppColors.SUCCESS : AppColors.TEXT_SECONDARY)
          Text(`行程 ${this.userDetail?.stats.totalTrips ?? 0} 次 · 累计 ${this.userDetail?.stats.totalDays ?? 0} 天`)
            .fontSize(13)
            .fontColor(AppColors.TEXT_SECONDARY)
        }
      } else {
        Text(`已完成 ${this.userDetail?.stats.totalTrips ?? 0} 次行程，累计 ${this.userDetail?.stats.totalDays ?? 0} 天`) 
          .fontSize(13)
          .fontColor(AppColors.TEXT_SECONDARY)
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .margin({ left: 16, right: 16, bottom: 16 })
    .backgroundColor(AppColors.WHITE)
    .borderRadius(12)
    .border({ width: 1, color: AppColors.BORDER_LIGHT })
    .onClick(() => {
      router.pushUrl({ url: `pages/${RouteConstants.TRAVEL_HISTORY}` });
    })
  }

  @Builder
  SocialLinks() {
    Column({ space: 10 }) {
      Text('社交链接')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.TEXT_PRIMARY)
      const links = this.userDetail?.socialLinks ?? {};
      const entries = Object.keys(links);
      if (entries.length > 0) {
        ForEach(entries, (key) => {
          this.SocialLinkRow(key, links[key])
        }, (key) => key)
      } else {
        Text('暂无社交链接，添加后便于伙伴联系你。')
          .fontSize(13)
          .fontColor(AppColors.TEXT_SECONDARY)
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .margin({ left: 16, right: 16, bottom: 16 })
    .backgroundColor(AppColors.WHITE)
    .borderRadius(12)
    .border({ width: 1, color: AppColors.BORDER_LIGHT })
  }

  @Builder
  SocialLinkRow(label: string, url: string) {
    Row({ space: 8 }) {
      Text(label).fontSize(14).fontColor(AppColors.TEXT_SECONDARY).width(80)
      Text(url)
        .fontSize(14)
        .fontColor(AppColors.PRIMARY)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
    }
  }

  @Builder
  HelpSupport() {
    Column({ space: 8 }) {
      Text('帮助与客服')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.TEXT_PRIMARY)
      Text('遇到问题？查看常见问题或联系支持团队。')
        .fontSize(13)
        .fontColor(AppColors.TEXT_SECONDARY)
      Button('联系客服')
        .height(40)
        .borderRadius(10)
        .backgroundColor(AppColors.PRIMARY_LIGHT)
        .fontColor(AppColors.PRIMARY)
        .onClick(() => { router.pushUrl({ url: `pages/${RouteConstants.SETTINGS}` }); })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .margin({ left: 16, right: 16, bottom: 16 })
    .backgroundColor(AppColors.WHITE)
    .borderRadius(12)
    .border({ width: 1, color: AppColors.BORDER_LIGHT })
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
