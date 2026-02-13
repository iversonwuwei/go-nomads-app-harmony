import { AppColors } from '../common/constants/AppColors';
import { RouteConstants } from '../common/constants/RouteConstants';
import { AuthService } from '../services/AuthService';
import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'RegisterPage';
const DOMAIN = 0x0001;

/**
 * 注册页面 - 100% 还原 Flutter register_page.dart
 *
 * Flutter 结构:
 *   RegisterHeader → 80x80 circle logo + "🌍 Go Nomad" 32px + subtitle
 *   RegisterForm → 4 fields (user/email/pwd/confirm) radius 12
 *   RegisterTermsCheckbox → checkbox + terms links
 *   RegisterSubmitButton → "Join Nomads" #FF4458
 *   RegisterLoginLink → "Already have an account?" + "Login"
 *   RegisterFeatureHighlights → 5 emoji+title+subtitle items
 */
@Entry
@Component
struct RegisterPage {
  @State userName: string = '';
  @State email: string = '';
  @State password: string = '';
  @State confirmPassword: string = '';
  @State isLoading: boolean = false;
  @State errorMessage: string = '';
  @State agreeTerms: boolean = false;
  @State isPasswordVisible: boolean = false;
  @State isConfirmPasswordVisible: boolean = false;

  async doRegister(): Promise<void> {
    if (!this.agreeTerms) {
      this.errorMessage = '请先同意服务条款';
      return;
    }
    if (!this.userName || !this.email || !this.password) {
      this.errorMessage = '请填写所有必填项';
      return;
    }
    if (this.password !== this.confirmPassword) {
      this.errorMessage = '两次输入的密码不一致';
      return;
    }
    if (this.password.length < 6) {
      this.errorMessage = '密码至少6位';
      return;
    }

    this.isLoading = true;
    this.errorMessage = '';

    try {
      await AuthService.getInstance().register(this.userName, this.email, this.password);
      hilog.info(DOMAIN, TAG, '✅ 注册成功');
      router.replaceUrl({ url: `pages/${RouteConstants.MAIN}` });
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ 注册失败: %{public}s', JSON.stringify(err));
      this.errorMessage = '注册失败，请稍后再试';
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Scroll() {
      Column() {
        // ===== RegisterHeader: 80x80 circle + "🌍 Go Nomad" 32px =====
        Column() {
          // Logo 圆形容器
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

          Text('🌍 Go Nomad')
            .fontSize(32)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.TEXT_BLACK87)
            .margin({ top: 24 })

          Text('加入全球数字游民社区')
            .fontSize(16)
            .fontColor(AppColors.TEXT_TERTIARY)
            .margin({ top: 12 })
            .textAlign(TextAlign.Center)
        }
        .alignItems(HorizontalAlign.Center)
        .margin({ top: 40, bottom: 48 })

        // ===== RegisterForm: 4 fields radius 12 =====
        Column({ space: 20 }) {
          // 用户名
          TextInput({ placeholder: '用户名', text: this.userName })
            .width('100%')
            .height(52)
            .borderRadius(12)
            .backgroundColor(AppColors.WHITE)
            .border({ width: 1, color: AppColors.GREY300 })
            .padding({ left: 16, right: 16 })
            .onChange((value: string) => {
              this.userName = value;
            })

          // 邮箱
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

          // 密码
          TextInput({ placeholder: '创建密码', text: this.password })
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

          // 确认密码
          TextInput({ placeholder: '确认密码', text: this.confirmPassword })
            .type(this.isConfirmPasswordVisible ? InputType.Normal : InputType.Password)
            .width('100%')
            .height(52)
            .borderRadius(12)
            .backgroundColor(AppColors.WHITE)
            .border({ width: 1, color: AppColors.GREY300 })
            .padding({ left: 16, right: 16 })
            .onChange((value: string) => {
              this.confirmPassword = value;
            })
        }
        .width('100%')
        .padding({ left: 24, right: 24 })

        // ===== RegisterTermsCheckbox =====
        Row() {
          Checkbox()
            .select(this.agreeTerms)
            .selectedColor(AppColors.PRIMARY)
            .onChange((value: boolean) => {
              this.agreeTerms = value;
            })
          Text('我同意 ')
            .fontSize(14)
            .fontColor(AppColors.TEXT_BLACK87)
          Text('服务条款')
            .fontSize(14)
            .fontColor(AppColors.PRIMARY)
            .decoration({ type: TextDecorationType.Underline })
            .onClick(() => {
              router.pushUrl({ url: `pages/${RouteConstants.TERMS_OF_SERVICE}` });
            })
          Text(' 和 ')
            .fontSize(14)
            .fontColor(AppColors.TEXT_BLACK87)
          Text('社区准则')
            .fontSize(14)
            .fontColor(AppColors.PRIMARY)
            .decoration({ type: TextDecorationType.Underline })
            .onClick(() => {
              router.pushUrl({ url: `pages/${RouteConstants.COMMUNITY_GUIDELINES}` });
            })
        }
        .width('100%')
        .padding({ left: 24, right: 24 })
        .margin({ top: 24 })

        // 错误提示
        if (this.errorMessage) {
          Text(this.errorMessage)
            .fontSize(14)
            .fontColor(AppColors.ERROR)
            .width('100%')
            .padding({ left: 24, right: 24 })
            .margin({ top: 12 })
        }

        // ===== RegisterSubmitButton: "Join Nomads" #FF4458, 18px w600 =====
        Button(this.isLoading ? '注册中...' : 'Join Nomads')
          .width('100%')
          .height(52)
          .borderRadius(12)
          .backgroundColor(this.isLoading ? AppColors.GREY300 : AppColors.PRIMARY)
          .fontColor(AppColors.WHITE)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .enabled(!this.isLoading)
          .margin({ left: 24, right: 24, top: 32 })
          .onClick(() => {
            this.doRegister();
          })

        // ===== RegisterLoginLink =====
        Row() {
          Text('Already have an account? ')
            .fontSize(15)
            .fontColor(AppColors.TEXT_BLACK87)
          Text('Login')
            .fontSize(15)
            .fontColor(AppColors.PRIMARY)
            .fontWeight(FontWeight.Bold)
            .onClick(() => {
              router.back();
            })
        }
        .margin({ top: 32 })
        .justifyContent(FlexAlign.Center)

        // ===== RegisterFeatureHighlights =====
        Column() {
          Text('Join 38,000+ members')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.GREY700)
            .width('100%')

          this.FeatureItem('🍹', 'Attend meetups', 'In cities worldwide')
          this.FeatureItem('❤️', 'Meet new people', 'For dating and friends')
          this.FeatureItem('🧪', 'Research destinations', 'Find the best place')
          this.FeatureItem('💬', 'Join exclusive chat', 'Messages sent this month')
          this.FeatureItem('🗺️', 'Track your travels', 'Share your journey')
        }
        .width('100%')
        .padding(20)
        .margin({ left: 24, right: 24, top: 24 })
        .borderRadius(16)
        .backgroundColor(AppColors.GREY50)

        // 底部间距
        Column()
          .height(40)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BACKGROUND)
    .scrollable(ScrollDirection.Vertical)
  }

  /**
   * 功能项 - Flutter: emoji 24px + title 15px w600 + subtitle 13px grey
   */
  @Builder
  FeatureItem(emoji: string, title: string, subtitle: string) {
    Row() {
      Text(emoji)
        .fontSize(24)
      Column() {
        Text(title)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_BLACK87)
        Text(subtitle)
          .fontSize(13)
          .fontColor(AppColors.GREY600)
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12 })
      .layoutWeight(1)
    }
    .width('100%')
    .margin({ top: 12 })
    .alignItems(VerticalAlign.Top)
  }
}
