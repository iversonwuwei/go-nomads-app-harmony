import { AppColors } from '../common/constants/AppColors';
import { HttpService } from '../services/HttpService';
import { router } from '@kit.ArkUI';

interface ProsConsPayload {
  cityId: string;
  text: string;
  isPro: boolean;
}

@Entry
@Component
struct AddProsConsPage {
  @State text: string = '';
  @State isPro: boolean = true;
  @State isSubmitting: boolean = false;
  @State errorMessage: string = '';
  private cityId: string = '';

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>;
    this.cityId = params?.['cityId'] ?? '';
  }

  async submit(): Promise<void> {
    if (this.isSubmitting) {
      return;
    }

    const textValue = this.text.trim();
    if (!this.cityId || !textValue) {
      this.errorMessage = '请输入内容';
      return;
    }
    this.isSubmitting = true;
    this.errorMessage = '';
    try {
      const payload: ProsConsPayload = {
        cityId: this.cityId,
        text: textValue,
        isPro: this.isPro,
      };
      await HttpService.getInstance().post<Object>(`/cities/${this.cityId}/user-content/pros-cons`, payload as Object);
      router.back();
    } catch (err) {
      this.errorMessage = '提交失败，请稍后重试';
    } finally {
      this.isSubmitting = false;
    }
  }

  build() {
    Column({ space: 12 }) {
      Row() {
        SymbolGlyph($r('sys.symbol.xmark')).fontSize(22).fontColor([AppColors.TEXT_PRIMARY]).onClick(() => { router.back(); })
        Text('添加优缺点').fontSize(18).fontWeight(FontWeight.Medium).layoutWeight(1).textAlign(TextAlign.Center)
        Column().width(22)
      }.width('100%').height(56).padding({ left: 16, right: 16 })

      Row({ space: 8 }) {
        Button('优点')
          .layoutWeight(1)
          .height(36)
          .borderRadius(8)
          .backgroundColor(this.isPro ? AppColors.SUCCESS : AppColors.WHITE)
          .fontColor(this.isPro ? AppColors.WHITE : AppColors.TEXT_PRIMARY)
          .onClick(() => { this.isPro = true; })
        Button('挑战')
          .layoutWeight(1)
          .height(36)
          .borderRadius(8)
          .backgroundColor(!this.isPro ? AppColors.ERROR : AppColors.WHITE)
          .fontColor(!this.isPro ? AppColors.WHITE : AppColors.TEXT_PRIMARY)
          .onClick(() => { this.isPro = false; })
      }
      TextInput({ text: this.text, placeholder: this.isPro ? '请输入优点内容' : '请输入挑战内容' })
        .height(140).borderRadius(8).backgroundColor(AppColors.WHITE).padding({ left: 12, right: 12, top: 8 })
        .onChange((v: string) => { this.text = v; })

      if (this.errorMessage) {
        Text(this.errorMessage)
          .fontSize(13)
          .fontColor(AppColors.ERROR)
          .width('100%')
      }

      Button(this.isSubmitting ? '提交中...' : '提交')
        .height(42).borderRadius(10).backgroundColor(AppColors.PRIMARY).fontColor(AppColors.WHITE)
        .enabled(!this.isSubmitting)
        .onClick(async () => { await this.submit(); })
    }
    .width('100%').height('100%').padding({ left: 16, right: 16, top: 8 })
    .backgroundColor(AppColors.BACKGROUND)
  }
}
