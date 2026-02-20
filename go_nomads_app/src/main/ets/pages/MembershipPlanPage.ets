import { AppColors } from '../common/constants/AppColors';
import { MembershipPlan, UserMembership } from '../models/Membership';
import { MembershipService } from '../services/MembershipService';
import { router } from '@kit.ArkUI';

@Entry
@Component
struct MembershipPlanPage {
  @State membership: UserMembership | null = null;
  @State plans: MembershipPlan[] = [];
  @State isLoading: boolean = true;
  @State isUpgrading: boolean = false;
  @State hasError: boolean = false;
  @State errorMsg: string = '';
  @State selectedPlanLevel: number = -1;
  @State actionMessage: string = '';

  aboutToAppear(): void {
    this.loadData();
  }

  private async loadData(): Promise<void> {
    this.isLoading = true;
    this.hasError = false;
    this.errorMsg = '';
    try {
      const service = MembershipService.getInstance();
      this.membership = await service.getMembership();
      this.plans = (await service.getPlans()).filter((p) => p.level > 0);
      this.selectedPlanLevel = this.membership ? this.membership.level : 0;
    } catch (err) {
      this.hasError = true;
      this.errorMsg = (err as Error).message;
    } finally {
      this.isLoading = false;
    }
  }

  private levelLabel(level: number): string {
    if (level <= 0) return 'Free';
    if (level === 1) return 'Pro';
    if (level >= 2) return 'Premium';
    return 'Free';
  }

  private async upgrade(plan: MembershipPlan): Promise<void> {
    if (this.isUpgrading) {
      return;
    }
    this.isUpgrading = true;
    this.actionMessage = '';
    try {
      const service = MembershipService.getInstance();
      const updated = await service.upgradeMembership(plan.level, 365);
      this.membership = updated;
      this.selectedPlanLevel = updated.level;
      this.actionMessage = `已升级到 ${plan.name}`;
    } catch (err) {
      this.actionMessage = `升级失败：${(err as Error).message}`;
    } finally {
      this.isUpgrading = false;
    }
  }

  build() {
    Column({ space: 12 }) {
      Row() {
        SymbolGlyph($r('sys.symbol.arrow_left')).fontSize(24).fontColor([AppColors.TEXT_PRIMARY]).onClick(() => { router.back(); })
        Text('会员计划').fontSize(18).fontWeight(FontWeight.Medium).layoutWeight(1).textAlign(TextAlign.Center)
        Column().width(24)
      }
      .width('100%').height(56).padding({ left: 16, right: 16 })
      .backgroundColor(AppColors.CARD_BACKGROUND)

      if (this.isLoading) {
        Column() {
          LoadingProgress().width(40).height(40)
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
      } else if (this.hasError) {
        Column({ space: 10 }) {
          Text(this.errorMsg.length > 0 ? this.errorMsg : '加载会员计划失败')
            .fontSize(14)
            .fontColor(AppColors.ERROR)
            .textAlign(TextAlign.Center)
          Button('重试')
            .height(40)
            .borderRadius(10)
            .backgroundColor(AppColors.PRIMARY)
            .fontColor(AppColors.WHITE)
            .onClick(async () => {
              await this.loadData();
            })
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        Scroll() {
          Column({ space: 12 }) {
            this.CurrentStatusCard()

            if (this.actionMessage.length > 0) {
              Text(this.actionMessage)
                .width('100%')
                .fontSize(13)
                .fontColor(this.actionMessage.startsWith('升级失败') ? AppColors.ERROR : AppColors.SUCCESS)
                .backgroundColor(this.actionMessage.startsWith('升级失败') ? '#FEE2E2' : '#ECFDF5')
                .borderRadius(8)
                .padding({ left: 12, right: 12, top: 8, bottom: 8 })
            }

            ForEach(this.plans, (plan: MembershipPlan) => {
              this.PlanCard(plan)
            }, (plan: MembershipPlan) => plan.id)
          }
          .width('100%')
        }
        .layoutWeight(1)
      }
    }
    .width('100%').height('100%').padding({ left: 16, right: 16, top: 8, bottom: 16 })
    .backgroundColor(AppColors.BACKGROUND)
  }

  @Builder
  CurrentStatusCard() {
    Column({ space: 8 }) {
      Text('当前会员状态')
        .fontSize(14)
        .fontColor(AppColors.TEXT_SECONDARY)

      Row() {
        Column({ space: 4 }) {
          Text(this.membership ? this.levelLabel(this.membership!.level) : 'Free')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.WHITE)
          Text(
            this.membership && this.membership!.isExpired
              ? '已过期'
              : (this.membership ? `剩余 ${this.membership!.remainingDays} 天` : '免费计划')
          )
            .fontSize(12)
            .fontColor('#FFFFFFCC')
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Text(this.membership && this.membership!.canUseAI ? 'AI 可用' : 'AI 受限')
          .fontSize(12)
          .fontColor('#FFFFFF')
          .backgroundColor('#FFFFFF33')
          .borderRadius(10)
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
      }
      .width('100%')
    }
    .width('100%')
    .padding(14)
    .borderRadius(12)
    .backgroundColor(AppColors.PRIMARY)
  }

  @Builder
  PlanCard(plan: MembershipPlan) {
    const selected = this.selectedPlanLevel === plan.level;
    Column({ space: 8 }) {
      Row() {
        Text(plan.name).fontSize(18).fontWeight(FontWeight.Bold).fontColor(AppColors.TEXT_PRIMARY).layoutWeight(1)
        Text(`¥${plan.priceMonthly.toFixed(0)}/月`).fontSize(16).fontColor(AppColors.PRIMARY).fontWeight(FontWeight.Medium)
      }
      Column({ space: 4 }) {
        ForEach(plan.features.slice(0, 6), (perk: string) => {
          Text(`• ${perk}`).fontSize(13).fontColor(selected ? AppColors.TEXT_PRIMARY : AppColors.TEXT_SECONDARY)
        }, (perk: string) => perk)
      }
      Button(selected ? '当前已选' : '选择此计划')
        .height(40)
        .borderRadius(10)
        .backgroundColor(selected ? '#E2E8F0' : AppColors.PRIMARY)
        .fontColor(selected ? AppColors.TEXT_SECONDARY : AppColors.WHITE)
        .enabled(!selected && !this.isUpgrading)
        .onClick(() => {
          this.upgrade(plan);
        })
    }
    .width('100%').padding(14).backgroundColor(AppColors.WHITE)
    .borderRadius(12)
    .border({ width: selected ? 2 : 1, color: selected ? AppColors.PRIMARY : AppColors.BORDER_LIGHT })
  }
}
