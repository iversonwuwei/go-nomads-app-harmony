import { City, CityHelper } from '../../models/City';
import { CityService } from '../../services/CityService';
import { AppColors } from '../../common/constants/AppColors';
import { RouteConstants } from '../../common/constants/RouteConstants';
import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'CityListTab';
const DOMAIN = 0x0001;

/**
 * 城市列表页 - 100% 还原 Flutter CityListPage
 *
 * Flutter 设计:
 *   AppBar: white bg, "探索城市" 20px bold, back button, map icon
 *   CityFilterBar: white bg
 *     搜索框: #FAFAFA bg, radius 8, magnifyingglass 16px, hint 14px
 *     区域 tab: selected #2B7A78 bg white text, unselected transparent + borderLight
 *   CityCard: ClipRRect radius 12, shadow black 8% blur 8
 *     全幅图片 + 渐变遮罩 (black 10%→transparent→black 60%)
 *     右上评分: black 55% radius 8, star #FFD700, score 12px bold white
 *     左下城市名: 16px bold white + country 12px white 80%
 *   2 列网格: crossSpacing 10, mainSpacing 10
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
  @State isRefreshing: boolean = false;
  @State currentPage: number = 1;
  @State hasMore: boolean = true;
  @State isLoadingMore: boolean = false;

  private regions: string[] = ['全部', 'Asia', 'Europe', 'Americas', 'Africa', 'Oceania'];
  private pageSize: number = 30;

  aboutToAppear(): void {
    this.loadCities();
  }

  async loadCities(): Promise<void> {
    this.isLoading = true;
    this.hasError = false;
    this.isLoadingMore = false;
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
    if (!this.hasMore || this.isLoading || this.isLoadingMore) {
      return;
    }
    this.isLoadingMore = true;
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
    } finally {
      this.isLoadingMore = false;
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
      // ===== Flutter AppBar: white bg, "探索城市" 20px bold =====
      Row() {
        SymbolGlyph($r('sys.symbol.chevron_left'))
          .fontSize(24)
          .fontColor([AppColors.TEXT_PRIMARY])
          .onClick(() => { router.back(); })
          .width(40)

        Text('探索城市')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        // Map icon
        SymbolGlyph($r('sys.symbol.map'))
          .fontSize(20)
          .fontColor([AppColors.TEXT_PRIMARY])
          .onClick(() => {
            router.pushUrl({ url: `pages/${RouteConstants.GLOBAL_MAP}` });
          })
          .width(40)
      }
      .width('100%')
      .height(56)
      .padding({ left: 8, right: 8 })
      .backgroundColor(AppColors.WHITE)
      .alignItems(VerticalAlign.Center)

      // ===== Flutter CityFilterBar: search + region tabs =====
      Column() {
        // 搜索框: #FAFAFA bg, radius 8
        Row() {
          SymbolGlyph($r('sys.symbol.magnifyingglass'))
            .fontSize(16)
            .fontColor([AppColors.TEXT_SECONDARY])

          TextInput({ placeholder: '搜索城市或国家', text: this.searchQuery })
            .layoutWeight(1)
            .backgroundColor('transparent')
            .height(36)
            .fontSize(14)
            .placeholderColor(AppColors.TEXT_TERTIARY)
            .onChange((value: string) => {
              this.searchQuery = value;
              this.applyFilter();
            })
        }
        .width('100%')
        .height(40)
        .borderRadius(8)
        .backgroundColor(AppColors.BACKGROUND) // #FAFAFA
        .padding({ left: 12, right: 12 })
        .margin({ left: 16, right: 16, top: 12, bottom: 8 })

        // 区域 Tab 栏: pills with #2B7A78 selected
        Scroll() {
          Row({ space: 8 }) {
            ForEach(this.regions, (region: string) => {
              Text(region)
                .fontSize(13)
                .fontWeight(this.selectedRegion === region ? FontWeight.Bold : FontWeight.Normal)
                .fontColor(this.selectedRegion === region ? AppColors.WHITE : AppColors.TEXT_SECONDARY)
                .backgroundColor(this.selectedRegion === region ? '#2B7A78' : 'transparent')
                .borderRadius(20)
                .border({
                  width: 1,
                  color: this.selectedRegion === region ? '#2B7A78' : AppColors.BORDER_LIGHT
                })
                .padding({ left: 16, right: 16, top: 6, bottom: 6 })
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
        .height(40)
      }
      .width('100%')
      .backgroundColor(AppColors.WHITE)
      .border({ width: { bottom: 1 }, color: { bottom: AppColors.BORDER_LIGHT } })

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
      } else if (this.filteredCities.length === 0) {
        this.EmptyView()
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
  EmptyView() {
    Column({ space: 16 }) {
      SymbolGlyph($r('sys.symbol.building'))
        .fontSize(64)
        .fontColor(['#C0C0C0'])
      Text('未找到匹配的城市')
        .fontSize(16)
        .fontColor(AppColors.TEXT_SECONDARY)
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

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
        .onClick(async () => { await this.loadCities(); })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  // ===== Flutter: 2-column GridView, crossSpacing 10, mainSpacing 10, aspectRatio 0.78 =====
  @Builder
  CityGrid() {
    Scroll() {
      Column() {
        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
          ForEach(this.filteredCities, (city: City) => {
            this.CityCard(city)
          }, (city: City) => city.id)
        }
        .width('100%')
        .padding({ left: 12, right: 12 })

        if (this.hasMore || this.isLoadingMore) {
          this.LoadMoreIndicator()
        }

        Column().height(100)
      }
    }
    .layoutWeight(1)
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
    .padding({ top: 12 })
  }

  // ===== Flutter CityCard: full-bleed image with gradient overlay =====
  @Builder
  CityCard(city: City) {
    Stack() {
      // Background image - fills entire card
      Image(CityHelper.landscapeImageUrl(city) || $r('app.media.startIcon'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)

      // Gradient overlay: black 10% → transparent → black 60%
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 180,
          colors: [
            ['#1A000000', 0.0],  // black 10%
            ['#00000000', 0.4],  // transparent
            ['#99000000', 1.0],  // black 60%
          ]
        })

      // Rating badge - top right: black 55%, radius 8
      if (city.overallScore && city.overallScore > 0) {
        Row({ space: 3 }) {
          Text('⭐')
            .fontSize(10)
          Text(city.overallScore.toFixed(1))
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.WHITE)
        }
        .padding({ left: 8, right: 8, top: 4, bottom: 4 })
        .backgroundColor('#8C000000') // black 55%
        .borderRadius(8)
        .position({ right: 8, top: 8 })
      }

      // City info - bottom left: name + country
      Column({ space: 2 }) {
        Text(CityHelper.displayName(city))
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.WHITE)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        if (city.country) {
          Text(city.country)
            .fontSize(12)
            .fontColor('#CCFFFFFF') // white 80%
        }
      }
      .alignItems(HorizontalAlign.Start)
      .position({ left: 10, bottom: 10 })
    }
    .width('48%')
    .aspectRatio(0.78) // Flutter: childAspectRatio 0.78
    .borderRadius(12)
    .clip(true)
    .shadow({ radius: 8, color: '#14000000', offsetX: 0, offsetY: 3 }) // black 8% blur 8
    .margin({ bottom: 10 })
    .onClick(() => {
      router.pushUrl({
        url: `pages/${RouteConstants.CITY_DETAIL}`,
        params: { cityId: city.id, cityName: city.name },
      });
    })
  }

  @Builder
  LoadMoreIndicator() {
    Column({ space: 8 }) {
      LoadingProgress()
        .width(28)
        .height(28)

      Text(this.isLoadingMore ? '加载中...' : '加载更多城市')
        .fontSize(13)
        .fontColor(AppColors.TEXT_SECONDARY)
    }
    .width('100%')
    .padding({ top: 16, bottom: 24 })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onAppear(() => {
      if (!this.isLoadingMore) {
        this.loadMore();
      }
    })
    .onClick(() => {
      if (!this.isLoadingMore) {
        this.loadMore();
      }
    })
  }
}
