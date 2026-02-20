import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { TokenStorageService } from '../services/TokenStorageService';
import { AppInitService } from '../services/AppInitService';
import { HttpService } from '../services/HttpService';
import { AppStorageKeys } from '../common/constants/AppStorageKeys';
import { AuthStatus } from '../models/AuthModels';

const DOMAIN = 0x0000;

export default class Go_nomads_appAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');

    // 绑定 TokenStorage 上下文（懒初始化兜底）
    TokenStorageService.getInstance().bindContext(this.context);

    // 初始化全局状态默认值（Ability 创建时立即设置，确保 UI 可用前就有值）
    AppStorage.setOrCreate(AppStorageKeys.AUTH_STATUS, AuthStatus.Unknown);
    AppStorage.setOrCreate(AppStorageKeys.IS_AUTHENTICATED, false);
    AppStorage.setOrCreate(AppStorageKeys.IS_INITIALIZED, false);
    AppStorage.setOrCreate(AppStorageKeys.CURRENT_TAB_INDEX, 0);
    AppStorage.setOrCreate(AppStorageKeys.UNREAD_NOTIFICATION_COUNT, 0);
    AppStorage.setOrCreate(AppStorageKeys.CURRENT_LOCALE, 'zh-CN');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    // 先加载启动页
    windowStage.loadContent('pages/SplashPage', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading SplashPage.');

      // 在后台执行初始化
      this.performInitialization();
    });
  }

  /**
   * 执行应用初始化（加载 SplashPage 后在后台执行）
   */
  private async performInitialization(): Promise<void> {
    try {
      hilog.info(DOMAIN, 'testTag', '🎯 开始应用初始化...');

      // 第一步：初始化 Token 存储服务
      const tokenService = TokenStorageService.getInstance();
      await tokenService.init(this.context);
      hilog.info(DOMAIN, 'testTag', '✅ TokenStorageService 初始化完成');

      // 第二步：设置 HttpService 的 401 回调
      HttpService.getInstance().onUnauthorized = () => {
        AppStorage.set(AppStorageKeys.IS_AUTHENTICATED, false);
        AppStorage.set(AppStorageKeys.AUTH_STATUS, AuthStatus.Unauthenticated);
      };

      // 第三步：恢复登录状态
      const appInitService = AppInitService.getInstance();
      await appInitService.initialize();
      hilog.info(DOMAIN, 'testTag', '✅ 应用初始化完成');

      // 标记初始化完成 - SplashPage 监听此状态后自动跳转
      AppStorage.set(AppStorageKeys.IS_INITIALIZED, true);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', '❌ 初始化失败: %{public}s', JSON.stringify(err));
      // 即使初始化失败也允许进入应用
      AppStorage.set(AppStorageKeys.AUTH_STATUS, AuthStatus.Unauthenticated);
      AppStorage.set(AppStorageKeys.IS_INITIALIZED, true);
    }
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}