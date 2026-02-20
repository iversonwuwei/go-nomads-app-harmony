import { AppColors } from '../common/constants/AppColors';
import { RouteConstants } from '../common/constants/RouteConstants';
import { City, CityHelper } from '../models/City';
import { CityService } from '../services/CityService';
import { router } from '@kit.ArkUI';

@Entry
@Component
struct CitySearchPage {
  @State query: string = '';
  @State cities: City[] = [];
  @State filteredCities: City[] = [];
  @State isLoading: boolean = false;
  @State selectedRegion: string = 'All';
  @State minInternetScore: number = 0;
  @State maxMonthlyCost: number = 5000;

  private regions: string[] = ['All', 'Asia', 'Europe', 'North America', 'South America', 'Africa', 'Oceania'];

  async searchCities(): Promise<void> {
    this.isLoading = true;
    try {
      const q = this.query.trim();
      if (!q) {
        this.cities = [];
        this.filteredCities = [];
        return;
      }

      const cityService = CityService.getInstance();
      this.cities = await cityService.searchCities(q, 1, 60);
      this.applyFilters();
    } finally {
      this.isLoading = false;
    }
  }

  applyFilters(): void {
    let list = [...this.cities];

    if (this.selectedRegion !== 'All') {
      const region = this.selectedRegion.toLowerCase();
      list = list.filter((city) => (city.region ?? '').toLowerCase().includes(region));
    }

    if (this.minInternetScore > 0) {
      list = list.filter((city) => (city.internetScore ?? 0) >= this.minInternetScore);
    }

    if (this.maxMonthlyCost < 5000) {
      list = list.filter((city) => (city.averageCost ?? 0) <= this.maxMonthlyCost);
    }

    this.filteredCities = list;
  }

  resetFilters(): void {
    this.selectedRegion = 'All';
    this.minInternetScore = 0;
    this.maxMonthlyCost = 5000;
    this.applyFilters();
  }

  build() {
    Column() {
      Row() {
        SymbolGlyph($r('sys.symbol.arrow_left'))
          .fontSize(24).fontColor([AppColors.TEXT_PRIMARY]).onClick(() => { router.back(); })
        Text('搜索城市')
          .fontSize(18).fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT_PRIMARY).layoutWeight(1).textAlign(TextAlign.Center)
        Column().width(24)
      }
      .width('100%').height(56).padding({ left: 16, right: 16 })
      .backgroundColor(AppColors.CARD_BACKGROUND)

      Row({ space: 8 }) {
        TextInput({ text: this.query, placeholder: '输入城市名...' })
          .layoutWeight(1).height(40).borderRadius(20)
          .backgroundColor(AppColors.WHITE).padding({ left: 14, right: 14 })
          .onChange((v: string) => { this.query = v; })
          .onSubmit(() => { this.searchCities(); })
        Button('搜索')
          .height(40).borderRadius(20)
          .backgroundColor(AppColors.PRIMARY).fontColor(AppColors.WHITE)
          .onClick(() => { this.searchCities(); })
      }
      .width('100%').padding({ left: 16, right: 16, top: 12, bottom: 12 })

      Scroll() {
        Row({ space: 8 }) {
          ForEach(this.regions, (region: string) => {
            Text(region)
              .fontSize(12)
              .fontColor(this.selectedRegion === region ? AppColors.WHITE : AppColors.TEXT_SECONDARY)
              .backgroundColor(this.selectedRegion === region ? AppColors.PRIMARY : AppColors.WHITE)
              .borderRadius(14)
              .padding({ left: 10, right: 10, top: 5, bottom: 5 })
              .onClick(() => {
                this.selectedRegion = region;
                this.applyFilters();
              })
          }, (region: string) => region)
        }
        .padding({ left: 16, right: 16, bottom: 8 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')

      Row({ space: 8 }) {
        Button(`网速≥${this.minInternetScore}`)
          .layoutWeight(1)
          .height(34)
          .borderRadius(8)
          .backgroundColor(AppColors.WHITE)
          .fontColor(AppColors.TEXT_PRIMARY)
          .fontSize(12)
          .onClick(() => {
            this.minInternetScore = this.minInternetScore >= 5 ? 0 : this.minInternetScore + 1;
            this.applyFilters();
          })
        Button(`预算≤$${this.maxMonthlyCost}`)
          .layoutWeight(1)
          .height(34)
          .borderRadius(8)
          .backgroundColor(AppColors.WHITE)
          .fontColor(AppColors.TEXT_PRIMARY)
          .fontSize(12)
          .onClick(() => {
            this.maxMonthlyCost = this.maxMonthlyCost <= 1000 ? 5000 : this.maxMonthlyCost - 500;
            this.applyFilters();
          })
        Button('重置')
          .height(34)
          .borderRadius(8)
          .backgroundColor('#FEE2E2')
          .fontColor(AppColors.ERROR)
          .fontSize(12)
          .onClick(() => { this.resetFilters(); })
      }
      .width('100%').padding({ left: 16, right: 16, bottom: 8 })

      if (this.isLoading) {
        Column() { LoadingProgress().width(36).height(36) }
          .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else if (this.filteredCities.length === 0) {
        Column({ space: 8 }) {
          Text('🔍').fontSize(40)
          Text('无匹配结果，请调整筛选条件').fontSize(14).fontColor(AppColors.TEXT_SECONDARY)
        }
        .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
      } else {
        List() {
          ForEach(this.filteredCities, (city: City) => {
            ListItem() {
              Row() {
                Column({ space: 2 }) {
                  Text(CityHelper.displayName(city)).fontSize(15).fontColor(AppColors.TEXT_PRIMARY)
                  Text(`${city.country ?? ''}${city.averageCost ? ' · $' + city.averageCost : ''}${city.internetScore ? ' · 网速 ' + city.internetScore?.toFixed(1) : ''}`)
                    .fontSize(12)
                    .fontColor(AppColors.TEXT_TERTIARY)
                }
                .layoutWeight(1)
                SymbolGlyph($r('sys.symbol.chevron_right')).fontSize(14).fontColor([AppColors.TEXT_TERTIARY])
              }
              .width('100%').padding({ left: 16, right: 16, top: 12, bottom: 12 })
              .backgroundColor(AppColors.WHITE)
              .borderRadius(10)
              .margin({ bottom: 8, left: 16, right: 16 })
              .onClick(() => {
                router.pushUrl({
                  url: `pages/${RouteConstants.CITY_DETAIL}`,
                  params: { cityId: city.id, cityName: city.name },
                });
              })
            }
          }, (city: City) => city.id)
        }
        .layoutWeight(1)
        .divider({ strokeWidth: 0 })
      }
    }
    .width('100%').height('100%').backgroundColor(AppColors.BACKGROUND)
  }
}
