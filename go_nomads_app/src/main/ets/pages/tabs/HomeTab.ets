import { City, CityHelper } from '../../models/City';
import { Meetup, MeetupHelper, MeetupStatus } from '../../models/Meetup';
import { HttpService } from '../../services/HttpService';
import { ApiConfig } from '../../common/constants/ApiConfig';
import { AppColors } from '../../common/constants/AppColors';
import { RouteConstants } from '../../common/constants/RouteConstants';
import { AppStorageKeys } from '../../common/constants/AppStorageKeys';
import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'HomeTab';
const DOMAIN = 0x0001;

/**
 * 首页 Tab 内容 - 对应 Flutter 端 HomePage
 * 包含 Hero 区域、搜索栏、城市网格、聚会列表等
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

      // 并行加载城市和聚会数据
      const citiesPromise = httpService.get<City[]>(ApiConfig.CITY_LIST_ENDPOINT, {
        queryParams: { 'pageSize': '12', 'page': '1' },
      });
      const meetupsPromise = httpService.get<Meetup[]>(ApiConfig.MEETUPS_ENDPOINT, {
        queryParams: { 'pageSize': '5', 'status': 'published' },
      });

      const results = await Promise.all<Object>([
        citiesPromise.catch((): City[] => []),
        meetupsPromise.catch((): Meetup[] => []),
      ]);

      const cities = results[0] as City[];
      const meetups = results[1] as Meetup[];

      this.cities = cities;
      this.meetups = meetups;
      hilog.info(DOMAIN, TAG, '✅ 首页数据加载完成: %{public}d 城市, %{public}d 聚会',
        cities.length, meetups.length);
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ 首页数据加载失败: %{public}s', JSON.stringify(err));
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Scroll() {
      Column() {
        // Hero 区域
        this.HeroSection()

        // 搜索栏
        this.SearchBar()

        // 快速入口
        this.QuickEntrySection()

        // AI Chat 入口
        this.AiEntryCard()

        // 推荐城市
        this.CitiesSection()

        // 近期聚会
        this.MeetupsSection()

        // 底部间距
        Column().height(80)
      }
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
  }

  // ============================================================
  // Hero 区域 - 深色背景 + Logo + 副标题
  // ============================================================
  @Builder
  HeroSection() {
    Column() {
      // Logo
      Row({ space: 12 }) {
        Text('🌍')
          .fontSize(32)
        Text('行途 GO-NOMADS')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
      }
      .margin({ top: 60 })

      // 副标题
      Text('加入全球数字游民社区\n探索世界，自由工作')
        .fontSize(16)
        .fontColor('#FFFFFFCC')
        .textAlign(TextAlign.Center)
        .lineHeight(24)
        .margin({ top: 16, bottom: 32 })
    }
    .width('100%')
    .padding({ left: 24, right: 24, top: 20, bottom: 32 })
    .linearGradient({
      direction: GradientDirection.Top,
      colors: [['#1a1a2e', 0.0], ['#16213e', 1.0]],
    })
  }

  // ============================================================
  // 搜索栏
  // ============================================================
  @Builder
  SearchBar() {
    Row() {
      SymbolGlyph($r('sys.symbol.magnifyingglass'))
        .fontSize(20)
        .fontColor([AppColors.TEXT_TERTIARY])

      TextInput({ placeholder: '搜索城市、国家...', text: this.searchQuery })
        .layoutWeight(1)
        .backgroundColor('transparent')
        .borderRadius(0)
        .height(40)
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
    }
    .width('100%')
    .height(48)
    .borderRadius(24)
    .backgroundColor('#F1F5F9')
    .padding({ left: 16, right: 16 })
    .margin({ left: 16, right: 16, top: 16, bottom: 8 })
  }

  // ============================================================
  // 快速入口（城市列表、全球地图、AI聊天、收藏）
  // ============================================================
  @Builder
  QuickEntrySection() {
    Row() {
      this.QuickEntryItem('🏙️', '城市', () => {
        // 切换到城市列表 Tab
        AppStorage.set(AppStorageKeys.CURRENT_TAB_INDEX, 1);
      })
      this.QuickEntryItem('🗺️', '地图', () => {
        router.pushUrl({ url: `pages/${RouteConstants.GLOBAL_MAP}` });
      })
      this.QuickEntryItem('🤖', 'AI助手', () => {
        router.pushUrl({ url: `pages/${RouteConstants.AI_CHAT}` });
      })
      this.QuickEntryItem('❤️', '收藏', () => {
        router.pushUrl({ url: `pages/${RouteConstants.FAVORITES}` });
      })
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceEvenly)
    .padding({ top: 12, bottom: 12 })
  }

  @Builder
  QuickEntryItem(icon: string, label: string, onClick: () => void) {
    Column({ space: 6 }) {
      Text(icon)
        .fontSize(28)
      Text(label)
        .fontSize(12)
        .fontColor(AppColors.TEXT_SECONDARY)
    }
    .onClick(onClick)
    .padding(8)
  }

  // ============================================================
  // AI Chat 入口卡片
  // ============================================================
  @Builder
  AiEntryCard() {
    Row() {
      Column({ space: 4 }) {
        Text('AI 旅行助手')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
        Text('让 AI 帮你规划下一段旅程')
          .fontSize(13)
          .fontColor('#FFFFFFCC')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Text('💬')
        .fontSize(32)
    }
    .width('100%')
    .padding(16)
    .margin({ left: 16, right: 16, top: 8, bottom: 8 })
    .borderRadius(12)
    .linearGradient({
      direction: GradientDirection.Right,
      colors: [[AppColors.PRIMARY, 0.0], [AppColors.PRIMARY_DARK, 1.0]],
    })
    .onClick(() => {
      router.pushUrl({ url: `pages/${RouteConstants.AI_CHAT}` });
    })
  }

  // ============================================================
  // 推荐城市网格
  // ============================================================
  @Builder
  CitiesSection() {
    Column() {
      // 标题行
      Row() {
        Text('推荐城市')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
        Blank()
        Text('查看全部 →')
          .fontSize(14)
          .fontColor(AppColors.PRIMARY)
          .onClick(() => {
            AppStorage.set(AppStorageKeys.CURRENT_TAB_INDEX, 1);
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 12 })

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
        // 城市网格 2列
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
      // 城市图片
      Stack() {
        Image(CityHelper.landscapeImageUrl(city) || $r('app.media.startIcon'))
          .width('100%')
          .height(120)
          .objectFit(ImageFit.Cover)
          .borderRadius({ topLeft: 10, topRight: 10 })

        // 评分标签
        if (city.overallScore && city.overallScore > 0) {
          Text(`⭐ ${city.overallScore.toFixed(1)}`)
            .fontSize(11)
            .fontColor('#FFFFFF')
            .backgroundColor('#00000066')
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

        // 标签
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
      .padding({ left: 8, right: 8, top: 8, bottom: 10 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('48%')
    .backgroundColor(AppColors.CARD_BACKGROUND)
    .borderRadius(10)
    .shadow({ radius: 4, color: '#0000000A', offsetX: 0, offsetY: 2 })
    .margin({ bottom: 12 })
    .onClick(() => {
      router.pushUrl({
        url: `pages/${RouteConstants.CITY_DETAIL}`,
        params: { cityId: city.id, cityName: city.name },
      });
    })
  }

  // ============================================================
  // 近期聚会
  // ============================================================
  @Builder
  MeetupsSection() {
    Column() {
      // 标题
      Row() {
        Text('近期聚会')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
        Blank()
        Text('查看全部 →')
          .fontSize(14)
          .fontColor(AppColors.PRIMARY)
          .onClick(() => {
            AppStorage.set(AppStorageKeys.CURRENT_TAB_INDEX, 2);
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
        ForEach(this.meetups.slice(0, 3), (meetup: Meetup) => {
          this.MeetupCard(meetup)
        }, (meetup: Meetup) => meetup.id)
      }
    }
  }

  @Builder
  MeetupCard(meetup: Meetup) {
    Row() {
      // 左侧日期
      Column({ space: 2 }) {
        Text(new Date(meetup.schedule.startTime).getDate().toString())
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.PRIMARY)
        Text(new Date(meetup.schedule.startTime).toLocaleDateString('zh-CN', { month: 'short' }))
          .fontSize(12)
          .fontColor(AppColors.TEXT_SECONDARY)
      }
      .width(56)
      .justifyContent(FlexAlign.Center)

      // 右侧信息
      Column({ space: 4 }) {
        Text(meetup.title)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT_PRIMARY)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(meetup.venue.name)
          .fontSize(13)
          .fontColor(AppColors.TEXT_SECONDARY)
          .maxLines(1)

        Row({ space: 8 }) {
          Text(`👥 ${meetup.capacity.current}${meetup.capacity.max ? '/' + meetup.capacity.max : ''}`)
            .fontSize(12)
            .fontColor(AppColors.TEXT_TERTIARY)

          if (MeetupHelper.isStartingSoon(meetup)) {
            Text('即将开始')
              .fontSize(11)
              .fontColor('#FFFFFF')
              .backgroundColor(AppColors.WARNING)
              .borderRadius(4)
              .padding({ left: 6, right: 6, top: 1, bottom: 1 })
          }
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .padding({ left: 12 })
    }
    .width('100%')
    .padding(12)
    .margin({ left: 16, right: 16, bottom: 8 })
    .backgroundColor(AppColors.CARD_BACKGROUND)
    .borderRadius(10)
    .shadow({ radius: 4, color: '#0000000A', offsetX: 0, offsetY: 1 })
    .onClick(() => {
      router.pushUrl({
        url: `pages/${RouteConstants.MEETUP_DETAIL}`,
        params: { meetupId: meetup.id },
      });
    })
  }
}
