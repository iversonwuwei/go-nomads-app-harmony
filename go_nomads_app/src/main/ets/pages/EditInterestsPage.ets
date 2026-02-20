import { AppColors } from '../common/constants/AppColors';
import { HttpService } from '../services/HttpService';
import { ApiConfig } from '../common/constants/ApiConfig';
import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'EditInterestsPage';
const DOMAIN = 0x0001;

/**
 * 兴趣列表响应
 */
interface UserInterestsResponse {
  interests: string[];
}

/**
 * 兴趣更新请求体
 */
class InterestsUpdateBody {
  interests: string[] = [];
}

const PRESET_INTERESTS: string[] = [
  '远程办公', '数字游民', '旅行摄影', '徒步', '冲浪', '潜水', '攀岩',
  '瑜伽', '冥想', '咖啡', '美食', '烹饪', '阅读', '写作', '博客',
  '播客', '电影', '音乐', '绘画', '手工', '语言学习', '文化交流',
  '创业', '投资', '加密货币', '可持续发展', '志愿活动', '社区建设',
  '健身', '跑步', '骑行', '滑雪', '帆船', '野营',
];

/**
 * 编辑兴趣页 — 对应 Flutter edit_interests_page.dart
 */
@Entry
@Component
struct EditInterestsPage {
  @State selectedInterests: string[] = [];
  @State customInterest: string = '';
  @State isLoading: boolean = true;
  @State isSaving: boolean = false;

  aboutToAppear(): void { this.loadData(); }

  async loadData(): Promise<void> {
    this.isLoading = true;
    try {
      const httpService = HttpService.getInstance();
      const user = await httpService.get<UserInterestsResponse>(ApiConfig.USER_ME_ENDPOINT);
      this.selectedInterests = user.interests ?? [];
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ %{public}s', JSON.stringify(err));
    } finally { this.isLoading = false; }
  }

  async save(): Promise<void> {
    if (this.isSaving) return;
    this.isSaving = true;
    try {
      const httpService = HttpService.getInstance();
      const body = new InterestsUpdateBody();
      body.interests = this.selectedInterests;
      await httpService.put<Object>(ApiConfig.USER_ME_ENDPOINT, body);
      router.back();
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ %{public}s', JSON.stringify(err));
    } finally { this.isSaving = false; }
  }

  toggle(item: string): void {
    const idx = this.selectedInterests.indexOf(item);
    if (idx >= 0) {
      this.selectedInterests = this.selectedInterests.filter(s => s !== item);
    } else {
      this.selectedInterests = [...this.selectedInterests, item];
    }
  }

  build() {
    Column() {
      Row() {
        SymbolGlyph($r('sys.symbol.arrow_left'))
          .fontSize(24).fontColor([AppColors.TEXT_PRIMARY]).onClick(() => { router.back(); })
        Text('编辑兴趣').fontSize(18).fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT_PRIMARY).layoutWeight(1).textAlign(TextAlign.Center)
        Button('保存').height(34).fontSize(14).borderRadius(17)
          .backgroundColor(AppColors.PRIMARY).fontColor('#FFFFFF')
          .enabled(!this.isSaving).onClick(async () => { await this.save(); })
      }
      .width('100%').height(56).padding({ left: 16, right: 16 })
      .backgroundColor(AppColors.CARD_BACKGROUND)

      if (this.isLoading) {
        Column() { LoadingProgress().width(40).height(40) }
          .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column({ space: 16 }) {
            Text(`已选 ${this.selectedInterests.length} 项兴趣`)
              .fontSize(14).fontColor(AppColors.TEXT_SECONDARY)

            Row({ space: 8 }) {
              TextInput({ placeholder: '添加自定义兴趣', text: this.customInterest })
                .layoutWeight(1).height(40).borderRadius(8).backgroundColor('#F8FAFC')
                .onChange((v: string) => { this.customInterest = v; })
              Button('+').width(40).height(40).borderRadius(8)
                .backgroundColor(AppColors.PRIMARY).fontColor('#FFFFFF')
                .onClick(() => {
                  const s = this.customInterest.trim();
                  if (s && !this.selectedInterests.includes(s)) {
                    this.selectedInterests = [...this.selectedInterests, s];
                    this.customInterest = '';
                  }
                })
            }.width('100%')

            Text('推荐兴趣').fontSize(16).fontWeight(FontWeight.Bold).fontColor(AppColors.TEXT_PRIMARY)
            Flex({ wrap: FlexWrap.Wrap }) {
              ForEach(PRESET_INTERESTS, (item: string) => {
                Text(item)
                  .fontSize(13)
                  .fontColor(this.selectedInterests.includes(item) ? '#FFFFFF' : AppColors.TEXT_SECONDARY)
                  .backgroundColor(this.selectedInterests.includes(item) ? AppColors.PRIMARY : '#F1F5F9')
                  .borderRadius(14)
                  .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                  .margin({ right: 6, bottom: 8 })
                  .onClick(async () => { await this.toggle(item); })
              }, (s: string) => s)
            }
            Column().height(40)
          }
          .padding({ left: 16, right: 16, top: 16 })
        }
        .layoutWeight(1).scrollBar(BarState.Off)
      }
    }
    .width('100%').height('100%').backgroundColor(AppColors.BACKGROUND)
  }
}
