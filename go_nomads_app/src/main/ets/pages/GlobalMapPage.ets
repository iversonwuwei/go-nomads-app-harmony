import { AppColors } from '../common/constants/AppColors';
import { RouteConstants } from '../common/constants/RouteConstants';
import { City, CityHelper } from '../models/City';
import { CityService } from '../services/CityService';
import { router } from '@kit.ArkUI';

@Entry
@Component
struct GlobalMapPage {
  @State cities: City[] = [];
  @State filteredCities: City[] = [];
  @State isLoading: boolean = true;
  @State keyword: string = '';
  @State selectedTileSource: string = 'gaode-road';
  @State selectedTileSourceLabel: string = '高德标准';
  @State zoomLevel: number = 4;

  private tileSourceOptions: Record<string, string> = {
    'gaode-road': '高德标准',
    'gaode-satellite': '高德卫星',
    'osm-standard': 'OpenStreetMap',
  };

  aboutToAppear(): void {
    this.loadCities();
  }

  private applyFilter(): void {
    const key = this.keyword.trim().toLowerCase();
    let list = this.cities.filter((city: City) => city.latitude !== undefined && city.longitude !== undefined);

    if (key.length > 0) {
      list = list.filter((city: City) => {
        const name = city.name ? city.name.toLowerCase() : '';
        const country = city.country ? city.country.toLowerCase() : '';
        return name.includes(key) || country.includes(key);
      });
    }

    list.sort((a: City, b: City) => CityHelper.displayName(a).localeCompare(CityHelper.displayName(b), 'zh-CN'));
    this.filteredCities = list;
  }

  async loadCities(): Promise<void> {
    this.isLoading = true;
    try {
      this.cities = await CityService.getInstance().getCities(1, 80);
      this.applyFilter();
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Column({ space: 12 }) {
      Row() {
        SymbolGlyph($r('sys.symbol.arrow_left'))
          .fontSize(24).fontColor([AppColors.TEXT_PRIMARY]).onClick(() => { router.back(); })
        Text('全球地图')
          .fontSize(18).fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT_PRIMARY).layoutWeight(1).textAlign(TextAlign.Center)
        Column().width(24)
      }
      .width('100%').height(56).padding({ left: 16, right: 16 })
      .backgroundColor(AppColors.CARD_BACKGROUND)

      if (this.isLoading) {
        Column() { LoadingProgress().width(36).height(36) }
          .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        Column({ space: 10 }) {
          TextInput({ text: this.keyword, placeholder: '搜索城市 / 国家' })
            .width('100%')
            .height(42)
            .borderRadius(10)
            .backgroundColor(AppColors.WHITE)
            .padding({ left: 12, right: 12 })
            .onChange((v: string) => {
              this.keyword = v;
              this.applyFilter();
            })

          Row() {
            Text(`已匹配 ${this.filteredCities.length} 个可定位城市`)
              .fontSize(12)
              .fontColor(AppColors.TEXT_TERTIARY)
            Blank()
            Text(`缩放 ${this.zoomLevel}x`) 
              .fontSize(12)
              .fontColor(AppColors.TEXT_TERTIARY)
          }
          .width('100%')

          Scroll({ direction: Axis.Horizontal }) {
            Row({ space: 8 }) {
              ForEach(Object.keys(this.tileSourceOptions), (key: string) => {
                Text(this.tileSourceOptions[key])
                  .fontSize(12)
                  .fontColor(this.selectedTileSource === key ? AppColors.WHITE : AppColors.TEXT_SECONDARY)
                  .backgroundColor(this.selectedTileSource === key ? AppColors.PRIMARY : AppColors.WHITE)
                  .borderRadius(14)
                  .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                  .onClick(() => {
                    this.selectedTileSource = key;
                    this.selectedTileSourceLabel = this.tileSourceOptions[key];
                  })
              }, (key: string) => key)
            }
            .width('100%')
          }

          Row({ space: 8 }) {
            Button('-')
              .width(34)
              .height(30)
              .backgroundColor(AppColors.WHITE)
              .fontColor(AppColors.TEXT_PRIMARY)
              .borderRadius(8)
              .onClick(() => {
                this.zoomLevel = Math.max(2, this.zoomLevel - 1);
              })

            Button('+')
              .width(34)
              .height(30)
              .backgroundColor(AppColors.WHITE)
              .fontColor(AppColors.TEXT_PRIMARY)
              .borderRadius(8)
              .onClick(() => {
                this.zoomLevel = Math.min(18, this.zoomLevel + 1);
              })

            Blank()
            Text(`样式：${this.selectedTileSourceLabel}`)
              .fontSize(12)
              .fontColor(AppColors.TEXT_SECONDARY)
          }
          .width('100%')
        }
        .padding({ left: 16, right: 16, top: 8, bottom: 2 })

        List() {
          ForEach(this.filteredCities, (city: City) => {
            ListItem() {
              Row() {
                Column({ space: 2 }) {
                  Text(CityHelper.displayName(city)).fontSize(15).fontColor(AppColors.TEXT_PRIMARY)
                  Text(`${city.latitude ?? 0}, ${city.longitude ?? 0}`)
                    .fontSize(12).fontColor(AppColors.TEXT_TERTIARY)
                }
                .layoutWeight(1)
                SymbolGlyph($r('sys.symbol.chevron_right')).fontSize(14).fontColor([AppColors.TEXT_TERTIARY])
              }
              .width('100%').padding({ left: 16, right: 16, top: 12, bottom: 12 })
              .backgroundColor(AppColors.WHITE)
              .borderRadius(10)
              .margin({ left: 16, right: 16, bottom: 8 })
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
