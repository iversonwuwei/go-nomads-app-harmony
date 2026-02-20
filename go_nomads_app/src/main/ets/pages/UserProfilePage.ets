import { AppColors } from '../common/constants/AppColors';
import { HttpService } from '../services/HttpService';
import { ApiConfig } from '../common/constants/ApiConfig';
import { Badge, User, UserHelper } from '../models/User';
import { RouteConstants } from '../common/constants/RouteConstants';
import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'UserProfilePage';
const DOMAIN = 0x0001;

/**
 * 他人资料页 — 对应 Flutter user_profile_page.dart
 */
@Entry
@Component
struct UserProfilePage {
  @State user: User | null = null;
  @State isLoading: boolean = true;
  @State isRefreshing: boolean = false;
  private userId: string = '';

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>;
    if (params) {
      this.userId = params['userId'] ?? '';
    }
    this.loadUser();
  }

  async loadUser(): Promise<void> {
    if (!this.isRefreshing) {
      this.isLoading = true;
    }
    try {
      const httpService = HttpService.getInstance();
      this.user = await httpService.get<User>(`${ApiConfig.USER_PROFILE_ENDPOINT}/${this.userId}`);
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ 加载用户资料失败: %{public}s', JSON.stringify(err));
    } finally {
      this.isLoading = false;
      this.isRefreshing = false;
    }
  }

  build() {
    Column() {
      this.TopBar()

      if (this.isLoading && !this.isRefreshing) {
        Column() { LoadingProgress().width(40).height(40) }
          .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else if (this.user) {
        Refresh({ refreshing: $$this.isRefreshing }) {
          Scroll() {
            Column() {
              this.UserHeader()
              this.StatsSection()
              this.BadgesSection()
              if (this.user!.skills.length > 0) {
                this.SkillsTagSection()
              }
              if (this.user!.interests.length > 0) {
                this.InterestsTagSection()
              }
              if (this.user!.socialLinks) { this.SocialLinksSection() }
              this.TravelHistorySection()
              this.ActionButtons()
              Column().height(40)
            }
          }
          .layoutWeight(1).scrollBar(BarState.Off).edgeEffect(EdgeEffect.Spring)
        }
        .onRefreshing(() => {
          this.isRefreshing = true;
          this.loadUser();
        })
      }
    }
    .width('100%').height('100%').backgroundColor(AppColors.BACKGROUND)
  }

  @Builder
  TopBar() {
    Row() {
      SymbolGlyph($r('sys.symbol.arrow_left'))
        .fontSize(24).fontColor([AppColors.TEXT_PRIMARY])
        .onClick(() => { router.back(); })
      Text('用户资料')
        .fontSize(18).fontWeight(FontWeight.Medium)
        .fontColor(AppColors.TEXT_PRIMARY).layoutWeight(1).textAlign(TextAlign.Center)
      Column().width(24)
    }
    .width('100%').height(56).padding({ left: 16, right: 16 })
    .backgroundColor(AppColors.CARD_BACKGROUND)
  }

  @Builder
  UserHeader() {
    Column({ space: 8 }) {
      if (this.user!.avatarUrl) {
        Image(this.user!.avatarUrl)
          .width(80).height(80).borderRadius(40).objectFit(ImageFit.Cover)
      } else {
        Text('👤').fontSize(40).width(80).height(80).textAlign(TextAlign.Center)
          .backgroundColor('#F1F5F9').borderRadius(40)
      }
      Text(this.user!.name)
        .fontSize(22).fontWeight(FontWeight.Bold).fontColor(AppColors.TEXT_PRIMARY)
      if (this.user!.bio) {
        Text(this.user!.bio!)
          .fontSize(14).fontColor(AppColors.TEXT_SECONDARY)
          .textAlign(TextAlign.Center).maxLines(3).padding({ left: 32, right: 32 })
      }
      if (this.user!.currentCity) {
        Row({ space: 4 }) {
          Text('📍').fontSize(14)
          Text(`${this.user!.currentCity}${this.user!.currentCountry ? ', ' + this.user!.currentCountry : ''}`)
            .fontSize(14).fontColor(AppColors.TEXT_SECONDARY)
        }
      }
      // 经验等级标签
      Text(`${UserHelper.experienceLevel(this.user!)} · ${this.user!.stats.citiesVisited} 城市`)
        .fontSize(13).fontColor(AppColors.PRIMARY)
        .backgroundColor('#0891B214').borderRadius(12)
        .padding({ left: 10, right: 10, top: 4, bottom: 4 })
    }
    .width('100%').padding({ top: 24, bottom: 16 }).alignItems(HorizontalAlign.Center)
  }

  @Builder
  StatsSection() {
    Row() {
      this.StatItem(this.user!.stats.countriesVisited.toString(), '国家')
      Divider().vertical(true).height(32).color(AppColors.DIVIDER)
      this.StatItem(this.user!.stats.citiesVisited.toString(), '城市')
      Divider().vertical(true).height(32).color(AppColors.DIVIDER)
      this.StatItem(this.user!.stats.totalTrips.toString(), '行程')
      Divider().vertical(true).height(32).color(AppColors.DIVIDER)
      this.StatItem(this.user!.stats.totalDays.toString(), '天数')
    }
    .width('100%').padding(16).margin({ left: 16, right: 16, bottom: 16 })
    .backgroundColor(AppColors.CARD_BACKGROUND).borderRadius(12)
    .justifyContent(FlexAlign.SpaceEvenly)
  }

  @Builder
  StatItem(value: string, label: string) {
    Column({ space: 4 }) {
      Text(value).fontSize(20).fontWeight(FontWeight.Bold).fontColor(AppColors.PRIMARY)
      Text(label).fontSize(12).fontColor(AppColors.TEXT_SECONDARY)
    }
  }

  private getSkillNames(): string[] {
    if (!this.user) return [];
    return this.user.skills.map((s): string => s.name);
  }

  private getInterestNames(): string[] {
    if (!this.user) return [];
    return this.user.interests.map((i): string => i.name);
  }

  @Builder
  SkillsTagSection() {
    this.TagSection('🎯 技能', this.getSkillNames())
  }

  @Builder
  InterestsTagSection() {
    this.TagSection('💡 兴趣', this.getInterestNames())
  }

  @Builder
  TagSection(title: string, tags: string[]) {
    Column({ space: 8 }) {
      Text(title).fontSize(16).fontWeight(FontWeight.Bold).fontColor(AppColors.TEXT_PRIMARY)
      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(tags, (tag: string) => {
          Text(tag)
            .fontSize(13).fontColor(AppColors.TEXT_SECONDARY)
            .backgroundColor('#F1F5F9').borderRadius(14)
            .padding({ left: 12, right: 12, top: 5, bottom: 5 })
            .margin({ right: 6, bottom: 6 })
        }, (tag: string) => tag)
      }
    }
    .width('100%').padding({ left: 16, right: 16, bottom: 12 }).alignItems(HorizontalAlign.Start)
  }

  @Builder
  BadgesSection() {
    Column({ space: 8 }) {
      Text('🎖 徽章').fontSize(16).fontWeight(FontWeight.Bold).fontColor(AppColors.TEXT_PRIMARY)
      if (this.user!.badges.length > 0) {
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.user!.badges, (badge: Badge) => {
            Row({ space: 6 }) {
              Text(badge.icon ?? '🏅')
              Column({ space: 2 }) {
                Text(badge.name).fontSize(13).fontWeight(FontWeight.Medium).fontColor(AppColors.TEXT_PRIMARY)
                if (badge.description) {
                  Text(badge.description!).fontSize(12).fontColor(AppColors.TEXT_SECONDARY)
                    .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                }
              }
            }
            .padding({ left: 10, right: 10, top: 8, bottom: 8 })
            .backgroundColor('#F8FAFC')
            .borderRadius(12)
            .border({ width: 1, color: AppColors.BORDER_LIGHT })
            .margin({ right: 8, bottom: 8 })
          }, (badge: Badge) => badge.id)
        }
      } else {
        Text('还没有获得徽章').fontSize(13).fontColor(AppColors.TEXT_SECONDARY)
      }
    }
    .width('100%').padding({ left: 16, right: 16, bottom: 12 }).alignItems(HorizontalAlign.Start)
  }

  @Builder
  SocialLinksSection() {
    Column({ space: 8 }) {
      Text('🔗 社交链接').fontSize(16).fontWeight(FontWeight.Bold).fontColor(AppColors.TEXT_PRIMARY)
      if (this.user!.socialLinks?.twitter) {
        this.LinkRow('𝕏', this.user!.socialLinks!.twitter!)
      }
      if (this.user!.socialLinks?.instagram) {
        this.LinkRow('📷', this.user!.socialLinks!.instagram!)
      }
      if (this.user!.socialLinks?.linkedin) {
        this.LinkRow('💼', this.user!.socialLinks!.linkedin!)
      }
      if (this.user!.socialLinks?.website) {
        this.LinkRow('🌐', this.user!.socialLinks!.website!)
      }
    }
    .width('100%').padding({ left: 16, right: 16, bottom: 16 }).alignItems(HorizontalAlign.Start)
  }

  @Builder
  LinkRow(icon: string, url: string) {
    Row({ space: 8 }) {
      Text(icon).fontSize(16)
      Text(url).fontSize(13).fontColor(AppColors.PRIMARY).maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis }).layoutWeight(1)
    }
    .padding({ top: 4, bottom: 4 })
  }

  @Builder
  TravelHistorySection() {
    Column({ space: 8 }) {
      Text('🧳 旅行历史').fontSize(16).fontWeight(FontWeight.Bold).fontColor(AppColors.TEXT_PRIMARY)
      Text(`行程 ${this.user!.stats.totalTrips} 次 · 天数 ${this.user!.stats.totalDays}`)
        .fontSize(13).fontColor(AppColors.TEXT_SECONDARY)
    }
    .width('100%').padding({ left: 16, right: 16, bottom: 16 }).alignItems(HorizontalAlign.Start)
    .onClick(() => {
      router.pushUrl({ url: `pages/${RouteConstants.TRAVEL_HISTORY}` });
    })
  }

  @Builder
  ActionButtons() {
    Row({ space: 12 }) {
      Button('💬 发消息')
        .layoutWeight(1).height(44).borderRadius(10)
        .backgroundColor(AppColors.PRIMARY).fontColor('#FFFFFF').fontSize(15)
        .onClick(() => {
          router.pushUrl({
            url: `pages/${RouteConstants.DIRECT_CHAT}`,
            params: { chatId: this.userId, chatTitle: this.user?.name },
          });
        })
      Button('👋 邀请聚会')
        .layoutWeight(1).height(44).borderRadius(10)
        .backgroundColor('#F1F5F9').fontColor(AppColors.TEXT_PRIMARY).fontSize(15)
    }
    .width('100%').padding({ left: 16, right: 16 })
  }
}
