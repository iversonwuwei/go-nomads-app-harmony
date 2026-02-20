import { AppColors } from '../common/constants/AppColors';
import { RouteConstants } from '../common/constants/RouteConstants';
import { TravelHistory } from '../models/TravelHistory';
import { TravelHistoryService } from '../services/TravelHistoryService';
import { router } from '@kit.ArkUI';

/**
 * 旅行历史页 - 对齐 Flutter TravelHistoryPage 主流程
 */
@Entry
@Component
struct TravelHistoryPage {
  @State trips: TravelHistory[] = [];
  @State pendingTrips: TravelHistory[] = [];
  @State confirmedTrips: TravelHistory[] = [];
  @State isLoading: boolean = true;
  @State isRefreshing: boolean = false;
  @State isAutoDetectionEnabled: boolean = true;
  @State homeLocation: string = '';
  @State homeConfidence: number = 0;
  @State showMenu: boolean = false;
  @State actionMessage: string = '';
  @State loadError: string = '';
  @State hasLoadedOnce: boolean = false;
  @State actionMessageToken: number = 0;
  @State lastActionMessageText: string = '';
  @State lastActionMessageTs: number = 0;

  aboutToAppear(): void {
    if (this.hasLoadedOnce) {
      this.refreshSilently();
      return;
    }
    this.loadTrips();
  }

  private async refreshSilently(): Promise<void> {
    try {
      const service = TravelHistoryService.getInstance();
      const latestTrips = await service.getList(1, 50);
      this.applyTrips(latestTrips);

      if (this.confirmedTrips.length > 0) {
        const latest = this.confirmedTrips[0];
        this.homeLocation = `${latest.city}${latest.country ? ', ' + latest.country : ''}`;
        this.homeConfidence = 78;
      } else {
        this.homeLocation = '';
        this.homeConfidence = 0;
      }
      this.loadError = '';
    } catch (_err) {
    }
  }

  async loadTrips(): Promise<void> {
    if (!this.isRefreshing) {
      this.isLoading = true;
    }
    try {
      this.loadError = '';
      const service = TravelHistoryService.getInstance();
      const latestTrips = await service.getList(1, 50);
      this.applyTrips(latestTrips);

      if (this.confirmedTrips.length > 0) {
        const latest = this.confirmedTrips[0];
        this.homeLocation = `${latest.city}${latest.country ? ', ' + latest.country : ''}`;
        this.homeConfidence = 78;
      } else {
        this.homeLocation = '';
        this.homeConfidence = 0;
      }
    } catch (_err) {
      this.loadError = '加载失败，请下拉重试';
    } finally {
      this.isLoading = false;
      this.isRefreshing = false;
      this.hasLoadedOnce = true;
    }
  }

  private showActionMessage(message: string): void {
    const now = Date.now();
    if (message === this.lastActionMessageText && now - this.lastActionMessageTs < 1200) {
      return;
    }

    this.lastActionMessageText = message;
    this.lastActionMessageTs = now;
    this.actionMessageToken += 1;
    const token = this.actionMessageToken;

    this.actionMessage = message;
    setTimeout(() => {
      if (this.actionMessageToken === token) {
        this.actionMessage = '';
      }
    }, 2600);
  }

  private applyTrips(sourceTrips: TravelHistory[]): void {
    const used: Record<string, boolean> = {};
    const merged: TravelHistory[] = [];
    for (let i = 0; i < sourceTrips.length; i++) {
      const item = sourceTrips[i];
      const key = this.getTripKey(item);
      if (!used[key]) {
        used[key] = true;
        merged.push(item);
      }
    }

    this.trips = merged;
    this.pendingTrips = this.trips.filter((trip: TravelHistory) => (trip.status ?? '').toLowerCase() === 'pending');
    this.confirmedTrips = this.trips.filter((trip: TravelHistory) => (trip.status ?? '').toLowerCase() !== 'pending');
  }

  private openTravelPlan(trip: TravelHistory): void {
    const planId = trip.backendId ?? trip.id;
    if (!planId) {
      return;
    }
    router.pushUrl({
      url: `pages/${RouteConstants.TRAVEL_PLAN}`,
      params: { planId },
    });
  }

  private openVisitedPlaces(trip: TravelHistory): void {
    const travelHistoryId = trip.backendId ?? trip.id;
    if (!travelHistoryId) {
      this.showActionMessage('该旅行记录暂未关联访问地点');
      return;
    }
    router.pushUrl({
      url: `pages/${RouteConstants.VISITED_PLACES}`,
      params: {
        travelHistoryId,
        cityId: trip.cityId ?? '',
        cityName: trip.city ?? '',
        countryName: trip.country ?? '',
      },
    });
  }

  private openCityDetail(trip: TravelHistory): void {
    if (!trip.cityId) {
      this.showActionMessage('该旅行记录暂无城市详情');
      return;
    }
    router.pushUrl({
      url: `pages/${RouteConstants.CITY_DETAIL}`,
      params: { cityId: trip.cityId, cityName: trip.city },
    });
  }

  private getTripKey(trip: TravelHistory): string {
    const key = (trip.backendId ?? trip.id ?? '').trim();
    if (key.length > 0) {
      return key;
    }
    return `${trip.city}|${trip.arrivalTime}|${trip.departureTime ?? ''}`;
  }

  @Builder
  OverflowMenu() {
    Column({ space: 6 }) {
      Text('设置常住地')
        .fontSize(13)
        .fontColor(AppColors.TEXT_PRIMARY)
        .onClick(() => {
          this.showMenu = false;
          if (this.confirmedTrips.length > 0) {
            this.homeLocation = `${this.confirmedTrips[0].city}${this.confirmedTrips[0].country ? ', ' + this.confirmedTrips[0].country : ''}`;
            this.homeConfidence = 82;
            this.showActionMessage('已从最新旅行记录设置常住地');
          } else {
            this.showActionMessage('暂无可用旅行记录');
          }
        })
      Divider().color(AppColors.BORDER_LIGHT)
      Text('清空本地展示数据')
        .fontSize(13)
        .fontColor(AppColors.ERROR)
        .onClick(() => {
          this.showMenu = false;
          this.pendingTrips = [];
          this.confirmedTrips = [];
          this.trips = [];
          this.homeLocation = '';
          this.homeConfidence = 0;
          this.showActionMessage('已清空本地展示数据');
        })
    }
    .width(180)
    .padding(12)
    .backgroundColor(AppColors.WHITE)
    .borderRadius(10)
    .border({ width: 1, color: AppColors.BORDER_LIGHT })
  }

  @Builder
  TopBanners() {
    Column({ space: 8 }) {
      if (this.actionMessage.length > 0) {
        Text(this.actionMessage)
          .width('100%')
          .fontSize(13)
          .fontColor(AppColors.SUCCESS)
          .backgroundColor('#ECFDF5')
          .borderRadius(8)
          .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      }

      if (this.loadError.length > 0 && !this.isRefreshing) {
        Row({ space: 8 }) {
          Text(this.loadError)
            .fontSize(13)
            .fontColor(AppColors.ERROR)
            .layoutWeight(1)
          Text('重试')
            .fontSize(13)
            .fontColor(AppColors.PRIMARY)
            .onClick(async () => {
              await this.loadTrips();
            })
        }
        .width('100%')
        .backgroundColor('#FEF2F2')
        .borderRadius(8)
        .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      }
    }
    .width('100%')
  }

  build() {
    Stack() {
      Column() {
        Row() {
          SymbolGlyph($r('sys.symbol.arrow_left'))
            .fontSize(24)
            .fontColor([AppColors.TEXT_PRIMARY])
            .onClick(() => {
              router.back();
            })
          Text('旅行历史')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.TEXT_PRIMARY)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)

          Text(this.isAutoDetectionEnabled ? '📍' : '📍✕')
            .fontSize(18)
            .fontColor(this.isAutoDetectionEnabled ? AppColors.PRIMARY : AppColors.TEXT_TERTIARY)
            .margin({ right: 10 })
            .onClick(() => {
              this.isAutoDetectionEnabled = !this.isAutoDetectionEnabled;
              this.showActionMessage(this.isAutoDetectionEnabled ? '自动检测已开启' : '自动检测已关闭');
            })

          Text('⋮')
            .fontSize(20)
            .fontColor(AppColors.TEXT_PRIMARY)
            .onClick(() => {
              this.showMenu = !this.showMenu;
            })
        }
        .width('100%')
        .height(56)
        .padding({ left: 16, right: 16 })
        .backgroundColor(AppColors.CARD_BACKGROUND)

        if (this.isLoading && !this.isRefreshing) {
          Column() { LoadingProgress().width(40).height(40) }
            .width('100%')
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)
        } else {
          Refresh({ refreshing: $$this.isRefreshing }) {
            Scroll() {
              Column() {
                if (this.homeLocation.length > 0) {
                  this.HomeLocationCard()
                }

                this.SectionHeader('待确认旅行', this.pendingTrips.length)
                if (this.pendingTrips.length > 0) {
                  Column() {
                    ForEach(this.pendingTrips, (trip: TravelHistory) => {
                      this.PendingTripCard(trip)
                    }, (trip: TravelHistory) => `p-${this.getTripKey(trip)}`)
                  }
                  .width('100%')
                }

                this.SectionHeader('已确认旅行', this.confirmedTrips.length)
                if (this.confirmedTrips.length === 0) {
                  this.EmptyState()
                } else {
                  List() {
                    ForEach(this.confirmedTrips, (trip: TravelHistory) => {
                      ListItem() {
                        this.TripCard(trip)
                      }
                    }, (trip: TravelHistory) => this.getTripKey(trip))
                  }
                  .layoutWeight(1)
                  .padding({ left: 16, right: 16, top: 8, bottom: 16 })
                  .divider({ strokeWidth: 0 })
                  .edgeEffect(EdgeEffect.Spring)
                }
              }
              .width('100%')
            }
            .width('100%')
            .height('100%')
          }
          .layoutWeight(1)
          .onRefreshing(() => {
            this.showMenu = false;
            this.actionMessage = '';
            this.isRefreshing = true;
            this.loadTrips();
          })
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(AppColors.BACKGROUND)

      if (!this.showMenu && (this.actionMessage.length > 0 || this.loadError.length > 0)) {
        Column() {
          this.TopBanners()
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 62 })
      }

      if (this.showMenu) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('#01000000')
          .onClick(() => {
            this.showMenu = false;
          })

        Column() {
          this.OverflowMenu()
        }
        .width('100%')
        .padding({ top: 60, right: 16 })
        .alignItems(HorizontalAlign.End)
      }
    }
  }

  @Builder
  EmptyState() {
    Column({ space: 12 }) {
      Text('🧳').fontSize(48)
      Text('暂无旅行历史').fontSize(16).fontColor(AppColors.TEXT_SECONDARY)
      Text('开始你的数字游民旅程吧').fontSize(14).fontColor(AppColors.TEXT_TERTIARY)
      if (this.isAutoDetectionEnabled) {
        Row({ space: 6 }) {
          Text('📍')
            .fontSize(14)
            .fontColor(AppColors.PRIMARY)
          Text('自动检测进行中')
            .fontSize(12)
            .fontColor(AppColors.PRIMARY)
        }
        .backgroundColor('#EEF2FF')
        .borderRadius(12)
        .padding({ left: 10, right: 10, top: 5, bottom: 5 })
      } else {
        Text('开启自动检测')
          .fontSize(13)
          .fontColor(AppColors.PRIMARY)
          .backgroundColor('#EEF2FF')
          .borderRadius(14)
          .padding({ left: 12, right: 12, top: 7, bottom: 7 })
          .onClick(() => {
            this.isAutoDetectionEnabled = true;
            this.showActionMessage('自动检测已开启');
          })
      }
    }
    .width('100%')
    .padding({ top: 16, bottom: 20 })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  HomeLocationCard() {
    Row({ space: 12 }) {
      Text('🏠').fontSize(24)
      Column({ space: 4 }) {
        Text('常住地')
          .fontSize(12)
          .fontColor(AppColors.TEXT_TERTIARY)
        Text(this.homeLocation)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
        Text(`置信度 ${this.homeConfidence}%`)
          .fontSize(12)
          .fontColor(AppColors.TEXT_TERTIARY)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Text(`${this.homeConfidence}`)
        .fontSize(12)
        .fontColor(AppColors.PRIMARY)
        .backgroundColor('#EEF2FF')
        .borderRadius(10)
        .padding({ left: 8, right: 8, top: 4, bottom: 4 })
    }
    .width('100%')
    .padding(14)
    .backgroundColor(AppColors.WHITE)
    .borderRadius(12)
    .margin({ left: 16, right: 16, top: 14 })
  }

  @Builder
  SectionHeader(title: string, count: number) {
    Row({ space: 8 }) {
      Text(title)
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.TEXT_PRIMARY)
      Text(`${count}`)
        .fontSize(12)
        .fontColor(AppColors.PRIMARY)
        .backgroundColor('#FEE2E2')
        .borderRadius(10)
        .padding({ left: 8, right: 8, top: 3, bottom: 3 })
    }
    .width('100%')
    .margin({ left: 16, right: 16, top: 18, bottom: 8 })
  }

  @Builder
  PendingTripCard(trip: TravelHistory) {
    Row({ space: 10 }) {
      Column({ space: 4 }) {
        Text(`${trip.city}${trip.country ? ', ' + trip.country : ''}`)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT_PRIMARY)
        Text(`${this.formatDate(trip.arrivalTime)} - ${trip.departureTime ? this.formatDate(trip.departureTime!) : '进行中'}`)
          .fontSize(12)
          .fontColor(AppColors.TEXT_SECONDARY)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Text('确认')
        .fontSize(12)
        .fontColor(AppColors.WHITE)
        .backgroundColor(AppColors.SUCCESS)
        .borderRadius(8)
        .padding({ left: 10, right: 10, top: 5, bottom: 5 })
        .onClick(() => {
          const tripKey = this.getTripKey(trip);
          this.pendingTrips = this.pendingTrips.filter((item: TravelHistory) => this.getTripKey(item) !== tripKey);
          const updatedTrip: TravelHistory = this.buildConfirmedTrip(trip);
          const mergedConfirmed: TravelHistory[] = [updatedTrip];
          const kept = this.confirmedTrips.filter((item: TravelHistory) => this.getTripKey(item) !== tripKey);
          for (let i = 0; i < kept.length; i++) {
            mergedConfirmed.push(kept[i]);
          }
          this.confirmedTrips = mergedConfirmed;
          this.trips = this.trips.map((item: TravelHistory) => this.getTripKey(item) === tripKey ? updatedTrip : item);
          if (this.homeLocation.length === 0) {
            this.homeLocation = `${updatedTrip.city}${updatedTrip.country ? ', ' + updatedTrip.country : ''}`;
            this.homeConfidence = 78;
          }
          this.showActionMessage(`已确认旅行：${trip.city}`);
        })

      Text('忽略')
        .fontSize(12)
        .fontColor(AppColors.TEXT_SECONDARY)
        .backgroundColor('#F1F5F9')
        .borderRadius(8)
        .padding({ left: 10, right: 10, top: 5, bottom: 5 })
        .onClick(() => {
          const tripKey = this.getTripKey(trip);
          this.pendingTrips = this.pendingTrips.filter((item: TravelHistory) => this.getTripKey(item) !== tripKey);
          this.trips = this.trips.filter((item: TravelHistory) => this.getTripKey(item) !== tripKey);
          this.showActionMessage(`已忽略旅行：${trip.city}`);
        })

      if (trip.backendId || trip.id) {
        Text('访问地点')
          .fontSize(12)
          .fontColor(AppColors.PRIMARY)
          .backgroundColor('#EEF2FF')
          .borderRadius(8)
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .onClick(() => {
            this.openVisitedPlaces(trip);
          })
      }
    }
    .width('100%')
    .padding({ left: 14, right: 14, top: 12, bottom: 12 })
    .backgroundColor(AppColors.WHITE)
    .borderRadius(12)
    .border({ width: 1, color: AppColors.BORDER_LIGHT })
    .margin({ left: 16, right: 16, bottom: 10 })
  }

  @Builder
  TripCard(trip: TravelHistory) {
    Column({ space: 10 }) {
      Row() {
        Text(`${trip.city}${trip.country ? ' · ' + trip.country : ''}`)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
          .layoutWeight(1)
        Text(trip.isOngoing ? '进行中' : '已完成')
          .fontSize(12)
          .fontColor(trip.isOngoing ? AppColors.SUCCESS : AppColors.TEXT_SECONDARY)
          .backgroundColor(trip.isOngoing ? '#ECFDF5' : '#F1F5F9')
          .borderRadius(10)
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
      }
      Text(`到达：${this.formatDate(trip.arrivalTime)}${trip.departureTime ? ' · 离开：' + this.formatDate(trip.departureTime!) : ''}`)
        .fontSize(13)
        .fontColor(AppColors.TEXT_SECONDARY)
      if (trip.durationDays !== undefined) {
        Text(`停留 ${trip.durationDays} 天`)
          .fontSize(13)
          .fontColor(AppColors.TEXT_TERTIARY)
      }
      if (trip.cityId) {
        Text('查看城市详情')
          .fontSize(13)
          .fontColor(AppColors.PRIMARY)
      }

      Row({ space: 10 }) {
        if (trip.backendId || trip.id) {
          Text('访问地点')
            .fontSize(12)
            .fontColor(AppColors.PRIMARY)
            .backgroundColor('#EEF2FF')
            .borderRadius(8)
            .padding({ left: 10, right: 10, top: 5, bottom: 5 })
            .onClick(() => {
              this.openVisitedPlaces(trip);
            })
        }

        if (trip.cityId) {
          Text('城市详情')
            .fontSize(12)
            .fontColor(AppColors.TEXT_SECONDARY)
            .backgroundColor('#F1F5F9')
            .borderRadius(8)
            .padding({ left: 10, right: 10, top: 5, bottom: 5 })
            .onClick(() => {
              this.openCityDetail(trip);
            })
        }
      }
      .width('100%')
    }
    .width('100%')
    .padding({ left: 14, right: 14, top: 14, bottom: 14 })
    .backgroundColor(AppColors.WHITE)
    .borderRadius(12)
    .border({ width: 1, color: AppColors.BORDER_LIGHT })
    .margin({ bottom: 10 })
    .onClick(() => {
      if (trip.backendId || trip.id) {
        this.openVisitedPlaces(trip);
      } else {
        this.showActionMessage('该旅行记录暂未关联访问地点');
      }
    })
  }

  formatDate(raw: string): string {
    if (!raw) return '';
    const d = new Date(raw);
    return d.toLocaleDateString('zh-CN', { month: '2-digit', day: '2-digit' });
  }

  private buildConfirmedTrip(trip: TravelHistory): TravelHistory {
    const confirmed: TravelHistory = {
      id: trip.id,
      backendId: trip.backendId,
      cityId: trip.cityId,
      city: trip.city,
      country: trip.country,
      arrivalTime: trip.arrivalTime,
      departureTime: trip.departureTime,
      durationDays: trip.durationDays,
      status: 'confirmed',
      isOngoing: trip.isOngoing,
      cityName: trip.cityName,
      countryCode: trip.countryCode,
    };
    return confirmed;
  }
}
