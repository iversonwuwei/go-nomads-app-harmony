import { AppColors } from '../common/constants/AppColors';
import { AppStorageKeys } from '../common/constants/AppStorageKeys';
import { RouteConstants } from '../common/constants/RouteConstants';
import { HttpService } from '../services/HttpService';
import { ApiConfig } from '../common/constants/ApiConfig';
import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'TravelPlanPage';
const DOMAIN = 0x0001;

interface TravelPlan {
  id: string;
  title: string;
  status: string; // 'draft' | 'planned' | 'active' | 'completed'
  startDate?: string;
  endDate?: string;
  destinations: TravelDestination[];
  coverImageUrl?: string;
}

interface TravelDestination {
  cityName: string;
  country: string;
  arrivalDate?: string;
  departureDate?: string;
}

/**
 * 旅行计划页 — 对应 Flutter travel_plan_page.dart
 */
@Entry
@Component
struct TravelPlanPage {
  @State plans: TravelPlan[] = [];
  @State isLoading: boolean = true;
  @State selectedFilter: string = '全部';
  @StorageProp(AppStorageKeys.IS_AUTHENTICATED) isAuthenticated: boolean = false;

  private filters: string[] = ['全部', '计划中', '进行中', '已完成'];

  aboutToAppear(): void {
    if (this.isAuthenticated) { this.loadPlans(); }
  }

  async loadPlans(): Promise<void> {
    this.isLoading = true;
    try {
      const httpService = HttpService.getInstance();
      this.plans = await httpService.get<TravelPlan[]>(ApiConfig.TRAVEL_PLANS_ENDPOINT);
      hilog.info(DOMAIN, TAG, '✅ 加载 %{public}d 个旅行计划', this.plans.length);
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ %{public}s', JSON.stringify(err));
    } finally { this.isLoading = false; }
  }

  getFilteredPlans(): TravelPlan[] {
    switch (this.selectedFilter) {
      case '计划中': return this.plans.filter(p => p.status === 'planned');
      case '进行中': return this.plans.filter(p => p.status === 'active');
      case '已完成': return this.plans.filter(p => p.status === 'completed');
      default: return this.plans;
    }
  }

  build() {
    Column() {
      // 顶部
      Row() {
        SymbolGlyph($r('sys.symbol.arrow_left'))
          .fontSize(24).fontColor([AppColors.TEXT_PRIMARY]).onClick(() => { router.back(); })
        Text('旅行计划').fontSize(18).fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT_PRIMARY).layoutWeight(1).textAlign(TextAlign.Center)
        Button('+').width(34).height(34).borderRadius(17)
          .backgroundColor(AppColors.PRIMARY).fontColor('#FFFFFF')
          .onClick(() => { router.pushUrl({ url: `pages/${RouteConstants.CREATE_TRAVEL_PLAN}` }); })
      }
      .width('100%').height(56).padding({ left: 16, right: 16 })
      .backgroundColor(AppColors.CARD_BACKGROUND)

      // 筛选
      Scroll() {
        Row({ space: 8 }) {
          ForEach(this.filters, (f: string) => {
            Text(f).fontSize(13)
              .fontColor(this.selectedFilter === f ? '#FFFFFF' : AppColors.TEXT_SECONDARY)
              .backgroundColor(this.selectedFilter === f ? AppColors.PRIMARY : '#F1F5F9')
              .borderRadius(16).padding({ left: 14, right: 14, top: 6, bottom: 6 })
              .onClick(() => { this.selectedFilter = f; })
          }, (f: string) => f)
        }.padding({ left: 16, right: 16, top: 12, bottom: 12 })
      }
      .scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off).width('100%')

      if (!this.isAuthenticated) {
        Column({ space: 12 }) {
          Text('✈️').fontSize(48)
          Text('登录后管理旅行计划').fontSize(16).fontColor(AppColors.TEXT_SECONDARY)
          Button('去登录').width(120).height(40).borderRadius(20)
            .backgroundColor(AppColors.PRIMARY).fontColor('#FFFFFF')
            .onClick(() => { router.pushUrl({ url: `pages/${RouteConstants.LOGIN}` }); })
        }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else if (this.isLoading) {
        Column() { LoadingProgress().width(40).height(40) }
          .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else if (this.getFilteredPlans().length === 0) {
        Column({ space: 12 }) {
          Text('✈️').fontSize(48)
          Text('还没有旅行计划').fontSize(16).fontColor(AppColors.TEXT_SECONDARY)
          Text('创建你的第一个旅行计划吧').fontSize(14).fontColor(AppColors.TEXT_TERTIARY)
          Button('创建计划').height(40).borderRadius(20)
            .backgroundColor(AppColors.PRIMARY).fontColor('#FFFFFF')
            .onClick(() => { router.pushUrl({ url: `pages/${RouteConstants.CREATE_TRAVEL_PLAN}` }); })
        }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        List() {
          ForEach(this.getFilteredPlans(), (plan: TravelPlan) => {
            ListItem() { this.PlanCard(plan) }
          }, (plan: TravelPlan) => plan.id)
        }
        .layoutWeight(1).padding({ left: 16, right: 16 })
        .divider({ strokeWidth: 0 }).edgeEffect(EdgeEffect.Spring)
      }
    }
    .width('100%').height('100%').backgroundColor(AppColors.BACKGROUND)
  }

  @Builder
  PlanCard(plan: TravelPlan) {
    Column() {
      // 封面
      if (plan.coverImageUrl) {
        Image(plan.coverImageUrl)
          .width('100%').height(120).objectFit(ImageFit.Cover)
          .borderRadius({ topLeft: 12, topRight: 12 })
      }
      Column({ space: 6 }) {
        Row() {
          Text(plan.title).fontSize(16).fontWeight(FontWeight.Bold)
            .fontColor(AppColors.TEXT_PRIMARY).layoutWeight(1)
            .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(this.statusLabel(plan.status)).fontSize(11)
            .fontColor(this.statusColor(plan.status))
            .backgroundColor(`${this.statusColor(plan.status)}18`)
            .borderRadius(4).padding({ left: 6, right: 6, top: 2, bottom: 2 })
        }.width('100%')

        if (plan.startDate) {
          Text(`📅 ${plan.startDate}${plan.endDate ? ' → ' + plan.endDate : ''}`)
            .fontSize(13).fontColor(AppColors.TEXT_SECONDARY)
        }

        if (plan.destinations.length > 0) {
          Text(`📍 ${plan.destinations.map(d => d.cityName).join(' → ')}`)
            .fontSize(13).fontColor(AppColors.TEXT_TERTIARY).maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .width('100%').padding({ left: 14, right: 14, top: plan.coverImageUrl ? 10 : 14, bottom: 14 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%').backgroundColor(AppColors.CARD_BACKGROUND).borderRadius(12)
    .shadow({ radius: 4, color: '#0000000A', offsetX: 0, offsetY: 2 }).margin({ bottom: 12 })
  }

  statusLabel(status: string): string {
    switch (status) {
      case 'draft': return '草稿';
      case 'planned': return '计划中';
      case 'active': return '进行中';
      case 'completed': return '已完成';
      default: return status;
    }
  }

  statusColor(status: string): string {
    switch (status) {
      case 'active': return AppColors.PRIMARY;
      case 'completed': return AppColors.SUCCESS;
      case 'planned': return AppColors.WARNING;
      default: return AppColors.TEXT_TERTIARY;
    }
  }
}
