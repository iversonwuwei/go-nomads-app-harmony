import { Meetup, MeetupHelper, MeetupStatus, MeetupType } from '../../models/Meetup';
import { MeetupService } from '../../services/MeetupService';
import { AppColors } from '../../common/constants/AppColors';
import { RouteConstants } from '../../common/constants/RouteConstants';
import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'MeetupListTab';
const DOMAIN = 0x0001;

/**
 * 聚会列表 Tab - 对应 Flutter 端 MeetupListPage
 */
@Component
export struct MeetupListTab {
  @State meetups: Meetup[] = [];
  @State isLoading: boolean = true;
  @State hasError: boolean = false;
  @State errorMsg: string = '';
  @State selectedFilter: string = '全部';
  @State isRefreshing: boolean = false;

  private filters: string[] = ['全部', '即将开始', '进行中', '我参加的'];

  aboutToAppear(): void {
    this.loadMeetups();
  }

  async loadMeetups(): Promise<void> {
    this.isLoading = true;
    this.hasError = false;
    try {
      const meetupService = MeetupService.getInstance();
      const meetups = await meetupService.getMeetups('upcoming', 1, 50);
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

  getFilteredMeetups(): Meetup[] {
    switch (this.selectedFilter) {
      case '即将开始':
        return this.meetups.filter(m => MeetupHelper.isStartingSoon(m));
      case '进行中':
        return this.meetups.filter(m => MeetupHelper.isOngoing(m));
      case '我参加的':
        return this.meetups.filter(m => m.isJoined === true);
      default:
        return this.meetups;
    }
  }

  build() {
    Column() {
      // 标题 + 创建按钮
      Row() {
        Text('聚会活动')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)

        Blank()

        Button('+ 创建')
          .height(34)
          .fontSize(14)
          .borderRadius(17)
          .backgroundColor(AppColors.PRIMARY)
          .fontColor('#FFFFFF')
          .onClick(() => {
            router.pushUrl({ url: `pages/${RouteConstants.CREATE_MEETUP}` });
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })

      // 筛选器
      this.FilterBar()

      // 聚会列表
      if (this.isLoading && !this.isRefreshing) {
        Column() {
          LoadingProgress().width(40).height(40)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.hasError) {
        Column({ space: 12 }) {
          Text('😞').fontSize(48)
          Text('加载失败').fontSize(16).fontColor(AppColors.TEXT_SECONDARY)
          Text(this.errorMsg).fontSize(13).fontColor(AppColors.TEXT_TERTIARY)
          Button('重试')
            .height(36)
            .fontSize(14)
            .borderRadius(18)
            .backgroundColor(AppColors.PRIMARY)
            .fontColor('#FFFFFF')
            .onClick(() => {
              this.loadMeetups();
            })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
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

  @Builder
  FilterBar() {
    Scroll() {
      Row({ space: 8 }) {
        ForEach(this.filters, (filter: string) => {
          Text(filter)
            .fontSize(13)
            .fontColor(this.selectedFilter === filter ? '#FFFFFF' : AppColors.TEXT_SECONDARY)
            .backgroundColor(this.selectedFilter === filter ? AppColors.PRIMARY : '#F1F5F9')
            .borderRadius(16)
            .padding({ left: 14, right: 14, top: 6, bottom: 6 })
            .onClick(() => {
              this.selectedFilter = filter;
            })
        }, (filter: string) => filter)
      }
      .padding({ left: 16, right: 16 })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
    .margin({ bottom: 12 })
  }

  @Builder
  MeetupList() {
    List() {
      ForEach(this.getFilteredMeetups(), (meetup: Meetup) => {
        ListItem() {
          this.MeetupCard(meetup)
        }
      }, (meetup: Meetup) => meetup.id)
    }
    .layoutWeight(1)
    .divider({ strokeWidth: 0 })
    .edgeEffect(EdgeEffect.Spring)
    .padding({ left: 16, right: 16 })
  }

  @Builder
  MeetupCard(meetup: Meetup) {
    Column() {
      // 封面图（如果有）
      if (meetup.images.length > 0) {
        Image(meetup.images[0])
          .width('100%')
          .height(140)
          .objectFit(ImageFit.Cover)
          .borderRadius({ topLeft: 12, topRight: 12 })
      }

      Column({ space: 6 }) {
        // 状态标签
        Row({ space: 6 }) {
          Text(this.getMeetupTypeLabel(meetup.type))
            .fontSize(11)
            .fontColor(AppColors.PRIMARY)
            .backgroundColor('#0891B214')
            .borderRadius(4)
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })

          if (MeetupHelper.isStartingSoon(meetup)) {
            Text('即将开始')
              .fontSize(11)
              .fontColor('#FFFFFF')
              .backgroundColor(AppColors.WARNING)
              .borderRadius(4)
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          }
          if (MeetupHelper.isOngoing(meetup)) {
            Text('进行中')
              .fontSize(11)
              .fontColor('#FFFFFF')
              .backgroundColor(AppColors.SUCCESS)
              .borderRadius(4)
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          }
        }

        // 标题
        Text(meetup.title)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        // 时间
        Row({ space: 6 }) {
          Text('📅')
            .fontSize(14)
          Text(new Date(meetup.schedule.startTime).toLocaleDateString('zh-CN', {
            month: 'long',
            day: 'numeric',
            hour: '2-digit',
            minute: '2-digit',
          }))
            .fontSize(13)
            .fontColor(AppColors.TEXT_SECONDARY)
        }

        // 地点
        Row({ space: 6 }) {
          Text('📍')
            .fontSize(14)
          Text(meetup.venue.name)
            .fontSize(13)
            .fontColor(AppColors.TEXT_SECONDARY)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }

        // 人数 + 组织者
        Row() {
          Text(`👥 ${meetup.capacity.current}${meetup.capacity.max ? '/' + meetup.capacity.max : ''} 人`)
            .fontSize(12)
            .fontColor(AppColors.TEXT_TERTIARY)

          Blank()

          Row({ space: 4 }) {
            Text(meetup.organizer.name)
              .fontSize(12)
              .fontColor(AppColors.TEXT_TERTIARY)
          }
        }
        .width('100%')
      }
      .width('100%')
      .padding({ left: 14, right: 14, top: meetup.images.length > 0 ? 10 : 14, bottom: 14 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .backgroundColor(AppColors.CARD_BACKGROUND)
    .borderRadius(12)
    .shadow({ radius: 4, color: '#0000000A', offsetX: 0, offsetY: 2 })
    .margin({ bottom: 12 })
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
