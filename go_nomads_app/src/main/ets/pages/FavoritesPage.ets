import { AppColors } from '../common/constants/AppColors';
import { AppStorageKeys } from '../common/constants/AppStorageKeys';
import { RouteConstants } from '../common/constants/RouteConstants';
import { HttpService } from '../services/HttpService';
import { ApiConfig } from '../common/constants/ApiConfig';
import { City, CityHelper } from '../models/City';
import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'FavoritesPage';
const DOMAIN = 0x0001;

/**
 * 收藏页 — 对应 Flutter favorites_page.dart
 */
@Entry
@Component
struct FavoritesPage {
  @State favorites: City[] = [];
  @State isLoading: boolean = true;
  @StorageProp(AppStorageKeys.IS_AUTHENTICATED) isAuthenticated: boolean = false;

  aboutToAppear(): void {
    if (this.isAuthenticated) { this.loadFavorites(); }
  }

  async loadFavorites(): Promise<void> {
    this.isLoading = true;
    try {
      const httpService = HttpService.getInstance();
      this.favorites = await httpService.get<City[]>(ApiConfig.FAVORITES_ENDPOINT);
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ %{public}s', JSON.stringify(err));
    } finally { this.isLoading = false; }
  }

  build() {
    Column() {
      Row() {
        SymbolGlyph($r('sys.symbol.arrow_left'))
          .fontSize(24).fontColor([AppColors.TEXT_PRIMARY]).onClick(() => { router.back(); })
        Text('我的收藏').fontSize(18).fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT_PRIMARY).layoutWeight(1).textAlign(TextAlign.Center)
        Column().width(24)
      }
      .width('100%').height(56).padding({ left: 16, right: 16 })
      .backgroundColor(AppColors.CARD_BACKGROUND)

      if (!this.isAuthenticated) {
        Column({ space: 12 }) {
          Text('❤️').fontSize(48)
          Text('登录后查看收藏').fontSize(16).fontColor(AppColors.TEXT_SECONDARY)
          Button('去登录').width(120).height(40).borderRadius(20)
            .backgroundColor(AppColors.PRIMARY).fontColor('#FFFFFF')
            .onClick(() => { router.pushUrl({ url: `pages/${RouteConstants.LOGIN}` }); })
        }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else if (this.isLoading) {
        Column() { LoadingProgress().width(40).height(40) }
          .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else if (this.favorites.length === 0) {
        Column({ space: 12 }) {
          Text('❤️').fontSize(48)
          Text('还没有收藏').fontSize(16).fontColor(AppColors.TEXT_SECONDARY)
          Text('浏览城市并点击收藏').fontSize(14).fontColor(AppColors.TEXT_TERTIARY)
        }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        List() {
          ForEach(this.favorites, (city: City) => {
            ListItem() { this.CityItem(city) }
          }, (city: City) => city.id)
        }
        .layoutWeight(1).padding({ left: 16, right: 16, top: 8 })
        .divider({ strokeWidth: 0 }).edgeEffect(EdgeEffect.Spring)
      }
    }
    .width('100%').height('100%').backgroundColor(AppColors.BACKGROUND)
  }

  @Builder
  CityItem(city: City) {
    Row() {
      Image(CityHelper.landscapeImageUrl(city) || $r('app.media.startIcon'))
        .width(80).height(60).objectFit(ImageFit.Cover).borderRadius(8)

      Column({ space: 4 }) {
        Text(CityHelper.displayName(city)).fontSize(15).fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT_PRIMARY)
        Text(CityHelper.fullLocation(city)).fontSize(13).fontColor(AppColors.TEXT_SECONDARY)
        Row({ space: 8 }) {
          if (city.overallScore && city.overallScore > 0) {
            Text(`⭐ ${city.overallScore.toFixed(1)}`).fontSize(12).fontColor(AppColors.TEXT_TERTIARY)
          }
          if (city.temperature !== undefined) {
            Text(`🌡️ ${city.temperature}°C`).fontSize(12).fontColor(AppColors.TEXT_TERTIARY)
          }
        }
      }
      .layoutWeight(1).alignItems(HorizontalAlign.Start).padding({ left: 12 })

      // 收藏图标
      Text('❤️').fontSize(20)
    }
    .width('100%').padding(10)
    .backgroundColor(AppColors.CARD_BACKGROUND).borderRadius(10)
    .shadow({ radius: 3, color: '#0000000A', offsetX: 0, offsetY: 1 })
    .margin({ bottom: 8 })
    .onClick(() => {
      router.pushUrl({
        url: `pages/${RouteConstants.CITY_DETAIL}`,
        params: { cityId: city.id, cityName: city.name },
      });
    })
  }
}
