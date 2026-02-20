import { AppColors } from '../common/constants/AppColors';
import { RouteConstants } from '../common/constants/RouteConstants';
import { Meetup, MeetupHelper } from '../models/Meetup';
import { MeetupService } from '../services/MeetupService';
import { router } from '@kit.ArkUI';

@Entry
@Component
struct MyMeetupsPage {
  @State currentTab: number = 0;
  @State myCreated: Meetup[] = [];
  @State myJoined: Meetup[] = [];
  @State isLoading: boolean = true;
  @State isRefreshing: boolean = false;
  @State hasError: boolean = false;
  @State errorMsg: string = '';

  aboutToAppear(): void {
    this.loadData();
  }

  private async loadData(): Promise<void> {
    if (!this.isRefreshing) {
      this.isLoading = true;
    }
    this.hasError = false;
    this.errorMsg = '';
    try {
      const service = MeetupService.getInstance();
      this.myCreated = await service.getMyCreatedMeetups();
      this.myJoined = await service.getJoinedMeetups(1, 100);
    } catch (err) {
      this.hasError = true;
      this.errorMsg = (err as Error).message;
    } finally {
      this.isLoading = false;
      this.isRefreshing = false;
    }
  }

  private formatDate(raw: string): string {
    const date = new Date(raw);
    if (isNaN(date.getTime())) {
      return '时间待定';
    }
    return date.toLocaleString('zh-CN', {
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
    });
  }

  private getCurrentList(): Meetup[] {
    return this.currentTab === 0 ? this.myCreated : this.myJoined;
  }

  build() {
    Column() {
      Row() {
        SymbolGlyph($r('sys.symbol.arrow_left'))
          .fontSize(24).fontColor([AppColors.TEXT_PRIMARY]).onClick(() => { router.back(); })
        Text('我的聚会')
          .fontSize(18).fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT_PRIMARY).layoutWeight(1).textAlign(TextAlign.Center)
        Column().width(24)
      }
      .width('100%').height(56).padding({ left: 16, right: 16 })
      .backgroundColor(AppColors.CARD_BACKGROUND)

      if (this.isLoading && !this.isRefreshing) {
        Column() {
          LoadingProgress().width(40).height(40)
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
      } else if (this.hasError) {
        Column({ space: 10 }) {
          Text(this.errorMsg.length > 0 ? this.errorMsg : '加载失败')
            .fontSize(14)
            .fontColor(AppColors.ERROR)
            .textAlign(TextAlign.Center)
          Button('重试')
            .height(40)
            .backgroundColor(AppColors.PRIMARY)
            .fontColor(AppColors.WHITE)
            .borderRadius(10)
            .onClick(async () => {
              await this.loadData();
            })
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        Refresh({ refreshing: $$this.isRefreshing }) {
          Column() {
            Row({ space: 8 }) {
              this.TabButton('我创建的', 0, this.myCreated.length)
              this.TabButton('我参加的', 1, this.myJoined.length)
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 12, bottom: 8 })

            if (this.getCurrentList().length === 0) {
              Column({ space: 12 }) {
                Text('📭').fontSize(42)
                Text(this.currentTab === 0 ? '还没有创建聚会' : '还没有参加聚会')
                  .fontSize(15)
                  .fontColor(AppColors.TEXT_SECONDARY)
                Button(this.currentTab === 0 ? '去创建聚会' : '去发现聚会')
                  .height(40)
                  .borderRadius(10)
                  .backgroundColor(AppColors.PRIMARY)
                  .fontColor(AppColors.WHITE)
                  .onClick(() => {
                    router.pushUrl({
                      url: `pages/${this.currentTab === 0 ? RouteConstants.CREATE_MEETUP : RouteConstants.MEETUP_LIST}`,
                    });
                  })
              }
              .layoutWeight(1)
              .width('100%')
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center)
            } else {
              List() {
                ForEach(this.getCurrentList(), (meetup: Meetup) => {
                  ListItem() {
                    this.MeetupCard(meetup)
                  }
                }, (meetup: Meetup) => meetup.id)
              }
              .layoutWeight(1)
              .divider({ strokeWidth: 0 })
              .padding({ left: 16, right: 16, bottom: 16 })
            }
          }
        }
        .layoutWeight(1)
        .onRefreshing(() => {
          this.isRefreshing = true;
          this.loadData();
        })
      }
    }
    .width('100%').height('100%').backgroundColor(AppColors.BACKGROUND)
  }

  @Builder
  TabButton(label: string, index: number, count: number) {
    Row({ space: 6 }) {
      Text(label)
        .fontSize(14)
        .fontWeight(this.currentTab === index ? FontWeight.Medium : FontWeight.Regular)
        .fontColor(this.currentTab === index ? AppColors.WHITE : AppColors.TEXT_SECONDARY)
      Text(`${count}`)
        .fontSize(12)
        .fontColor(this.currentTab === index ? AppColors.WHITE : AppColors.TEXT_TERTIARY)
    }
    .padding({ left: 12, right: 12, top: 8, bottom: 8 })
    .borderRadius(18)
    .backgroundColor(this.currentTab === index ? AppColors.PRIMARY : AppColors.WHITE)
    .onClick(() => {
      this.currentTab = index;
    })
  }

  @Builder
  MeetupCard(meetup: Meetup) {
    Column({ space: 10 }) {
      Row({ space: 8 }) {
        Text(meetup.title)
          .layoutWeight(1)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        if (MeetupHelper.isOngoing(meetup)) {
          Text('进行中')
            .fontSize(11)
            .fontColor(AppColors.WHITE)
            .backgroundColor(AppColors.SUCCESS)
            .borderRadius(6)
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
        } else if (MeetupHelper.isStartingSoon(meetup)) {
          Text('即将开始')
            .fontSize(11)
            .fontColor(AppColors.WHITE)
            .backgroundColor(AppColors.WARNING)
            .borderRadius(6)
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
        }
      }

      Text(`📅 ${this.formatDate(meetup.startTime)}`)
        .fontSize(13)
        .fontColor(AppColors.TEXT_SECONDARY)

      Text(`📍 ${meetup.location ?? meetup.city?.name ?? '待定地点'}`)
        .fontSize(13)
        .fontColor(AppColors.TEXT_SECONDARY)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Row() {
        Text(`👥 ${meetup.participantCount}${meetup.maxParticipants ? '/' + meetup.maxParticipants : ''}`)
          .fontSize(12)
          .fontColor(AppColors.TEXT_TERTIARY)
        Blank()
        Text('查看详情')
          .fontSize(12)
          .fontColor(AppColors.PRIMARY)
      }
      .width('100%')
    }
    .width('100%')
    .padding(14)
    .backgroundColor(AppColors.WHITE)
    .borderRadius(12)
    .border({ width: 1, color: AppColors.BORDER_LIGHT })
    .margin({ top: 8 })
    .onClick(() => {
      router.pushUrl({
        url: `pages/${RouteConstants.MEETUP_DETAIL}`,
        params: { meetupId: meetup.id },
      });
    })
  }
}
