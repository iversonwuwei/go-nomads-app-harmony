import { AppColors } from '../common/constants/AppColors';
import { AppStorageKeys } from '../common/constants/AppStorageKeys';
import { RouteConstants } from '../common/constants/RouteConstants';
import { HttpService } from '../services/HttpService';
import { ApiConfig } from '../common/constants/ApiConfig';
import { User } from '../models/User';
import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'ProfileEditPage';
const DOMAIN = 0x0001;

/**
 * 个人资料更新请求体
 */
class ProfileUpdateBody {
  name: string = '';
  bio: string = '';
  currentCity: string = '';
  currentCountry: string = '';
}

/**
 * 个人资料编辑页 — 对应 Flutter profile_edit_page.dart
 */
@Entry
@Component
struct ProfileEditPage {
  @State user: User | null = null;
  @State isLoading: boolean = true;
  @State isSaving: boolean = false;
  @State name: string = '';
  @State bio: string = '';
  @State currentCity: string = '';
  @State currentCountry: string = '';

  aboutToAppear(): void {
    this.loadProfile();
  }

  async loadProfile(): Promise<void> {
    this.isLoading = true;
    try {
      const httpService = HttpService.getInstance();
      const user = await httpService.get<User>(ApiConfig.USER_ME_ENDPOINT);
      this.user = user;
      this.name = user.name;
      this.bio = user.bio ?? '';
      this.currentCity = user.currentCity ?? '';
      this.currentCountry = user.currentCountry ?? '';
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ 加载个人信息失败: %{public}s', JSON.stringify(err));
    } finally {
      this.isLoading = false;
    }
  }

  async saveProfile(): Promise<void> {
    if (this.isSaving) return;
    this.isSaving = true;
    try {
      const httpService = HttpService.getInstance();
      const body = new ProfileUpdateBody();
      body.name = this.name;
      body.bio = this.bio;
      body.currentCity = this.currentCity;
      body.currentCountry = this.currentCountry;
      await httpService.put<Object>(ApiConfig.USER_ME_ENDPOINT, body);
      hilog.info(DOMAIN, TAG, '✅ 个人信息已保存');
      router.back();
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ 保存失败: %{public}s', JSON.stringify(err));
    } finally {
      this.isSaving = false;
    }
  }

  build() {
    Column() {
      this.TopBar()

      if (this.isLoading) {
        Column() { LoadingProgress().width(40).height(40) }
          .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column({ space: 16 }) {
            // 头像区域
            this.AvatarSection()

            // 表单
            this.FormField('昵称', this.name, (v: string) => { this.name = v; })
            this.FormTextArea('个人简介', this.bio, (v: string) => { this.bio = v; }, '介绍一下你自己...')
            this.FormField('当前城市', this.currentCity, (v: string) => { this.currentCity = v; })
            this.FormField('当前国家', this.currentCountry, (v: string) => { this.currentCountry = v; })

            // 更多编辑入口
            this.EditEntryItem('🎯 技能', () => {
              router.pushUrl({ url: `pages/${RouteConstants.EDIT_SKILLS}` });
            })
            this.EditEntryItem('💡 兴趣', () => {
              router.pushUrl({ url: `pages/${RouteConstants.EDIT_INTERESTS}` });
            })
            this.EditEntryItem('🔗 社交链接', () => {
              router.pushUrl({ url: `pages/${RouteConstants.EDIT_SOCIAL_LINKS}` });
            })

            Column().height(40)
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 16 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BACKGROUND)
  }

  @Builder
  TopBar() {
    Row() {
      Text('取消')
        .fontSize(16)
        .fontColor(AppColors.TEXT_SECONDARY)
        .onClick(() => { router.back(); })

      Text('编辑资料')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.TEXT_PRIMARY)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      Button('保存')
        .height(34)
        .fontSize(14)
        .borderRadius(17)
        .backgroundColor(AppColors.PRIMARY)
        .fontColor('#FFFFFF')
        .enabled(!this.isSaving)
        .onClick(() => { this.saveProfile(); })
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor(AppColors.CARD_BACKGROUND)
  }

  @Builder
  AvatarSection() {
    Column({ space: 8 }) {
      if (this.user?.avatarUrl) {
        Image(this.user.avatarUrl)
          .width(80).height(80).borderRadius(40).objectFit(ImageFit.Cover)
      } else {
        Text('👤')
          .fontSize(40).width(80).height(80)
          .textAlign(TextAlign.Center)
          .backgroundColor('#F1F5F9').borderRadius(40)
      }
      Text('更换头像')
        .fontSize(14).fontColor(AppColors.PRIMARY)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .padding({ top: 8, bottom: 8 })
  }

  @Builder
  FormField(label: string, value: string, onChange: (v: string) => void) {
    Column({ space: 6 }) {
      Text(label).fontSize(14).fontColor(AppColors.TEXT_SECONDARY)
      TextInput({ text: value })
        .width('100%').height(44).borderRadius(8)
        .backgroundColor('#F8FAFC')
        .padding({ left: 12, right: 12 })
        .onChange(onChange)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  FormTextArea(label: string, value: string, onChange: (v: string) => void, placeholder: string) {
    Column({ space: 6 }) {
      Text(label).fontSize(14).fontColor(AppColors.TEXT_SECONDARY)
      TextArea({ text: value, placeholder: placeholder })
        .width('100%').height(100).borderRadius(8)
        .backgroundColor('#F8FAFC')
        .padding(12)
        .onChange(onChange)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  EditEntryItem(title: string, onClick: () => void) {
    Row() {
      Text(title)
        .fontSize(15).fontColor(AppColors.TEXT_PRIMARY).layoutWeight(1)
      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(16).fontColor([AppColors.TEXT_TERTIARY])
    }
    .width('100%').height(52).padding({ left: 4, right: 4 })
    .onClick(onClick)
  }
}
