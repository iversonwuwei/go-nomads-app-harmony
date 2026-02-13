import { Meetup, MeetupHelper } from '../models/Meetup';
import { MeetupService } from '../services/MeetupService';
import { AppColors } from '../common/constants/AppColors';
import { AppStorageKeys } from '../common/constants/AppStorageKeys';
import { RouteConstants } from '../common/constants/RouteConstants';
import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'MeetupDetailPage';
const DOMAIN = 0x0001;

/**
 * 聚会详情页 - 对应 Flutter 端 MeetupDetailPage
 */
@Entry
@Component
struct MeetupDetailPage {
  @State meetup: Meetup | null = null;
  @State isLoading: boolean = true;
  @State hasError: boolean = false;
  @State errorMsg: string = '';
  @State isJoining: boolean = false;
  @StorageProp(AppStorageKeys.IS_AUTHENTICATED) isAuthenticated: boolean = false;

  private meetupId: string = '';

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>;
    if (params) {
      this.meetupId = params['meetupId'] ?? '';
    }
    this.loadMeetupDetail();
  }

  async loadMeetupDetail(): Promise<void> {
    this.isLoading = true;
    this.hasError = false;
    try {
      const meetupService = MeetupService.getInstance();
      const meetup = await meetupService.getMeetupById(this.meetupId);
      this.meetup = meetup;
      hilog.info(DOMAIN, TAG, '✅ 聚会详情加载: %{public}s', meetup.title);
    } catch (err) {
      this.hasError = true;
      this.errorMsg = (err instanceof Error) ? err.message : '加载失败';
      hilog.error(DOMAIN, TAG, '❌ 加载聚会详情失败: %{public}s', this.errorMsg);
    } finally {
      this.isLoading = false;
    }
  }

  async joinMeetup(): Promise<void> {
    if (this.isJoining || !this.meetup) return;
    this.isJoining = true;
    try {
      const meetupService = MeetupService.getInstance();
      await meetupService.joinMeetup(this.meetupId);
      // 重新加载
      await this.loadMeetupDetail();
      hilog.info(DOMAIN, TAG, '✅ 已加入聚会');
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ 加入聚会失败: %{public}s', (err as Error).message);
    } finally {
      this.isJoining = false;
    }
  }

  async leaveMeetup(): Promise<void> {
    if (this.isJoining || !this.meetup) return;
    this.isJoining = true;
    try {
      const meetupService = MeetupService.getInstance();
      await meetupService.leaveMeetup(this.meetupId);
      await this.loadMeetupDetail();
      hilog.info(DOMAIN, TAG, '✅ 已退出聚会');
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ 退出聚会失败: %{public}s', (err as Error).message);
    } finally {
      this.isJoining = false;
    }
  }

  build() {
    Column() {
      // 顶部栏
      this.TopBar()

      if (this.isLoading) {
        Column() {
          LoadingProgress().width(40).height(40)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.meetup) {
        Scroll() {
          Column() {
            // 封面图
            this.CoverSection()

            // 基本信息
            this.InfoSection()

            // 详细描述
            this.DescriptionSection()

            // 地点信息
            this.VenueSection()

            // 参与者
            this.ParticipantsSection()

            Column().height(100)
          }
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)

        // 底部操作栏
        this.BottomActionBar()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BACKGROUND)
  }

  @Builder
  TopBar() {
    Row() {
      SymbolGlyph($r('sys.symbol.arrow_left'))
        .fontSize(24)
        .fontColor([AppColors.TEXT_PRIMARY])
        .onClick(() => {
          router.back();
        })

      Text('聚会详情')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.TEXT_PRIMARY)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      SymbolGlyph($r('sys.symbol.share'))
        .fontSize(22)
        .fontColor([AppColors.TEXT_PRIMARY])
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor(AppColors.CARD_BACKGROUND)
  }

  @Builder
  CoverSection() {
    if (this.meetup!.images && this.meetup!.images!.length > 0) {
      Image(this.meetup!.images![0])
        .width('100%')
        .height(200)
        .objectFit(ImageFit.Cover)
    } else if (this.meetup!.imageUrl) {
      Image(this.meetup!.imageUrl!)
        .width('100%')
        .height(200)
        .objectFit(ImageFit.Cover)
    }
  }

  @Builder
  InfoSection() {
    Column({ space: 10 }) {
      // 标题
      Text(this.meetup!.title)
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.TEXT_PRIMARY)

      // 状态标签
      Row({ space: 8 }) {
        Text(this.getMeetupCategoryLabel(this.meetup!.category))
          .fontSize(12)
          .fontColor(AppColors.PRIMARY)
          .backgroundColor('#0891B214')
          .borderRadius(6)
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })

        if (MeetupHelper.isStartingSoon(this.meetup!)) {
          Text('即将开始')
            .fontSize(12)
            .fontColor('#FFFFFF')
            .backgroundColor(AppColors.WARNING)
            .borderRadius(6)
            .padding({ left: 8, right: 8, top: 3, bottom: 3 })
        }
        if (MeetupHelper.isOngoing(this.meetup!)) {
          Text('进行中')
            .fontSize(12)
            .fontColor('#FFFFFF')
            .backgroundColor(AppColors.SUCCESS)
            .borderRadius(6)
            .padding({ left: 8, right: 8, top: 3, bottom: 3 })
        }
      }

      // 时间
      Row({ space: 8 }) {
        Text('📅')
          .fontSize(18)
        Column({ space: 2 }) {
          Text(new Date(this.meetup!.startTime).toLocaleDateString('zh-CN', {
            year: 'numeric',
            month: 'long',
            day: 'numeric',
            weekday: 'long',
          }))
            .fontSize(14)
            .fontColor(AppColors.TEXT_PRIMARY)
          Text(`${new Date(this.meetup!.startTime).toLocaleTimeString('zh-CN', {
            hour: '2-digit',
            minute: '2-digit',
          })}${this.meetup!.endTime ? ' - ' + new Date(this.meetup!.endTime!).toLocaleTimeString('zh-CN', {
            hour: '2-digit',
            minute: '2-digit',
          }) : ''}`)
            .fontSize(13)
            .fontColor(AppColors.TEXT_SECONDARY)
        }
      }

      // 组织者
      Row({ space: 8 }) {
        Text('👤')
          .fontSize(18)
        Text(`组织者：${this.meetup!.organizer?.name ?? '未知'}`)
          .fontSize(14)
          .fontColor(AppColors.TEXT_SECONDARY)
      }
    }
    .width('100%')
    .padding(16)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  DescriptionSection() {
    if (this.meetup!.description) {
      Column({ space: 8 }) {
        Text('活动介绍')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)

        Text(this.meetup!.description)
          .fontSize(14)
          .lineHeight(22)
          .fontColor(AppColors.TEXT_SECONDARY)
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 16 })
      .alignItems(HorizontalAlign.Start)
    }
  }

  @Builder
  VenueSection() {
    Column({ space: 8 }) {
      Text('活动地点')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.TEXT_PRIMARY)

      Row() {
        Column({ space: 4 }) {
          Text(this.meetup!.location ?? this.meetup!.city?.name ?? '未指定地点')
            .fontSize(15)
            .fontColor(AppColors.TEXT_PRIMARY)

          if (this.meetup!.address) {
            Text(this.meetup!.address!)
              .fontSize(13)
              .fontColor(AppColors.TEXT_SECONDARY)
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Text('📍')
          .fontSize(24)
      }
      .width('100%')
      .padding(14)
      .backgroundColor(AppColors.CARD_BACKGROUND)
      .borderRadius(10)
    }
    .width('100%')
    .padding({ left: 16, right: 16, bottom: 16 })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  ParticipantsSection() {
    Column({ space: 8 }) {
      Row() {
        Text('参与者')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
        Blank()
        Text(`${this.meetup!.participantCount}${this.meetup!.maxParticipants ? '/' + this.meetup!.maxParticipants : ''} 人`)
          .fontSize(14)
          .fontColor(AppColors.TEXT_SECONDARY)
      }
      .width('100%')

      // 容量进度条
      if (this.meetup!.maxParticipants) {
        Progress({
          value: this.meetup!.participantCount,
          total: this.meetup!.maxParticipants!,
          type: ProgressType.Linear,
        })
          .width('100%')
          .style({ strokeWidth: 8 })
          .color(this.meetup!.participantCount >= this.meetup!.maxParticipants! ? AppColors.ERROR : AppColors.PRIMARY)
          .backgroundColor('#E2E8F0')
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16 })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  BottomActionBar() {
    Row() {
      // 参加/已参加按钮
      if (this.meetup!.isParticipant) {
        Button('已参加 ✓')
          .layoutWeight(1)
          .height(48)
          .borderRadius(10)
          .backgroundColor('#E8F5E9')
          .fontColor(AppColors.SUCCESS)
          .fontSize(16)
      } else if (MeetupHelper.canJoin(this.meetup!)) {
        Button(this.isJoining ? '加入中...' : '参加聚会')
          .layoutWeight(1)
          .height(48)
          .borderRadius(10)
          .backgroundColor(AppColors.PRIMARY)
          .fontColor('#FFFFFF')
          .fontSize(16)
          .enabled(!this.isJoining)
          .onClick(() => {
            if (this.isAuthenticated) {
              this.joinMeetup();
            } else {
              router.pushUrl({ url: `pages/${RouteConstants.LOGIN}` });
            }
          })
      } else {
        Button(MeetupHelper.isEnded(this.meetup!) ? '已结束' : '名额已满')
          .layoutWeight(1)
          .height(48)
          .borderRadius(10)
          .backgroundColor('#E2E8F0')
          .fontColor(AppColors.TEXT_TERTIARY)
          .fontSize(16)
          .enabled(false)
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor(AppColors.CARD_BACKGROUND)
    .shadow({ radius: 8, color: '#00000010', offsetX: 0, offsetY: -2 })
  }

  getMeetupCategoryLabel(category: string | undefined): string {
    if (!category) return '其他';
    switch (category.toLowerCase()) {
      case 'social': return '社交';
      case 'coworking': return '共同办公';
      case 'workshop': return '工作坊';
      case 'sports': return '运动';
      case 'cultural': return '文化';
      case 'networking': return '社交联络';
      default: return '其他';
    }
  }
}
