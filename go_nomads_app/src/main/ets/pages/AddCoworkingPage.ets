import { AppColors } from '../common/constants/AppColors';
import { ApiConfig } from '../common/constants/ApiConfig';
import { HttpService } from '../services/HttpService';
import { router } from '@kit.ArkUI';

interface CoworkingPayload {
  name: string;
  city: string;
  address: string;
  wifiSpeedMbps: number;
}

@Entry
@Component
struct AddCoworkingPage {
  @State name: string = '';
  @State city: string = '';
  @State address: string = '';
  @State wifiMbps: string = '';
  @State isSubmitting: boolean = false;
  @State errorMessage: string = '';

  async submit(): Promise<void> {
    if (this.isSubmitting) {
      return;
    }

    const nameText = this.name.trim();
    const cityText = this.city.trim();
    const addressText = this.address.trim();
    const wifiText = this.wifiMbps.trim();
    const wifiValue = wifiText.length > 0 ? Number(wifiText) : 0;

    if (!nameText || !cityText) {
      this.errorMessage = '请填写名称和城市';
      return;
    }
    if (!Number.isFinite(wifiValue) || wifiValue < 0) {
      this.errorMessage = '网速必须为不小于 0 的数字';
      return;
    }

    this.isSubmitting = true;
    this.errorMessage = '';
    try {
      const payload: CoworkingPayload = {
        name: nameText,
        city: cityText,
        address: addressText,
        wifiSpeedMbps: wifiValue,
      };
      await HttpService.getInstance().post<Object>(ApiConfig.COWORKING_SPACES_ENDPOINT, payload as Object);
      router.back();
    } catch (_err) {
      this.errorMessage = '提交失败，请稍后重试';
    } finally {
      this.isSubmitting = false;
    }
  }

  build() {
    Column({ space: 12 }) {
      Row() {
        SymbolGlyph($r('sys.symbol.arrow_left')).fontSize(24).fontColor([AppColors.TEXT_PRIMARY]).onClick(() => { router.back(); })
        Text('添加共享办公').fontSize(18).fontWeight(FontWeight.Medium).layoutWeight(1).textAlign(TextAlign.Center)
        Column().width(24)
      }.width('100%').height(56).padding({ left: 16, right: 16 })

      TextInput({ text: this.name, placeholder: '名称' })
        .height(40).borderRadius(8).backgroundColor(AppColors.WHITE).padding({ left: 12, right: 12 })
        .onChange((v: string) => { this.name = v; })
      TextInput({ text: this.city, placeholder: '城市' })
        .height(40).borderRadius(8).backgroundColor(AppColors.WHITE).padding({ left: 12, right: 12 })
        .onChange((v: string) => { this.city = v; })
      TextInput({ text: this.address, placeholder: '地址' })
        .height(40).borderRadius(8).backgroundColor(AppColors.WHITE).padding({ left: 12, right: 12 })
        .onChange((v: string) => { this.address = v; })
      TextInput({ text: this.wifiMbps, placeholder: '网速 Mbps' })
        .height(40).borderRadius(8).backgroundColor(AppColors.WHITE).padding({ left: 12, right: 12 })
        .onChange((v: string) => { this.wifiMbps = v; })

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
