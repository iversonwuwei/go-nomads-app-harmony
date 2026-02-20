import { City, CityHelper } from '../models/City';
import { CityService } from '../services/CityService';
import { AppColors } from '../common/constants/AppColors';
import { RouteConstants } from '../common/constants/RouteConstants';
import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'CityDetailPage';
const DOMAIN = 0x0001;

/**
 * 城市详情页 - 对应 Flutter 端 CityDetailPage
 * NestedScrollView + TabBar 架构
 */
@Entry
@Component
struct CityDetailPage {
  @State city: City | null = null;
  @State isLoading: boolean = true;
  @State hasError: boolean = false;
  @State errorMsg: string = '';
  @State currentTabIndex: number = 0;
  @State isFavorited: boolean = false;
  @State isFavoriteLoading: boolean = false;
  @State shareUrl: string = '';
  @State shareDescription: string = '';

  private cityId: string = '';
  private cityName: string = '';
  private tabTitles: string[] = ['评分', '指南', '优缺点', '评价', '费用', '天气', '照片', '附近'];

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>;
    if (params) {
      this.cityId = params['cityId'] ?? '';
      this.cityName = params['cityName'] ?? '';
    }
    this.loadCityDetail();
    this.checkFavoriteStatus();
  }

  private buildShareContent(city: City): void {
    const title = city.country ? `${city.name}, ${city.country} - Go Nomads` : `${city.name} - Go Nomads`;
    const descParts: string[] = [];

    if (city.overallScore && city.overallScore > 0) {
      descParts.push(`⭐ 综合评分: ${city.overallScore.toFixed(1)}/5.0`);
    }
    if (city.temperature !== undefined && city.temperature !== null) {
      descParts.push(`🌡️ ${city.temperature}°C`);
    }
    if (city.population) {
      descParts.push(`👥 人口: ${city.population}`);
    }
    if (city.averageCost !== undefined && city.averageCost !== null && city.averageCost > 0) {
      descParts.push(`💰 月均消费: $${city.averageCost}`);
    }
    if (city.safetyScore && city.safetyScore > 0) {
      descParts.push(`🛡️ 安全: ${city.safetyScore.toFixed(1)}/5.0`);
    }
    if (city.internetScore && city.internetScore > 0) {
      descParts.push(`📶 网速: ${city.internetScore.toFixed(1)}/5.0`);
    }
    if (city.description) {
      descParts.push(`\n${city.description}`);
    }

    this.shareUrl = `https://nomadcities.app/cities/${city.id}`;
    this.shareDescription = `${title}\n${descParts.join('\n')}`;
  }

  private async copyShareLink(): Promise<void> {
    if (!this.city) {
      return;
    }
    this.buildShareContent(this.city);
    hilog.info(DOMAIN, TAG, '✅ 分享链接已准备: %{public}s', this.shareUrl);
  }

  async loadCityDetail(): Promise<void> {
    this.isLoading = true;
    this.hasError = false;
    try {
      const cityService = CityService.getInstance();
      const city = await cityService.getCityById(this.cityId);
      this.city = city;
      hilog.info(DOMAIN, TAG, '✅ 城市详情加载: %{public}s', city.name);
    } catch (err) {
      this.hasError = true;
      this.errorMsg = (err instanceof Error) ? err.message : '加载失败';
      hilog.error(DOMAIN, TAG, '❌ 加载城市详情失败: %{public}s', this.errorMsg);
    } finally {
      this.isLoading = false;
    }
  }

  async checkFavoriteStatus(): Promise<void> {
    try {
      const cityService = CityService.getInstance();
      this.isFavorited = await cityService.isCityFavorited(this.cityId);
    } catch (err) {
      hilog.warn(DOMAIN, TAG, '⚠️ 检查收藏状态失败');
    }
  }

  async toggleFavorite(): Promise<void> {
    if (this.isFavoriteLoading) {
      return;
    }
    this.isFavoriteLoading = true;
    try {
      const cityService = CityService.getInstance();
      if (this.isFavorited) {
        await cityService.unfavoriteCity(this.cityId);
        this.isFavorited = false;
      } else {
        await cityService.favoriteCity(this.cityId);
        this.isFavorited = true;
      }
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ 切换收藏失败: %{public}s', (err as Error).message);
    } finally {
      this.isFavoriteLoading = false;
    }
  }

  build() {
    Column() {
      // 自定义顶部导航栏
      this.TopBar()

      if (this.isLoading) {
        Column() {
          LoadingProgress().width(40).height(40)
          Text('加载中...')
            .fontSize(14)
            .fontColor(AppColors.TEXT_TERTIARY)
            .margin({ top: 12 })
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
            .onClick(async () => {
              await this.loadCityDetail();
            })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.city) {
        Scroll() {
          Column() {
            // 城市图片 + 基础信息
            this.CityHeroSection()

            // 摘要卡片
            this.SummaryCard()

            // AI 旅行计划入口
            this.AiTravelPlanEntry()

            // Tab 栏
            this.TabSection()

            // Tab 内容
            this.TabContent()

            Column().height(80)
          }
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BACKGROUND)
  }

  // ============================================================
  // 顶部导航
  // ============================================================
  @Builder
  TopBar() {
    Row() {
      SymbolGlyph($r('sys.symbol.arrow_left'))
        .fontSize(24)
        .fontColor([AppColors.TEXT_PRIMARY])
        .onClick(() => {
          router.back();
        })

      Text(this.cityName || this.city?.name || '城市详情')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.TEXT_PRIMARY)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      SymbolGlyph($r('sys.symbol.share'))
        .fontSize(22)
        .fontColor([AppColors.TEXT_PRIMARY])
        .onClick(async () => {
          await this.copyShareLink();
        })

      Text(this.isFavorited ? '❤️' : '🤍')
        .fontSize(22)
        .margin({ left: 12 })
        .onClick(async () => {
          await this.toggleFavorite();
        })
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor(AppColors.CARD_BACKGROUND)
  }

  // ============================================================
  // Hero 区域 - 城市图片 + 评分
  // ============================================================
  @Builder
  CityHeroSection() {
    Stack() {
      Image(CityHelper.landscapeImageUrl(this.city!) || $r('app.media.startIcon'))
        .width('100%')
        .height(220)
        .objectFit(ImageFit.Cover)

      // 底部渐变遮罩
      Column() {
        Blank()
        Row() {
          Column({ space: 4 }) {
            Text(CityHelper.displayName(this.city!))
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')

            Text(CityHelper.fullLocation(this.city!))
              .fontSize(14)
              .fontColor('#FFFFFFCC')
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          // 评分
          if (this.city!.overallScore && this.city!.overallScore! > 0) {
            Column({ space: 2 }) {
              Text(this.city!.overallScore!.toFixed(1))
                .fontSize(28)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFF')
              Text('综合评分')
                .fontSize(11)
                .fontColor('#FFFFFFBB')
            }
          }
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 16 })
      }
      .width('100%')
      .height('100%')
      .linearGradient({
        direction: GradientDirection.Bottom,
        colors: [['#00000000', 0.0], ['#00000000', 0.4], ['#000000AA', 1.0]],
      })
    }
    .width('100%')
    .height(220)
  }

  // ============================================================
  // 摘要卡片（温度、WiFi、类型、费用等）
  // ============================================================
  @Builder
  SummaryCard() {
    Row() {
      this.SummaryItem('🌡️', `${this.city!.temperature ?? '--'}°C`, '温度')
      Divider().vertical(true).height(36).color(AppColors.DIVIDER)
      this.SummaryItem('📶', this.city!.internetScore?.toFixed(1) ?? '--', '网速')
      Divider().vertical(true).height(36).color(AppColors.DIVIDER)
      this.SummaryItem('💰', this.city!.costLevel ?? '--', '消费')
      Divider().vertical(true).height(36).color(AppColors.DIVIDER)
      this.SummaryItem('👥', `${this.city!.meetupCount ?? 0}`, '聚会')
    }
    .width('100%')
    .padding({ top: 14, bottom: 14 })
    .margin({ left: 16, right: 16, top: 16 })
    .backgroundColor(AppColors.CARD_BACKGROUND)
    .borderRadius(12)
    .justifyContent(FlexAlign.SpaceEvenly)
    .shadow({ radius: 4, color: '#0000000A', offsetX: 0, offsetY: 2 })
  }

  @Builder
  SummaryItem(icon: string, value: string, label: string) {
    Column({ space: 4 }) {
      Text(icon)
        .fontSize(20)
      Text(value)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.TEXT_PRIMARY)
      Text(label)
        .fontSize(11)
        .fontColor(AppColors.TEXT_SECONDARY)
    }
    .alignItems(HorizontalAlign.Center)
  }

  // ============================================================
  // AI 旅行计划入口（对齐 Flutter 城市详情页 FAB 语义）
  // ============================================================
  @Builder
  AiTravelPlanEntry() {
    Row({ space: 10 }) {
      Text('✨')
        .fontSize(18)

      Column({ space: 2 }) {
        Text('AI Travel Plan')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.WHITE)
        Text('基于你的偏好智能生成行程')
          .fontSize(12)
          .fontColor('#FFFFFFCC')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      SymbolGlyph($r('sys.symbol.arrow_right'))
        .fontSize(16)
        .fontColor([AppColors.WHITE])
    }
    .width('100%')
    .padding({ left: 14, right: 14, top: 12, bottom: 12 })
    .margin({ left: 16, right: 16, top: 12 })
    .borderRadius(12)
    .backgroundColor(AppColors.PRIMARY)
    .onClick(() => {
      router.pushUrl({
        url: `pages/${RouteConstants.CREATE_TRAVEL_PLAN}`,
        params: {
          cityId: this.cityId || this.city?.id || '',
          cityName: this.city?.name || this.cityName || '',
        },
      });
    })
  }

  // ============================================================
  // Tab 栏
  // ============================================================
  @Builder
  TabSection() {
    Scroll() {
      Row({ space: 4 }) {
        ForEach(this.tabTitles, (title: string, index: number) => {
          Text(title)
            .fontSize(13)
            .fontColor(this.currentTabIndex === index ? '#FFFFFF' : AppColors.TEXT_SECONDARY)
            .backgroundColor(this.currentTabIndex === index ? AppColors.PRIMARY : '#F1F5F9')
            .borderRadius(16)
            .padding({ left: 14, right: 14, top: 7, bottom: 7 })
            .onClick(() => {
              this.currentTabIndex = index;
            })
        }, (title: string, index: number) => `${title}-${index}`)
      }
      .padding({ left: 16, right: 16 })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
    .margin({ top: 16, bottom: 12 })
  }

  // ============================================================
  // Tab 内容
  // ============================================================
  @Builder
  TabContent() {
    Column() {
      if (this.currentTabIndex === 0) {
        this.ScoresContent()
      } else if (this.currentTabIndex === 1) {
        this.GuideContent()
      } else if (this.currentTabIndex === 2) {
        this.ProsConsContent()
      } else if (this.currentTabIndex === 3) {
        this.ReviewsContent()
      } else if (this.currentTabIndex === 4) {
        this.CostContent()
      } else if (this.currentTabIndex === 5) {
        this.WeatherContent()
      } else if (this.currentTabIndex === 6) {
        this.PhotosContent()
      } else if (this.currentTabIndex === 7) {
        this.NeighborhoodsContent()
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16 })
  }

  // ============================================================
  // 评分 Tab
  // ============================================================
  @Builder
  ScoresContent() {
    Column({ space: 10 }) {
      Text('城市评分')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.TEXT_PRIMARY)

      this.ScoreRow('🌡️ 气候', this.city!.weatherScore)
      this.ScoreRow('💰 费用', this.city!.costScore)
      this.ScoreRow('📶 网络', this.city!.internetScore)
      this.ScoreRow('🎉 娱乐', this.city!.funScore)
      this.ScoreRow('🛡️ 安全', this.city!.safetyScore)
      this.ScoreRow('🏥 医疗', this.city!.healthScore)
      this.ScoreRow('🚶 步行', this.city!.walkabilityScore)
    }
    .padding({ top: 8, bottom: 16 })
  }

  @Builder
  ScoreRow(label: string, score: number | undefined) {
    Row() {
      Text(label)
        .fontSize(14)
        .fontColor(AppColors.TEXT_PRIMARY)
        .width(100)

      Progress({ value: (score ?? 0) * 20, total: 100, type: ProgressType.Linear })
        .layoutWeight(1)
        .style({ strokeWidth: 8 })
        .color(AppColors.PRIMARY)
        .backgroundColor('#E2E8F0')

      Text(score?.toFixed(1) ?? '--')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.TEXT_PRIMARY)
        .width(40)
        .textAlign(TextAlign.End)
    }
    .width('100%')
    .height(36)
    .alignItems(VerticalAlign.Center)
  }

  // ============================================================
  // 指南 Tab (AI 生成）
  // ============================================================
  @Builder
  GuideContent() {
    Column({ space: 12 }) {
      Text('城市指南')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.TEXT_PRIMARY)

      if (this.city!.description) {
        Text(this.city!.description!)
          .fontSize(14)
          .lineHeight(22)
          .fontColor(AppColors.TEXT_SECONDARY)
      }

      // AI 生成指南按钮
      Button('🤖 AI 生成详细指南')
        .width('100%')
        .height(44)
        .borderRadius(10)
        .backgroundColor('#F0F9FF')
        .fontColor(AppColors.PRIMARY)
        .fontSize(15)
        .margin({ top: 8 })
        .onClick(() => {
          router.pushUrl({
            url: `pages/${RouteConstants.AI_CHAT}`,
            params: { prompt: `请为我介绍 ${this.city!.name} 这座城市的详细指南` },
          });
        })
    }
    .padding({ top: 8, bottom: 16 })
    .alignItems(HorizontalAlign.Start)
  }

  // ============================================================
  // 优缺点 Tab
  // ============================================================
  @Builder
  ProsConsContent() {
    Column({ space: 12 }) {
      Row() {
        Text('优缺点')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
        Blank()
        Text('+ 添加')
          .fontSize(14)
          .fontColor(AppColors.PRIMARY)
          .onClick(() => {
            router.pushUrl({
              url: `pages/${RouteConstants.ADD_PROS_CONS}`,
              params: { cityId: this.cityId },
            });
          })
      }
      .width('100%')

      Text('暂无优缺点数据，成为第一个贡献者吧！')
        .fontSize(14)
        .fontColor(AppColors.TEXT_TERTIARY)
        .margin({ top: 16 })
    }
    .padding({ top: 8, bottom: 16 })
  }

  // ============================================================
  // 评价 Tab
  // ============================================================
  @Builder
  ReviewsContent() {
    Column({ space: 12 }) {
      Row() {
        Text('用户评价')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
        Blank()
        Text('+ 写评价')
          .fontSize(14)
          .fontColor(AppColors.PRIMARY)
          .onClick(() => {
            router.pushUrl({
              url: `pages/${RouteConstants.ADD_REVIEW}`,
              params: { cityId: this.cityId },
            });
          })
      }
      .width('100%')

      Text('还没有评价，快来分享你的体验吧！')
        .fontSize(14)
        .fontColor(AppColors.TEXT_TERTIARY)
        .margin({ top: 16 })
    }
    .padding({ top: 8, bottom: 16 })
  }

  // ============================================================
  // 费用 Tab
  // ============================================================
  @Builder
  CostContent() {
    Column({ space: 12 }) {
      Text('生活费用')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.TEXT_PRIMARY)

      if (this.city!.costLevel) {
        Text(`消费水平：${this.city!.costLevel}`)
          .fontSize(14)
          .fontColor(AppColors.TEXT_SECONDARY)
      }

      Text('详细费用数据加载中...')
        .fontSize(14)
        .fontColor(AppColors.TEXT_TERTIARY)
        .margin({ top: 16 })
    }
    .padding({ top: 8, bottom: 16 })
    .alignItems(HorizontalAlign.Start)
  }

  // ============================================================
  // 天气 Tab
  // ============================================================
  @Builder
  WeatherContent() {
    Column({ space: 12 }) {
      Text('天气信息')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.TEXT_PRIMARY)

      Row() {
        Column({ space: 4 }) {
          Text(`${this.city!.temperature ?? '--'}°C`)
            .fontSize(36)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.TEXT_PRIMARY)
          Text(this.city!.weatherEmoji ?? '🌤️')
            .fontSize(32)
        }
        .layoutWeight(1)

        Column({ space: 8 }) {
          this.WeatherInfoRow('💧 湿度', `${this.city!.humidity ?? '--'}%`)
          this.WeatherInfoRow('🌬️ 空气', this.city!.airQuality ?? '--')
        }
        .layoutWeight(1)
      }
      .width('100%')
    }
    .padding({ top: 8, bottom: 16 })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  WeatherInfoRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(14)
        .fontColor(AppColors.TEXT_SECONDARY)
      Blank()
      Text(value)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.TEXT_PRIMARY)
    }
    .width('100%')
  }

  // ============================================================
  // 照片 Tab
  // ============================================================
  @Builder
  PhotosContent() {
    Column({ space: 12 }) {
      Row() {
        Text('城市照片')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
        Blank()
        Text('+ 上传')
          .fontSize(14)
          .fontColor(AppColors.PRIMARY)
      }
      .width('100%')

      Text('暂无照片，上传第一张吧！')
        .fontSize(14)
        .fontColor(AppColors.TEXT_TERTIARY)
        .margin({ top: 16 })
    }
    .padding({ top: 8, bottom: 16 })
  }

  // ============================================================
  // 附近 Tab
  // ============================================================
  @Builder
  NeighborhoodsContent() {
    Column({ space: 12 }) {
      Text('附近城市')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.TEXT_PRIMARY)

      Button('🤖 AI 发现附近城市')
        .width('100%')
        .height(44)
        .borderRadius(10)
        .backgroundColor('#F0F9FF')
        .fontColor(AppColors.PRIMARY)
        .fontSize(15)
        .onClick(() => {
          router.pushUrl({
            url: `pages/${RouteConstants.AI_CHAT}`,
            params: {
              cityId: this.cityId,
              cityName: this.cityName || this.city?.name || '',
              prompt: `请推荐 ${this.cityName || this.city?.name || '当前城市'} 周边适合数字游民的城市，并给出简要原因。`,
            },
          });
        })
    }
    .padding({ top: 8, bottom: 16 })
    .alignItems(HorizontalAlign.Start)
  }
}
