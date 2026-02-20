import { AppColors } from '../common/constants/AppColors';
import { CityRecommendation, Question, TripReport } from '../models/Community';
import { CommunityService } from '../services/CommunityService';
import { router } from '@kit.ArkUI';

@Entry
@Component
struct CommunityPage {
  @State isLoading: boolean = true;
  @State currentTab: number = 0;
  @State selectedCategory: string = 'All';
  @State tripReports: TripReport[] = [];
  @State recommendations: CityRecommendation[] = [];
  @State questions: Question[] = [];
  private tabController: TabsController = new TabsController();
  private categories: string[] = ['All', 'Restaurant', 'Cafe', 'Coworking', 'Activity'];

  aboutToAppear(): void {
    this.loadData();
  }

  private async loadData(): Promise<void> {
    this.isLoading = true;
    try {
      const svc = CommunityService.getInstance();
      this.tripReports = await svc.getTripReports();
      this.recommendations = await svc.getRecommendations(this.selectedCategory);
      this.questions = await svc.getQuestions();
    } finally {
      this.isLoading = false;
    }
  }

  private async onCategoryChange(category: string): Promise<void> {
    this.selectedCategory = category;
    try {
      const svc = CommunityService.getInstance();
      this.recommendations = await svc.getRecommendations(category);
    } catch (_err) {
      this.recommendations = [];
    }
  }

  private likeTripReport(id: string): void {
    this.tripReports = CommunityService.getInstance().toggleLikeTripReport(id);
  }

  private upvoteQuestion(id: string): void {
    this.questions = CommunityService.getInstance().toggleUpvoteQuestion(id);
  }

  build() {
    Column({ space: 12 }) {
      Row() {
        SymbolGlyph($r('sys.symbol.arrow_left')).fontSize(24).fontColor([AppColors.TEXT_PRIMARY]).onClick(() => { router.back(); })
        Text('社区').fontSize(18).fontWeight(FontWeight.Medium).layoutWeight(1).textAlign(TextAlign.Center)
        Column().width(24)
      }
      .width('100%').height(56).padding({ left: 16, right: 16 })
      .backgroundColor(AppColors.CARD_BACKGROUND)

      if (this.isLoading) {
        Column() { LoadingProgress().width(40).height(40) }
          .layoutWeight(1)
          .width('100%')
          .justifyContent(FlexAlign.Center)
      } else {
        Tabs({ controller: this.tabController }) {
          TabContent() {
            this.TripReportsTab()
          }
          .tabBar(this.TabLabel('Trip Reports', 0))

          TabContent() {
            this.RecommendationsTab()
          }
          .tabBar(this.TabLabel('Recommendations', 1))

          TabContent() {
            this.QATab()
          }
          .tabBar(this.TabLabel('Q&A', 2))
        }
        .barMode(BarMode.Fixed)
        .barWidth('100%')
        .barHeight(44)
        .layoutWeight(1)
        .onChange((index: number) => {
          this.currentTab = index;
        })
      }
    }
    .width('100%').height('100%').backgroundColor(AppColors.BACKGROUND)
  }

  @Builder
  TabLabel(title: string, index: number) {
    Text(title)
      .fontSize(13)
      .fontWeight(this.currentTab === index ? FontWeight.Bold : FontWeight.Normal)
      .fontColor(this.currentTab === index ? AppColors.PRIMARY : AppColors.TEXT_SECONDARY)
  }

  @Builder
  TripReportsTab() {
    List() {
      ForEach(this.tripReports, (item: TripReport) => {
        ListItem() {
          Row({ space: 10 }) {
            Column({ space: 6 }) {
              Text(`${item.userName} · ${item.city}, ${item.country}`)
                .fontSize(12)
                .fontColor(AppColors.TEXT_SECONDARY)
              Text(item.title)
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor(AppColors.TEXT_PRIMARY)
              Text(item.content)
                .fontSize(13)
                .fontColor(AppColors.TEXT_SECONDARY)
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Row({ space: 12 }) {
                Text(`⭐ ${item.overallRating.toFixed(1)}`).fontSize(12).fontColor(AppColors.WARNING)
                Text(`💬 ${item.comments}`).fontSize(12).fontColor(AppColors.TEXT_TERTIARY)
                Text(item.isLiked ? `❤️ ${item.likes}` : `🤍 ${item.likes}`)
                  .fontSize(12)
                  .fontColor(item.isLiked ? AppColors.PRIMARY : AppColors.TEXT_TERTIARY)
                  .onClick(() => { this.likeTripReport(item.id); })
              }
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')
          .padding(14)
          .backgroundColor(AppColors.WHITE)
          .borderRadius(12)
          .border({ width: 1, color: AppColors.BORDER_LIGHT })
          .margin({ left: 16, right: 16, top: 10 })
        }
      }, (item: TripReport) => item.id)
    }
    .divider({ strokeWidth: 0 })
  }

  @Builder
  RecommendationsTab() {
    Column() {
      Scroll({ direction: Axis.Horizontal }) {
        Row({ space: 8 }) {
          ForEach(this.categories, (cat: string) => {
            Text(cat)
              .fontSize(12)
              .fontColor(this.selectedCategory === cat ? AppColors.WHITE : AppColors.TEXT_SECONDARY)
              .backgroundColor(this.selectedCategory === cat ? AppColors.PRIMARY : AppColors.WHITE)
              .borderRadius(16)
              .padding({ left: 12, right: 12, top: 6, bottom: 6 })
              .onClick(() => { this.onCategoryChange(cat); })
          }, (cat: string) => cat)
        }
        .padding({ left: 16, right: 16, top: 10, bottom: 6 })
      }

      List() {
        ForEach(this.recommendations, (item: CityRecommendation) => {
          ListItem() {
            Row({ space: 10 }) {
              Column({ space: 4 }) {
                Text(`${item.name} · ${item.city}`)
                  .fontSize(15)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(AppColors.TEXT_PRIMARY)
                Text(item.category)
                  .fontSize(12)
                  .fontColor(AppColors.PRIMARY)
                Text(item.description)
                  .fontSize(13)
                  .fontColor(AppColors.TEXT_SECONDARY)
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(`⭐ ${item.rating.toFixed(1)} · ${item.reviewCount} reviews · 👍 ${item.upvotes}`)
                  .fontSize(12)
                  .fontColor(AppColors.TEXT_TERTIARY)
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)
            }
            .width('100%')
            .padding(14)
            .backgroundColor(AppColors.WHITE)
            .borderRadius(12)
            .border({ width: 1, color: AppColors.BORDER_LIGHT })
            .margin({ left: 16, right: 16, top: 10 })
          }
        }, (item: CityRecommendation) => item.id)
      }
      .layoutWeight(1)
      .divider({ strokeWidth: 0 })
    }
  }

  @Builder
  QATab() {
    List() {
      ForEach(this.questions, (item: Question) => {
        ListItem() {
          Row({ space: 10 }) {
            Column({ space: 4 }) {
              Text(`${item.userName} · ${item.city}`)
                .fontSize(12)
                .fontColor(AppColors.TEXT_SECONDARY)
              Text(item.title)
                .fontSize(15)
                .fontWeight(FontWeight.Bold)
                .fontColor(AppColors.TEXT_PRIMARY)
              Text(item.content)
                .fontSize(13)
                .fontColor(AppColors.TEXT_SECONDARY)
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Row({ space: 12 }) {
                Text(`💬 ${item.answerCount} answers`).fontSize(12).fontColor(AppColors.TEXT_TERTIARY)
                Text(item.isUpvoted ? `👍 ${item.upvotes}` : `👆 ${item.upvotes}`)
                  .fontSize(12)
                  .fontColor(item.isUpvoted ? AppColors.PRIMARY : AppColors.TEXT_TERTIARY)
                  .onClick(() => { this.upvoteQuestion(item.id); })
              }
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')
          .padding(14)
          .backgroundColor(AppColors.WHITE)
          .borderRadius(12)
          .border({ width: 1, color: AppColors.BORDER_LIGHT })
          .margin({ left: 16, right: 16, top: 10 })
        }
      }, (item: Question) => item.id)
    }
    .divider({ strokeWidth: 0 })
  }

  @Builder
  ActionCard(title: string, desc: string, action: () => void) {
    Row({ space: 10 }) {
      Column({ space: 4 }) {
        Text(title)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT_PRIMARY)
        Text(desc)
          .fontSize(12)
          .fontColor(AppColors.TEXT_SECONDARY)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Text('进入')
        .fontSize(12)
        .fontColor(AppColors.PRIMARY)
    }
    .width('100%')
    .padding({ left: 14, right: 14, top: 12, bottom: 12 })
    .backgroundColor(AppColors.WHITE)
    .borderRadius(12)
    .border({ width: 1, color: AppColors.BORDER_LIGHT })
    .onClick(() => {
      this.actionMessage = '';
      action();
    })
  }
}
