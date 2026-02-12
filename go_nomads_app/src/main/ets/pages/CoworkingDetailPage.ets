import { AppColors } from '../common/constants/AppColors';
import { HttpService } from '../services/HttpService';
import { ApiConfig } from '../common/constants/ApiConfig';
import { CoworkingSpace, CoworkingHelper } from '../models/CoworkingSpace';
import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'CoworkingDetailPage';
const DOMAIN = 0x0001;

/**
 * 共享办公空间详情页 — 对应 Flutter coworking_detail_page.dart
 */
@Entry
@Component
struct CoworkingDetailPage {
  @State space: CoworkingSpace | null = null;
  @State isLoading: boolean = true;

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>;
    if (params?.['spaceId']) { this.loadSpace(params['spaceId']); }
  }

  async loadSpace(id: string): Promise<void> {
    this.isLoading = true;
    try {
      const httpService = HttpService.getInstance();
      this.space = await httpService.get<CoworkingSpace>(`${ApiConfig.COWORKING_SPACES_ENDPOINT}/${id}`);
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ %{public}s', JSON.stringify(err));
    } finally { this.isLoading = false; }
  }

  build() {
    Column() {
      if (this.isLoading || !this.space) {
        Column() { LoadingProgress().width(40).height(40) }
          .width('100%').height('100%').justifyContent(FlexAlign.Center)
          .backgroundColor(AppColors.BACKGROUND)
      } else {
        this.DetailContent(this.space!)
      }
    }
    .width('100%').height('100%')
  }

  @Builder
  DetailContent(s: CoworkingSpace) {
    Column() {
      Scroll() {
        Column({ space: 0 }) {
          // 封面图
          Stack() {
            Image(s.imageUrl || $r('app.media.startIcon'))
              .width('100%').height(220).objectFit(ImageFit.Cover)
            // 返回按钮
            Row() {
              SymbolGlyph($r('sys.symbol.arrow_left'))
                .fontSize(22).fontColor(['#FFFFFF'])
                .onClick(() => { router.back(); })
            }.width('100%').padding({ left: 16, top: 44 })
          }.width('100%')

          Column({ space: 16 }) {
            // 名称 + 验证
            Row({ space: 8 }) {
              Text(s.name).fontSize(22).fontWeight(FontWeight.Bold)
                .fontColor(AppColors.TEXT_PRIMARY).layoutWeight(1)
              if (s.isVerified) {
                Text('已认证 ✓').fontSize(12).fontColor(AppColors.SUCCESS)
                  .backgroundColor(`${AppColors.SUCCESS}18`).borderRadius(4)
                  .padding({ left: 8, right: 8, top: 3, bottom: 3 })
              }
            }.width('100%')

            // 评分和价格
            Row({ space: 16 }) {
              Text(`⭐ ${s.rating.toFixed(1)} (${s.reviewCount} 条评价)`)
                .fontSize(14).fontColor(AppColors.TEXT_SECONDARY)
              Text(CoworkingHelper.priceLabel(s))
                .fontSize(16).fontWeight(FontWeight.Bold).fontColor(AppColors.PRIMARY)
            }

            // 地址
            if (s.address) {
              Row({ space: 6 }) {
                Text('📍').fontSize(14)
                Text(s.address).fontSize(14).fontColor(AppColors.TEXT_SECONDARY)
              }
            }

            // WiFi
            if (s.wifiSpeed) {
              Row({ space: 6 }) {
                Text('📶').fontSize(14)
                Text(`WiFi ${s.wifiSpeed} Mbps`).fontSize(14).fontColor(AppColors.TEXT_SECONDARY)
              }
            }

            Divider().color(AppColors.DIVIDER)

            // 描述
            if (s.description) {
              Column({ space: 6 }) {
                Text('简介').fontSize(16).fontWeight(FontWeight.Medium).fontColor(AppColors.TEXT_PRIMARY)
                Text(s.description).fontSize(14).fontColor(AppColors.TEXT_SECONDARY).lineHeight(22)
              }
              .width('100%').alignItems(HorizontalAlign.Start)
            }

            // 价格详情
            this.PricingSection(s)

            // 设施
            this.AmenitiesSection(s)

            // 运营时间
            if (s.openTime) {
              Column({ space: 6 }) {
                Text('🕐 营业时间').fontSize(16).fontWeight(FontWeight.Medium).fontColor(AppColors.TEXT_PRIMARY)
                Text(`${s.openTime} - ${s.closeTime ?? '关门'}`).fontSize(14).fontColor(AppColors.TEXT_SECONDARY)
              }
              .width('100%').alignItems(HorizontalAlign.Start)
            }

            // 联系方式
            this.ContactSection(s)

            Column().height(30)
          }
          .padding({ left: 16, right: 16, top: 16 })
          .alignItems(HorizontalAlign.Start)
        }
      }
      .layoutWeight(1).scrollBar(BarState.Off)

      // 底栏
      Row({ space: 12 }) {
        Column() {
          Text(CoworkingHelper.priceLabel(s)).fontSize(18).fontWeight(FontWeight.Bold).fontColor(AppColors.PRIMARY)
        }.layoutWeight(1)
        Button('联系空间').height(44).borderRadius(10)
          .backgroundColor(AppColors.PRIMARY).fontColor('#FFFFFF').fontSize(15)
      }
      .width('100%').padding({ left: 16, right: 16, top: 10, bottom: 10 })
      .backgroundColor(AppColors.CARD_BACKGROUND)
      .shadow({ radius: 6, color: '#0000000F', offsetX: 0, offsetY: -2 })
    }
    .width('100%').height('100%').backgroundColor(AppColors.BACKGROUND)
  }

  @Builder
  PricingSection(s: CoworkingSpace) {
    Column({ space: 8 }) {
      Text('💰 价格').fontSize(16).fontWeight(FontWeight.Medium).fontColor(AppColors.TEXT_PRIMARY)
      Grid() {
        if (s.hourlyRate) { this.PriceCell(`¥${s.hourlyRate}`, '每小时') }
        if (s.dailyRate) { this.PriceCell(`¥${s.dailyRate}`, '每天') }
        if (s.weeklyRate) { this.PriceCell(`¥${s.weeklyRate}`, '每周') }
        if (s.monthlyRate) { this.PriceCell(`¥${s.monthlyRate}`, '每月') }
      }
      .columnsTemplate('1fr 1fr').rowsGap(8).columnsGap(8).width('100%')
    }
    .width('100%').alignItems(HorizontalAlign.Start)
  }

  @Builder
  PriceCell(price: string, period: string) {
    GridItem() {
      Column({ space: 2 }) {
        Text(price).fontSize(16).fontWeight(FontWeight.Bold).fontColor(AppColors.PRIMARY)
        Text(period).fontSize(12).fontColor(AppColors.TEXT_TERTIARY)
      }
      .width('100%').padding(10).backgroundColor('#F0F9FF').borderRadius(8)
    }
  }

  @Builder
  AmenitiesSection(s: CoworkingSpace) {
    Column({ space: 8 }) {
      Text('🏢 设施服务').fontSize(16).fontWeight(FontWeight.Medium).fontColor(AppColors.TEXT_PRIMARY)
      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(CoworkingHelper.amenitiesList(s), (a: string) => {
          Text(a).fontSize(13).fontColor(AppColors.TEXT_SECONDARY)
            .backgroundColor('#F1F5F9').borderRadius(6)
            .padding({ left: 10, right: 10, top: 5, bottom: 5 })
            .margin({ right: 6, bottom: 6 })
        }, (a: string) => a)
      }
    }
    .width('100%').alignItems(HorizontalAlign.Start)
  }

  @Builder
  ContactSection(s: CoworkingSpace) {
    if (s.phone || s.email || s.website) {
      Column({ space: 8 }) {
        Text('📞 联系方式').fontSize(16).fontWeight(FontWeight.Medium).fontColor(AppColors.TEXT_PRIMARY)
        if (s.phone) { Text(`电话: ${s.phone}`).fontSize(14).fontColor(AppColors.TEXT_SECONDARY) }
        if (s.email) { Text(`邮箱: ${s.email}`).fontSize(14).fontColor(AppColors.TEXT_SECONDARY) }
        if (s.website) { Text(`网站: ${s.website}`).fontSize(14).fontColor(AppColors.PRIMARY) }
      }
      .width('100%').alignItems(HorizontalAlign.Start)
    }
  }
}
