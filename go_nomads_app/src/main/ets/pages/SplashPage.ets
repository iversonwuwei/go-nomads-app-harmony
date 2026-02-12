import { AppColors } from '../common/constants/AppColors';
import { AppStorageKeys } from '../common/constants/AppStorageKeys';
import { AuthStatus } from '../models/AuthModels';
import { RouteConstants } from '../common/constants/RouteConstants';
import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'SplashPage';
const DOMAIN = 0x0001;

/**
 * 启动页 - 对应 Flutter 端 SplashLoadingScreen
 * 显示青蓝色背景，等待初始化完成后跳转
 */
@Entry
@Component
struct SplashPage {
  @StorageProp(AppStorageKeys.AUTH_STATUS) authStatus: AuthStatus = AuthStatus.Unknown;
  @StorageProp(AppStorageKeys.IS_INITIALIZED) isInitialized: boolean = false;
  private hasNavigated: boolean = false;

  aboutToAppear(): void {
    hilog.info(DOMAIN, TAG, '📱 SplashPage appeared');
  }

  private navigateToTarget(): void {
    if (this.hasNavigated) {
      return;
    }

    if (!this.isInitialized) {
      return;
    }

    this.hasNavigated = true;
    let targetPage: string;

    if (this.authStatus === AuthStatus.Authenticated) {
      targetPage = RouteConstants.MAIN;
      hilog.info(DOMAIN, TAG, '🚀 已认证，导航到主页');
    } else {
      targetPage = RouteConstants.LOGIN;
      hilog.info(DOMAIN, TAG, '🚀 未认证，导航到登录页');
    }

    router.replaceUrl({
      url: `pages/${targetPage}`,
    }).catch((err: Error) => {
      hilog.error(DOMAIN, TAG, '❌ 导航失败: %{public}s', JSON.stringify(err));
    });
  }

  build() {
    Column() {
      // 应用名称
      Text('行途')
        .fontSize(36)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .margin({ bottom: 8 })

      Text('GO-NOMADS')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#FFFFFFCC')

      // 加载指示器
      if (!this.isInitialized) {
        LoadingProgress()
          .width(48)
          .height(48)
          .color('#FFFFFF')
          .margin({ top: 60 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.SPLASH_BACKGROUND)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onAreaChange(() => {
      // 当初始化完成后触发导航
      if (this.isInitialized && !this.hasNavigated) {
        // 延迟一帧再导航
        setTimeout(() => {
          this.navigateToTarget();
        }, 100);
      }
    })
  }
}
