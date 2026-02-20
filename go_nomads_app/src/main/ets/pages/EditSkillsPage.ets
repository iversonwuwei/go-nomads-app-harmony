import { AppColors } from '../common/constants/AppColors';
import { HttpService } from '../services/HttpService';
import { ApiConfig } from '../common/constants/ApiConfig';
import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'EditSkillsPage';
const DOMAIN = 0x0001;

/**
 * 技能列表响应
 */
interface UserSkillsResponse {
  skills: string[];
}

/**
 * 技能更新请求体
 */
class SkillsUpdateBody {
  skills: string[] = [];
}

const PRESET_SKILLS: string[] = [
  'JavaScript', 'TypeScript', 'Python', 'Rust', 'Go', 'Swift', 'Kotlin', 'Dart',
  'React', 'Vue', 'Angular', 'Flutter', 'React Native', 'Node.js', 'Django', 'Spring',
  'UI/UX Design', 'Product Management', 'DevOps', 'Machine Learning', 'Data Science',
  'Marketing', 'Copywriting', 'SEO', 'Photography', 'Videography', 'Illustration',
  'Web3', 'Blockchain', 'Cloud Computing', 'Cybersecurity', 'Mobile Dev',
];

/**
 * 编辑技能页 — 对应 Flutter edit_skills_page.dart
 */
@Entry
@Component
struct EditSkillsPage {
  @State selectedSkills: string[] = [];
  @State customSkill: string = '';
  @State isLoading: boolean = true;
  @State isSaving: boolean = false;

  aboutToAppear(): void {
    this.loadSkills();
  }

  async loadSkills(): Promise<void> {
    this.isLoading = true;
    try {
      const httpService = HttpService.getInstance();
      const user = await httpService.get<UserSkillsResponse>(ApiConfig.USER_ME_ENDPOINT);
      this.selectedSkills = user.skills ?? [];
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ %{public}s', JSON.stringify(err));
    } finally {
      this.isLoading = false;
    }
  }

  async save(): Promise<void> {
    if (this.isSaving) return;
    this.isSaving = true;
    try {
      const httpService = HttpService.getInstance();
      const body = new SkillsUpdateBody();
      body.skills = this.selectedSkills;
      await httpService.put<Object>(ApiConfig.USER_ME_ENDPOINT, body);
      router.back();
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ 保存失败: %{public}s', JSON.stringify(err));
    } finally {
      this.isSaving = false;
    }
  }

  toggleSkill(skill: string): void {
    const idx = this.selectedSkills.indexOf(skill);
    if (idx >= 0) {
      this.selectedSkills = this.selectedSkills.filter(s => s !== skill);
    } else {
      this.selectedSkills = [...this.selectedSkills, skill];
    }
  }

  build() {
    Column() {
      // 顶部
      Row() {
        SymbolGlyph($r('sys.symbol.arrow_left'))
          .fontSize(24).fontColor([AppColors.TEXT_PRIMARY]).onClick(() => { router.back(); })
        Text('编辑技能').fontSize(18).fontWeight(FontWeight.Medium)
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
            Text(`已选 ${this.selectedSkills.length} 项技能`)
              .fontSize(14).fontColor(AppColors.TEXT_SECONDARY)

            // 自定义添加
            Row({ space: 8 }) {
              TextInput({ placeholder: '添加自定义技能', text: this.customSkill })
                .layoutWeight(1).height(40).borderRadius(8).backgroundColor('#F8FAFC')
                .onChange((v: string) => { this.customSkill = v; })
              Button('+').width(40).height(40).borderRadius(8)
                .backgroundColor(AppColors.PRIMARY).fontColor('#FFFFFF')
                .onClick(() => {
                  const s = this.customSkill.trim();
                  if (s && !this.selectedSkills.includes(s)) {
                    this.selectedSkills = [...this.selectedSkills, s];
                    this.customSkill = '';
                  }
                })
            }.width('100%')

            // 预设技能网格
            Text('推荐技能').fontSize(16).fontWeight(FontWeight.Bold).fontColor(AppColors.TEXT_PRIMARY)
            Flex({ wrap: FlexWrap.Wrap }) {
              ForEach(PRESET_SKILLS, (skill: string) => {
                Text(skill)
                  .fontSize(13)
                  .fontColor(this.selectedSkills.includes(skill) ? '#FFFFFF' : AppColors.TEXT_SECONDARY)
                  .backgroundColor(this.selectedSkills.includes(skill) ? AppColors.PRIMARY : '#F1F5F9')
                  .borderRadius(14)
                  .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                  .margin({ right: 6, bottom: 8 })
                  .onClick(async () => { await this.toggleSkill(skill); })
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
