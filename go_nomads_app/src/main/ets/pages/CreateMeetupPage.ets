import { AppColors } from '../common/constants/AppColors';
import { MeetupService } from '../services/MeetupService';
import { Meetup, MeetupType } from '../models/Meetup';
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
  @State validationError: string = '';
  @State submitError: string = '';
  @State isPageLoading: boolean = false;
  @State isEditMode: boolean = false;

  private typeOptions: MeetupTypeOption[] = [
    new MeetupTypeOption('社交', MeetupType.Social),
    new MeetupTypeOption('共同办公', MeetupType.Coworking),
    new MeetupTypeOption('工作坊', MeetupType.Workshop),
    new MeetupTypeOption('运动', MeetupType.Sports),
    new MeetupTypeOption('文化', MeetupType.Cultural),
    new MeetupTypeOption('社交联络', MeetupType.Networking),
  ];
  private meetupId: string = '';

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>;
    this.meetupId = params?.['meetupId'] ?? '';
    this.isEditMode = this.meetupId.length > 0;

    if (this.isEditMode) {
      this.loadForEdit();
    }
  }

  private mapCategoryToType(category: string | undefined): MeetupType {
    if (!category) {
      return MeetupType.Other;
    }
    switch (category.toLowerCase()) {
      case 'social': return MeetupType.Social;
      case 'coworking': return MeetupType.Coworking;
      case 'workshop': return MeetupType.Workshop;
      case 'sports': return MeetupType.Sports;
      case 'cultural': return MeetupType.Cultural;
      case 'networking': return MeetupType.Networking;
      default: return MeetupType.Other;
    }
  }

  private fillFormByMeetup(meetup: Meetup): void {
    this.title = meetup.title;
    this.description = meetup.description ?? '';
    this.venueName = meetup.location ?? '';
    this.venueAddress = meetup.address ?? '';
    this.meetupType = this.mapCategoryToType(meetup.category);

    const startAt = new Date(meetup.startTime);
    if (!isNaN(startAt.getTime())) {
      const year = startAt.getFullYear();
      const month = (startAt.getMonth() + 1).toString().padStart(2, '0');
      const day = startAt.getDate().toString().padStart(2, '0');
      const hour = startAt.getHours().toString().padStart(2, '0');
      const minute = startAt.getMinutes().toString().padStart(2, '0');
      this.startDate = `${year}-${month}-${day}`;
      this.startTime = `${hour}:${minute}`;
    }

    if (meetup.endTime) {
      const endAt = new Date(meetup.endTime);
      if (!isNaN(endAt.getTime())) {
        const endHour = endAt.getHours().toString().padStart(2, '0');
        const endMinute = endAt.getMinutes().toString().padStart(2, '0');
        this.endTime = `${endHour}:${endMinute}`;
      }
    }

    this.maxCapacity = meetup.maxParticipants ? meetup.maxParticipants.toString() : '';
  }

  private async loadForEdit(): Promise<void> {
    this.isPageLoading = true;
    this.submitError = '';
    try {
      const meetupService = MeetupService.getInstance();
      const meetup = await meetupService.getMeetupById(this.meetupId);
      this.fillFormByMeetup(meetup);
      hilog.info(DOMAIN, TAG, '✅ 编辑模式已回填: %{public}s', meetup.title);
    } catch (err) {
      this.submitError = (err as Error).message;
      hilog.error(DOMAIN, TAG, '❌ 加载编辑数据失败: %{public}s', (err as Error).message);
    } finally {
      this.isPageLoading = false;
    }
  }

  private isDateValid(dateText: string): boolean {
    const reg = /^\d{4}-\d{2}-\d{2}$/;
    if (!reg.test(dateText)) {
      return false;
    }
    return !isNaN(new Date(`${dateText}T00:00:00`).getTime());
  }

  private isTimeValid(timeText: string): boolean {
    const reg = /^([01]\d|2[0-3]):[0-5]\d$/;
    return reg.test(timeText);
  }

  private validateForm(): boolean {
    this.validationError = '';
    const title = this.title.trim();
    const venueName = this.venueName.trim();
    const startDate = this.startDate.trim();
    const startTime = this.startTime.trim();
    const endTime = this.endTime.trim();

    if (!title) {
      this.validationError = '请输入活动标题';
      return false;
    }
    if (!venueName) {
      this.validationError = '请输入场地名称';
      return false;
    }
    if (!startDate || !this.isDateValid(startDate)) {
      this.validationError = '日期格式应为 YYYY-MM-DD';
      return false;
    }
    if (!startTime || !this.isTimeValid(startTime)) {
      this.validationError = '开始时间格式应为 HH:MM';
      return false;
    }
    if (endTime.length > 0 && !this.isTimeValid(endTime)) {
      this.validationError = '结束时间格式应为 HH:MM';
      return false;
    }
    if (endTime.length > 0) {
      const startAt = new Date(`${startDate}T${startTime}:00`).getTime();
      const endAt = new Date(`${startDate}T${endTime}:00`).getTime();
      if (endAt <= startAt) {
        this.validationError = '结束时间必须晚于开始时间';
        return false;
      }
    }
    if (this.maxCapacity.trim().length > 0) {
      const maxCap = parseInt(this.maxCapacity.trim());
      if (isNaN(maxCap) || maxCap <= 0) {
        this.validationError = '最大人数需为正整数';
        return false;
      }
    }
    return true;
  }

  async submit(): Promise<void> {
    if (this.isSubmitting) {
      return;
    }

    this.title = this.title.trim();
    this.description = this.description.trim();
    this.venueName = this.venueName.trim();
    this.venueAddress = this.venueAddress.trim();
    this.startDate = this.startDate.trim();
    this.startTime = this.startTime.trim();
    this.endTime = this.endTime.trim();
    this.maxCapacity = this.maxCapacity.trim();

    this.submitError = '';
    if (!this.validateForm()) {
      return;
    }

    this.isSubmitting = true;
    try {
      const meetupService = MeetupService.getInstance();
      const startTimeStr = `${this.startDate}T${this.startTime}:00`;
      const endTimeStr = this.endTime ? `${this.startDate}T${this.endTime}:00` : '';
      const maxCap = this.maxCapacity ? parseInt(this.maxCapacity) : 0;

      if (this.isEditMode) {
        const updates: Record<string, Object> = {
          title: this.title.trim() as Object,
          description: this.description as Object,
          location: this.venueName as Object,
          address: this.venueAddress as Object,
          category: this.meetupType as Object,
          startTime: startTimeStr as Object,
          endTime: endTimeStr as Object,
          maxParticipants: maxCap as Object,
        };
        await meetupService.updateMeetup(this.meetupId, updates);
        hilog.info(DOMAIN, TAG, '✅ 聚会更新成功');
      } else {
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
      }

      router.back();
    } catch (err) {
      this.submitError = (err as Error).message;
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
        Text(this.isEditMode ? '编辑聚会' : '创建聚会').fontSize(18).fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT_PRIMARY).layoutWeight(1).textAlign(TextAlign.Center)
        Column().width(24)
      }
      .width('100%').height(56).padding({ left: 16, right: 16 })
      .backgroundColor(AppColors.CARD_BACKGROUND)

      if (this.isPageLoading) {
        Column() {
          LoadingProgress().width(36).height(36)
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
      } else {
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

          if (this.validationError.length > 0) {
            Text(this.validationError)
              .width('100%')
              .fontSize(13)
              .fontColor(AppColors.ERROR)
              .backgroundColor('#FEE2E2')
              .borderRadius(8)
              .padding({ left: 12, right: 12, top: 8, bottom: 8 })
          }

          if (this.submitError.length > 0) {
            Text(this.submitError)
              .width('100%')
              .fontSize(13)
              .fontColor(AppColors.ERROR)
              .backgroundColor('#FEE2E2')
              .borderRadius(8)
              .padding({ left: 12, right: 12, top: 8, bottom: 8 })
          }

          // 提交
          Button(this.isSubmitting ? (this.isEditMode ? '更新中...' : '创建中...') : (this.isEditMode ? '更新聚会' : '创建聚会'))
            .width('100%').height(48).borderRadius(10)
            .backgroundColor(AppColors.PRIMARY).fontColor('#FFFFFF').fontSize(16)
            .enabled(!this.isSubmitting)
            .margin({ top: 8 })
            .onClick(async () => { await this.submit(); })

          Column().height(40)
        }
        .padding({ left: 16, right: 16, top: 16 })
        }
        .layoutWeight(1).scrollBar(BarState.Off)
      }
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
