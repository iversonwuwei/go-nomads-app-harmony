import { AppColors } from '../common/constants/AppColors';
import { HttpService } from '../services/HttpService';
import { ApiConfig } from '../common/constants/ApiConfig';
import { InnovationProject, InnovationHelper, TeamMember } from '../models/InnovationProject';
import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'InnovationDetailPage';
const DOMAIN = 0x0001;

/**
 * 创新项目详情页 — 对应 Flutter innovation_detail_page.dart
 */
@Entry
@Component
struct InnovationDetailPage {
  @State project: InnovationProject | null = null;
  @State isLoading: boolean = true;

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>;
    if (params?.['projectId']) { this.loadProject(params['projectId']); }
  }

  async loadProject(id: string): Promise<void> {
    this.isLoading = true;
    try {
      const httpService = HttpService.getInstance();
      this.project = await httpService.get<InnovationProject>(`${ApiConfig.INNOVATION_PROJECTS_ENDPOINT}/${id}`);
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ %{public}s', JSON.stringify(err));
    } finally { this.isLoading = false; }
  }

  build() {
    Column() {
      if (this.isLoading || !this.project) {
        Column() { LoadingProgress().width(40).height(40) }
          .width('100%').height('100%').justifyContent(FlexAlign.Center).backgroundColor(AppColors.BACKGROUND)
      } else {
        this.Content(this.project!)
      }
    }.width('100%').height('100%')
  }

  @Builder
  Content(p: InnovationProject) {
    Column() {
      Scroll() {
        Column({ space: 0 }) {
          // 封面
          Stack() {
            Image(p.imageUrl || $r('app.media.startIcon'))
              .width('100%').height(200).objectFit(ImageFit.Cover)
            Row() {
              SymbolGlyph($r('sys.symbol.arrow_left'))
                .fontSize(22).fontColor(['#FFFFFF'])
                .onClick(() => { router.back(); })
            }.width('100%').padding({ left: 16, top: 44 })
          }.width('100%')

          Column({ space: 20 }) {
            // 标题 + 状态
            Row() {
              Text(p.projectName).fontSize(22).fontWeight(FontWeight.Bold)
                .fontColor(AppColors.TEXT_PRIMARY).layoutWeight(1)
              Text(InnovationHelper.statusLabel(p.currentStatus)).fontSize(13)
            }.width('100%')

            // 创建者
            if (p.userName) {
              Row({ space: 8 }) {
                Image(p.userAvatar || $r('app.media.startIcon'))
                  .width(32).height(32).borderRadius(16).objectFit(ImageFit.Cover)
                Column({ space: 2 }) {
                  Text(p.userName).fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.TEXT_PRIMARY)
                  Text(InnovationHelper.productTypeLabel(p.productType))
                    .fontSize(12).fontColor(AppColors.TEXT_TERTIARY)
                }
              }
            }

            // 一句话介绍
            Text(p.elevatorPitch).fontSize(15).fontColor(AppColors.TEXT_SECONDARY).lineHeight(24)
              .padding(12).backgroundColor('#F0F9FF').borderRadius(8).width('100%')

            // 详细信息区
            this.Section('🎯 解决的问题', p.problem)
            this.Section('💡 解决方案', p.solution)
            this.Section('👥 目标用户', p.targetAudience)
            this.Section('✨ 核心功能', p.keyFeatures)
            this.Section('🏆 竞争优势', p.competitiveAdvantage)
            this.Section('💰 商业模式', p.businessModel)
            this.Section('📊 市场机会', p.marketOpportunity)
            this.Section('🤝 寻求', p.ask)

            // 团队
            if (p.team.length > 0) {
              Column({ space: 8 }) {
                Text('👥 团队').fontSize(16).fontWeight(FontWeight.Medium).fontColor(AppColors.TEXT_PRIMARY)
                ForEach(p.team, (m: TeamMember) => {
                  Row({ space: 10 }) {
                    Image(m.avatar || $r('app.media.startIcon'))
                      .width(36).height(36).borderRadius(18).objectFit(ImageFit.Cover)
                    Column({ space: 2 }) {
                      Text(m.name).fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.TEXT_PRIMARY)
                      Text(m.role).fontSize(12).fontColor(AppColors.TEXT_TERTIARY)
                    }
                  }
                  .width('100%').padding(10).backgroundColor('#F8FAFC').borderRadius(8)
                }, (m: TeamMember) => m.name + m.role)
              }
              .width('100%').alignItems(HorizontalAlign.Start)
            }

            // 互动数据
            Row({ space: 20 }) {
              this.Stat('👁', '浏览', p.viewCount ?? 0)
              this.Stat('❤', '喜欢', p.likeCount ?? 0)
              this.Stat('💬', '评论', p.commentCount ?? 0)
            }
            .width('100%').justifyContent(FlexAlign.Center)
            .padding(14).backgroundColor(AppColors.CARD_BACKGROUND).borderRadius(10)

            Column().height(30)
          }
          .padding({ left: 16, right: 16, top: 16 }).alignItems(HorizontalAlign.Start)
        }
      }
      .layoutWeight(1).scrollBar(BarState.Off)

      // Bottom Bar
      Row({ space: 12 }) {
        Button('❤ 点赞').layoutWeight(1).height(44).borderRadius(10)
          .backgroundColor('#FEF2F2').fontColor(AppColors.ERROR)
        Button('💬 联系').layoutWeight(1).height(44).borderRadius(10)
          .backgroundColor(AppColors.PRIMARY).fontColor('#FFFFFF')
      }
      .width('100%').padding({ left: 16, right: 16, top: 10, bottom: 10 })
      .backgroundColor(AppColors.CARD_BACKGROUND)
      .shadow({ radius: 6, color: '#0000000F', offsetX: 0, offsetY: -2 })
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

  @Builder
  Stat(icon: string, label: string, value: number) {
    Column({ space: 2 }) {
      Text(`${icon} ${value}`).fontSize(16).fontWeight(FontWeight.Medium).fontColor(AppColors.TEXT_PRIMARY)
      Text(label).fontSize(12).fontColor(AppColors.TEXT_TERTIARY)
    }
  }
}
