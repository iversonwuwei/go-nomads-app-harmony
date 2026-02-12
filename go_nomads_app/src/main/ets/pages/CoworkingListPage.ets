import { AppColors } from '../common/constants/AppColors';
import { RouteConstants } from '../common/constants/RouteConstants';
import { HttpService } from '../services/HttpService';
import { ApiConfig } from '../common/constants/ApiConfig';
import { CoworkingSpace, CoworkingHelper } from '../models/CoworkingSpace';
import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'CoworkingListPage';
const DOMAIN = 0x0001;

/**
 * 共享办公列表页 — 对应 Flutter coworking_list_page.dart
 */
@Entry
@Component
struct CoworkingListPage {
  @State spaces: CoworkingSpace[] = [];
  @State filtered: CoworkingSpace[] = [];
  @State isLoading: boolean = true;
  @State searchText: string = '';
  @State sortBy: string = '评分'; // 评分 | 价格 | 距离

  private cityId: string = '';
  private cityName: string = '';

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>;
    if (params?.['cityId']) { this.cityId = params['cityId']; }
    if (params?.['cityName']) { this.cityName = params['cityName']; }
    this.loadSpaces();
  }

  async loadSpaces(): Promise<void> {
    this.isLoading = true;
    try {
      const httpService = HttpService.getInstance();
      const endpoint = this.cityId
        ? `${ApiConfig.COWORKING_SPACES_ENDPOINT}?cityId=${this.cityId}`
        : ApiConfig.COWORKING_SPACES_ENDPOINT;
      this.spaces = await httpService.get<CoworkingSpace[]>(endpoint);
      this.applyFilter();
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ %{public}s', JSON.stringify(err));
    } finally { this.isLoading = false; }
  }

  applyFilter(): void {
    let list = this.spaces;
    if (this.searchText.trim()) {
      const q = this.searchText.toLowerCase();
      list = list.filter(s => s.name.toLowerCase().includes(q) || (s.address ?? '').toLowerCase().includes(q));
    }
    if (this.sortBy === '评分') {
      list = [...list].sort((a, b) => b.rating - a.rating);
    } else if (this.sortBy === '价格') {
      list = [...list].sort((a, b) => CoworkingHelper.lowestPrice(a) - CoworkingHelper.lowestPrice(b));
    }
    this.filtered = list;
  }

  build() {
    Column() {
      // Header
      Row() {
        SymbolGlyph($r('sys.symbol.arrow_left'))
          .fontSize(24).fontColor([AppColors.TEXT_PRIMARY]).onClick(() => { router.back(); })
        Text(this.cityName ? `${this.cityName} 共享办公` : '共享办公')
          .fontSize(18).fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT_PRIMARY).layoutWeight(1).textAlign(TextAlign.Center)
        Column().width(24)
      }
      .width('100%').height(56).padding({ left: 16, right: 16 })
      .backgroundColor(AppColors.CARD_BACKGROUND)

      // 搜索 + 排序
      Row({ space: 8 }) {
        TextInput({ placeholder: '搜索办公空间...', text: this.searchText })
          .layoutWeight(1).height(38).borderRadius(19).backgroundColor('#F1F5F9')
          .padding({ left: 14, right: 14 })
          .onChange((v: string) => { this.searchText = v; this.applyFilter(); })

        ForEach(['评分', '价格'], (opt: string) => {
          Text(opt).fontSize(13)
            .fontColor(this.sortBy === opt ? '#FFFFFF' : AppColors.TEXT_SECONDARY)
            .backgroundColor(this.sortBy === opt ? AppColors.PRIMARY : '#F1F5F9')
            .borderRadius(14).padding({ left: 10, right: 10, top: 5, bottom: 5 })
            .onClick(() => { this.sortBy = opt; this.applyFilter(); })
        }, (opt: string) => opt)
      }
      .width('100%').padding({ left: 16, right: 16, top: 10, bottom: 10 })

      // 列表
      if (this.isLoading) {
        Column() { LoadingProgress().width(40).height(40) }
          .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else if (this.filtered.length === 0) {
        Column({ space: 12 }) {
          Text('🏢').fontSize(48)
          Text('暂无共享办公空间').fontSize(16).fontColor(AppColors.TEXT_SECONDARY)
        }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        List() {
          ForEach(this.filtered, (space: CoworkingSpace) => {
            ListItem() { this.SpaceCard(space) }
          }, (s: CoworkingSpace) => s.id)
        }
        .layoutWeight(1).padding({ left: 16, right: 16, top: 4 })
        .divider({ strokeWidth: 0 }).edgeEffect(EdgeEffect.Spring)
      }
    }
    .width('100%').height('100%').backgroundColor(AppColors.BACKGROUND)
  }

  @Builder
  SpaceCard(space: CoworkingSpace) {
    Row() {
      // 图片
      Image(space.imageUrl || $r('app.media.startIcon'))
        .width(90).height(72).objectFit(ImageFit.Cover).borderRadius(8)

      Column({ space: 4 }) {
        Row({ space: 6 }) {
          Text(space.name).fontSize(15).fontWeight(FontWeight.Medium)
            .fontColor(AppColors.TEXT_PRIMARY).layoutWeight(1)
            .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
          if (space.isVerified) {
            Text('✓').fontSize(11).fontColor('#FFFFFF')
              .backgroundColor(AppColors.SUCCESS).borderRadius(4)
              .padding({ left: 4, right: 4, top: 1, bottom: 1 })
          }
        }
        if (space.address) {
          Text(`📍 ${space.address}`).fontSize(12).fontColor(AppColors.TEXT_TERTIARY)
            .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        Row({ space: 12 }) {
          Text(`⭐ ${space.rating.toFixed(1)} (${space.reviewCount})`).fontSize(12).fontColor(AppColors.TEXT_SECONDARY)
          Text(CoworkingHelper.priceLabel(space)).fontSize(12).fontColor(AppColors.PRIMARY).fontWeight(FontWeight.Medium)
        }
        // 设施标签
        Row({ space: 4 }) {
          ForEach(CoworkingHelper.amenitiesList(space).slice(0, 4), (a: string) => {
            Text(a).fontSize(10).fontColor(AppColors.TEXT_TERTIARY)
              .backgroundColor('#F1F5F9').borderRadius(4)
              .padding({ left: 5, right: 5, top: 2, bottom: 2 })
          }, (a: string) => a)
        }
      }
      .layoutWeight(1).alignItems(HorizontalAlign.Start).padding({ left: 10 })
    }
    .width('100%').padding(10)
    .backgroundColor(AppColors.CARD_BACKGROUND).borderRadius(10)
    .shadow({ radius: 3, color: '#0000000A', offsetX: 0, offsetY: 1 })
    .margin({ bottom: 8 })
    .onClick(() => {
      router.pushUrl({
        url: `pages/${RouteConstants.COWORKING_DETAIL}`,
        params: { spaceId: space.id },
      });
    })
  }
}
