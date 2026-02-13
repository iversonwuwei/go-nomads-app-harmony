import { AppColors } from '../common/constants/AppColors';
import { RouteConstants } from '../common/constants/RouteConstants';
import { TokenStorageService } from '../services/TokenStorageService';
import { AuthService } from '../services/AuthService';
import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'LoginPage';
const DOMAIN = 0x0001;

/**
 * 登录页面 - 100% 还原 Flutter login_page.dart
 *
 * Flutter 结构:
 *   LoginHeader → Logo 80x80 圆 + "Welcome" 32px + "Login" 16px grey
 *   LoginEmailForm → 邮箱/密码 (radius12) + 记住我 + 登录按钮
 *   LoginSocialButtons → 分隔线 + 微信/QQ/手机号按钮
 *   LoginCommunityHighlight → 38000+ nomads card
 *   LoginRegisterLink → "Let's Go" + "Register"
 */
@Entry
@Component
struct LoginPage {
  @State email: string = '';
  @State password: string = '';
  @State isLoading: boolean = false;
  @State errorMessage: string = '';
  @State rememberMe: boolean = false;
  @State isPasswordVisible: boolean = false;

  aboutToAppear(): void {
    const tokenService = TokenStorageService.getInstance();
    this.rememberMe = tokenService.isRememberMe();
    const savedEmail = tokenService.getSavedEmail();
    if (savedEmail) {
      this.email = savedEmail;
    }
  }

  async doLogin(): Promise<void> {
    if (!this.email || !this.password) {
      this.errorMessage = '请输入邮箱和密码';
      return;
    }
    this.isLoading = true;
    this.errorMessage = '';
    try {
      await AuthService.getInstance().login(this.email, this.password, this.rememberMe);
      hilog.info(DOMAIN, TAG, '✅ 登录成功: %{public}s', this.email);
      router.replaceUrl({ url: `pages/${RouteConstants.MAIN}` });
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ 登录失败: %{public}s', JSON.stringify(err));
      this.errorMessage = '登录失败，请检查邮箱和密码';
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Scroll() {
      Column() {
        // ===== LoginHeader: Logo 80x80 圆 + "Welcome" 32px =====
        Column() {
          // Logo 圆形容器 80x80, primaryColor 10% alpha 背景
          Column() {
            SymbolGlyph($r('sys.symbol.globe_badge_heart'))
              .fontSize(40)
              .fontColor([AppColors.PRIMARY])
          }
          .width(80)
          .height(80)
          .borderRadius(40)
          .backgroundColor('#1AFF4458') // #FF4458 with 10% alpha
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)

          // 标题 "Welcome" 32px bold black87
          Text('Welcome')
            .fontSize(32)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.TEXT_BLACK87)
            .margin({ top: 24 })

          // 副标题 "Login" 16px grey
          Text('登录')
            .fontSize(16)
            .fontColor(AppColors.TEXT_TERTIARY)
            .margin({ top: 12 })
            .textAlign(TextAlign.Center)
        }
        .margin({ top: 60, bottom: 32 })
        .alignItems(HorizontalAlign.Center)

        // ===== LoginEmailForm =====
        Column({ space: 20 }) {
          // 邮箱输入 - radius 12, grey.shade300 border
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

          // 密码输入 - radius 12
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

          // 记住我 & 忘记密码 - Flutter: Checkbox activeColor #FF4458
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

            Text('忘记密码?')
              .fontSize(14)
              .fontColor(AppColors.PRIMARY)
              .fontWeight(FontWeight.Bold)
              .onClick(() => {
                // TODO: 忘记密码
              })
          }
          .width('100%')

          // 错误提示
          if (this.errorMessage) {
            Text(this.errorMessage)
              .fontSize(14)
              .fontColor(AppColors.ERROR)
              .width('100%')
          }

          // 登录按钮 - Flutter: full width, #FF4458, white 18px w600, padding 16, radius 12, elevation 0
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
              this.doLogin();
            })
        }
        .width('100%')
        .padding({ left: 24, right: 24 })

        // ===== LoginSocialButtons =====
        Column() {
          // 分隔线 "Or continue with"
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
          .margin({ top: 24, bottom: 24 })

          // 社交按钮行1: 微信 + QQ
          Row({ space: 12 }) {
            // 微信按钮
            this.SocialButton('微信', AppColors.WECHAT_GREEN)
            // QQ按钮
            this.SocialButton('QQ', AppColors.QQ_BLUE)
          }
          .width('100%')
          .padding({ left: 24, right: 24 })

          // 社交按钮行2: 手机号
          Row() {
            this.SocialButton('手机号', AppColors.PHONE_GREEN)
          }
          .width('50%')
          .margin({ top: 12 })
          .padding({ left: 24, right: 24 })
        }
        .width('100%')

        // ===== LoginCommunityHighlight =====
        Column() {
          // 顶部行: icon + text
          Row() {
            // icon容器
            Column() {
              SymbolGlyph($r('sys.symbol.person_3'))
                .fontSize(24)
                .fontColor([AppColors.PRIMARY])
            }
            .width(40)
            .height(40)
            .borderRadius(8)
            .backgroundColor('#1AFF4458') // #FF4458 10% alpha
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

          // 特性徽章行
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

        // ===== LoginRegisterLink: "Let's Go" + "Register" =====
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

  /**
   * 社交登录按钮 - Flutter: white容器, radius 12, grey border, icon+label
   */
  @Builder
  SocialButton(label: string, iconColor: string) {
    Column() {
      // 使用文字代替图标
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
      // TODO: social login
    })
  }

  /**
   * 特性徽章 - Flutter: white容器, radius 8, grey border, emoji+text
   */
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
}
