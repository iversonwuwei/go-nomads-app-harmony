import { router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AppColors } from '../common/constants/AppColors';
import { AppStorageKeys } from '../common/constants/AppStorageKeys';
import { RouteConstants } from '../common/constants/RouteConstants';
import { AuthService } from '../services/AuthService';
import { TokenStorageService } from '../services/TokenStorageService';

const TAG = 'LoginPage';
const DOMAIN = 0x0001;

enum LoginMode {
  Email = 'email',
  Phone = 'phone',
}

@Entry
@Component
struct LoginPage {
  @State email: string = '';
  @State password: string = '';
  @State phone: string = '';
  @State smsCode: string = '';

  @State rememberMe: boolean = false;
  @State isPasswordVisible: boolean = false;
  @State isLoading: boolean = false;
  @State errorMessage: string = '';
  @State loginMode: LoginMode = LoginMode.Email;
  @State smsCountdown: number = 0;

  private countdownTimerId: number = -1;

  async aboutToAppear(): Promise<void> {
    const tokenService = TokenStorageService.getInstance();
    const ctx = getContext(this) as common.UIAbilityContext;
    tokenService.bindContext(ctx);

    if (!tokenService.isInitialized()) {
      try {
        await tokenService.init(ctx);
      } catch (err) {
        hilog.error(DOMAIN, TAG, '❌ TokenStorage 初始化失败: %{public}s', JSON.stringify(err));
        this.errorMessage = '本地存储初始化失败，请重启应用';
        return;
      }
    }

    this.rememberMe = tokenService.isRememberMe();
    const savedEmail = tokenService.getSavedEmail();
    if (savedEmail) {
      this.email = savedEmail;
    }
  }

  aboutToDisappear(): void {
    this.clearCountdownTimer();
  }

  private clearCountdownTimer(): void {
    if (this.countdownTimerId >= 0) {
      clearInterval(this.countdownTimerId);
      this.countdownTimerId = -1;
    }
  }

  private isChineseUser(): boolean {
    const locale = AppStorage.get<string>(AppStorageKeys.CURRENT_LOCALE);
    if (!locale) {
      return true;
    }

    const lower = locale.toLowerCase();
    return lower.indexOf('zh') >= 0
      || lower.indexOf('cn') >= 0
      || lower.indexOf('hk') >= 0
      || lower.indexOf('mo') >= 0
      || lower.indexOf('tw') >= 0;
  }

  private setLoginMode(mode: LoginMode): void {
    this.loginMode = mode;
    this.errorMessage = '';
  }

  private buildPhoneNumberForApi(): string {
    const value = this.phone.trim();
    if (value.startsWith('+')) {
      return value;
    }
    return `+86${value}`;
  }

  private validatePhoneNumber(): boolean {
    const rawPhone = this.phone.trim();
    if (!rawPhone) {
      this.errorMessage = '请输入手机号';
      return false;
    }

    const digitsOnly = rawPhone.replace(/\D/g, '');
    if (digitsOnly.length < 11) {
      this.errorMessage = '请输入正确的手机号';
      return false;
    }

    return true;
  }

  private startSmsCountdown(): void {
    this.smsCountdown = 60;
    this.clearCountdownTimer();

    this.countdownTimerId = setInterval(() => {
      if (this.smsCountdown <= 1) {
        this.smsCountdown = 0;
        this.clearCountdownTimer();
      } else {
        this.smsCountdown = this.smsCountdown - 1;
      }
    }, 1000);
  }

  private buildFallbackOpenId(provider: string): string {
    return `${provider}_harmony_${Date.now()}`;
  }

  private resolveErrorMessage(err: Object, fallback: string): string {
    if (err instanceof Error) {
      const msg = err.message ? err.message.trim() : '';
      if (msg.length > 0) {
        return msg;
      }
    }
    const text = JSON.stringify(err);
    if (text && text !== '{}' && text !== '""') {
      return text;
    }
    return fallback;
  }

  async sendSmsCode(): Promise<void> {
    if (!this.validatePhoneNumber()) {
      return;
    }

    this.isLoading = true;
    this.errorMessage = '';

    try {
      await AuthService.getInstance().sendSmsCode(this.buildPhoneNumberForApi(), 'login');
      this.startSmsCountdown();
      this.errorMessage = '验证码已发送，请注意查收';
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ 发送验证码失败: %{public}s', JSON.stringify(err));
      this.errorMessage = this.resolveErrorMessage(err as Object, '发送验证码失败，请稍后重试');
    } finally {
      this.isLoading = false;
    }
  }

  async doEmailLogin(): Promise<void> {
    if (!this.email || !this.password) {
      this.errorMessage = '请输入邮箱和密码';
      return;
    }

    this.isLoading = true;
    this.errorMessage = '';

    try {
      await AuthService.getInstance().login(this.email, this.password, this.rememberMe);
      hilog.info(DOMAIN, TAG, '✅ 邮箱登录成功: %{public}s', this.email);
      router.replaceUrl({ url: `pages/${RouteConstants.MAIN}` });
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ 邮箱登录失败: %{public}s', JSON.stringify(err));
      this.errorMessage = this.resolveErrorMessage(err as Object, '登录失败，请检查邮箱和密码');
    } finally {
      this.isLoading = false;
    }
  }

  async doPhoneLogin(): Promise<void> {
    if (!this.validatePhoneNumber()) {
      return;
    }

    if (!this.smsCode.trim()) {
      this.errorMessage = '请输入验证码';
      return;
    }

    this.isLoading = true;
    this.errorMessage = '';

    try {
      await AuthService.getInstance().loginWithPhone(this.buildPhoneNumberForApi(), this.smsCode.trim());
      hilog.info(DOMAIN, TAG, '✅ 手机号登录成功');
      router.replaceUrl({ url: `pages/${RouteConstants.MAIN}` });
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ 手机号登录失败: %{public}s', JSON.stringify(err));
      this.errorMessage = this.resolveErrorMessage(err as Object, '登录失败，请检查验证码是否正确');
    } finally {
      this.isLoading = false;
    }
  }

  async doSocialLogin(provider: string, label: string): Promise<void> {
    if (provider === 'phone') {
      this.setLoginMode(LoginMode.Phone);
      return;
    }

    if (provider === 'facebook') {
      this.errorMessage = 'Facebook 登录即将上线';
      return;
    }

    if (provider === 'google' || provider === 'twitter') {
      this.errorMessage = `${label} 登录待接入授权 SDK`; 
      return;
    }

    this.isLoading = true;
    this.errorMessage = '';

    try {
      await AuthService.getInstance().socialLogin(
        provider,
        undefined,
        undefined,
        this.buildFallbackOpenId(provider)
      );
      hilog.info(DOMAIN, TAG, '✅ 社交登录成功: %{public}s', provider);
      router.replaceUrl({ url: `pages/${RouteConstants.MAIN}` });
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ 社交登录失败: %{public}s', JSON.stringify(err));
      this.errorMessage = this.resolveErrorMessage(err as Object, `${label} 登录失败，请稍后重试`);
    } finally {
      this.isLoading = false;
    }
  }

  @Builder
  LoginModeSwitch() {
    Row({ space: 8 }) {
      this.ModeButton('邮箱登录', LoginMode.Email)
      this.ModeButton('手机号登录', LoginMode.Phone)
    }
    .width('100%')
    .margin({ bottom: 20 })
  }

  @Builder
  ModeButton(label: string, mode: LoginMode) {
    Button(label)
      .layoutWeight(1)
      .height(42)
      .borderRadius(10)
      .backgroundColor(this.loginMode === mode ? AppColors.PRIMARY : AppColors.WHITE)
      .fontColor(this.loginMode === mode ? AppColors.WHITE : AppColors.TEXT_PRIMARY)
      .border({ width: 1, color: this.loginMode === mode ? AppColors.PRIMARY : AppColors.GREY300 })
      .onClick(() => {
        this.setLoginMode(mode);
      })
  }

  @Builder
  EmailForm() {
    Column({ space: 20 }) {
      TextInput({ placeholder: '邮箱', text: this.email })
        .type(InputType.Email)
        .width('100%')
        .height(52)
        .borderRadius(12)
        .backgroundColor(AppColors.WHITE)
        .border({ width: 1, color: AppColors.GREY300 })
        .padding({ left: 16, right: 16 })
        .onChange((value: string) => {
          this.email = value;
        })

      TextInput({ placeholder: '密码', text: this.password })
        .type(this.isPasswordVisible ? InputType.Normal : InputType.Password)
        .width('100%')
        .height(52)
        .borderRadius(12)
        .backgroundColor(AppColors.WHITE)
        .border({ width: 1, color: AppColors.GREY300 })
        .padding({ left: 16, right: 16 })
        .onChange((value: string) => {
          this.password = value;
        })

      Row() {
        Row() {
          Checkbox()
            .select(this.rememberMe)
            .selectedColor(AppColors.PRIMARY)
            .onChange((value: boolean) => {
              this.rememberMe = value;
            })
          Text('记住我')
            .fontSize(14)
            .fontColor(AppColors.TEXT_BLACK87)
            .margin({ left: 4 })
        }

        Blank()

        Text(this.isPasswordVisible ? '隐藏密码' : '显示密码')
          .fontSize(14)
          .fontColor(AppColors.PRIMARY)
          .fontWeight(FontWeight.Bold)
          .onClick(() => {
            this.isPasswordVisible = !this.isPasswordVisible;
          })
      }
      .width('100%')

      Button(this.isLoading ? '登录中...' : '登录')
        .width('100%')
        .height(52)
        .borderRadius(12)
        .backgroundColor(AppColors.PRIMARY)
        .fontColor(AppColors.WHITE)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .enabled(!this.isLoading)
        .onClick(() => {
          this.doEmailLogin();
        })
    }
    .width('100%')
  }

  @Builder
  PhoneForm() {
    Column({ space: 20 }) {
      TextInput({ placeholder: '手机号', text: this.phone })
        .type(InputType.PhoneNumber)
        .width('100%')
        .height(52)
        .borderRadius(12)
        .backgroundColor(AppColors.WHITE)
        .border({ width: 1, color: AppColors.GREY300 })
        .padding({ left: 16, right: 16 })
        .onChange((value: string) => {
          this.phone = value;
        })

      Row({ space: 12 }) {
        TextInput({ placeholder: '验证码', text: this.smsCode })
          .type(InputType.Number)
          .maxLength(6)
          .layoutWeight(1)
          .height(52)
          .borderRadius(12)
          .backgroundColor(AppColors.WHITE)
          .border({ width: 1, color: AppColors.GREY300 })
          .padding({ left: 16, right: 16 })
          .onChange((value: string) => {
            this.smsCode = value;
          })

        Button(this.smsCountdown > 0 ? `${this.smsCountdown}s` : '发送验证码')
          .height(52)
          .borderRadius(12)
          .backgroundColor(AppColors.PRIMARY)
          .fontColor(AppColors.WHITE)
          .enabled(!this.isLoading && this.smsCountdown === 0)
          .onClick(() => {
            this.sendSmsCode();
          })
      }
      .width('100%')

      Button(this.isLoading ? '登录中...' : '登录')
        .width('100%')
        .height(52)
        .borderRadius(12)
        .backgroundColor(AppColors.PRIMARY)
        .fontColor(AppColors.WHITE)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .enabled(!this.isLoading)
        .onClick(() => {
          this.doPhoneLogin();
        })

      Text('使用邮箱密码登录')
        .fontSize(14)
        .fontColor(AppColors.PRIMARY)
        .fontWeight(FontWeight.Medium)
        .textAlign(TextAlign.Center)
        .width('100%')
        .onClick(() => {
          this.setLoginMode(LoginMode.Email);
        })
    }
    .width('100%')
  }

  @Builder
  SocialButtons() {
    Column() {
      Row() {
        Line().width('35%').height(1).backgroundColor(AppColors.GREY300)
        Text('Or continue with')
          .fontSize(14)
          .fontColor(AppColors.GREY600)
          .margin({ left: 16, right: 16 })
        Line().width('35%').height(1).backgroundColor(AppColors.GREY300)
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .margin({ top: 8, bottom: 24 })

      if (this.isChineseUser()) {
        Row({ space: 12 }) {
          this.SocialButton('微信', 'wechat', AppColors.WECHAT_GREEN)
          this.SocialButton('QQ', 'qq', '#12B7F5')
        }
        .width('100%')

        Row() {
          this.SocialButton('手机号', 'phone', AppColors.PHONE_GREEN)
        }
        .width('50%')
        .margin({ top: 12 })
      } else {
        Row({ space: 12 }) {
          this.SocialButton('Google', 'google', AppColors.GOOGLE_RED)
          this.SocialButton('Twitter', 'twitter', AppColors.TEXT_BLACK87)
          this.SocialButton('Facebook', 'facebook', AppColors.FACEBOOK_BLUE)
        }
        .width('100%')

        Row() {
          this.SocialButton('Phone', 'phone', AppColors.PHONE_GREEN)
        }
        .width('50%')
        .margin({ top: 12 })
      }
    }
    .width('100%')
  }

  @Builder
  SocialButton(label: string, provider: string, iconColor: string) {
    Column() {
      Text(label.charAt(0))
        .fontSize(28)
        .fontColor(iconColor)
        .fontWeight(FontWeight.Bold)
      Text(label)
        .fontSize(12)
        .fontColor(AppColors.GREY700)
        .fontWeight(FontWeight.Medium)
        .margin({ top: 6 })
    }
    .layoutWeight(1)
    .padding({ top: 12, bottom: 12, left: 8, right: 8 })
    .borderRadius(12)
    .backgroundColor(AppColors.WHITE)
    .border({ width: 1, color: AppColors.GREY200 })
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      this.doSocialLogin(provider, label);
    })
  }

  @Builder
  FeatureBadge(emoji: string, text: string) {
    Column() {
      Text(emoji)
        .fontSize(20)
      Text(text)
        .fontSize(11)
        .fontColor(AppColors.GREY700)
        .fontWeight(FontWeight.Medium)
        .margin({ top: 4 })
        .textAlign(TextAlign.Center)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .layoutWeight(1)
    .padding({ top: 12, bottom: 12, left: 8, right: 8 })
    .borderRadius(8)
    .backgroundColor(AppColors.WHITE)
    .border({ width: 1, color: AppColors.GREY200 })
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }

  build() {
    Scroll() {
      Column() {
        Column() {
          Column() {
            SymbolGlyph($r('sys.symbol.globe_badge_heart'))
              .fontSize(40)
              .fontColor([AppColors.PRIMARY])
          }
          .width(80)
          .height(80)
          .borderRadius(40)
          .backgroundColor('#1AFF4458')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)

          Text('Welcome')
            .fontSize(32)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.TEXT_BLACK87)
            .margin({ top: 24 })

          Text('登录')
            .fontSize(16)
            .fontColor(AppColors.TEXT_TERTIARY)
            .margin({ top: 12 })
            .textAlign(TextAlign.Center)
        }
        .margin({ top: 60, bottom: 32 })
        .alignItems(HorizontalAlign.Center)

        Column() {
          this.LoginModeSwitch()

          if (this.loginMode === LoginMode.Email) {
            this.EmailForm()
          } else {
            this.PhoneForm()
          }

          if (this.errorMessage) {
            Text(this.errorMessage)
              .fontSize(14)
              .fontColor(this.errorMessage.indexOf('已发送') >= 0 ? AppColors.SUCCESS : AppColors.ERROR)
              .width('100%')
              .margin({ top: 12 })
          }
        }
        .width('100%')
        .padding({ left: 24, right: 24 })

        if (this.loginMode === LoginMode.Email) {
          Column() {
            this.SocialButtons()
          }
          .width('100%')
          .padding({ left: 24, right: 24 })
          .margin({ top: 16 })
        }

        Column() {
          Row() {
            Column() {
              SymbolGlyph($r('sys.symbol.person_3'))
                .fontSize(24)
                .fontColor([AppColors.PRIMARY])
            }
            .width(40)
            .height(40)
            .borderRadius(8)
            .backgroundColor('#1AFF4458')
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)

            Column() {
              Text('Join 38,000+ nomads')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor(AppColors.TEXT_BLACK87)
              Text('Living and working around the world')
                .fontSize(13)
                .fontColor(AppColors.GREY600)
                .margin({ top: 2 })
            }
            .alignItems(HorizontalAlign.Start)
            .margin({ left: 12 })
            .layoutWeight(1)
          }
          .width('100%')

          Row({ space: 8 }) {
            this.FeatureBadge('🍹', '363 meetups/yr')
            this.FeatureBadge('💬', '15k+ messages')
            this.FeatureBadge('🌍', '100+ cities')
          }
          .width('100%')
          .margin({ top: 16 })
        }
        .width('100%')
        .padding(20)
        .margin({ left: 24, right: 24, top: 32 })
        .borderRadius(16)
        .backgroundColor(AppColors.GREY50)
        .border({ width: 1, color: AppColors.GREY200 })

        Row() {
          Text("Let's Go")
            .fontSize(15)
            .fontColor(AppColors.TEXT_BLACK87)
          Text(' ')
            .width(8)
          Text('Register')
            .fontSize(15)
            .fontColor(AppColors.PRIMARY)
            .fontWeight(FontWeight.Bold)
            .onClick(() => {
              router.pushUrl({ url: `pages/${RouteConstants.REGISTER}` });
            })
        }
        .margin({ top: 32, bottom: 40 })
        .justifyContent(FlexAlign.Center)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BACKGROUND)
    .scrollable(ScrollDirection.Vertical)
  }
}
