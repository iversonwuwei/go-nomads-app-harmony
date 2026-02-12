import { AppColors } from '../common/constants/AppColors';
import { router } from '@kit.ArkUI';

/**
 * 隐私政策页
 */
@Entry
@Component
struct PrivacyPolicyPage {
  build() {
    Column() {
      Row() {
        SymbolGlyph($r('sys.symbol.arrow_left'))
          .fontSize(24).fontColor([AppColors.TEXT_PRIMARY]).onClick(() => { router.back(); })
        Text('隐私政策').fontSize(18).fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT_PRIMARY).layoutWeight(1).textAlign(TextAlign.Center)
        Column().width(24)
      }
      .width('100%').height(56).padding({ left: 16, right: 16 })
      .backgroundColor(AppColors.CARD_BACKGROUND)

      Scroll() {
        Column({ space: 16 }) {
          Text('Go Nomads 隐私政策')
            .fontSize(22).fontWeight(FontWeight.Bold).fontColor(AppColors.TEXT_PRIMARY)
          Text('最后更新: 2024年1月')
            .fontSize(13).fontColor(AppColors.TEXT_TERTIARY)

          this.Section('1. 信息收集',
            '我们收集的信息包括：您注册时提供的个人信息（邮箱、用户名）、个人资料信息（技能、兴趣、社交链接）、使用数据和设备信息。')
          this.Section('2. 信息用途',
            '收集的信息用于：提供和改善服务、个性化体验、发送重要通知、分析使用趋势。')
          this.Section('3. 信息共享',
            '我们不会向第三方出售您的个人信息。但在以下情况可能共享：获得您的同意、法律要求、保护平台权益。')
          this.Section('4. 数据安全',
            '我们采用行业标准的安全措施保护您的数据，包括加密传输和安全存储。但无法保证绝对安全。')
          this.Section('5. Cookie 使用',
            '我们使用 Cookie 和类似技术改善用户体验、分析流量和个性化内容。')
          this.Section('6. 您的权利',
            '您有权访问、修改或删除您的个人数据。如需行使这些权利，请联系 privacy@go-nomads.com。')
          this.Section('7. 数据保留',
            '我们会在您使用服务期间保留您的数据。账户删除后，我们会在合理时间内删除您的个人数据。')
          this.Section('8. 联系方式',
            '如有隐私相关问题，请发送邮件至 privacy@go-nomads.com。')

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
