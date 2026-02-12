import { AppColors } from '../common/constants/AppColors';
import { RouteConstants } from '../common/constants/RouteConstants';
import { HttpService } from '../services/HttpService';
import { ApiConfig } from '../common/constants/ApiConfig';
import { InnovationProject, InnovationHelper } from '../models/InnovationProject';
import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'InnovationListPage';
const DOMAIN = 0x0001;

/**
 * 创新项目列表页 — 对应 Flutter innovation_list_page.dart
 */
@Entry
@Component
struct InnovationListPage {
  @State projects: InnovationProject[] = [];
  @State isLoading: boolean = true;
  @State searchText: string = '';

  aboutToAppear(): void { this.loadProjects(); }

  async loadProjects(): Promise<void> {
    this.isLoading = true;
    try {
      const httpService = HttpService.getInstance();
      this.projects = await httpService.get<InnovationProject[]>(ApiConfig.INNOVATION_PROJECTS_ENDPOINT);
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ %{public}s', JSON.stringify(err));
    } finally { this.isLoading = false; }
  }

  getFiltered(): InnovationProject[] {
    if (!this.searchText.trim()) return this.projects;
    const q = this.searchText.toLowerCase();
    return this.projects.filter(p =>
      p.projectName.toLowerCase().includes(q) || p.elevatorPitch.toLowerCase().includes(q));
  }

  build() {
    Column() {
      Row() {
        SymbolGlyph($r('sys.symbol.arrow_left'))
          .fontSize(24).fontColor([AppColors.TEXT_PRIMARY]).onClick(() => { router.back(); })
        Text('创新项目').fontSize(18).fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT_PRIMARY).layoutWeight(1).textAlign(TextAlign.Center)
        Column().width(24)
      }
      .width('100%').height(56).padding({ left: 16, right: 16 })
      .backgroundColor(AppColors.CARD_BACKGROUND)

      // 搜索
      Row() {
        TextInput({ placeholder: '搜索项目...', text: this.searchText })
          .width('100%').height(38).borderRadius(19).backgroundColor('#F1F5F9')
          .padding({ left: 14, right: 14 })
          .onChange((v: string) => { this.searchText = v; })
      }
      .width('100%').padding({ left: 16, right: 16, top: 10, bottom: 10 })

      if (this.isLoading) {
        Column() { LoadingProgress().width(40).height(40) }
          .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else if (this.getFiltered().length === 0) {
        Column({ space: 12 }) {
          Text('🚀').fontSize(48)
          Text('暂无创新项目').fontSize(16).fontColor(AppColors.TEXT_SECONDARY)
        }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        List() {
          ForEach(this.getFiltered(), (p: InnovationProject) => {
            ListItem() { this.ProjectCard(p) }
          }, (p: InnovationProject) => p.id.toString())
        }
        .layoutWeight(1).padding({ left: 16, right: 16, top: 4 })
        .divider({ strokeWidth: 0 }).edgeEffect(EdgeEffect.Spring)
      }
    }
    .width('100%').height('100%').backgroundColor(AppColors.BACKGROUND)
  }

  @Builder
  ProjectCard(p: InnovationProject) {
    Column() {
      // 封面
      if (p.imageUrl) {
        Image(p.imageUrl).width('100%').height(130).objectFit(ImageFit.Cover)
          .borderRadius({ topLeft: 10, topRight: 10 })
      }

      Column({ space: 6 }) {
        Row() {
          Text(p.projectName).fontSize(16).fontWeight(FontWeight.Bold)
            .fontColor(AppColors.TEXT_PRIMARY).layoutWeight(1)
            .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(InnovationHelper.statusLabel(p.currentStatus)).fontSize(11)
        }

        Text(p.elevatorPitch).fontSize(13).fontColor(AppColors.TEXT_SECONDARY)
          .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis }).lineHeight(20)

        Row({ space: 4 }) {
          Text(InnovationHelper.productTypeLabel(p.productType)).fontSize(11)
            .fontColor(AppColors.PRIMARY).backgroundColor(`${AppColors.PRIMARY}18`)
            .borderRadius(4).padding({ left: 6, right: 6, top: 2, bottom: 2 })
          if (p.targetAudience) {
            Text(p.targetAudience).fontSize(11).fontColor(AppColors.TEXT_TERTIARY)
              .backgroundColor('#F1F5F9').borderRadius(4)
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
              .constraintSize({ maxWidth: 120 })
          }
        }

        // 创建者 + 互动数据
        Row() {
          if (p.userName) {
            Row({ space: 4 }) {
              Image(p.userAvatar || $r('app.media.startIcon'))
                .width(18).height(18).borderRadius(9).objectFit(ImageFit.Cover)
              Text(p.userName).fontSize(12).fontColor(AppColors.TEXT_TERTIARY)
            }
          }
          Blank()
          Row({ space: 10 }) {
            Text(`👁 ${p.viewCount ?? 0}`).fontSize(11).fontColor(AppColors.TEXT_TERTIARY)
            Text(`❤ ${p.likeCount ?? 0}`).fontSize(11)
              .fontColor(p.isLiked ? AppColors.ERROR : AppColors.TEXT_TERTIARY)
            Text(`💬 ${p.commentCount ?? 0}`).fontSize(11).fontColor(AppColors.TEXT_TERTIARY)
          }
        }.width('100%')
      }
      .width('100%').padding({ left: 12, right: 12, top: p.imageUrl ? 8 : 12, bottom: 12 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%').backgroundColor(AppColors.CARD_BACKGROUND).borderRadius(10)
    .shadow({ radius: 3, color: '#0000000A', offsetX: 0, offsetY: 1 }).margin({ bottom: 10 })
    .onClick(() => {
      router.pushUrl({
        url: `pages/${RouteConstants.INNOVATION_DETAIL}`,
        params: { projectId: p.id.toString() },
      });
    })
  }
}
