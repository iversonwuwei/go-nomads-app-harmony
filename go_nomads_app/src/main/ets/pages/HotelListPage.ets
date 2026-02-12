import { AppColors } from '../common/constants/AppColors';
import { RouteConstants } from '../common/constants/RouteConstants';
import { HttpService } from '../services/HttpService';
import { ApiConfig } from '../common/constants/ApiConfig';
import { Hotel, HotelHelper } from '../models/Hotel';
import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'HotelListPage';
const DOMAIN = 0x0001;

/**
 * 酒店列表页 — 对应 Flutter hotel_list_page.dart
 */
@Entry
@Component
struct HotelListPage {
  @State hotels: Hotel[] = [];
  @State filtered: Hotel[] = [];
  @State isLoading: boolean = true;
  @State searchText: string = '';
  @State sortBy: string = '推荐'; // 推荐 | 价格 | 评分

  private cityId: string = '';
  private cityName: string = '';

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>;
    if (params?.['cityId']) { this.cityId = params['cityId']; }
    if (params?.['cityName']) { this.cityName = params['cityName']; }
    this.loadHotels();
  }

  async loadHotels(): Promise<void> {
    this.isLoading = true;
    try {
      const httpService = HttpService.getInstance();
      const endpoint = this.cityId
        ? `${ApiConfig.CITIES_ENDPOINT}/${this.cityId}/hotels`
        : `${ApiConfig.CITIES_ENDPOINT}/hotels`;
      this.hotels = await httpService.get<Hotel[]>(endpoint);
      this.applyFilter();
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ %{public}s', JSON.stringify(err));
    } finally { this.isLoading = false; }
  }

  applyFilter(): void {
    let list = this.hotels;
    if (this.searchText.trim()) {
      const q = this.searchText.toLowerCase();
      list = list.filter(h => h.name.toLowerCase().includes(q) || h.address.toLowerCase().includes(q));
    }
    if (this.sortBy === '价格') {
      list = [...list].sort((a, b) => a.pricePerNight - b.pricePerNight);
    } else if (this.sortBy === '评分') {
      list = [...list].sort((a, b) => b.rating - a.rating);
    } else {
      // 推荐 = nomadScore 降序
      list = [...list].sort((a, b) => (b.nomadScore ?? 0) - (a.nomadScore ?? 0));
    }
    this.filtered = list;
  }

  build() {
    Column() {
      Row() {
        SymbolGlyph($r('sys.symbol.arrow_left'))
          .fontSize(24).fontColor([AppColors.TEXT_PRIMARY]).onClick(() => { router.back(); })
        Text(this.cityName ? `${this.cityName} 酒店` : '酒店')
          .fontSize(18).fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT_PRIMARY).layoutWeight(1).textAlign(TextAlign.Center)
        Column().width(24)
      }
      .width('100%').height(56).padding({ left: 16, right: 16 })
      .backgroundColor(AppColors.CARD_BACKGROUND)

      // 搜索 + 排序
      Row({ space: 8 }) {
        TextInput({ placeholder: '搜索酒店...', text: this.searchText })
          .layoutWeight(1).height(38).borderRadius(19).backgroundColor('#F1F5F9')
          .padding({ left: 14, right: 14 })
          .onChange((v: string) => { this.searchText = v; this.applyFilter(); })
        ForEach(['推荐', '价格', '评分'], (opt: string) => {
          Text(opt).fontSize(12)
            .fontColor(this.sortBy === opt ? '#FFFFFF' : AppColors.TEXT_SECONDARY)
            .backgroundColor(this.sortBy === opt ? AppColors.PRIMARY : '#F1F5F9')
            .borderRadius(12).padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .onClick(() => { this.sortBy = opt; this.applyFilter(); })
        }, (o: string) => o)
      }
      .width('100%').padding({ left: 16, right: 16, top: 10, bottom: 10 })

      if (this.isLoading) {
        Column() { LoadingProgress().width(40).height(40) }
          .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else if (this.filtered.length === 0) {
        Column({ space: 12 }) {
          Text('🏨').fontSize(48)
          Text('暂无酒店').fontSize(16).fontColor(AppColors.TEXT_SECONDARY)
        }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        List() {
          ForEach(this.filtered, (h: Hotel) => {
            ListItem() { this.HotelCard(h) }
          }, (h: Hotel) => h.id)
        }
        .layoutWeight(1).padding({ left: 16, right: 16, top: 4 })
        .divider({ strokeWidth: 0 }).edgeEffect(EdgeEffect.Spring)
      }
    }
    .width('100%').height('100%').backgroundColor(AppColors.BACKGROUND)
  }

  @Builder
  HotelCard(h: Hotel) {
    Column() {
      // 图片
      Stack() {
        Image(HotelHelper.imageUrl(h) || $r('app.media.startIcon'))
          .width('100%').height(140).objectFit(ImageFit.Cover)
          .borderRadius({ topLeft: 10, topRight: 10 })
        if (h.isFeatured) {
          Text('精选').fontSize(11).fontColor('#FFFFFF')
            .backgroundColor(AppColors.WARNING)
            .borderRadius(4).padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .position({ x: 8, y: 8 })
        }
        if (h.nomadScore) {
          Text(`🏆 ${h.nomadScore}`).fontSize(11)
            .fontColor('#FFFFFF').backgroundColor('#00000060')
            .borderRadius(4).padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .position({ x: 8, y: 115 })
        }
      }.width('100%')

      Column({ space: 4 }) {
        Row() {
          Text(h.name).fontSize(16).fontWeight(FontWeight.Medium)
            .fontColor(AppColors.TEXT_PRIMARY).layoutWeight(1)
            .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(HotelHelper.priceLabel(h))
            .fontSize(14).fontWeight(FontWeight.Bold).fontColor(AppColors.PRIMARY)
        }
        Row({ space: 8 }) {
          Text(`⭐ ${h.rating.toFixed(1)} (${h.reviewCount})`).fontSize(12).fontColor(AppColors.TEXT_SECONDARY)
          if (h.starRating) {
            Text(HotelHelper.starText(h)).fontSize(12).fontColor(AppColors.WARNING)
          }
        }
        // 游民特性
        Row({ space: 4 }) {
          ForEach(HotelHelper.nomadFeatures(h).slice(0, 5), (f: string) => {
            Text(f).fontSize(10).fontColor(AppColors.TEXT_TERTIARY)
              .backgroundColor('#F1F5F9').borderRadius(4)
              .padding({ left: 4, right: 4, top: 1, bottom: 1 })
          }, (f: string) => f)
        }
      }
      .width('100%').padding({ left: 10, right: 10, top: 8, bottom: 10 }).alignItems(HorizontalAlign.Start)
    }
    .width('100%').backgroundColor(AppColors.CARD_BACKGROUND).borderRadius(10)
    .shadow({ radius: 3, color: '#0000000A', offsetX: 0, offsetY: 1 }).margin({ bottom: 10 })
    .onClick(() => {
      router.pushUrl({ url: `pages/${RouteConstants.HOTEL_DETAIL}`, params: { hotelId: h.id } });
    })
  }
}
