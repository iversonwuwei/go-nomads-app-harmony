import { City, CityHelper } from '../../models/City';
import { Meetup, MeetupHelper, MeetupStatus } from '../../models/Meetup';
import { HttpService } from '../../services/HttpService';
import { ApiConfig } from '../../common/constants/ApiConfig';
import { AppColors } from '../../common/constants/AppColors';
import { RouteConstants } from '../../common/constants/RouteConstants';
import { AppStorageKeys } from '../../common/constants/AppStorageKeys';
import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

/**
 * 后端分页响应结构
 */
interface PaginatedResponse<T> {
  items: T[];
  totalCount: number;
  page: number;
  pageSize: number;
}

const TAG = 'HomeTab';
const DOMAIN = 0x0001;

/**
 * 首页 Tab - 100% 还原 Flutter HomePage
 *
 * Flutter 结构:
 *   HeroSection → 深色渐变 #1a1a2e→#16213e, logo + "Go Nomad" 32px white, 4 service cards 2x2
 *   SearchBar → 白色容器 radius 8, borderLight, 红色Search按钮
 *   HomeToolbar → (省略,用QuickEntry代替)
 *   AiEntryCard → 渐变 #0F172A→#1E293B→#0EA5E9, "AI Copilot" + Beta badge
 *   CityGrid → 2列网格, 白色卡片, 图片+渐变叠加
 *   MeetupsSection → 水平滚动, 卡片280px宽
 *   FeatureHighlights → emoji 列表
 */
@Component
export struct HomeTab {
  @State cities: City[] = [];
  @State meetups: Meetup[] = [];
  @State isLoading: boolean = true;
  @State searchQuery: string = '';
  @StorageProp(AppStorageKeys.IS_AUTHENTICATED) isAuthenticated: boolean = false;

  aboutToAppear(): void {
    this.loadData();
  }

  async loadData(): Promise<void> {
    this.isLoading = true;
    try {
      const httpService = HttpService.getInstance();
      // 后端返回 PaginatedResponse 分页包装，需要解包 items
      const citiesPromise = httpService.get<PaginatedResponse<City>>(ApiConfig.CITY_LIST_ENDPOINT, {
        queryParams: { 'pageSize': '12', 'pageNumber': '1' },
      });
      const meetupsPromise = httpService.get<PaginatedResponse<Meetup>>(ApiConfig.EVENTS_ENDPOINT, {
        queryParams: { 'pageSize': '5', 'status': 'upcoming' },
      });
      const results = await Promise.all<Object>([
        citiesPromise.catch((): City[] => []),
        meetupsPromise.catch((): Meetup[] => []),
      ]);
      // 从分页响应中提取 items，兼容 catch 返回空数组的情况
      const citiesResult = results[0];
      if (Array.isArray(citiesResult)) {
        this.cities = citiesResult as City[];
      } else {
        const paged = citiesResult as PaginatedResponse<City>;
        this.cities = paged.items ?? [];
      }
      const meetupsResult = results[1];
      if (Array.isArray(meetupsResult)) {
        this.meetups = meetupsResult as Meetup[];
      } else {
        const paged = meetupsResult as PaginatedResponse<Meetup>;
        this.meetups = paged.items ?? [];
      }
      hilog.info(DOMAIN, TAG, '✅ 首页数据加载完成: %{public}d 城市, %{public}d 聚会',
        this.cities.length, this.meetups.length);
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ 首页数据加载失败: %{public}s', JSON.stringify(err));
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Scroll() {
      Column() {
        // ===== HeroSection: gradient #1a1a2e→#16213e =====
        this.HeroSection()

        // ===== SearchBar: white container, radius 8, red button =====
        this.SearchBar()

        // ===== AI Entry Card: gradient #0F172A→#1E293B→#0EA5E9 =====
        this.AiEntryCard()

        // ===== City Grid: 2 columns =====
        this.CitiesSection()

        // ===== Meetups: horizontal scroll =====
        this.MeetupsSection()

        // ===== Feature Highlights =====
        this.FeatureHighlights()

        // 底部间距 (为底部导航栏留空间)
        Column().height(100)
      }
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
    .backgroundColor(AppColors.BACKGROUND)
  }

  // ===== Hero 区域 - Flutter: gradient #1a1a2e→#16213e =====
  @Builder
  HeroSection() {
    Column() {
      // Logo 和标题行
      Row({ space: 16 }) {
        // Logo 容器: white 10% bg, radius 12
        Column() {
          SymbolGlyph($r('sys.symbol.globe_badge_heart'))
            .fontSize(32)
            .fontColor([AppColors.WHITE])
        }
        .width(56)
        .height(56)
        .borderRadius(12)
        .backgroundColor('#1AFFFFFF') // white 10%
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)

        Text('Go Nomad')
          .fontSize(32)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.WHITE)
      }
      .margin({ top: 60 })
      .justifyContent(FlexAlign.Center)

      // 副标题
      Text('加入全球数字游民社区')
        .fontSize(18)
        .fontColor(AppColors.WHITE)
        .margin({ top: 24 })
        .textAlign(TextAlign.Center)

      Text('探索世界，自由工作')
        .fontSize(18)
        .fontColor(AppColors.WHITE)
        .margin({ top: 8 })
        .textAlign(TextAlign.Center)

      // 4 Service Cards 2x2
      Column({ space: 12 }) {
        // 第一行: Cities + Coworks
        Row({ space: 12 }) {
          this.ServiceCard('Cities', AppColors.HOME_CITIES, '🏙️', () => {
            router.pushUrl({ url: `pages/${RouteConstants.CITY_LIST}` });
          })
          this.ServiceCard('Coworks', AppColors.HOME_COWORKS, '🏢', () => {
            router.pushUrl({ url: `pages/${RouteConstants.COWORKING_LIST}` });
          })
        }
        .width('100%')

        // 第二行: Meetups + Innovation
        Row({ space: 12 }) {
          this.ServiceCard('Meetups', AppColors.HOME_MEETUPS, '👥', () => {
            router.pushUrl({ url: `pages/${RouteConstants.MEETUP_LIST}` });
          })
          this.ServiceCard('Innovation', AppColors.HOME_INNOVATION, '💡', () => {
            router.pushUrl({ url: `pages/${RouteConstants.INNOVATION_LIST}` });
          })
        }
        .width('100%')
      }
      .width('100%')
      .margin({ top: 32 })
    }
    .width('100%')
    .padding({ left: 24, right: 24, top: 20, bottom: 32 })
    .linearGradient({
      direction: GradientDirection.Top,
      colors: [[AppColors.HERO_DARK1, 0.0], [AppColors.HERO_DARK2, 1.0]],
    })
  }

  // Service Card - Flutter: gradient color→color*0.8, radius 16, shadow
  @Builder
  ServiceCard(title: string, color: string, emoji: string, onClick: () => void) {
    Column() {
      // 图标容器: white 25% bg, radius 14
      Column() {
        Text(emoji)
          .fontSize(32)
      }
      .width(56)
      .height(56)
      .borderRadius(14)
      .backgroundColor('#40FFFFFF') // white 25%
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      Text(title)
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.WHITE)
        .margin({ top: 12 })
        .textAlign(TextAlign.Center)
    }
    .layoutWeight(1)
    .padding({ top: 20, bottom: 20, left: 16, right: 16 })
    .borderRadius(16)
    .backgroundColor(color)
    .shadow({ radius: 12, color: '#4D000000', offsetX: 0, offsetY: 4 })
    .alignItems(HorizontalAlign.Center)
    .onClick(onClick)
  }

  // ===== SearchBar - Flutter: white, radius 8, borderLight border, red Search button =====
  @Builder
  SearchBar() {
    Row() {
      SymbolGlyph($r('sys.symbol.magnifyingglass'))
        .fontSize(20)
        .fontColor([AppColors.TEXT_SECONDARY])

      TextInput({ placeholder: 'Search cities... (支持中英文搜索)', text: this.searchQuery })
        .layoutWeight(1)
        .backgroundColor('transparent')
        .borderRadius(0)
        .height(40)
        .fontSize(14)
        .fontColor(AppColors.TEXT_PRIMARY)
        .onChange((value: string) => {
          this.searchQuery = value;
        })
        .onSubmit(() => {
          if (this.searchQuery) {
            router.pushUrl({
              url: `pages/${RouteConstants.CITY_SEARCH}`,
              params: { query: this.searchQuery },
            });
          }
        })

      // Search 按钮 - red #FF4458, radius 6
      Text('Search')
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.WHITE)
        .padding({ left: 16, right: 16, top: 8, bottom: 8 })
        .borderRadius(6)
        .backgroundColor(AppColors.PRIMARY)
        .onClick(() => {
          if (this.searchQuery) {
            router.pushUrl({
              url: `pages/${RouteConstants.CITY_SEARCH}`,
              params: { query: this.searchQuery },
            });
          }
        })
    }
    .width('100%')
    .padding({ left: 20, right: 14, top: 14, bottom: 14 })
    .margin({ left: 16, right: 16, top: 20, bottom: 8 })
    .borderRadius(8)
    .backgroundColor(AppColors.WHITE)
    .border({ width: 1, color: AppColors.BORDER_LIGHT })
    .shadow({ radius: 8, color: '#08000000', offsetX: 0, offsetY: 2 })
  }

  // ===== AI Chat 入口卡片 - Flutter: gradient #0F172A→#1E293B→#0EA5E9 =====
  @Builder
  AiEntryCard() {
    Row() {
      // AI 图标: 44x44, white 12% bg, radius 12
      Column() {
        Text('✨')
          .fontSize(18)
      }
      .width(44)
      .height(44)
      .borderRadius(12)
      .backgroundColor('#1FFFFFFF') // white 12%
      .border({ width: 1, color: '#26FFFFFF' }) // white 15%
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      Column() {
        Row({ space: 8 }) {
          Text('AI Copilot')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.WHITE)
          // Beta badge
          Text('Beta')
            .fontSize(10)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.WHITE)
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .borderRadius(6)
            .backgroundColor('#26FFFFFF') // white 15%
        }
        Text('智能旅行助手，帮你探索目的地')
          .fontSize(12)
          .fontColor('#B3FFFFFF') // white 70%
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 14 })
      .layoutWeight(1)

      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(16)
        .fontColor(['#80FFFFFF']) // white 50%
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .margin({ left: 16, right: 16, top: 12 })
    .borderRadius(16)
    .linearGradient({
      direction: GradientDirection.Right,
      colors: [[AppColors.AI_GRADIENT1, 0.0], [AppColors.AI_GRADIENT2, 0.6], [AppColors.AI_GRADIENT3, 1.0]],
    })
    .shadow({ radius: 16, color: '#2E0EA5E9', offsetX: 0, offsetY: 6 })
    .onClick(() => {
      router.pushUrl({ url: `pages/${RouteConstants.AI_CHAT}` });
    })
  }

  // ===== 推荐城市网格 - Flutter: 2 columns, white cards =====
  @Builder
  CitiesSection() {
    Column() {
      Row() {
        Text('🌍 推荐城市')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
        Blank()
        Text('查看全部 →')
          .fontSize(14)
          .fontColor(AppColors.PRIMARY)
          .onClick(() => {
            router.pushUrl({ url: `pages/${RouteConstants.CITY_LIST}` });
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 24, bottom: 16 })

      if (this.isLoading) {
        LoadingProgress()
          .width(40)
          .height(40)
          .margin({ top: 20, bottom: 20 })
      } else if (this.cities.length === 0) {
        Text('暂无城市数据')
          .fontSize(14)
          .fontColor(AppColors.TEXT_TERTIARY)
          .margin({ top: 20, bottom: 20 })
      } else {
        // 城市网格 2列 - Flutter: spacing 12, aspect 0.68
        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
          ForEach(this.cities.slice(0, 6), (city: City) => {
            this.CityCard(city)
          }, (city: City) => city.id)
        }
        .width('100%')
        .padding({ left: 16, right: 16 })
      }
    }
  }

  @Builder
  CityCard(city: City) {
    Column() {
      // 城市图片 - Flutter: gradient overlay
      Stack() {
        Image(CityHelper.landscapeImageUrl(city) || $r('app.media.startIcon'))
          .width('100%')
          .height(130)
          .objectFit(ImageFit.Cover)
          .borderRadius({ topLeft: 12, topRight: 12 })

        // 评分标签
        if (city.overallScore && city.overallScore > 0) {
          Text(`⭐ ${city.overallScore.toFixed(1)}`)
            .fontSize(11)
            .fontColor(AppColors.WHITE)
            .backgroundColor('#66000000')
            .borderRadius(10)
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .position({ x: 8, y: 8 })
        }
      }
      .width('100%')

      // 城市信息
      Column({ space: 4 }) {
        Text(CityHelper.displayName(city))
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(city.country ?? '')
          .fontSize(12)
          .fontColor(AppColors.TEXT_SECONDARY)
          .maxLines(1)

        Row({ space: 4 }) {
          if (city.temperature !== undefined) {
            Text(`🌡️ ${city.temperature}°C`)
              .fontSize(11)
              .fontColor(AppColors.TEXT_TERTIARY)
          }
          if (city.meetupCount && city.meetupCount > 0) {
            Text(`👥 ${city.meetupCount}`)
              .fontSize(11)
              .fontColor(AppColors.TEXT_TERTIARY)
          }
        }
      }
      .width('100%')
      .padding({ left: 10, right: 10, top: 10, bottom: 12 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('48%')
    .backgroundColor(AppColors.WHITE) // Flutter: white card
    .borderRadius(12)
    .shadow({ radius: 4, color: '#0A000000', offsetX: 0, offsetY: 2 })
    .margin({ bottom: 12 })
    .onClick(() => {
      router.pushUrl({
        url: `pages/${RouteConstants.CITY_DETAIL}`,
        params: { cityId: city.id, cityName: city.name },
      });
    })
  }

  // ===== MeetupsSection - Flutter: horizontal scroll, card 280px =====
  @Builder
  MeetupsSection() {
    Column() {
      Row() {
        Text('🍹 近期聚会')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
        Blank()
        Text('查看全部 →')
          .fontSize(14)
          .fontColor(AppColors.PRIMARY)
          .onClick(() => {
            router.pushUrl({ url: `pages/${RouteConstants.MEETUP_LIST}` });
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 24, bottom: 12 })

      if (this.meetups.length === 0 && !this.isLoading) {
        Text('暂无近期聚会')
          .fontSize(14)
          .fontColor(AppColors.TEXT_TERTIARY)
          .margin({ top: 12, bottom: 12 })
      } else {
        // 水平滚动 - Flutter: card width 280
        Scroll() {
          Row({ space: 12 }) {
            ForEach(this.meetups, (meetup: Meetup) => {
              this.MeetupCard(meetup)
            }, (meetup: Meetup) => meetup.id)
          }
          .padding({ left: 16, right: 16 })
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
      }
    }
  }

  @Builder
  MeetupCard(meetup: Meetup) {
    Column() {
      // 日期
      Row({ space: 8 }) {
        Text(meetup.startTime ? new Date(meetup.startTime).getDate().toString() : '-')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.PRIMARY)
        Text(meetup.startTime
          ? new Date(meetup.startTime).toLocaleDateString('zh-CN', { month: 'short' })
          : '')
          .fontSize(13)
          .fontColor(AppColors.TEXT_SECONDARY)
      }

      Text(meetup.title)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.TEXT_PRIMARY)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 8 })

      Text(MeetupHelper.displayLocation(meetup))
        .fontSize(13)
        .fontColor(AppColors.TEXT_SECONDARY)
        .maxLines(1)
        .margin({ top: 4 })

      Blank()

      Row({ space: 8 }) {
        Text(`👥 ${meetup.participantCount ?? 0}${meetup.maxParticipants ? '/' + meetup.maxParticipants : ''}`)
          .fontSize(12)
          .fontColor(AppColors.TEXT_TERTIARY)

        if (MeetupHelper.isStartingSoon(meetup)) {
          Text('即将开始')
            .fontSize(11)
            .fontColor(AppColors.WHITE)
            .backgroundColor(AppColors.WARNING)
            .borderRadius(4)
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
        }
      }
    }
    .width(280)
    .height(160)
    .padding(16)
    .backgroundColor(AppColors.WHITE)
    .borderRadius(12)
    .shadow({ radius: 4, color: '#0A000000', offsetX: 0, offsetY: 2 })
    .alignItems(HorizontalAlign.Start)
    .onClick(() => {
      router.pushUrl({
        url: `pages/${RouteConstants.MEETUP_DETAIL}`,
        params: { meetupId: meetup.id },
      });
    })
  }

  // ===== Feature Highlights - Flutter: emoji + text list =====
  @Builder
  FeatureHighlights() {
    Column() {
      this.FeatureItem('🏆', 'Attend meetups in cities across the world')
      this.FeatureItem('❤️', 'Meet new people for dating and friends')
      this.FeatureItem('📊', 'Research destinations to find the best place')
      this.FeatureItem('🌍', 'Keep track of your travels and plan trips')
      this.FeatureItem('💬', 'Join our exclusive community chat')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 40, bottom: 20 })
  }

  @Builder
  FeatureItem(emoji: string, text: string) {
    Row() {
      Text(emoji)
        .fontSize(24)
      Text(text)
        .fontSize(15)
        .fontColor(AppColors.TEXT_PRIMARY)
        .margin({ left: 12 })
        .layoutWeight(1)
    }
    .width('100%')
    .margin({ bottom: 12 })
    .alignItems(VerticalAlign.Top)
  }
}
