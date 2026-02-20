import { AppColors } from '../common/constants/AppColors';
import { HttpService } from '../services/HttpService';
import { router } from '@kit.ArkUI';

@Entry
@Component
struct AddCostPage {
  @State amount: string = '';
  @State currency: string = 'USD';
  @State category: string = 'accommodation';
  @State note: string = '';
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

    const amountText = this.amount.trim();
    const currencyText = this.currency.trim().toUpperCase();
    const categoryText = this.category.trim().toLowerCase();
    const noteText = this.note.trim();

    if (!this.cityId || !amountText) {
      this.errorMessage = '请填写费用金额';
      return;
    }

    const amountValue = Number(amountText);
    if (!Number.isFinite(amountValue) || amountValue <= 0) {
      this.errorMessage = '费用金额必须为大于 0 的数字';
      return;
    }

    this.isSubmitting = true;
    this.errorMessage = '';
    try {
      await HttpService.getInstance().post<Object>(`/cities/${this.cityId}/user-content/expenses`, {
        cityId: this.cityId,
        category: categoryText.length > 0 ? categoryText : 'other',
        amount: amountValue,
        currency: currencyText.length > 0 ? currencyText : 'USD',
        description: noteText,
        date: new Date().toISOString(),
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
        Text('添加费用').fontSize(18).fontWeight(FontWeight.Medium).layoutWeight(1).textAlign(TextAlign.Center)
        Column().width(22)
      }.width('100%').height(56).padding({ left: 16, right: 16 })

      TextInput({ text: this.amount, placeholder: '金额' })
        .height(40).borderRadius(8).backgroundColor(AppColors.WHITE).padding({ left: 12, right: 12 })
        .onChange((v: string) => { this.amount = v; })
      TextInput({ text: this.currency, placeholder: '币种，例如 USD' })
        .height(40).borderRadius(8).backgroundColor(AppColors.WHITE).padding({ left: 12, right: 12 })
        .onChange((v: string) => { this.currency = v; })
      TextInput({ text: this.category, placeholder: '分类，例如 accommodation' })
        .height(40).borderRadius(8).backgroundColor(AppColors.WHITE).padding({ left: 12, right: 12 })
        .onChange((v: string) => { this.category = v; })
      TextInput({ text: this.note, placeholder: '备注' })
        .height(80).borderRadius(8).backgroundColor(AppColors.WHITE).padding({ left: 12, right: 12, top: 8 })
        .onChange((v: string) => { this.note = v; })

      if (this.errorMessage) {
        Text(this.errorMessage)
          .fontSize(13)
          .fontColor(AppColors.ERROR)
          .width('100%')
      }

      Button(this.isSubmitting ? '提交中...' : '提交费用')
        .height(42).borderRadius(10).backgroundColor(AppColors.PRIMARY).fontColor(AppColors.WHITE)
        .enabled(!this.isSubmitting)
        .onClick(async () => { await this.submit(); })
    }
    .width('100%').height('100%').padding({ left: 16, right: 16, top: 8 })
    .backgroundColor(AppColors.BACKGROUND)
  }
}
