import { AppColors } from '../common/constants/AppColors';
import { router } from '@kit.ArkUI';

/**
 * 服务条款页 — 对应 Flutter terms_of_service_page.dart
 */
@Entry
@Component
struct TermsOfServicePage {
  build() {
    Column() {
      Row() {
        SymbolGlyph($r('sys.symbol.arrow_left'))
          .fontSize(24).fontColor([AppColors.TEXT_PRIMARY]).onClick(() => { router.back(); })
        Text('服务条款').fontSize(18).fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT_PRIMARY).layoutWeight(1).textAlign(TextAlign.Center)
        Column().width(24)
      }
      .width('100%').height(56).padding({ left: 16, right: 16 })
      .backgroundColor(AppColors.CARD_BACKGROUND)

      Scroll() {
        Column({ space: 16 }) {
          Text('Go Nomads 服务条款')
            .fontSize(22).fontWeight(FontWeight.Bold).fontColor(AppColors.TEXT_PRIMARY)
          Text('最后更新: 2024年1月')
            .fontSize(13).fontColor(AppColors.TEXT_TERTIARY)

          this.Section('1. 接受条款',
            '使用 Go Nomads 服务即表示您同意本服务条款。如果您不同意，请勿使用本服务。')
          this.Section('2. 服务描述',
            'Go Nomads 为数字游民社区提供城市信息、聚会组织、即时通讯、AI 旅行助手等功能。')
          this.Section('3. 用户账户',
            '您需要注册账户才能使用大部分功能。您有责任维护账户安全，并对账户下的所有活动负责。')
          this.Section('4. 用户行为',
            '您同意不会发布违法、辱骂、歧视或侵犯他人权利的内容。违反者账户可能会被暂停或终止。')
          this.Section('5. 知识产权',
            'Go Nomads 的商标、标识、界面及软件受版权保护。用户生成的内容归用户所有，但授予平台使用许可。')
          this.Section('6. 隐私',
            '您的隐私对我们很重要。请参阅我们的隐私政策了解详情。')
          this.Section('7. 免责声明',
            'Go Nomads 提供的城市信息、费用数据仅供参考，不保证完全准确。旅行安全由用户自行负责。')
          this.Section('8. 变更',
            '我们可能会不时修改这些条款。继续使用服务即表示您接受修改后的条款。')
          this.Section('9. 联系我们',
            '如有任何问题，请发送邮件至 support@go-nomads.com。')

          Column().height(40)
        }
        .padding({ left: 20, right: 20, top: 20 })
        .alignItems(HorizontalAlign.Start)
      }
      .layoutWeight(1).scrollBar(BarState.Auto)
    }
    .width('100%').height('100%').backgroundColor(AppColors.BACKGROUND)
  }

  @Builder
  Section(title: string, content: string) {
    Column({ space: 6 }) {
      Text(title).fontSize(16).fontWeight(FontWeight.Medium).fontColor(AppColors.TEXT_PRIMARY)
      Text(content).fontSize(14).fontColor(AppColors.TEXT_SECONDARY).lineHeight(22)
    }
    .width('100%').alignItems(HorizontalAlign.Start)
  }
}
