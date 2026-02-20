import { AppColors } from '../common/constants/AppColors';
import { HttpService } from '../services/HttpService';
import { ApiConfig } from '../common/constants/ApiConfig';
import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'EditSocialLinksPage';
const DOMAIN = 0x0001;

/**
 * 社交链接数据
 */
interface SocialLinksData {
  twitter?: string;
  instagram?: string;
  linkedin?: string;
  github?: string;
  website?: string;
  wechat?: string;
}

/**
 * 社交链接响应
 */
interface UserSocialLinksResponse {
  socialLinks?: SocialLinksData;
}

/**
 * 社交链接更新请求体
 */
class SocialLinksUpdateBody {
  socialLinks: SocialLinksData = {};
}

/**
 * 编辑社交链接页 — 对应 Flutter edit_social_links_page.dart
 */
@Entry
@Component
struct EditSocialLinksPage {
  @State twitter: string = '';
  @State instagram: string = '';
  @State linkedin: string = '';
  @State github: string = '';
  @State website: string = '';
  @State wechat: string = '';
  @State isLoading: boolean = true;
  @State isSaving: boolean = false;

  aboutToAppear(): void { this.loadData(); }

  async loadData(): Promise<void> {
    this.isLoading = true;
    try {
      const httpService = HttpService.getInstance();
      const user = await httpService.get<UserSocialLinksResponse>(ApiConfig.USER_ME_ENDPOINT);
      const links = user.socialLinks;
      if (links) {
        this.twitter = links.twitter ?? '';
        this.instagram = links.instagram ?? '';
        this.linkedin = links.linkedin ?? '';
        this.github = links.github ?? '';
        this.website = links.website ?? '';
        this.wechat = links.wechat ?? '';
      }
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ %{public}s', JSON.stringify(err));
    } finally { this.isLoading = false; }
  }

  async save(): Promise<void> {
    if (this.isSaving) return;
    this.isSaving = true;
    try {
      const httpService = HttpService.getInstance();
      const linksData: SocialLinksData = {
        twitter: this.twitter || undefined,
        instagram: this.instagram || undefined,
        linkedin: this.linkedin || undefined,
        github: this.github || undefined,
        website: this.website || undefined,
        wechat: this.wechat || undefined,
      };
      const body = new SocialLinksUpdateBody();
      body.socialLinks = linksData;
      await httpService.put<Object>(ApiConfig.USER_ME_ENDPOINT, body);
      router.back();
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ %{public}s', JSON.stringify(err));
    } finally { this.isSaving = false; }
  }

  build() {
    Column() {
      Row() {
        SymbolGlyph($r('sys.symbol.arrow_left'))
          .fontSize(24).fontColor([AppColors.TEXT_PRIMARY]).onClick(() => { router.back(); })
        Text('社交链接').fontSize(18).fontWeight(FontWeight.Medium)
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
            this.LinkField('𝕏 Twitter', this.twitter, 'https://twitter.com/...', (v: string) => { this.twitter = v; })
            this.LinkField('📷 Instagram', this.instagram, 'https://instagram.com/...', (v: string) => { this.instagram = v; })
            this.LinkField('💼 LinkedIn', this.linkedin, 'https://linkedin.com/in/...', (v: string) => { this.linkedin = v; })
            this.LinkField('🐙 GitHub', this.github, 'https://github.com/...', (v: string) => { this.github = v; })
            this.LinkField('🌐 个人网站', this.website, 'https://...', (v: string) => { this.website = v; })
            this.LinkField('💬 微信号', this.wechat, '微信号', (v: string) => { this.wechat = v; })
            Column().height(40)
          }
          .padding({ left: 16, right: 16, top: 16 })
        }
        .layoutWeight(1).scrollBar(BarState.Off)
      }
    }
    .width('100%').height('100%').backgroundColor(AppColors.BACKGROUND)
  }

  @Builder
  LinkField(label: string, value: string, placeholder: string, onChange: (v: string) => void) {
    Column({ space: 6 }) {
      Text(label).fontSize(14).fontColor(AppColors.TEXT_SECONDARY)
      TextInput({ text: value, placeholder: placeholder })
        .width('100%').height(44).borderRadius(8).backgroundColor('#F8FAFC')
        .padding({ left: 12, right: 12 }).onChange(onChange)
    }
    .width('100%').alignItems(HorizontalAlign.Start)
  }
}
