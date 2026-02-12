import { AppColors } from '../common/constants/AppColors';
import { RouteConstants } from '../common/constants/RouteConstants';
import { TokenStorageService } from '../services/TokenStorageService';
import { AuthService } from '../services/AuthService';
import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'LoginPage';
const DOMAIN = 0x0001;

/**
 * 登录页面 - 对应 Flutter 端 login 页面
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
    // 恢复记住我
    const tokenService = TokenStorageService.getInstance();
    this.rememberMe = tokenService.isRememberMe();
    const savedEmail = tokenService.getSavedEmail();
    if (savedEmail) {
      this.email = savedEmail;
    }
  }

  /**
   * 执行登录
   */
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

      // 跳转到主页（AuthService 已更新全局状态）
      router.replaceUrl({ url: `pages/${RouteConstants.MAIN}` });
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ 登录失败: %{public}s', JSON.stringify(err));
      this.errorMessage = '登录失败，请检查邮箱和密码';
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Column() {
      // Logo 区域
      Column() {
        Text('行途')
          .fontSize(40)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.PRIMARY)

        Text('GO-NOMADS')
          .fontSize(16)
          .fontColor(AppColors.TEXT_SECONDARY)
          .margin({ top: 4 })
      }
      .margin({ top: 80, bottom: 48 })

      // 表单区域
      Column({ space: 16 }) {
        // 邮箱输入
        TextInput({ placeholder: '邮箱', text: this.email })
          .type(InputType.Email)
          .width('100%')
          .height(48)
          .borderRadius(10)
          .backgroundColor('#F1F5F9')
          .padding({ left: 16, right: 16 })
          .onChange((value: string) => {
            this.email = value;
          })

        // 密码输入
        TextInput({ placeholder: '密码', text: this.password })
          .type(this.isPasswordVisible ? InputType.Normal : InputType.Password)
          .width('100%')
          .height(48)
          .borderRadius(10)
          .backgroundColor('#F1F5F9')
          .padding({ left: 16, right: 16 })
          .onChange((value: string) => {
            this.password = value;
          })

        // 记住我 & 忘记密码
        Row() {
          Row() {
            Checkbox()
              .select(this.rememberMe)
              .onChange((value: boolean) => {
                this.rememberMe = value;
              })
            Text('记住我')
              .fontSize(14)
              .fontColor(AppColors.TEXT_SECONDARY)
              .margin({ left: 4 })
          }

          Blank()

          Text('忘记密码?')
            .fontSize(14)
            .fontColor(AppColors.PRIMARY)
        }
        .width('100%')

        // 错误提示
        if (this.errorMessage) {
          Text(this.errorMessage)
            .fontSize(14)
            .fontColor(AppColors.ERROR)
            .width('100%')
        }

        // 登录按钮
        Button(this.isLoading ? '登录中...' : '登录')
          .width('100%')
          .height(48)
          .borderRadius(10)
          .backgroundColor(AppColors.PRIMARY)
          .fontColor('#FFFFFF')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .enabled(!this.isLoading)
          .onClick(() => {
            this.doLogin();
          })

        // 分割线
        Row() {
          Divider().width('40%').color(AppColors.DIVIDER)
          Text('或')
            .fontSize(14)
            .fontColor(AppColors.TEXT_TERTIARY)
            .margin({ left: 12, right: 12 })
          Divider().width('40%').color(AppColors.DIVIDER)
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .margin({ top: 8, bottom: 8 })

        // 社交登录按钮（占位，后续实现）
        Button('微信登录')
          .width('100%')
          .height(48)
          .borderRadius(10)
          .backgroundColor('#07C160')
          .fontColor('#FFFFFF')
          .fontSize(16)
          .onClick(() => {
            // TODO: 微信登录
          })

        Button('华为账号登录')
          .width('100%')
          .height(48)
          .borderRadius(10)
          .backgroundColor('#CF0A2C')
          .fontColor('#FFFFFF')
          .fontSize(16)
          .onClick(() => {
            // TODO: 华为账号登录
          })
      }
      .width('100%')
      .padding({ left: 24, right: 24 })

      Blank()

      // 底部注册提示
      Row() {
        Text('还没有账号？')
          .fontSize(14)
          .fontColor(AppColors.TEXT_SECONDARY)
        Text('立即注册')
          .fontSize(14)
          .fontColor(AppColors.PRIMARY)
          .fontWeight(FontWeight.Medium)
          .onClick(() => {
            router.pushUrl({ url: `pages/${RouteConstants.REGISTER}` });
          })
      }
      .margin({ bottom: 40 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BACKGROUND)
  }
}
