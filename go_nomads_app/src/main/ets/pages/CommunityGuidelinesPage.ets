import { AppColors } from '../common/constants/AppColors';
import { router } from '@kit.ArkUI';

/**
 * 社区规范页 — 对应 Flutter community_guidelines_page.dart
 */
@Entry
@Component
struct CommunityGuidelinesPage {
  build() {
    Column() {
      Row() {
        SymbolGlyph($r('sys.symbol.arrow_left'))
          .fontSize(24).fontColor([AppColors.TEXT_PRIMARY]).onClick(() => { router.back(); })
        Text('社区规范').fontSize(18).fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT_PRIMARY).layoutWeight(1).textAlign(TextAlign.Center)
        Column().width(24)
      }
      .width('100%').height(56).padding({ left: 16, right: 16 })
      .backgroundColor(AppColors.CARD_BACKGROUND)

      Scroll() {
        Column({ space: 16 }) {
          Text('Go Nomads 社区规范')
            .fontSize(22).fontWeight(FontWeight.Bold).fontColor(AppColors.TEXT_PRIMARY)
          Text('我们致力于打造一个友好、包容、互助的数字游民社区。')
            .fontSize(14).fontColor(AppColors.TEXT_SECONDARY).lineHeight(22)

          this.Guideline('🤝 尊重他人',
            '尊重社区中每个人的背景、文化和观点。不容忍任何形式的歧视、骚扰或仇恨言论。')
          this.Guideline('🌍 分享真实信息',
            '请分享真实的城市体验和评价。不要发布虚假或误导性的信息。')
          this.Guideline('🎉 负责任地组织聚会',
            '作为聚会组织者，请确保活动安全合法。及时更新活动信息，尊重参与者的时间。')
          this.Guideline('💬 友善沟通',
            '保持交流友善和建设性。意见分歧时保持礼貌。不要发送垃圾信息或过度推广。')
          this.Guideline('🔒 保护隐私',
            '不要未经允许分享他人的个人信息。保护自己和他人的隐私安全。')
          this.Guideline('📸 尊重版权',
            '只上传你有权使用的照片和内容。给予原始创作者适当的认可。')
          this.Guideline('🚫 禁止行为',
            '• 发布违法内容\n• 商业垃圾信息\n• 冒充他人\n• 滥用平台功能\n• 骚扰或跟踪其他用户')
          this.Guideline('⚠️ 违规处理',
            '对于违反社区规范的行为，我们可能会采取警告、限制功能或永久封禁等措施。如发现违规行为，请及时举报。')

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
  Guideline(title: string, content: string) {
    Column({ space: 6 }) {
      Text(title).fontSize(16).fontWeight(FontWeight.Medium).fontColor(AppColors.TEXT_PRIMARY)
      Text(content).fontSize(14).fontColor(AppColors.TEXT_SECONDARY).lineHeight(22)
    }
    .width('100%').alignItems(HorizontalAlign.Start)
    .padding(14).backgroundColor(AppColors.CARD_BACKGROUND).borderRadius(10)
  }
}
