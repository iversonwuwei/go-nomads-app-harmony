import { City, CityHelper } from '../../models/City';
import { CityService } from '../../services/CityService';
import { AppColors } from '../../common/constants/AppColors';
import { RouteConstants } from '../../common/constants/RouteConstants';
import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'CityListTab';
const DOMAIN = 0x0001;

/**
 * 城市列表 Tab - 对应 Flutter 端 CityListPage
 */
@Component
export struct CityListTab {
  @State cities: City[] = [];
  @State filteredCities: City[] = [];
  @State isLoading: boolean = true;
  @State hasError: boolean = false;
  @State errorMsg: string = '';
  @State searchQuery: string = '';
  @State selectedRegion: string = '全部';
  @State isGridView: boolean = true;
  @State isRefreshing: boolean = false;
  @State currentPage: number = 1;
  @State hasMore: boolean = true;

  private regions: string[] = ['全部', 'Asia', 'Europe', 'Americas', 'Africa', 'Oceania'];
  private pageSize: number = 30;

  aboutToAppear(): void {
    this.loadCities();
  }

  async loadCities(): Promise<void> {
    this.isLoading = true;
    this.hasError = false;
    try {
      const cityService = CityService.getInstance();
      const cities = await cityService.getCities(1, this.pageSize);
      this.cities = cities;
      this.currentPage = 1;
      this.hasMore = cities.length >= this.pageSize;
      this.applyFilter();
      hilog.info(DOMAIN, TAG, '✅ 加载 %{public}d 个城市', cities.length);
    } catch (err) {
      this.hasError = true;
      this.errorMsg = (err instanceof Error) ? err.message : '加载失败';
      hilog.error(DOMAIN, TAG, '❌ 加载城市失败: %{public}s', this.errorMsg);
    } finally {
      this.isLoading = false;
      this.isRefreshing = false;
    }
  }

  async loadMore(): Promise<void> {
    if (!this.hasMore || this.isLoading) {
      return;
    }
    try {
      const nextPage = this.currentPage + 1;
      const cityService = CityService.getInstance();
      const moreCities = await cityService.getCities(nextPage, this.pageSize);
      if (moreCities.length > 0) {
        this.cities = this.cities.concat(moreCities);
        this.currentPage = nextPage;
        this.hasMore = moreCities.length >= this.pageSize;
        this.applyFilter();
      } else {
        this.hasMore = false;
      }
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ 加载更多失败: %{public}s', (err as Error).message);
    }
  }

  applyFilter(): void {
    let result = this.cities;

    // 地区筛选
    if (this.selectedRegion !== '全部') {
      result = result.filter(c => c.region === this.selectedRegion);
    }

    // 搜索筛选
    if (this.searchQuery) {
      const query = this.searchQuery.toLowerCase();
      result = result.filter(c =>
        c.name.toLowerCase().includes(query) ||
        (c.nameEn && c.nameEn.toLowerCase().includes(query)) ||
        (c.country && c.country.toLowerCase().includes(query))
      );
    }

    this.filteredCities = result;
  }

  build() {
    Column() {
      // 顶部搜索
      this.SearchHeader()

      // 地区筛选
      this.RegionFilter()

      // 城市列表
      if (this.isLoading && !this.isRefreshing) {
        Column() {
          LoadingProgress().width(40).height(40)
          Text('加载中...').fontSize(14).fontColor(AppColors.TEXT_TERTIARY).margin({ top: 12 })
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
              this.loadCities();
            })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.filteredCities.length === 0) {
        Column() {
          Text('🏙️').fontSize(48)
          Text('未找到匹配的城市').fontSize(16).fontColor(AppColors.TEXT_SECONDARY).margin({ top: 12 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        Refresh({ refreshing: $$this.isRefreshing }) {
          this.CityGrid()
        }
        .layoutWeight(1)
        .onRefreshing(() => {
          this.loadCities();
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BACKGROUND)
  }

  @Builder
  SearchHeader() {
    Row() {
      Text('探索城市')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.TEXT_PRIMARY)

      Blank()

      // 视图切换
      SymbolGlyph(this.isGridView ? $r('sys.symbol.list_bullet') : $r('sys.symbol.square_grid_2x2'))
        .fontSize(22)
        .fontColor([AppColors.TEXT_SECONDARY])
        .onClick(() => {
          this.isGridView = !this.isGridView;
        })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 8 })

    // 搜索框
    Row() {
      SymbolGlyph($r('sys.symbol.magnifyingglass'))
        .fontSize(18)
        .fontColor([AppColors.TEXT_TERTIARY])

      TextInput({ placeholder: '搜索城市或国家', text: this.searchQuery })
        .layoutWeight(1)
        .backgroundColor('transparent')
        .height(36)
        .onChange((value: string) => {
          this.searchQuery = value;
          this.applyFilter();
        })
    }
    .width('100%')
    .height(44)
    .borderRadius(22)
    .backgroundColor('#F1F5F9')
    .padding({ left: 14, right: 14 })
    .margin({ left: 16, right: 16, bottom: 8 })
  }

  @Builder
  RegionFilter() {
    Scroll() {
      Row({ space: 8 }) {
        ForEach(this.regions, (region: string) => {
          Text(region)
            .fontSize(13)
            .fontColor(this.selectedRegion === region ? '#FFFFFF' : AppColors.TEXT_SECONDARY)
            .backgroundColor(this.selectedRegion === region ? AppColors.PRIMARY : '#F1F5F9')
            .borderRadius(16)
            .padding({ left: 14, right: 14, top: 6, bottom: 6 })
            .onClick(() => {
              this.selectedRegion = region;
              this.applyFilter();
            })
        }, (region: string) => region)
      }
      .padding({ left: 16, right: 16 })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
    .margin({ bottom: 12 })
  }

  @Builder
  CityGrid() {
    Scroll() {
      Column() {
        if (this.isGridView) {
          // 网格视图
          Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
            ForEach(this.filteredCities, (city: City) => {
              this.CityGridItem(city)
            }, (city: City) => city.id)
          }
          .width('100%')
          .padding({ left: 16, right: 16 })
        } else {
          // 列表视图
          Column({ space: 8 }) {
            ForEach(this.filteredCities, (city: City) => {
              this.CityListItem(city)
            }, (city: City) => city.id)
          }
          .width('100%')
          .padding({ left: 16, right: 16 })
        }

        Column().height(80)
      }
    }
    .layoutWeight(1)
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
  }

  @Builder
  CityGridItem(city: City) {
    Column() {
      Stack() {
        Image(CityHelper.landscapeImageUrl(city) || $r('app.media.startIcon'))
          .width('100%')
          .height(110)
          .objectFit(ImageFit.Cover)
          .borderRadius({ topLeft: 10, topRight: 10 })

        if (city.overallScore && city.overallScore > 0) {
          Text(`⭐ ${city.overallScore.toFixed(1)}`)
            .fontSize(11)
            .fontColor('#FFFFFF')
            .backgroundColor('#00000066')
            .borderRadius(8)
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .position({ x: 8, y: 8 })
        }
      }

      Column({ space: 3 }) {
        Text(CityHelper.displayName(city))
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(city.country ?? '')
          .fontSize(12)
          .fontColor(AppColors.TEXT_SECONDARY)

        Row({ space: 6 }) {
          if (city.temperature !== undefined) {
            Text(`${city.temperature}°C`)
              .fontSize(11)
              .fontColor(AppColors.TEXT_TERTIARY)
          }
          if (city.internetScore !== undefined) {
            Text(`📶 ${city.internetScore.toFixed(1)}`)
              .fontSize(11)
              .fontColor(AppColors.TEXT_TERTIARY)
          }
        }
      }
      .width('100%')
      .padding({ left: 8, right: 8, top: 6, bottom: 8 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('48%')
    .backgroundColor(AppColors.CARD_BACKGROUND)
    .borderRadius(10)
    .shadow({ radius: 4, color: '#0000000A', offsetX: 0, offsetY: 2 })
    .margin({ bottom: 10 })
    .onClick(() => {
      router.pushUrl({
        url: `pages/${RouteConstants.CITY_DETAIL}`,
        params: { cityId: city.id, cityName: city.name },
      });
    })
  }

  @Builder
  CityListItem(city: City) {
    Row() {
      Image(CityHelper.landscapeImageUrl(city) || $r('app.media.startIcon'))
        .width(80)
        .height(60)
        .objectFit(ImageFit.Cover)
        .borderRadius(8)

      Column({ space: 4 }) {
        Text(CityHelper.displayName(city))
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT_PRIMARY)

        Text(CityHelper.fullLocation(city))
          .fontSize(13)
          .fontColor(AppColors.TEXT_SECONDARY)

        Row({ space: 8 }) {
          if (city.overallScore && city.overallScore > 0) {
            Text(`⭐ ${city.overallScore.toFixed(1)}`)
              .fontSize(12)
              .fontColor(AppColors.TEXT_TERTIARY)
          }
          if (city.temperature !== undefined) {
            Text(`🌡️ ${city.temperature}°C`)
              .fontSize(12)
              .fontColor(AppColors.TEXT_TERTIARY)
          }
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .padding({ left: 12 })
    }
    .width('100%')
    .padding(10)
    .backgroundColor(AppColors.CARD_BACKGROUND)
    .borderRadius(10)
    .shadow({ radius: 3, color: '#0000000A', offsetX: 0, offsetY: 1 })
    .onClick(() => {
      router.pushUrl({
        url: `pages/${RouteConstants.CITY_DETAIL}`,
        params: { cityId: city.id, cityName: city.name },
      });
    })
  }
}
