import { AppColors } from '../common/constants/AppColors';
import { HttpService } from '../services/HttpService';
import { ApiConfig } from '../common/constants/ApiConfig';
import { Hotel, HotelHelper } from '../models/Hotel';
import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'HotelDetailPage';
const DOMAIN = 0x0001;

/**
 * 酒店详情页 — 对应 Flutter hotel_detail_page.dart
 */
@Entry
@Component
struct HotelDetailPage {
  @State hotel: Hotel | null = null;
  @State isLoading: boolean = true;
  @State currentImageIndex: number = 0;

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>;
    if (params?.['hotelId']) { this.loadHotel(params['hotelId']); }
  }

  async loadHotel(id: string): Promise<void> {
    this.isLoading = true;
    try {
      const httpService = HttpService.getInstance();
      this.hotel = await httpService.get<Hotel>(`${ApiConfig.CITIES_ENDPOINT}/hotels/${id}`);
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ %{public}s', JSON.stringify(err));
    } finally { this.isLoading = false; }
  }

  build() {
    Column() {
      if (this.isLoading || !this.hotel) {
        Column() { LoadingProgress().width(40).height(40) }
          .width('100%').height('100%').justifyContent(FlexAlign.Center).backgroundColor(AppColors.BACKGROUND)
      } else {
        this.Content(this.hotel!)
      }
    }.width('100%').height('100%')
  }

  @Builder
  Content(h: Hotel) {
    Column() {
      Scroll() {
        Column({ space: 0 }) {
          // 图片
          Stack() {
            if (h.images && h.images.length > 0) {
              Swiper() {
                ForEach(h.images!, (url: string) => {
                  Image(url).width('100%').height(240).objectFit(ImageFit.Cover)
                }, (url: string) => url)
              }
              .width('100%').height(240).autoPlay(false)
              .onChange((i: number) => { this.currentImageIndex = i; })
            } else {
              Image($r('app.media.startIcon'))
                .width('100%').height(240).objectFit(ImageFit.Cover)
            }
            Row() {
              SymbolGlyph($r('sys.symbol.arrow_left'))
                .fontSize(22).fontColor(['#FFFFFF'])
                .onClick(() => { router.back(); })
            }.width('100%').padding({ left: 16, top: 44 })
          }.width('100%')

          Column({ space: 16 }) {
            // 名称 + 价格
            Row() {
              Column({ space: 4 }) {
                Text(h.name).fontSize(22).fontWeight(FontWeight.Bold).fontColor(AppColors.TEXT_PRIMARY)
                Row({ space: 8 }) {
                  if (h.starRating) {
                    Text(HotelHelper.starText(h)).fontSize(14).fontColor(AppColors.WARNING)
                  }
                  Text(`⭐ ${h.rating.toFixed(1)} (${h.reviewCount}条)`)
                    .fontSize(13).fontColor(AppColors.TEXT_SECONDARY)
                }
              }.layoutWeight(1).alignItems(HorizontalAlign.Start)

              Column({ space: 2 }) {
                Text(HotelHelper.priceLabel(h)).fontSize(20).fontWeight(FontWeight.Bold).fontColor(AppColors.PRIMARY)
                if (h.hasLongStayDiscount) {
                  Text(`长住折扣 ${h.longStayDiscountPercent}%`).fontSize(11).fontColor(AppColors.SUCCESS)
                }
              }.alignItems(HorizontalAlign.End)
            }.width('100%')

            // 地址
            Row({ space: 6 }) {
              Text('📍').fontSize(14)
              Text(`${h.address}${h.cityName ? ', ' + h.cityName : ''}`).fontSize(14).fontColor(AppColors.TEXT_SECONDARY)
            }

            // Nomad Score
            if (h.nomadScore) {
              Row({ space: 8 }) {
                Text('🏆 游民评分').fontSize(14).fontColor(AppColors.TEXT_PRIMARY).fontWeight(FontWeight.Medium)
                Text(`${h.nomadScore}/100`).fontSize(14).fontWeight(FontWeight.Bold).fontColor(AppColors.PRIMARY)
              }
              .width('100%').padding(12).backgroundColor('#F0F9FF').borderRadius(8)
            }

            Divider().color(AppColors.DIVIDER)

            // 描述
            if (h.description) {
              Column({ space: 6 }) {
                Text('简介').fontSize(16).fontWeight(FontWeight.Medium).fontColor(AppColors.TEXT_PRIMARY)
                Text(h.description!).fontSize(14).fontColor(AppColors.TEXT_SECONDARY).lineHeight(22)
              }.width('100%').alignItems(HorizontalAlign.Start)
            }

            // 游民特性
            Column({ space: 8 }) {
              Text('🎒 数字游民特性').fontSize(16).fontWeight(FontWeight.Medium).fontColor(AppColors.TEXT_PRIMARY)
              Flex({ wrap: FlexWrap.Wrap }) {
                ForEach(HotelHelper.nomadFeatures(h), (f: string) => {
                  Text(f).fontSize(13).fontColor(AppColors.TEXT_SECONDARY)
                    .backgroundColor('#F1F5F9').borderRadius(6)
                    .padding({ left: 10, right: 10, top: 5, bottom: 5 })
                    .margin({ right: 6, bottom: 6 })
                }, (f: string) => f)
              }
              if (h.wifiSpeed) {
                Text(`📶 WiFi ${h.wifiSpeed} Mbps`).fontSize(13).fontColor(AppColors.TEXT_SECONDARY)
              }
            }.width('100%').alignItems(HorizontalAlign.Start)

            // 联系方式
            if (h.phone || h.email || h.website) {
              Column({ space: 6 }) {
                Text('📞 联系方式').fontSize(16).fontWeight(FontWeight.Medium).fontColor(AppColors.TEXT_PRIMARY)
                if (h.phone) { Text(`电话: ${h.phone}`).fontSize(14).fontColor(AppColors.TEXT_SECONDARY) }
                if (h.email) { Text(`邮箱: ${h.email}`).fontSize(14).fontColor(AppColors.TEXT_SECONDARY) }
                if (h.website) { Text(`网站: ${h.website}`).fontSize(14).fontColor(AppColors.PRIMARY) }
              }.width('100%').alignItems(HorizontalAlign.Start)
            }

            Column().height(30)
          }
          .padding({ left: 16, right: 16, top: 16 }).alignItems(HorizontalAlign.Start)
        }
      }
      .layoutWeight(1).scrollBar(BarState.Off)

      // Bottom Bar
      Row({ space: 12 }) {
        Column() {
          Text(HotelHelper.priceLabel(h)).fontSize(18).fontWeight(FontWeight.Bold).fontColor(AppColors.PRIMARY)
        }.layoutWeight(1)
        Button('预订').height(44).borderRadius(10)
          .backgroundColor(AppColors.PRIMARY).fontColor('#FFFFFF').fontSize(15)
      }
      .width('100%').padding({ left: 16, right: 16, top: 10, bottom: 10 })
      .backgroundColor(AppColors.CARD_BACKGROUND)
      .shadow({ radius: 6, color: '#0000000F', offsetX: 0, offsetY: -2 })
    }
    .width('100%').height('100%').backgroundColor(AppColors.BACKGROUND)
  }
}
