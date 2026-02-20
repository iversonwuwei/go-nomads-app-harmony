import { AppColors } from '../common/constants/AppColors';
import { RouteConstants } from '../common/constants/RouteConstants';
import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'CreateTravelPlanPage';
const DOMAIN = 0x0001;

@Entry
@Component
struct CreateTravelPlanPage {
  @State cityName: string = '';
  @State cityId: string = '';
  @State departureLocation: string = '';
  @State departureDate: string = '';
  @State duration: number = 7;
  @State budget: string = 'medium';
  @State customBudget: string = '';
  @State selectedCurrency: string = 'USD';
  @State travelStyle: string = 'culture';
  @State selectedInterests: string[] = [];
  @State selectedAttractions: string[] = [];
  @State errorMessage: string = '';
  @State isSubmitting: boolean = false;

  private readonly durationOptions: number[] = [3, 5, 7, 10, 14];
  private readonly budgetOptions: Array<{ key: string; label: string }> = [
    { key: 'low', label: 'Budget' },
    { key: 'medium', label: 'Moderate' },
    { key: 'high', label: 'Luxury' },
    { key: 'custom', label: 'Custom' },
  ];
  private readonly currencyOptions: string[] = ['USD', 'CNY', 'EUR', 'JPY'];
  private readonly styleOptions: Array<{ key: string; label: string; emoji: string }> = [
    { key: 'culture', label: '文化探索', emoji: '🏛️' },
    { key: 'adventure', label: '冒险体验', emoji: '🏕️' },
    { key: 'relaxation', label: '放松疗愈', emoji: '🏖️' },
    { key: 'nightlife', label: '夜生活', emoji: '🌃' },
  ];
  private readonly interestOptions: string[] = [
    '历史古迹',
    '博物馆',
    '城市漫步',
    '咖啡馆',
    '夜生活',
    '当地美食',
    '自然徒步',
    '拍照打卡',
    '亲子友好',
    '创意市集',
  ];
  private readonly attractionOptions: Array<{ id: string; label: string }> = [
    { id: 'historic', label: '历史古迹' },
    { id: 'museum', label: '博物馆' },
    { id: 'park', label: '公园绿地' },
    { id: 'food_district', label: '美食街区' },
    { id: 'shopping_mall', label: '购物中心' },
    { id: 'art_gallery', label: '艺术画廊' },
    { id: 'viewpoint', label: '观景台' },
    { id: 'night_market', label: '夜市' },
  ];

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>;
    if (params) {
      this.cityId = params['cityId'] ?? '';
      this.cityName = params['cityName'] ?? '';
    }
  }

  private toggleInterest(interest: string): void {
    const idx = this.selectedInterests.indexOf(interest);
    if (idx >= 0) {
      this.selectedInterests.splice(idx, 1);
      this.selectedInterests = [...this.selectedInterests];
    } else {
      this.selectedInterests.push(interest);
      this.selectedInterests = [...this.selectedInterests];
    }
  }

  private toggleAttraction(id: string): void {
    const idx = this.selectedAttractions.indexOf(id);
    if (idx >= 0) {
      this.selectedAttractions.splice(idx, 1);
      this.selectedAttractions = [...this.selectedAttractions];
    } else {
      this.selectedAttractions.push(id);
      this.selectedAttractions = [...this.selectedAttractions];
    }
  }

  private validate(): boolean {
    this.cityName = this.cityName.trim();
    this.departureLocation = this.departureLocation.trim();
    this.departureDate = this.departureDate.trim();
    this.customBudget = this.customBudget.trim();

    if (!this.cityName) {
      this.errorMessage = '请输入目的地城市';
      return false;
    }
    if (!this.departureDate) {
      this.errorMessage = '请输入出发日期（YYYY-MM-DD）';
      return false;
    }
    if (!/^\d{4}-\d{2}-\d{2}$/.test(this.departureDate)) {
      this.errorMessage = '出发日期格式不正确，请使用 YYYY-MM-DD';
      return false;
    }
    if (this.budget === 'custom' && !this.customBudget) {
      this.errorMessage = '请输入自定义预算金额';
      return false;
    }
    if (this.budget === 'custom') {
      const custom = Number(this.customBudget);
      if (!Number.isFinite(custom) || custom <= 0) {
        this.errorMessage = '自定义预算必须为大于 0 的数字';
        return false;
      }
    }
    if (this.selectedInterests.length === 0) {
      this.errorMessage = '请至少选择一个兴趣标签';
      return false;
    }
    this.errorMessage = '';
    return true;
  }

  submit(): void {
    if (this.isSubmitting) {
      return;
    }
    if (!this.validate()) {
      return;
    }

    this.isSubmitting = true;
    hilog.info(DOMAIN, TAG, '🚀 开始生成旅行计划, city=%{public}s', this.cityName);
    router.pushUrl({
      url: `pages/${RouteConstants.TRAVEL_PLAN}`,
      params: {
        cityId: this.cityId,
        cityName: this.cityName,
        duration: this.duration,
        budget: this.budget,
        travelStyle: this.travelStyle,
        interests: this.selectedInterests,
        selectedAttractions: this.selectedAttractions,
        departureLocation: this.departureLocation,
        departureDate: this.departureDate,
        customBudget: this.customBudget,
        selectedCurrency: this.selectedCurrency,
      },
    });
    this.isSubmitting = false;
  }

  build() {
    Column() {
      Row() {
        SymbolGlyph($r('sys.symbol.arrow_left'))
          .fontSize(24)
          .fontColor([AppColors.TEXT_PRIMARY])
          .onClick(() => {
            router.back();
          })
        Text('创建旅行计划')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT_PRIMARY)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        Column().width(24)
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor(AppColors.CARD_BACKGROUND)

      Scroll() {
        Column({ space: 14 }) {
          this.HeaderCard()

          this.FormField('目的地城市', this.cityName, (v: string) => {
            this.cityName = v;
          }, '例：大阪 / Chiang Mai')

          this.FormField('出发地', this.departureLocation, (v: string) => {
            this.departureLocation = v;
          }, '例：上海市浦东新区')

          this.FormField('出发日期', this.departureDate, (v: string) => {
            this.departureDate = v;
          }, 'YYYY-MM-DD')

          this.DurationSection()

          this.BudgetSection()

          if (this.budget === 'custom') {
            this.FormField('自定义预算', this.customBudget, (v: string) => {
              this.customBudget = v;
            }, '例：3000')

            this.CurrencySection()
          }

          this.StyleSection()

          this.InterestsSection()

          this.AttractionsSection()

          if (this.errorMessage) {
            Text(this.errorMessage)
              .fontSize(13)
              .fontColor('#DC2626')
              .width('100%')
          }

          Button(this.isSubmitting ? '跳转中...' : '生成旅行计划')
            .width('100%')
            .height(44)
            .borderRadius(12)
            .backgroundColor(AppColors.PRIMARY)
            .fontColor(AppColors.WHITE)
            .enabled(!this.isSubmitting)
            .onClick(async () => {
              await this.submit();
            })

          Column().height(40)
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 16 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BACKGROUND)
  }

  @Builder
  HeaderCard() {
    Column({ space: 8 }) {
      Text('🤖 AI Travel Planner')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.WHITE)
      Text('告诉我你的偏好，我会生成更贴合你的每日行程与预算建议。')
        .fontSize(13)
        .fontColor('#FFEFF2')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding({ left: 14, right: 14, top: 14, bottom: 14 })
    .backgroundColor(AppColors.PRIMARY)
    .borderRadius(12)
  }

  @Builder
  FormField(label: string, value: string, onChange: (v: string) => void, placeholder: string) {
    Column({ space: 8 }) {
      Text(label)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.TEXT_PRIMARY)
      TextInput({ text: value, placeholder: placeholder })
        .width('100%')
        .height(44)
        .borderRadius(10)
        .backgroundColor(AppColors.WHITE)
        .border({ width: 1, color: AppColors.BORDER_LIGHT })
        .padding({ left: 12, right: 12 })
        .fontSize(14)
        .onChange((v: string) => {
          onChange(v);
        })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  DurationSection() {
    Column({ space: 8 }) {
      Text('行程天数')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.TEXT_PRIMARY)

      Row({ space: 8 }) {
        ForEach(this.durationOptions, (item: number) => {
          Text(`${item}天`)
            .fontSize(13)
            .fontColor(this.duration === item ? AppColors.WHITE : AppColors.TEXT_SECONDARY)
            .backgroundColor(this.duration === item ? AppColors.PRIMARY : '#F1F5F9')
            .borderRadius(16)
            .padding({ left: 12, right: 12, top: 7, bottom: 7 })
            .onClick(() => {
              this.duration = item;
            })
        }, (item: number) => `duration-${item}`)
      }
      .width('100%')
      .flexWrap(FlexWrap.Wrap)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  BudgetSection() {
    Column({ space: 8 }) {
      Text('预算等级')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.TEXT_PRIMARY)

      Row({ space: 8 }) {
        ForEach(this.budgetOptions, (item: { key: string; label: string }) => {
          Text(item.label)
            .fontSize(13)
            .fontColor(this.budget === item.key ? AppColors.WHITE : AppColors.TEXT_SECONDARY)
            .backgroundColor(this.budget === item.key ? AppColors.PRIMARY : '#F1F5F9')
            .borderRadius(16)
            .padding({ left: 12, right: 12, top: 7, bottom: 7 })
            .onClick(() => {
              this.budget = item.key;
              if (this.budget !== 'custom') {
                this.customBudget = '';
              }
            })
        }, (item: { key: string; label: string }) => `budget-${item.key}`)
      }
      .width('100%')
      .flexWrap(FlexWrap.Wrap)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  CurrencySection() {
    Column({ space: 8 }) {
      Text('币种')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.TEXT_PRIMARY)

      Row({ space: 8 }) {
        ForEach(this.currencyOptions, (item: string) => {
          Text(item)
            .fontSize(13)
            .fontColor(this.selectedCurrency === item ? AppColors.WHITE : AppColors.TEXT_SECONDARY)
            .backgroundColor(this.selectedCurrency === item ? AppColors.PRIMARY : '#F1F5F9')
            .borderRadius(16)
            .padding({ left: 12, right: 12, top: 7, bottom: 7 })
            .onClick(() => {
              this.selectedCurrency = item;
            })
        }, (item: string) => `currency-${item}`)
      }
      .width('100%')
      .flexWrap(FlexWrap.Wrap)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  StyleSection() {
    Column({ space: 8 }) {
      Text('旅行风格')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.TEXT_PRIMARY)

      Row({ space: 8 }) {
        ForEach(this.styleOptions, (item: { key: string; label: string; emoji: string }) => {
          Text(`${item.emoji} ${item.label}`)
            .fontSize(13)
            .fontColor(this.travelStyle === item.key ? AppColors.WHITE : AppColors.TEXT_SECONDARY)
            .backgroundColor(this.travelStyle === item.key ? AppColors.PRIMARY : '#F1F5F9')
            .borderRadius(16)
            .padding({ left: 12, right: 12, top: 7, bottom: 7 })
            .onClick(() => {
              this.travelStyle = item.key;
            })
        }, (item: { key: string; label: string; emoji: string }) => `style-${item.key}`)
      }
      .width('100%')
      .flexWrap(FlexWrap.Wrap)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  InterestsSection() {
    Column({ space: 8 }) {
      Text('兴趣偏好（可多选）')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.TEXT_PRIMARY)

      Row({ space: 8 }) {
        ForEach(this.interestOptions, (item: string) => {
          Text(item)
            .fontSize(13)
            .fontColor(this.selectedInterests.indexOf(item) >= 0 ? AppColors.WHITE : AppColors.TEXT_SECONDARY)
            .backgroundColor(this.selectedInterests.indexOf(item) >= 0 ? AppColors.PRIMARY : '#F1F5F9')
            .borderRadius(16)
            .padding({ left: 12, right: 12, top: 7, bottom: 7 })
            .onClick(async () => {
              await this.toggleInterest(item);
            })
        }, (item: string) => `interest-${item}`)
      }
      .width('100%')
      .flexWrap(FlexWrap.Wrap)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  AttractionsSection() {
    Column({ space: 8 }) {
      Text('想去的景点（可多选）')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.TEXT_PRIMARY)

      Row({ space: 8 }) {
        ForEach(this.attractionOptions, (item: { id: string; label: string }) => {
          const selected = this.selectedAttractions.indexOf(item.id) >= 0;
          Text(item.label)
            .fontSize(13)
            .fontColor(selected ? AppColors.WHITE : AppColors.TEXT_SECONDARY)
            .backgroundColor(selected ? AppColors.PRIMARY : '#F1F5F9')
            .borderRadius(16)
            .padding({ left: 12, right: 12, top: 7, bottom: 7 })
            .onClick(async () => {
              await this.toggleAttraction(item.id);
            })
        }, (item: { id: string; label: string }) => `attraction-${item.id}`)
      }
      .width('100%')
      .flexWrap(FlexWrap.Wrap)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
}
