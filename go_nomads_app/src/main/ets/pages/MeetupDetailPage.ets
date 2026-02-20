import { Meetup, MeetupHelper } from '../models/Meetup';
import { MeetupService } from '../services/MeetupService';
import { AppColors } from '../common/constants/AppColors';
import { AppStorageKeys } from '../common/constants/AppStorageKeys';
import { RouteConstants } from '../common/constants/RouteConstants';
import { router } from '@kit.ArkUI';
import clipboard from '@ohos.clipboard';
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
  @State actionMessage: string = '';
  @State actionError: string = '';
  @State currentImageIndex: number = 0;
  @State showAllParticipants: boolean = false;
  @State shareUrl: string = '';
  @State shareDescription: string = '';
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
      this.currentImageIndex = 0;
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
    this.actionError = '';
    try {
      const meetupService = MeetupService.getInstance();
      await meetupService.joinMeetup(this.meetupId);
      // 重新加载
      await this.loadMeetupDetail();
      this.actionMessage = '已成功参加聚会';
      hilog.info(DOMAIN, TAG, '✅ 已加入聚会');
    } catch (err) {
      this.actionError = (err as Error).message;
      hilog.error(DOMAIN, TAG, '❌ 加入聚会失败: %{public}s', (err as Error).message);
    } finally {
      this.isJoining = false;
    }
  }

  async leaveMeetup(): Promise<void> {
    if (this.isJoining || !this.meetup) return;
    this.isJoining = true;
    this.actionError = '';
    try {
      const meetupService = MeetupService.getInstance();
      await meetupService.leaveMeetup(this.meetupId);
      await this.loadMeetupDetail();
      this.actionMessage = '已退出该聚会';
      hilog.info(DOMAIN, TAG, '✅ 已退出聚会');
    } catch (err) {
      this.actionError = (err as Error).message;
      hilog.error(DOMAIN, TAG, '❌ 退出聚会失败: %{public}s', (err as Error).message);
    } finally {
      this.isJoining = false;
    }
  }

  async cancelMeetup(): Promise<void> {
    if (this.isJoining || !this.meetup) return;
    this.isJoining = true;
    this.actionError = '';
    try {
      const meetupService = MeetupService.getInstance();
      await meetupService.cancelMeetup(this.meetupId);
      await this.loadMeetupDetail();
      this.actionMessage = '聚会已取消';
      hilog.info(DOMAIN, TAG, '✅ 聚会已取消');
    } catch (err) {
      this.actionError = (err as Error).message;
      hilog.error(DOMAIN, TAG, '❌ 取消聚会失败: %{public}s', (err as Error).message);
    } finally {
      this.isJoining = false;
    }
  }

  private buildShareContent(): void {
    if (!this.meetup) {
      this.shareUrl = '';
      this.shareDescription = '';
      return;
    }

    const meetup = this.meetup;
    const title = `${meetup.title} - Go Nomads`;
    const details: string[] = [];
    details.push(`📅 ${new Date(meetup.startTime).toLocaleString('zh-CN')}`);
    details.push(`📍 ${meetup.location ?? meetup.city?.name ?? '待定地点'}`);
    if (meetup.participantCount >= 0) {
      details.push(`👥 ${meetup.participantCount} 人参加`);
    }
    if (meetup.description && meetup.description.length > 0) {
      details.push(`\n${meetup.description}`);
    }

    this.shareUrl = `https://nomadcities.app/meetups/${meetup.id}`;
    this.shareDescription = `${title}\n${details.join('\n')}\n\n${this.shareUrl}`;
  }

  async copyShareLink(): Promise<void> {
    if (!this.meetup) {
      return;
    }
    this.actionError = '';
    this.buildShareContent();
    try {
      await clipboard.setData(this.shareDescription);
      this.actionMessage = '分享文案已复制，可直接粘贴发送';
      hilog.info(DOMAIN, TAG, '✅ 分享文案已复制');
    } catch (err) {
      this.actionError = (err as Error).message;
      hilog.error(DOMAIN, TAG, '❌ 复制分享文案失败: %{public}s', (err as Error).message);
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
      } else if (this.hasError) {
        Column({ space: 12 }) {
          Text(this.errorMsg.length > 0 ? this.errorMsg : '加载失败')
            .fontSize(14)
            .fontColor(AppColors.ERROR)
            .textAlign(TextAlign.Center)

          Button('重试')
            .height(40)
            .borderRadius(8)
            .backgroundColor(AppColors.PRIMARY)
            .fontColor('#FFFFFF')
            .onClick(async () => {
              await this.loadMeetupDetail();
            })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else if (this.meetup) {
        Scroll() {
          Column() {
            if (this.actionMessage.length > 0) {
              Text(this.actionMessage)
                .width('100%')
                .fontSize(13)
                .fontColor(AppColors.SUCCESS)
                .backgroundColor('#E8F5E9')
                .borderRadius(8)
                .padding({ left: 12, right: 12, top: 8, bottom: 8 })
                .margin({ left: 16, right: 16, top: 12 })
            }

            if (this.actionError.length > 0) {
              Text(this.actionError)
                .width('100%')
                .fontSize(13)
                .fontColor(AppColors.ERROR)
                .backgroundColor('#FEE2E2')
                .borderRadius(8)
                .padding({ left: 12, right: 12, top: 8, bottom: 8 })
                .margin({ left: 16, right: 16, top: 12 })
            }

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

      if (this.meetup?.isOrganizer) {
        Text('编辑')
          .fontSize(14)
          .fontColor(AppColors.PRIMARY)
          .margin({ right: 12 })
          .onClick(() => {
            router.pushUrl({
              url: `pages/${RouteConstants.CREATE_MEETUP}`,
              params: {
                meetupId: this.meetupId,
              },
            });
          })
      }

      SymbolGlyph($r('sys.symbol.share'))
        .fontSize(22)
        .fontColor([AppColors.TEXT_PRIMARY])
        .onClick(async () => {
          await this.copyShareLink();
        })
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor(AppColors.CARD_BACKGROUND)
  }

  @Builder
  CoverSection() {
    Stack({ alignContent: Alignment.Bottom }) {
      if (this.meetup!.images && this.meetup!.images!.length > 0) {
        Swiper() {
          ForEach(this.meetup!.images!, (url: string, index?: number) => {
            Image(url)
              .width('100%')
              .height(220)
              .objectFit(ImageFit.Cover)
          }, (url: string) => url)
        }
        .width('100%')
        .height(220)
        .autoPlay(false)
        .onChange((index: number) => {
          this.currentImageIndex = index;
        })

        if (this.meetup!.images!.length > 1) {
          Row({ space: 6 }) {
            ForEach(this.meetup!.images!, (url: string, index?: number) => {
              Row()
                .width(this.currentImageIndex === (index ?? 0) ? 18 : 8)
                .height(8)
                .borderRadius(6)
                .backgroundColor(this.currentImageIndex === (index ?? 0) ? '#FFFFFF' : '#FFFFFF88')
            }, (url: string, index?: number) => `${url}-${index}`)
          }
          .margin({ bottom: 14 })

          Text(`${this.currentImageIndex + 1}/${this.meetup!.images!.length}`)
            .fontSize(12)
            .fontColor('#FFFFFF')
            .backgroundColor('#00000088')
            .borderRadius(10)
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .position({ x: '82%', y: 12 })
        }
      } else if (this.meetup!.imageUrl) {
        Image(this.meetup!.imageUrl!)
          .width('100%')
          .height(220)
          .objectFit(ImageFit.Cover)
      } else {
        Row() {
          Text('📅')
            .fontSize(42)
        }
        .width('100%')
        .height(220)
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#E2E8F0')
    }
  }
    .width('100%')
    .height(220)

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
          .onClick(() => {
            const organizerId = this.meetup?.organizer?.id ?? '';
            if (organizerId.length > 0) {
              router.pushUrl({
                url: `pages/${RouteConstants.USER_PROFILE}`,
                params: {
                  userId: organizerId,
                },
              });
            }
          })
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
    const participants = this.meetup!.participants ?? [];
    const displayCount = this.showAllParticipants ? participants.length : Math.min(participants.length, 10);

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

      if (participants.length > 0) {
        Scroll({ direction: Axis.Horizontal }) {
          Row({ space: 10 }) {
            ForEach(participants.slice(0, displayCount), (p) => {
              Column({ space: 6 }) {
                if (p.avatarUrl) {
                  Image(p.avatarUrl)
                    .width(40)
                    .height(40)
                    .borderRadius(20)
                    .objectFit(ImageFit.Cover)
                } else {
                  Row() {
                    Text((p.name.length > 0 ? p.name.substring(0, 1) : 'U').toUpperCase())
                      .fontSize(16)
                      .fontColor('#FFFFFF')
                      .fontWeight(FontWeight.Medium)
                  }
                  .width(40)
                  .height(40)
                  .borderRadius(20)
                  .justifyContent(FlexAlign.Center)
                  .backgroundColor(AppColors.PRIMARY)
                }

                Text(p.name)
                  .fontSize(11)
                  .fontColor(AppColors.TEXT_SECONDARY)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .width(56)
                  .textAlign(TextAlign.Center)
              }
              .width(56)
              .onClick(() => {
                if (p.userId.length > 0) {
                  router.pushUrl({
                    url: `pages/${RouteConstants.USER_PROFILE}`,
                    params: {
                      userId: p.userId,
                    },
                  });
                }
              })
            }, (p) => p.id)
          }
          .padding({ top: 4, bottom: 6 })
        }
        .width('100%')

        if (participants.length > 10) {
          Text(this.showAllParticipants ? '收起' : '查看全部')
            .fontSize(12)
            .fontColor(AppColors.PRIMARY)
            .fontWeight(FontWeight.Medium)
            .onClick(() => {
              this.showAllParticipants = !this.showAllParticipants;
            })
        }

        if (this.showAllParticipants) {
          Column({ space: 8 }) {
            ForEach(participants, (p) => {
              Row({ space: 10 }) {
                if (p.avatarUrl) {
                  Image(p.avatarUrl)
                    .width(36)
                    .height(36)
                    .borderRadius(18)
                    .objectFit(ImageFit.Cover)
                } else {
                  Row() {
                    Text((p.name.length > 0 ? p.name.substring(0, 1) : 'U').toUpperCase())
                      .fontSize(14)
                      .fontColor('#FFFFFF')
                      .fontWeight(FontWeight.Medium)
                  }
                  .width(36)
                  .height(36)
                  .borderRadius(18)
                  .justifyContent(FlexAlign.Center)
                  .backgroundColor(AppColors.PRIMARY)
                }

                Column({ space: 2 }) {
                  Text(p.name)
                    .fontSize(13)
                    .fontColor(AppColors.TEXT_PRIMARY)
                    .fontWeight(FontWeight.Medium)
                  if (p.email && p.email!.length > 0) {
                    Text(p.email!)
                      .fontSize(11)
                      .fontColor(AppColors.TEXT_SECONDARY)
                  }
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)

                Text('查看')
                  .fontSize(12)
                  .fontColor(AppColors.PRIMARY)
              }
              .width('100%')
              .padding({ left: 10, right: 10, top: 8, bottom: 8 })
              .borderRadius(8)
              .backgroundColor('#F8FAFC')
              .onClick(() => {
                if (p.userId.length > 0) {
                  router.pushUrl({
                    url: `pages/${RouteConstants.USER_PROFILE}`,
                    params: {
                      userId: p.userId,
                    },
                  });
                }
              })
            }, (p) => `${p.id}-full`)
          }
          .width('100%')
          .margin({ top: 8 })
        }
      } else {
        Text('暂无参与者')
          .fontSize(13)
          .fontColor(AppColors.TEXT_TERTIARY)
      }

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
      if (this.meetup!.isOrganizer) {
        Button('进入聊天')
          .layoutWeight(1)
          .height(48)
          .borderRadius(10)
          .backgroundColor(AppColors.PRIMARY)
          .fontColor('#FFFFFF')
          .fontSize(16)
          .onClick(() => {
            if (!this.meetup?.city?.id) {
              this.actionError = '当前聚会缺少城市信息，无法进入聊天';
              return;
            }
            router.pushUrl({
              url: `pages/${RouteConstants.CITY_CHAT}`,
              params: {
                cityId: this.meetup!.city!.id,
                cityName: this.meetup!.city!.name,
              },
            });
          })

        Button(MeetupHelper.isEnded(this.meetup!) ? '已结束' : (this.isJoining ? '取消中...' : '取消聚会'))
          .width(112)
          .height(48)
          .borderRadius(10)
          .backgroundColor(MeetupHelper.isEnded(this.meetup!) ? '#E2E8F0' : AppColors.WARNING)
          .fontColor(MeetupHelper.isEnded(this.meetup!) ? AppColors.TEXT_TERTIARY : '#FFFFFF')
          .fontSize(15)
          .enabled(!MeetupHelper.isEnded(this.meetup!) && !this.isJoining)
          .margin({ left: 10 })
          .onClick(() => {
            if (this.isAuthenticated && !MeetupHelper.isEnded(this.meetup!)) {
              this.cancelMeetup();
            }
          })
      } else if (this.meetup!.isParticipant) {
        Button('进入聊天')
          .layoutWeight(1)
          .height(48)
          .borderRadius(10)
          .backgroundColor(AppColors.PRIMARY)
          .fontColor('#FFFFFF')
          .fontSize(16)
          .onClick(() => {
            if (!this.meetup?.city?.id) {
              this.actionError = '当前聚会缺少城市信息，无法进入聊天';
              return;
            }
            router.pushUrl({
              url: `pages/${RouteConstants.CITY_CHAT}`,
              params: {
                cityId: this.meetup!.city!.id,
                cityName: this.meetup!.city!.name,
              },
            });
          })

        Button(this.isJoining ? '退出中...' : '退出聚会')
          .width(112)
          .height(48)
          .borderRadius(10)
          .backgroundColor('#FEE2E2')
          .fontColor(AppColors.ERROR)
          .fontSize(15)
          .enabled(!this.isJoining)
          .margin({ left: 10 })
          .onClick(() => {
            if (this.isAuthenticated) {
              this.leaveMeetup();
            }
          })
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
