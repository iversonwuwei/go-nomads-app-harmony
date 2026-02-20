import { AppColors } from '../common/constants/AppColors';
import { HttpService } from '../services/HttpService';
import { router } from '@kit.ArkUI';

@Entry
@Component
struct AddReviewPage {
  @State rating: string = '5';
  @State title: string = '';
  @State content: string = '';
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

    const titleText = this.title.trim();
    const contentText = this.content.trim();
    const ratingValue = Number(this.rating.trim());

    if (!this.cityId || !titleText || !contentText) {
      this.errorMessage = '请填写完整评论信息';
      return;
    }

    if (!Number.isFinite(ratingValue) || ratingValue < 1 || ratingValue > 5) {
      this.errorMessage = '评分必须在 1 到 5 之间';
      return;
    }

    this.isSubmitting = true;
    this.errorMessage = '';
    try {
      await HttpService.getInstance().post<Object>(`/cities/${this.cityId}/user-content/reviews`, {
        cityId: this.cityId,
        rating: Math.round(ratingValue),
        title: titleText,
        content: contentText,
      });
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
        Text('添加评论').fontSize(18).fontWeight(FontWeight.Medium).layoutWeight(1).textAlign(TextAlign.Center)
        Column().width(22)
      }.width('100%').height(56).padding({ left: 16, right: 16 })

      TextInput({ text: this.rating, placeholder: '评分 1-5' })
        .height(40).borderRadius(8).backgroundColor(AppColors.WHITE).padding({ left: 12, right: 12 })
        .onChange((v: string) => { this.rating = v; })
      TextInput({ text: this.title, placeholder: '标题' })
        .height(40).borderRadius(8).backgroundColor(AppColors.WHITE).padding({ left: 12, right: 12 })
        .onChange((v: string) => { this.title = v; })
      TextInput({ text: this.content, placeholder: '内容' })
        .height(120).borderRadius(8).backgroundColor(AppColors.WHITE).padding({ left: 12, right: 12, top: 8 })
        .onChange((v: string) => { this.content = v; })

      if (this.errorMessage) {
        Text(this.errorMessage)
          .fontSize(13)
          .fontColor(AppColors.ERROR)
          .width('100%')
      }

      Button(this.isSubmitting ? '提交中...' : '提交评论')
        .height(42).borderRadius(10).backgroundColor(AppColors.PRIMARY).fontColor(AppColors.WHITE)
        .enabled(!this.isSubmitting)
        .onClick(async () => { await this.submit(); })
    }
    .width('100%').height('100%').padding({ left: 16, right: 16, top: 8 })
    .backgroundColor(AppColors.BACKGROUND)
  }
}
