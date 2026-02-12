import { AppColors } from '../common/constants/AppColors';
import { AppStorageKeys } from '../common/constants/AppStorageKeys';
import { MeetupService } from '../services/MeetupService';
import { MeetupType } from '../models/Meetup';
import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'CreateMeetupPage';
const DOMAIN = 0x0001;

/**
 * 聚会类型选项
 */
class MeetupTypeOption {
  label: string = '';
  value: MeetupType = MeetupType.Social;

  constructor(label: string, value: MeetupType) {
    this.label = label;
    this.value = value;
  }
}

/**
 * 创建聚会页 — 对应 Flutter create_meetup 目录
 */
@Entry
@Component
struct CreateMeetupPage {
  @State title: string = '';
  @State description: string = '';
  @State venueName: string = '';
  @State venueAddress: string = '';
  @State meetupType: MeetupType = MeetupType.Social;
  @State startDate: string = '';
  @State startTime: string = '';
  @State endTime: string = '';
  @State maxCapacity: string = '';
  @State isSubmitting: boolean = false;

  private typeOptions: MeetupTypeOption[] = [
    new MeetupTypeOption('社交', MeetupType.Social),
    new MeetupTypeOption('共同办公', MeetupType.Coworking),
    new MeetupTypeOption('工作坊', MeetupType.Workshop),
    new MeetupTypeOption('运动', MeetupType.Sports),
    new MeetupTypeOption('文化', MeetupType.Cultural),
    new MeetupTypeOption('社交联络', MeetupType.Networking),
  ];

  async submit(): Promise<void> {
    if (!this.title.trim() || !this.venueName.trim() || !this.startDate || !this.startTime) {
      return; // 基础校验
    }
    this.isSubmitting = true;
    try {
      const meetupService = MeetupService.getInstance();
      const startTimeStr = `${this.startDate}T${this.startTime}:00`;
      const endTimeStr = this.endTime ? `${this.startDate}T${this.endTime}:00` : '';
      const maxCap = this.maxCapacity ? parseInt(this.maxCapacity) : 0;
      await meetupService.createMeetup(
        this.title,
        this.description,
        this.venueName,
        this.venueAddress,
        this.meetupType,
        startTimeStr,
        endTimeStr,
        maxCap
      );
      hilog.info(DOMAIN, TAG, '✅ 聚会创建成功');
      router.back();
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ 创建失败: %{public}s', (err as Error).message);
    } finally {
      this.isSubmitting = false;
    }
  }

  build() {
    Column() {
      // 顶部
      Row() {
        SymbolGlyph($r('sys.symbol.arrow_left'))
          .fontSize(24).fontColor([AppColors.TEXT_PRIMARY]).onClick(() => { router.back(); })
        Text('创建聚会').fontSize(18).fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT_PRIMARY).layoutWeight(1).textAlign(TextAlign.Center)
        Column().width(24)
      }
      .width('100%').height(56).padding({ left: 16, right: 16 })
      .backgroundColor(AppColors.CARD_BACKGROUND)

      Scroll() {
        Column({ space: 20 }) {
          // 标题
          this.Field('活动标题 *', this.title, '给你的聚会起个名字', (v: string) => { this.title = v; })

          // 类型选择
          Column({ space: 8 }) {
            Text('活动类型').fontSize(14).fontColor(AppColors.TEXT_SECONDARY)
            Flex({ wrap: FlexWrap.Wrap }) {
              ForEach(this.typeOptions, (opt: MeetupTypeOption) => {
                Text(opt.label)
                  .fontSize(13)
                  .fontColor(this.meetupType === opt.value ? '#FFFFFF' : AppColors.TEXT_SECONDARY)
                  .backgroundColor(this.meetupType === opt.value ? AppColors.PRIMARY : '#F1F5F9')
                  .borderRadius(14)
                  .padding({ left: 14, right: 14, top: 6, bottom: 6 })
                  .margin({ right: 8, bottom: 8 })
                  .onClick(() => { this.meetupType = opt.value; })
              }, (opt: MeetupTypeOption) => opt.label)
            }
          }
          .width('100%').alignItems(HorizontalAlign.Start)

          // 描述
          Column({ space: 6 }) {
            Text('活动描述').fontSize(14).fontColor(AppColors.TEXT_SECONDARY)
            TextArea({ text: this.description, placeholder: '介绍一下你的聚会活动...' })
              .width('100%').height(120).borderRadius(8).backgroundColor('#F8FAFC')
              .padding(12).onChange((v: string) => { this.description = v; })
          }
          .width('100%').alignItems(HorizontalAlign.Start)

          // 时间
          Row({ space: 12 }) {
            Column({ space: 6 }) {
              Text('日期 *').fontSize(14).fontColor(AppColors.TEXT_SECONDARY)
              TextInput({ text: this.startDate, placeholder: 'YYYY-MM-DD' })
                .width('100%').height(44).borderRadius(8).backgroundColor('#F8FAFC')
                .onChange((v: string) => { this.startDate = v; })
            }.layoutWeight(1)

            Column({ space: 6 }) {
              Text('开始时间 *').fontSize(14).fontColor(AppColors.TEXT_SECONDARY)
              TextInput({ text: this.startTime, placeholder: 'HH:MM' })
                .width('100%').height(44).borderRadius(8).backgroundColor('#F8FAFC')
                .onChange((v: string) => { this.startTime = v; })
            }.layoutWeight(1)
          }.width('100%')

          Row({ space: 12 }) {
            Column({ space: 6 }) {
              Text('结束时间').fontSize(14).fontColor(AppColors.TEXT_SECONDARY)
              TextInput({ text: this.endTime, placeholder: 'HH:MM' })
                .width('100%').height(44).borderRadius(8).backgroundColor('#F8FAFC')
                .onChange((v: string) => { this.endTime = v; })
            }.layoutWeight(1)

            Column({ space: 6 }) {
              Text('最大人数').fontSize(14).fontColor(AppColors.TEXT_SECONDARY)
              TextInput({ text: this.maxCapacity, placeholder: '不限' })
                .width('100%').height(44).borderRadius(8).backgroundColor('#F8FAFC')
                .type(InputType.Number)
                .onChange((v: string) => { this.maxCapacity = v; })
            }.layoutWeight(1)
          }.width('100%')

          // 地点
          this.Field('场地名称 *', this.venueName, '咖啡馆、公园...', (v: string) => { this.venueName = v; })
          this.Field('详细地址', this.venueAddress, '具体地址', (v: string) => { this.venueAddress = v; })

          // 提交
          Button(this.isSubmitting ? '创建中...' : '创建聚会')
            .width('100%').height(48).borderRadius(10)
            .backgroundColor(AppColors.PRIMARY).fontColor('#FFFFFF').fontSize(16)
            .enabled(!this.isSubmitting)
            .margin({ top: 8 })
            .onClick(() => { this.submit(); })

          Column().height(40)
        }
        .padding({ left: 16, right: 16, top: 16 })
      }
      .layoutWeight(1).scrollBar(BarState.Off)
    }
    .width('100%').height('100%').backgroundColor(AppColors.BACKGROUND)
  }

  @Builder
  Field(label: string, value: string, placeholder: string, onChange: (v: string) => void) {
    Column({ space: 6 }) {
      Text(label).fontSize(14).fontColor(AppColors.TEXT_SECONDARY)
      TextInput({ text: value, placeholder: placeholder })
        .width('100%').height(44).borderRadius(8).backgroundColor('#F8FAFC')
        .padding({ left: 12, right: 12 }).onChange(onChange)
    }
    .width('100%').alignItems(HorizontalAlign.Start)
  }
}
