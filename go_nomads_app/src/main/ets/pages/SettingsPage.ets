import { AppColors } from '../common/constants/AppColors';
import { AppStorageKeys } from '../common/constants/AppStorageKeys';
import { RouteConstants } from '../common/constants/RouteConstants';
import { HttpService } from '../services/HttpService';
import { ApiConfig } from '../common/constants/ApiConfig';
import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'SettingsPage';
const DOMAIN = 0x0001;

/**
 * 设置页 — 对应 Flutter settings 模块
 */
@Entry
@Component
struct SettingsPage {
  @StorageProp(AppStorageKeys.IS_AUTHENTICATED) isAuthenticated: boolean = false;

  build() {
    Column() {
      Row() {
        SymbolGlyph($r('sys.symbol.arrow_left'))
          .fontSize(24).fontColor([AppColors.TEXT_PRIMARY]).onClick(() => { router.back(); })
        Text('设置').fontSize(18).fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT_PRIMARY).layoutWeight(1).textAlign(TextAlign.Center)
        Column().width(24)
      }
      .width('100%').height(56).padding({ left: 16, right: 16 })
      .backgroundColor(AppColors.CARD_BACKGROUND)

      Scroll() {
        Column({ space: 0 }) {
          // 账户
          this.SectionHeader('账户')
          if (this.isAuthenticated) {
            this.MenuItem('编辑资料', '修改个人信息', () => {
              router.pushUrl({ url: `pages/${RouteConstants.PROFILE_EDIT}` });
            })
            this.MenuItem('修改密码', '更改账户密码', () => { /* TODO */ })
          }

          // 通知
          this.SectionHeader('通知')
          this.MenuItem('推送通知', '聚会、消息通知', () => { /* TODO */ })

          // 关于
          this.SectionHeader('关于')
          this.MenuItem('服务条款', '', () => {
            router.pushUrl({ url: `pages/${RouteConstants.TERMS_OF_SERVICE}` });
          })
          this.MenuItem('社区规范', '', () => {
            router.pushUrl({ url: `pages/${RouteConstants.COMMUNITY_GUIDELINES}` });
          })
          this.MenuItem('隐私政策', '', () => {
            router.pushUrl({ url: `pages/${RouteConstants.PRIVACY_POLICY}` });
          })
          this.MenuItem('关于 Go Nomads', 'v1.0.0', () => { /* TODO */ })

          // 危险操作
          if (this.isAuthenticated) {
            this.SectionHeader('危险区域')
            this.MenuItemDanger('删除账户', '永久删除你的账户和数据', () => { /* TODO 确认弹窗 */ })
          }

          Column().height(40)
        }
      }
      .layoutWeight(1).scrollBar(BarState.Off)
    }
    .width('100%').height('100%').backgroundColor(AppColors.BACKGROUND)
  }

  @Builder
  SectionHeader(title: string) {
    Text(title).fontSize(13).fontWeight(FontWeight.Medium).fontColor(AppColors.TEXT_TERTIARY)
      .padding({ left: 16, right: 16, top: 20, bottom: 8 })
  }

  @Builder
  MenuItem(title: string, subtitle: string, action: () => void) {
    Row() {
      Column({ space: 2 }) {
        Text(title).fontSize(15).fontColor(AppColors.TEXT_PRIMARY)
        if (subtitle) {
          Text(subtitle).fontSize(13).fontColor(AppColors.TEXT_TERTIARY)
        }
      }
      .layoutWeight(1).alignItems(HorizontalAlign.Start)

      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(16).fontColor([AppColors.TEXT_TERTIARY])
    }
    .width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .backgroundColor(AppColors.CARD_BACKGROUND)
    .border({ width: { bottom: 0.5 }, color: AppColors.DIVIDER })
    .onClick(action)
  }

  @Builder
  MenuItemDanger(title: string, subtitle: string, action: () => void) {
    Row() {
      Column({ space: 2 }) {
        Text(title).fontSize(15).fontColor(AppColors.ERROR)
        if (subtitle) {
          Text(subtitle).fontSize(13).fontColor(AppColors.TEXT_TERTIARY)
        }
      }
      .layoutWeight(1).alignItems(HorizontalAlign.Start)

      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(16).fontColor([AppColors.TEXT_TERTIARY])
    }
    .width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .backgroundColor(AppColors.CARD_BACKGROUND)
    .border({ width: { bottom: 0.5 }, color: AppColors.DIVIDER })
    .onClick(action)
  }
}
