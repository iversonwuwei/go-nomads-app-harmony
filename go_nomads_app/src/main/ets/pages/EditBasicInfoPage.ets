import { AppColors } from '../common/constants/AppColors';
import { UserService } from '../services/UserService';
import { router } from '@kit.ArkUI';

@Entry
@Component
struct EditBasicInfoPage {
  @State name: string = '';
  @State bio: string = '';
  @State currentCity: string = '';
  @State currentCountry: string = '';
  @State isSaving: boolean = false;
  @State errorMessage: string = '';
  private userId: string = '';

  async aboutToAppear(): Promise<void> {
    try {
      const user = await UserService.getInstance().getCurrentUser();
      this.userId = user.id;
      this.name = user.name;
      this.bio = user.bio ?? '';
      this.currentCity = user.currentCity ?? '';
      this.currentCountry = user.currentCountry ?? '';
      this.errorMessage = '';
    } catch (_err) {
      this.errorMessage = '加载用户信息失败，请稍后重试';
    }
  }

  async save(): Promise<void> {
    if (this.isSaving) return;
    if (!this.userId) return;

    this.name = this.name.trim();
    this.bio = this.bio.trim();
    this.currentCity = this.currentCity.trim();
    this.currentCountry = this.currentCountry.trim();
    if (!this.name) {
      this.errorMessage = '姓名不能为空';
      return;
    }

    this.isSaving = true;
    this.errorMessage = '';
    try {
      const payload: Record<string, Object> = {};
      payload['name'] = this.name as Object;
      payload['bio'] = this.bio as Object;
      payload['currentCity'] = this.currentCity as Object;
      payload['currentCountry'] = this.currentCountry as Object;
      await UserService.getInstance().updateUser(this.userId, payload);
      router.back();
    } catch (_err) {
      this.errorMessage = '保存失败，请稍后重试';
    } finally {
      this.isSaving = false;
    }
  }

  build() {
    Column({ space: 12 }) {
      Row() {
        SymbolGlyph($r('sys.symbol.arrow_left')).fontSize(24).fontColor([AppColors.TEXT_PRIMARY]).onClick(() => { router.back(); })
        Text('编辑基本信息').fontSize(18).fontWeight(FontWeight.Medium).layoutWeight(1).textAlign(TextAlign.Center)
        Column().width(24)
      }.width('100%').height(56).padding({ left: 16, right: 16 })

      TextInput({ text: this.name, placeholder: '姓名' })
        .height(40).borderRadius(8).backgroundColor(AppColors.WHITE).padding({ left: 12, right: 12 })
        .onChange((v: string) => { this.name = v; })
      TextInput({ text: this.bio, placeholder: '简介' })
        .height(80).borderRadius(8).backgroundColor(AppColors.WHITE).padding({ left: 12, right: 12, top: 8 })
        .onChange((v: string) => { this.bio = v; })
      TextInput({ text: this.currentCity, placeholder: '当前城市' })
        .height(40).borderRadius(8).backgroundColor(AppColors.WHITE).padding({ left: 12, right: 12 })
        .onChange((v: string) => { this.currentCity = v; })
      TextInput({ text: this.currentCountry, placeholder: '当前国家' })
        .height(40).borderRadius(8).backgroundColor(AppColors.WHITE).padding({ left: 12, right: 12 })
        .onChange((v: string) => { this.currentCountry = v; })

      if (this.errorMessage) {
        Text(this.errorMessage)
          .fontSize(13)
          .fontColor(AppColors.ERROR)
          .width('100%')
      }

      Button(this.isSaving ? '保存中...' : '保存')
        .height(42).borderRadius(10).backgroundColor(AppColors.PRIMARY).fontColor(AppColors.WHITE)
        .enabled(!this.isSaving)
        .onClick(async () => { await this.save(); })
    }
    .width('100%').height('100%').padding({ left: 16, right: 16, top: 8 })
    .backgroundColor(AppColors.BACKGROUND)
  }
}
