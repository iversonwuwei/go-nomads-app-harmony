import { router } from '@kit.ArkUI';
import { AppColors } from '../common/constants/AppColors';
import { VisitedPlace, VisitedPlacesCitySummary } from '../models/VisitedPlace';
import { VisitedPlaceService } from '../services/VisitedPlaceService';

@Entry
@Component
struct VisitedPlacesPage {
  @State travelHistoryId: string = '';
  @State cityId: string = '';
  @State cityName: string = '';
  @State countryName: string = '';
  @State places: VisitedPlace[] = [];
  @State citySummary: VisitedPlacesCitySummary | null = null;
  @State currentPage: number = 1;
  @State pageSize: number = 20;
  @State hasMore: boolean = false;
  @State totalCount: number = 0;
  @State isLoading: boolean = true;
  @State isRefreshing: boolean = false;
  @State isLoadingMore: boolean = false;
  @State loadMoreError: string = '';
  @State errorMessage: string = '';
  @State actionMessage: string = '';
  @State actionMessageToken: number = 0;
  @State lastActionMessageText: string = '';
  @State lastActionMessageTs: number = 0;
  @State showPlaceSheet: boolean = false;
  @State selectedPlace: VisitedPlace | null = null;
  @State selectedPlaceIndex: number = -1;
  @State isHighlightUpdating: boolean = false;

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>;
    this.travelHistoryId = params?.travelHistoryId ?? '';
    this.cityId = params?.cityId ?? '';
    this.cityName = params?.cityName ?? '';
    this.countryName = params?.countryName ?? '';
    this.loadData();
  }

  async loadData(): Promise<void> {
    if (!this.isRefreshing) {
      this.isLoading = true;
    }

    try {
      this.errorMessage = '';
      this.citySummary = null;
      this.currentPage = 1;
      this.hasMore = false;
      this.totalCount = 0;
      this.loadMoreError = '';

      if (!this.travelHistoryId) {
        this.places = [];
        this.syncSelectedPlaceWithList();
        this.errorMessage = '缺少旅行记录标识';
        return;
      }

      const service = VisitedPlaceService.getInstance();

      if (this.cityId.length > 0) {
        const summary = await service.getCitySummary(this.cityId, 1, this.pageSize);
        if (summary) {
          this.citySummary = summary;
          this.places = summary.visitedPlaces.items;
          this.totalCount = summary.visitedPlaces.totalCount;
          this.currentPage = summary.visitedPlaces.page;
          this.hasMore = this.places.length < this.totalCount;
          if (this.cityName.length === 0) {
            this.cityName = summary.cityName;
          }
          if (this.countryName.length === 0) {
            this.countryName = summary.country;
          }
        } else {
          this.places = await service.getByTravelHistoryId(this.travelHistoryId);
          this.totalCount = this.places.length;
        }
      } else {
        this.places = await service.getByTravelHistoryId(this.travelHistoryId);
        this.totalCount = this.places.length;
      }

      if (this.places.length === 0) {
        this.errorMessage = '';
      }
      this.syncSelectedPlaceWithList();
    } catch (_err) {
      this.errorMessage = '加载访问地点失败';
    } finally {
      this.isLoading = false;
      this.isRefreshing = false;
    }
  }

  async loadMore(): Promise<void> {
    if (this.isLoadingMore || !this.hasMore || this.cityId.length === 0) {
      return;
    }

    this.isLoadingMore = true;
    this.loadMoreError = '';
    try {
      const nextPage = this.currentPage + 1;
      const service = VisitedPlaceService.getInstance();
      const pageData = await service.getCityVisitedPlaces(this.cityId, nextPage, this.pageSize);
      if (pageData.items.length > 0) {
        this.places = this.mergeUniquePlaces(this.places, pageData.items);
        this.currentPage = pageData.page;
        this.totalCount = pageData.totalCount;
        this.hasMore = this.places.length < this.totalCount;
        this.syncSelectedPlaceWithList();
      } else {
        this.hasMore = false;
      }
    } catch (_err) {
      this.loadMoreError = '加载更多失败，请重试';
    } finally {
      this.isLoadingMore = false;
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
    }, 2200);
  }

  private getPlaceKey(place: VisitedPlace): string {
    const idKey = (place.id ?? '').trim();
    if (idKey.length > 0) {
      return idKey;
    }
    const name = place.placeName ?? '';
    const arrival = place.arrivalTime ?? '';
    const departure = place.departureTime ?? '';
    const address = place.address ?? '';
    return `${name}|${arrival}|${departure}|${address}`;
  }

  private mergeUniquePlaces(base: VisitedPlace[], incoming: VisitedPlace[]): VisitedPlace[] {
    if (incoming.length === 0) {
      return base;
    }

    const used: Record<string, boolean> = {};
    const merged: VisitedPlace[] = [];

    for (let i = 0; i < base.length; i++) {
      const item = base[i];
      const key = this.getPlaceKey(item);
      if (!used[key]) {
        used[key] = true;
        merged.push(item);
      }
    }

    for (let i = 0; i < incoming.length; i++) {
      const item = incoming[i];
      const key = this.getPlaceKey(item);
      if (!used[key]) {
        used[key] = true;
        merged.push(item);
      }
    }

    return merged;
  }

  private syncSelectedPlaceWithList(): void {
    if (!this.selectedPlace) {
      return;
    }

    const selectedKey = this.getPlaceKey(this.selectedPlace);
    const index = this.places.findIndex((item: VisitedPlace) => this.getPlaceKey(item) === selectedKey);
    if (index >= 0) {
      this.selectedPlaceIndex = index;
      this.selectedPlace = this.places[index];
      return;
    }

    this.closePlaceDetails();
  }

  private resolvePlaceIndex(place: VisitedPlace, hintIndex: number): number {
    if (hintIndex >= 0 && hintIndex < this.places.length) {
      const hinted = this.places[hintIndex];
      if (this.getPlaceKey(hinted) === this.getPlaceKey(place)) {
        return hintIndex;
      }
    }
    const key = this.getPlaceKey(place);
    return this.places.findIndex((item: VisitedPlace) => this.getPlaceKey(item) === key);
  }

  async toggleHighlight(place: VisitedPlace, index: number): Promise<void> {
    const targetIndex = this.resolvePlaceIndex(place, index);
    if (this.isHighlightUpdating || !place.id || targetIndex < 0 || targetIndex >= this.places.length) {
      return;
    }

    this.isHighlightUpdating = true;
    try {
      const original = this.places[targetIndex];
      const next: VisitedPlace = {
        ...original,
        isHighlight: !original.isHighlight,
      };
      this.places[targetIndex] = next;
      if (this.selectedPlace && this.getPlaceKey(this.selectedPlace) === this.getPlaceKey(next)) {
        this.selectedPlace = next;
        this.selectedPlaceIndex = targetIndex;
      }

      let ok = false;
      try {
        ok = await VisitedPlaceService.getInstance().toggleHighlight(place.id, next.isHighlight);
      } catch (_err) {
        ok = false;
      }
      if (!ok) {
        this.places[targetIndex] = original;
        if (this.selectedPlace && this.getPlaceKey(this.selectedPlace) === this.getPlaceKey(original)) {
          this.selectedPlace = original;
          this.selectedPlaceIndex = targetIndex;
        }
        this.showActionMessage('精选状态更新失败');
        return;
      }

      this.showActionMessage(next.isHighlight ? '已标记为精选地点' : '已取消精选地点');
    } finally {
      this.isHighlightUpdating = false;
    }
  }

  private openPlaceDetails(place: VisitedPlace, index: number): void {
    this.selectedPlace = place;
    this.selectedPlaceIndex = index;
    this.showPlaceSheet = true;
  }

  private closePlaceDetails(): void {
    this.showPlaceSheet = false;
    this.selectedPlace = null;
    this.selectedPlaceIndex = -1;
  }

  private getTitle(): string {
    if (this.cityName.length > 0 && this.countryName.length > 0) {
      return `${this.cityName} · ${this.countryName}`;
    }
    if (this.cityName.length > 0) {
      return this.cityName;
    }
    return '访问地点';
  }

  private getCountText(): string {
    const loaded = this.places.length;
    const total = this.totalCount > 0 ? this.totalCount : loaded;
    return `${loaded}/${total}`;
  }

  private getWeatherText(): string {
    if (!this.citySummary || !this.citySummary.weather) {
      return '';
    }
    const w = this.citySummary.weather;
    const temp = Math.round(w.temperature);
    if (w.condition && w.condition.length > 0) {
      return `${temp}°C · ${w.condition}`;
    }
    return `${temp}°C`;
  }

  private formatDateOnly(raw?: string): string {
    if (!raw || raw.length === 0) return '';
    const d = new Date(raw);
    return d.toLocaleDateString('zh-CN', {
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
    });
  }

  private getDateRangeText(): string {
    if (!this.citySummary) {
      return '';
    }
    const start = this.formatDateOnly(this.citySummary.travelDate);
    const end = this.formatDateOnly(this.citySummary.lastVisitDate);
    if (start.length === 0 && end.length === 0) {
      return '';
    }
    if (start.length > 0 && end.length > 0) {
      return start === end ? start : `${start} - ${end}`;
    }
    if (start.length > 0) {
      return `${start} - 至今`;
    }
    return end;
  }

  private getHighlightCount(): number {
    let count = 0;
    for (let i = 0; i < this.places.length; i++) {
      if (this.places[i].isHighlight) {
        count += 1;
      }
    }
    return count;
  }

  private getFormattedTotalDuration(): string {
    let totalMinutes = 0;
    for (let i = 0; i < this.places.length; i++) {
      totalMinutes += this.places[i].durationMinutes ?? 0;
    }
    if (totalMinutes <= 0) {
      return '0 分钟';
    }
    const hours = Math.floor(totalMinutes / 60);
    const minutes = totalMinutes % 60;
    if (hours <= 0) {
      return `${minutes} 分钟`;
    }
    if (minutes === 0) {
      return `${hours} 小时`;
    }
    return `${hours} 小时 ${minutes} 分钟`;
  }

  private formatDate(raw: string): string {
    if (!raw) return '';
    const d = new Date(raw);
    return d.toLocaleString('zh-CN', {
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
    });
  }

  private formatDateTimeLong(raw?: string): string {
    if (!raw || raw.length === 0) {
      return '-';
    }
    const d = new Date(raw);
    return d.toLocaleString('zh-CN', {
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
    });
  }

  @Builder
  private DetailRow(label: string, value: string) {
    Row({ space: 8 }) {
      Text(label)
        .fontSize(12)
        .fontColor(AppColors.TEXT_TERTIARY)
        .width(64)
      Text(value)
        .fontSize(13)
        .fontColor(AppColors.TEXT_SECONDARY)
        .layoutWeight(1)
    }
    .width('100%')
  }

  @Builder
  private PlaceDetailSheet(place: VisitedPlace) {
    Column() {
      Row()
        .width(44)
        .height(4)
        .borderRadius(2)
        .backgroundColor(AppColors.BORDER)
        .margin({ top: 10, bottom: 14 })

      Column({ space: 10 }) {
        Row() {
          Text('地点详情')
            .fontSize(13)
            .fontColor(AppColors.TEXT_TERTIARY)
            .layoutWeight(1)

          Text('关闭')
            .fontSize(12)
            .fontColor(AppColors.TEXT_SECONDARY)
            .backgroundColor('#F1F5F9')
            .borderRadius(8)
            .padding({ left: 10, right: 10, top: 6, bottom: 6 })
            .onClick(() => {
              this.closePlaceDetails();
            })
        }

        Row({ space: 8 }) {
          Text(place.isHighlight ? '⭐' : this.getPlaceIconEmoji(place.iconType)).fontSize(16)
          Text(place.placeName && place.placeName.length > 0 ? place.placeName : '未命名地点')
            .fontSize(19)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.TEXT_PRIMARY)
            .layoutWeight(1)

          Text(this.isHighlightUpdating ? '处理中...' : (place.isHighlight ? '取消精选' : '设为精选'))
            .fontSize(12)
            .fontColor(this.isHighlightUpdating ? AppColors.TEXT_TERTIARY : (place.isHighlight ? AppColors.WARNING : AppColors.PRIMARY))
            .backgroundColor(this.isHighlightUpdating ? '#F3F4F6' : (place.isHighlight ? '#FEF3C7' : '#EEF2FF'))
            .borderRadius(8)
            .padding({ left: 10, right: 10, top: 6, bottom: 6 })
            .onClick(async () => {
              if (!this.isHighlightUpdating) {
                await this.toggleHighlight(place, this.selectedPlaceIndex);
              }
            })
        }

        if (this.formatPlaceType(place.placeType).length > 0) {
          Text(this.formatPlaceType(place.placeType))
            .fontSize(12)
            .fontColor(AppColors.PRIMARY)
        }

        Divider().color(AppColors.BORDER_LIGHT)

        this.DetailRow('停留时长', place.formattedDuration ?? '-')
        this.DetailRow('到达时间', this.formatDateTimeLong(place.arrivalTime))
        this.DetailRow('离开时间', this.formatDateTimeLong(place.departureTime))

        if (place.address && place.address.length > 0) {
          this.DetailRow('地址', place.address)
        }

        if (place.notes && place.notes.length > 0) {
          this.DetailRow('备注', place.notes)
        }

        Divider().color(AppColors.BORDER_LIGHT)

        Row({ space: 10 }) {
          Text('添加备注')
            .fontSize(12)
            .fontColor(AppColors.TEXT_SECONDARY)
            .backgroundColor('#F1F5F9')
            .borderRadius(8)
            .padding({ left: 12, right: 12, top: 7, bottom: 7 })
            .onClick(() => {
              this.showActionMessage('备注编辑即将上线');
              this.closePlaceDetails();
            })

          Text('地图查看')
            .fontSize(12)
            .fontColor(AppColors.PRIMARY)
            .backgroundColor('#EEF2FF')
            .borderRadius(8)
            .padding({ left: 12, right: 12, top: 7, bottom: 7 })
            .onClick(() => {
              this.showActionMessage('地图查看即将上线');
              this.closePlaceDetails();
            })
        }
        .margin({ top: 4, bottom: 10 })
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 12 })
    }
    .width('100%')
    .backgroundColor(AppColors.WHITE)
    .borderRadius({ topLeft: 20, topRight: 20 })
    .onClick(() => {
    })
  }

  private formatTime(raw: string): string {
    if (!raw) return '';
    const d = new Date(raw);
    return d.toLocaleTimeString('zh-CN', {
      hour: '2-digit',
      minute: '2-digit',
      hour12: false,
    });
  }

  private formatTimeRange(arrivalTime: string, departureTime?: string): string {
    if (!arrivalTime) {
      return '';
    }
    const startText = this.formatTime(arrivalTime);
    if (!departureTime || departureTime.length === 0) {
      return `${startText} - 至今`;
    }

    const start = new Date(arrivalTime);
    const end = new Date(departureTime);
    const sameDay = start.getFullYear() === end.getFullYear()
      && start.getMonth() === end.getMonth()
      && start.getDate() === end.getDate();
    const endText = this.formatTime(departureTime);

    if (sameDay) {
      return `${startText} - ${endText}`;
    }

    return `${this.formatDate(arrivalTime)} - ${this.formatDate(departureTime)}`;
  }

  private formatPlaceType(placeType?: string): string {
    if (!placeType || placeType.length === 0) {
      return '';
    }

    const normalized = placeType.toLowerCase();
    if (normalized === 'food') return '餐饮';
    if (normalized === 'hotel') return '住宿';
    if (normalized === 'nature') return '自然';
    if (normalized === 'shopping') return '购物';
    if (normalized === 'culture') return '文化';
    if (normalized === 'work') return '办公';
    if (normalized === 'entertainment') return '娱乐';

    const cleaned = placeType.replace(/_/g, ' ').trim();
    if (cleaned.length === 0) {
      return '';
    }
    return cleaned[0].toUpperCase() + cleaned.slice(1);
  }

  private getPlaceIconEmoji(iconType?: string): string {
    if (!iconType || iconType.length === 0) {
      return '📍';
    }
    const normalized = iconType.toLowerCase();
    if (normalized === 'food') return '🍜';
    if (normalized === 'hotel') return '🛏️';
    if (normalized === 'nature') return '🌳';
    if (normalized === 'shopping') return '🛍️';
    if (normalized === 'culture') return '🏛️';
    if (normalized === 'work') return '💼';
    if (normalized === 'entertainment') return '🎵';
    return '📍';
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
      Row() {
        SymbolGlyph($r('sys.symbol.arrow_left'))
          .fontSize(24)
          .fontColor([AppColors.TEXT_PRIMARY])
          .onClick(() => {
            router.back();
          })
        Text(this.getTitle())
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT_PRIMARY)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        Text(this.getCountText())
          .fontSize(12)
          .fontColor(AppColors.PRIMARY)
          .backgroundColor('#EEF2FF')
          .borderRadius(10)
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
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
            Column({ space: 10 }) {
              if (this.actionMessage.length > 0 && !this.showPlaceSheet) {
                Text(this.actionMessage)
                  .width('100%')
                  .fontSize(13)
                  .fontColor(AppColors.SUCCESS)
                  .backgroundColor('#ECFDF5')
                  .borderRadius(8)
                  .padding({ left: 12, right: 12, top: 8, bottom: 8 })
                  .margin({ left: 16, right: 16, top: 8 })
              }

              if (this.errorMessage.length > 0 && !this.isRefreshing && !this.showPlaceSheet) {
                Row({ space: 8 }) {
                  Text(this.errorMessage)
                    .fontSize(13)
                    .fontColor(AppColors.ERROR)
                    .layoutWeight(1)
                  Text('重试')
                    .fontSize(13)
                    .fontColor(AppColors.PRIMARY)
                    .onClick(async () => {
                      await this.loadData();
                    })
                }
                .width('100%')
                .backgroundColor('#FEF2F2')
                .borderRadius(8)
                .padding({ left: 12, right: 12, top: 8, bottom: 8 })
                .margin({ left: 16, right: 16, top: 8 })
              }

              if (this.citySummary) {
                Column({ space: 8 }) {
                  Text(`${this.citySummary!.cityName}${this.citySummary!.country ? ' · ' + this.citySummary!.country : ''}`)
                    .fontSize(18)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(AppColors.TEXT_PRIMARY)

                  Row({ space: 8 }) {
                    if (this.getWeatherText().length > 0) {
                      Text(this.getWeatherText())
                        .fontSize(12)
                        .fontColor(AppColors.TEXT_SECONDARY)
                    }
                    if (this.citySummary!.overallScore !== undefined) {
                      Text(`评分 ${this.citySummary!.overallScore!.toFixed(1)}`)
                        .fontSize(12)
                        .fontColor(AppColors.TEXT_SECONDARY)
                    }
                    if (this.citySummary!.averageMonthlyCost !== undefined) {
                      Text(`$${Math.round(this.citySummary!.averageMonthlyCost!)} / 月`)
                        .fontSize(12)
                        .fontColor(AppColors.TEXT_SECONDARY)
                    }
                  }

                  Row({ space: 8 }) {
                    Text(`停留 ${this.citySummary!.totalDurationDays} 天`)
                      .fontSize(12)
                      .fontColor(AppColors.PRIMARY)
                    Text(`访问地点 ${this.getCountText()}`)
                      .fontSize(12)
                      .fontColor(AppColors.PRIMARY)
                  }

                  if (this.getDateRangeText().length > 0) {
                    Text(this.getDateRangeText())
                      .fontSize(12)
                      .fontColor(AppColors.TEXT_TERTIARY)
                  }
                }
                .width('100%')
                .padding({ left: 14, right: 14, top: 12, bottom: 12 })
                .backgroundColor(AppColors.WHITE)
                .borderRadius(12)
                .border({ width: 1, color: AppColors.BORDER_LIGHT })
                .margin({ left: 16, right: 16, top: 4 })
              }

              if (this.places.length === 0 && this.errorMessage.length === 0) {
                Column({ space: 10 }) {
                  Text('📍').fontSize(44)
                  Text('暂无访问地点')
                    .fontSize(16)
                    .fontColor(AppColors.TEXT_SECONDARY)
                  Text('该行程还没有停留地点记录')
                    .fontSize(13)
                    .fontColor(AppColors.TEXT_TERTIARY)
                }
                .width('100%')
                .padding({ top: 60, bottom: 40 })
                .alignItems(HorizontalAlign.Center)
              } else {
                Column() {
                  ForEach(this.places, (place: VisitedPlace, index?: number) => {
                    Column({ space: 8 }) {
                      Row({ space: 8 }) {
                        Text(place.isHighlight ? '⭐' : this.getPlaceIconEmoji(place.iconType)).fontSize(14)
                        Text(place.placeName && place.placeName!.length > 0 ? place.placeName! : '未命名地点')
                          .fontSize(16)
                          .fontWeight(FontWeight.Medium)
                          .fontColor(AppColors.TEXT_PRIMARY)
                          .layoutWeight(1)
                        Text(this.isHighlightUpdating ? '处理中...' : (place.isHighlight ? '取消精选' : '设为精选'))
                          .fontSize(12)
                          .fontColor(this.isHighlightUpdating ? AppColors.TEXT_TERTIARY : (place.isHighlight ? AppColors.WARNING : AppColors.PRIMARY))
                          .backgroundColor(this.isHighlightUpdating ? '#F3F4F6' : (place.isHighlight ? '#FEF3C7' : '#EEF2FF'))
                          .borderRadius(8)
                          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                          .onClick(() => {
                            if (!this.isHighlightUpdating) {
                              this.toggleHighlight(place, index ?? -1);
                            }
                          })

                        Text('详情')
                          .fontSize(12)
                          .fontColor(AppColors.TEXT_SECONDARY)
                          .backgroundColor('#F1F5F9')
                          .borderRadius(8)
                          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                          .onClick(() => {
                            this.openPlaceDetails(place, index ?? 0);
                          })
                      }

                      if (place.address && place.address!.length > 0) {
                        Text(place.address!)
                          .fontSize(13)
                          .fontColor(AppColors.TEXT_SECONDARY)
                      }

                      Row({ space: 8 }) {
                        Text(this.formatTimeRange(place.arrivalTime, place.departureTime))
                          .fontSize(12)
                          .fontColor(AppColors.TEXT_TERTIARY)
                        if (place.formattedDuration && place.formattedDuration!.length > 0) {
                          Text(`· ${place.formattedDuration!}`)
                            .fontSize(12)
                            .fontColor(AppColors.TEXT_TERTIARY)
                        }
                        if (this.formatPlaceType(place.placeType).length > 0) {
                          Text(`· ${this.formatPlaceType(place.placeType)}`)
                            .fontSize(12)
                            .fontColor(AppColors.PRIMARY)
                        }
                      }

                    }
                    .width('100%')
                    .padding({ left: 14, right: 14, top: 12, bottom: 12 })
                    .backgroundColor(AppColors.WHITE)
                    .borderRadius(12)
                    .border({ width: 1, color: AppColors.BORDER_LIGHT })
                    .margin({ left: 16, right: 16, bottom: 8 })
                    .onClick(() => {
                      this.openPlaceDetails(place, index ?? 0);
                    })
                  }, (place: VisitedPlace, index?: number) => `${this.getPlaceKey(place)}-${index ?? 0}`)
                }

                Row({ space: 8 }) {
                  Text(`总停留 ${this.getFormattedTotalDuration()}`)
                    .fontSize(12)
                    .fontColor(AppColors.TEXT_SECONDARY)
                  Text(`精选 ${this.getHighlightCount()} 个`)
                    .fontSize(12)
                    .fontColor(AppColors.TEXT_SECONDARY)
                }
                .margin({ left: 16, right: 16, top: 2, bottom: 6 })

                if (this.loadMoreError.length > 0 && !this.isLoadingMore) {
                  Row({ space: 8 }) {
                    Text(this.loadMoreError)
                      .fontSize(12)
                      .fontColor(AppColors.ERROR)
                      .layoutWeight(1)
                    Text('重试')
                      .fontSize(12)
                      .fontColor(AppColors.PRIMARY)
                      .onClick(async () => {
                        await this.loadMore();
                      })
                  }
                  .margin({ left: 16, right: 16, top: 2, bottom: 2 })
                }

                if (this.hasMore) {
                  Text(this.isLoadingMore ? '加载中...' : '加载更多')
                    .fontSize(13)
                    .fontColor(this.isLoadingMore ? AppColors.TEXT_TERTIARY : AppColors.PRIMARY)
                    .backgroundColor(this.isLoadingMore ? '#F3F4F6' : '#EEF2FF')
                    .borderRadius(10)
                    .padding({ left: 14, right: 14, top: 8, bottom: 8 })
                    .margin({ top: 6, bottom: 14 })
                    .onClick(() => {
                      if (!this.isLoadingMore) {
                        this.loadMore();
                      }
                    })
                } else if (this.cityId.length > 0 && this.places.length > 0) {
                  Text('已全部加载')
                    .fontSize(12)
                    .fontColor(AppColors.TEXT_TERTIARY)
                    .margin({ top: 6, bottom: 12 })
                }
              }
            }
          }
          .width('100%')
          .height('100%')
        }
        .layoutWeight(1)
        .onRefreshing(() => {
          this.actionMessage = '';
          this.showPlaceSheet = false;
          this.isRefreshing = true;
          this.loadData();
        })
      }

      }
      .width('100%')
      .height('100%')
      .backgroundColor(AppColors.BACKGROUND)

      if (this.showPlaceSheet && this.selectedPlace) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('#55000000')
          .onClick(() => {
            this.closePlaceDetails();
          })

        Column() {
          this.PlaceDetailSheet(this.selectedPlace!)
        }
        .width('100%')
      }
    }
  }
}
