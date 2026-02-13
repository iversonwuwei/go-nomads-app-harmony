import { Meetup, MeetupHelper, MeetupStatus, MeetupType } from '../../models/Meetup';
import { MeetupService } from '../../services/MeetupService';
import { AppColors } from '../../common/constants/AppColors';
import { RouteConstants } from '../../common/constants/RouteConstants';
import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'MeetupListTab';
const DOMAIN = 0x0001;

/**
 * 聚会列表页 - 100% 还原 Flutter MeetupListPage
 *
 * Flutter 设计:
 *   AppBar: white bg, "聚会活动", backButton, createButton (#FF4458 circle_plus)
 *   TabBar: 4 tabs (全部/已参加/过去的/已取消)
 *     selected: #FF4458, w600, 13px
 *     unselected: grey[600], w500, 13px
 *     indicator: #FF4458, 2.5px underline
 *   MeetupListCard: white bg, radius 16, border borderLight 1px, shadow
 *     image: 180h, top radius 16
 *     content: title 16px bold, time/location/participants
 */
@Component
export struct MeetupListTab {
  @State meetups: Meetup[] = [];
  @State isLoading: boolean = true;
  @State hasError: boolean = false;
  @State errorMsg: string = '';
  @State selectedTabIndex: number = 0;
  @State isRefreshing: boolean = false;

  private tabLabels: string[] = ['全部', '已参加', '过去的', '已取消'];

  aboutToAppear(): void {
    this.loadMeetups();
  }

  async loadMeetups(): Promise<void> {
    this.isLoading = true;
    this.hasError = false;
    try {
      const meetupService = MeetupService.getInstance();
      // 根据 tab 加载不同类型
      let filter: string = 'upcoming';
      if (this.selectedTabIndex === 1) {
        filter = 'joined';
      } else if (this.selectedTabIndex === 2) {
        filter = 'past';
      } else if (this.selectedTabIndex === 3) {
        filter = 'cancelled';
      }
      const meetups = await meetupService.getMeetups(filter, 1, 50);
      this.meetups = meetups;
      hilog.info(DOMAIN, TAG, '✅ 加载 %{public}d 个聚会', meetups.length);
    } catch (err) {
      this.hasError = true;
      this.errorMsg = (err instanceof Error) ? err.message : '加载失败';
      hilog.error(DOMAIN, TAG, '❌ 加载聚会失败: %{public}s', this.errorMsg);
    } finally {
      this.isLoading = false;
      this.isRefreshing = false;
    }
  }

  build() {
    Column() {
      // ===== Flutter AppBar: white bg, title, create button =====
      Row() {
        // Back button
        SymbolGlyph($r('sys.symbol.chevron_left'))
          .fontSize(24)
          .fontColor([AppColors.TEXT_PRIMARY])
          .onClick(() => {
            router.back();
          })
          .width(40)

        Text('聚会活动')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        // Create button: #FF4458 plus_circle
        SymbolGlyph($r('sys.symbol.plus_circle'))
          .fontSize(24)
          .fontColor([AppColors.PRIMARY])
          .onClick(() => {
            router.pushUrl({ url: `pages/${RouteConstants.CREATE_MEETUP}` });
          })
          .width(40)
      }
      .width('100%')
      .height(56)
      .padding({ left: 8, right: 8 })
      .backgroundColor(AppColors.WHITE)
      .alignItems(VerticalAlign.Center)

      // ===== Flutter TabBar: 4 tabs =====
      this.TabBarSection()

      // ===== Content =====
      if (this.isLoading && !this.isRefreshing) {
        Column() {
          LoadingProgress().width(40).height(40)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.hasError) {
        this.ErrorView()
      } else if (this.meetups.length === 0) {
        this.EmptyView()
      } else {
        Refresh({ refreshing: $$this.isRefreshing }) {
          this.MeetupList()
        }
        .layoutWeight(1)
        .onRefreshing(() => {
          this.loadMeetups();
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BACKGROUND)
  }

  // ===== Flutter TabBar: selected #FF4458 w600 13px, underline 2.5px =====
  @Builder
  TabBarSection() {
    Column() {
      Row() {
        ForEach(this.tabLabels, (label: string, index: number) => {
          Column({ space: 8 }) {
            Text(label)
              .fontSize(13)
              .fontWeight(this.selectedTabIndex === index ? FontWeight.Bold : FontWeight.Medium)
              .fontColor(this.selectedTabIndex === index ? AppColors.PRIMARY : '#757575')

            // Underline indicator
            Column()
              .width('60%')
              .height(2.5)
              .borderRadius(1.25)
              .backgroundColor(this.selectedTabIndex === index ? AppColors.PRIMARY : 'transparent')
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
          .padding({ top: 12, bottom: 6 })
          .onClick(() => {
            if (this.selectedTabIndex !== index) {
              this.selectedTabIndex = index;
              this.loadMeetups();
            }
          })
        }, (label: string, index: number) => label)
      }
      .width('100%')
    }
    .width('100%')
    .backgroundColor(AppColors.WHITE)
    .border({ width: { bottom: 1 }, color: { bottom: '#11000000' } })
  }

  // ===== Empty View =====
  @Builder
  EmptyView() {
    Column({ space: 16 }) {
      SymbolGlyph($r('sys.symbol.compass'))
        .fontSize(64)
        .fontColor(['#C0C0C0'])

      Text('暂无聚会')
        .fontSize(16)
        .fontColor(AppColors.TEXT_SECONDARY)

      Text('创建或发现更多有趣的聚会吧')
        .fontSize(14)
        .fontColor(AppColors.TEXT_TERTIARY)
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  // ===== Error View =====
  @Builder
  ErrorView() {
    Column({ space: 12 }) {
      Text('⚠️').fontSize(48)
      Text('加载失败').fontSize(16).fontColor(AppColors.TEXT_SECONDARY)
      Text(this.errorMsg).fontSize(13).fontColor(AppColors.TEXT_TERTIARY)
      Button('重试')
        .height(40)
        .fontSize(14)
        .borderRadius(20)
        .backgroundColor(AppColors.PRIMARY)
        .fontColor(AppColors.WHITE)
        .onClick(() => {
          this.loadMeetups();
        })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  // ===== Meetup List =====
  @Builder
  MeetupList() {
    List() {
      ForEach(this.meetups, (meetup: Meetup) => {
        ListItem() {
          this.MeetupCard(meetup)
        }
      }, (meetup: Meetup) => meetup.id)
    }
    .layoutWeight(1)
    .divider({ strokeWidth: 0 })
    .edgeEffect(EdgeEffect.Spring)
    .padding({ left: 16, right: 16, top: 16, bottom: 100 })
  }

  // ===== Flutter MeetupListCard: white bg, radius 16, border borderLight, shadow =====
  @Builder
  MeetupCard(meetup: Meetup) {
    Column() {
      // Image section: 180h, top radius 16
      Stack() {
        if (meetup.images.length > 0) {
          Image(meetup.images[0])
            .width('100%')
            .height(180)
            .objectFit(ImageFit.Cover)
            .borderRadius({ topLeft: 16, topRight: 16 })
        } else {
          // Placeholder
          Column() {
            SymbolGlyph($r('sys.symbol.compass'))
              .fontSize(64)
              .fontColor(['#BDBDBD'])
          }
          .width('100%')
          .height(180)
          .backgroundColor('#F5F5F5')
          .borderRadius({ topLeft: 16, topRight: 16 })
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        }

        // Cancelled overlay
        if (meetup.status === MeetupStatus.Cancelled) {
          Column() {
            Text('已取消')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.WHITE)
              .padding({ left: 20, right: 20, top: 10, bottom: 10 })
              .backgroundColor('#FF0000')
              .borderRadius(8)
          }
          .width('100%')
          .height(180)
          .borderRadius({ topLeft: 16, topRight: 16 })
          .backgroundColor('#80000000')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        }
      }

      // Content area
      Column({ space: 8 }) {
        // Type + status tags
        Row({ space: 6 }) {
          Text(this.getMeetupTypeLabel(meetup.type))
            .fontSize(11)
            .fontColor(AppColors.PRIMARY)
            .backgroundColor('#14FF4458') // PRIMARY 8% alpha
            .borderRadius(4)
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })

          if (MeetupHelper.isStartingSoon(meetup)) {
            Text('即将开始')
              .fontSize(11)
              .fontColor(AppColors.WHITE)
              .backgroundColor(AppColors.WARNING)
              .borderRadius(4)
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          }
          if (MeetupHelper.isOngoing(meetup)) {
            Text('进行中')
              .fontSize(11)
              .fontColor(AppColors.WHITE)
              .backgroundColor(AppColors.SUCCESS)
              .borderRadius(4)
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          }
        }

        // Title
        Text(meetup.title)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        // Date
        Row({ space: 6 }) {
          Text('📅').fontSize(14)
          Text(new Date(meetup.schedule.startTime).toLocaleDateString('zh-CN', {
            month: 'long', day: 'numeric', hour: '2-digit', minute: '2-digit',
          }))
            .fontSize(13)
            .fontColor(AppColors.TEXT_SECONDARY)
        }

        // Location
        Row({ space: 6 }) {
          Text('📍').fontSize(14)
          Text(meetup.venue.name)
            .fontSize(13)
            .fontColor(AppColors.TEXT_SECONDARY)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }

        // Participants + organizer
        Row() {
          Text(`👥 ${meetup.capacity.current}${meetup.capacity.max ? '/' + meetup.capacity.max : ''} 人`)
            .fontSize(12)
            .fontColor(AppColors.TEXT_TERTIARY)
          Blank()
          Text(meetup.organizer.name)
            .fontSize(12)
            .fontColor(AppColors.TEXT_TERTIARY)
        }
        .width('100%')
      }
      .width('100%')
      .padding({ left: 14, right: 14, top: meetup.images.length > 0 ? 10 : 14, bottom: 14 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .backgroundColor(AppColors.WHITE) // Flutter: white, NOT CARD_BACKGROUND
    .borderRadius(16) // Flutter: 16
    .border({ width: 1, color: AppColors.BORDER_LIGHT })
    .shadow({ radius: 10, color: '#0D000000', offsetX: 0, offsetY: 2 }) // Flutter: black 5% blur 10
    .margin({ bottom: 16 })
    .onClick(() => {
      router.pushUrl({
        url: `pages/${RouteConstants.MEETUP_DETAIL}`,
        params: { meetupId: meetup.id },
      });
    })
  }

  getMeetupTypeLabel(type: MeetupType): string {
    switch (type) {
      case MeetupType.Social: return '社交';
      case MeetupType.Coworking: return '共同办公';
      case MeetupType.Workshop: return '工作坊';
      case MeetupType.Sports: return '运动';
      case MeetupType.Cultural: return '文化';
      case MeetupType.Networking: return '社交联络';
      default: return '其他';
    }
  }
}
