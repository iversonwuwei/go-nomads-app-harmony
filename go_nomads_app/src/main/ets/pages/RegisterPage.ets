import { AppColors } from '../common/constants/AppColors';
import { RouteConstants } from '../common/constants/RouteConstants';
import { HttpService } from '../services/HttpService';
import { TokenStorageService } from '../services/TokenStorageService';
import { ApiConfig } from '../common/constants/ApiConfig';
import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'RegisterPage';
const DOMAIN = 0x0001;

/**
 * 注册响应用户信息
 */
interface RegisterResponseUser {
  id: string;
  userName: string;
  email: string;
  role: string;
}

/**
 * 注册响应
 */
interface RegisterResponse {
  token: string;
  refreshToken?: string;
  expiresAt?: string;
  user: RegisterResponseUser;
}

/**
 * 注册请求体
 */
class RegisterRequestBody {
  userName: string = '';
  email: string = '';
  password: string = '';
}

/**
 * 注册页面 - 对应 Flutter 端 register 页面
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

  /**
   * 执行注册
   */
  async doRegister(): Promise<void> {
    // 表单校验
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
      const httpService = HttpService.getInstance();
      const regBody = new RegisterRequestBody();
      regBody.userName = this.userName;
      regBody.email = this.email;
      regBody.password = this.password;
      const result = await httpService.post<RegisterResponse>(ApiConfig.REGISTER_ENDPOINT, regBody);

      // 保存 Token 和用户信息
      const tokenService = TokenStorageService.getInstance();
      await tokenService.saveTokens(
        result.token,
        result.refreshToken,
        result.expiresAt ? new Date(result.expiresAt) : undefined
      );
      await tokenService.saveUserInfo(
        result.user.id,
        result.user.userName,
        result.user.email,
        result.user.role,
      );

      hilog.info(DOMAIN, TAG, '✅ 注册成功');
      // 跳转到主页
      router.replaceUrl({ url: `pages/${RouteConstants.MAIN}` });
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ 注册失败: %{public}s', JSON.stringify(err));
      this.errorMessage = '注册失败，请稍后再试';
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Column() {
      // 顶部返回按钮
      Row() {
        SymbolGlyph($r('sys.symbol.chevron_left'))
          .fontSize(24)
          .fontColor([AppColors.TEXT_PRIMARY])
          .onClick(() => {
            router.back();
          })

        Text('创建账号')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
          .margin({ left: 12 })

        Blank()
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)

      // 表单
      Column({ space: 16 }) {
        TextInput({ placeholder: '用户名', text: this.userName })
          .width('100%')
          .height(48)
          .borderRadius(10)
          .backgroundColor('#F1F5F9')
          .padding({ left: 16, right: 16 })
          .onChange((value: string) => {
            this.userName = value;
          })

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

        TextInput({ placeholder: '密码', text: this.password })
          .type(InputType.Password)
          .width('100%')
          .height(48)
          .borderRadius(10)
          .backgroundColor('#F1F5F9')
          .padding({ left: 16, right: 16 })
          .onChange((value: string) => {
            this.password = value;
          })

        TextInput({ placeholder: '确认密码', text: this.confirmPassword })
          .type(InputType.Password)
          .width('100%')
          .height(48)
          .borderRadius(10)
          .backgroundColor('#F1F5F9')
          .padding({ left: 16, right: 16 })
          .onChange((value: string) => {
            this.confirmPassword = value;
          })

        // 错误提示
        if (this.errorMessage) {
          Text(this.errorMessage)
            .fontSize(14)
            .fontColor(AppColors.ERROR)
            .width('100%')
        }

        // 注册按钮
        Button(this.isLoading ? '注册中...' : '注册')
          .width('100%')
          .height(48)
          .borderRadius(10)
          .backgroundColor(AppColors.PRIMARY)
          .fontColor('#FFFFFF')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .enabled(!this.isLoading)
          .onClick(() => {
            this.doRegister();
          })

        // 服务条款
        Row() {
          Text('注册即表示您同意 ')
            .fontSize(12)
            .fontColor(AppColors.TEXT_TERTIARY)
          Text('服务条款')
            .fontSize(12)
            .fontColor(AppColors.PRIMARY)
            .onClick(() => {
              router.pushUrl({ url: `pages/${RouteConstants.TERMS_OF_SERVICE}` });
            })
          Text(' 和 ')
            .fontSize(12)
            .fontColor(AppColors.TEXT_TERTIARY)
          Text('社区准则')
            .fontSize(12)
            .fontColor(AppColors.PRIMARY)
            .onClick(() => {
              router.pushUrl({ url: `pages/${RouteConstants.COMMUNITY_GUIDELINES}` });
            })
        }
        .margin({ top: 8 })
      }
      .width('100%')
      .padding({ left: 24, right: 24, top: 16 })

      Blank()

      // 底部
      Row() {
        Text('已有账号？')
          .fontSize(14)
          .fontColor(AppColors.TEXT_SECONDARY)
        Text('立即登录')
          .fontSize(14)
          .fontColor(AppColors.PRIMARY)
          .fontWeight(FontWeight.Medium)
          .onClick(() => {
            router.back();
          })
      }
      .margin({ bottom: 40 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BACKGROUND)
  }
}
