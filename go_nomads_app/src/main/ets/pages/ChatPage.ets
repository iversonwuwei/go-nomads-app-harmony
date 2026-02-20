import { AppColors } from '../common/constants/AppColors';
import { AppStorageKeys } from '../common/constants/AppStorageKeys';
import { ChatService, ChatMessage } from '../services/ChatService';
import { AuthStore } from '../state/AuthStore';
import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'ChatPage';
const DOMAIN = 0x0001;

/**
 * 聊天页面 - 对应 Flutter 端 DirectChatPage
 */
@Entry
@Component
struct ChatPage {
  @State messages: ChatMessage[] = [];
  @State inputText: string = '';
  @State isLoading: boolean = true;
  @State isSending: boolean = false;
  @State hasError: boolean = false;
  @State errorMsg: string = '';
  @State actionMessage: string = '';
  @StorageProp(AppStorageKeys.IS_AUTHENTICATED) isAuthenticated: boolean = false;

  private chatId: string = '';
  private chatTitle: string = '';
  private scroller: Scroller = new Scroller();

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>;
    if (params) {
      this.chatId = params['chatId'] ?? '';
      this.chatTitle = params['chatTitle'] ?? '聊天';
    }

    if (!this.chatId) {
      this.hasError = true;
      this.errorMsg = '未找到会话 ID';
      this.isLoading = false;
      return;
    }

    this.loadMessages();
  }

  async loadMessages(): Promise<void> {
    this.isLoading = true;
    this.hasError = false;
    this.errorMsg = '';
    try {
      const chatService = ChatService.getInstance();
      const messages = await chatService.getMessages(this.chatId, 1, 50);
      this.messages = messages;
      this.scrollToBottom();
    } catch (err) {
      this.hasError = true;
      this.errorMsg = (err as Error).message;
      hilog.error(DOMAIN, TAG, '❌ 加载消息失败: %{public}s', this.errorMsg);
    } finally {
      this.isLoading = false;
    }
  }

  async sendMessage(): Promise<void> {
    const text = this.inputText.trim();
    if (!text || this.isSending) return;

    this.isSending = true;
    const authUser = AuthStore.getInstance().currentUser;
    const tempId = `temp_${Date.now()}`;
    const tempMsg: ChatMessage = {
      id: tempId,
      roomId: this.chatId,
      senderId: authUser ? authUser.id : 'me',
      senderName: authUser ? authUser.userName : 'Me',
      content: text,
      createdAt: new Date().toISOString(),
      isDeleted: false,
    };
    this.messages.push(tempMsg);
    this.inputText = '';
    this.scrollToBottom();

    try {
      const chatService = ChatService.getInstance();
      const sent = await chatService.sendMessage(this.chatId, text);
      const idx = this.messages.findIndex((m: ChatMessage) => m.id === tempId);
      if (idx >= 0) {
        this.messages[idx] = sent;
      } else {
        this.messages.push(sent);
      }
      this.actionMessage = '';
    } catch (err) {
      const idx = this.messages.findIndex((m: ChatMessage) => m.id === tempId);
      if (idx >= 0) {
        this.messages.splice(idx, 1);
        this.messages = [...this.messages];
      }
      this.actionMessage = `发送失败：${(err as Error).message}`;
      hilog.error(DOMAIN, TAG, '❌ 发送失败: %{public}s', (err as Error).message);
    } finally {
      this.isSending = false;
    }
  }

  scrollToBottom(): void {
    setTimeout(() => {
      this.scroller.scrollEdge(Edge.Bottom);
    }, 100);
  }

  isMyMessage(msg: ChatMessage): boolean {
    const authUser = AuthStore.getInstance().currentUser;
    if (authUser) {
      return msg.senderId === authUser.id;
    }
    return msg.senderId === 'me';
  }

  build() {
    Column() {
      // 顶部栏
      this.TopBar()

      // 消息列表
      if (!this.isAuthenticated) {
        Column({ space: 12 }) {
          Text('登录后可使用聊天功能')
            .fontSize(14)
            .fontColor(AppColors.TEXT_SECONDARY)
          Button('去登录')
            .height(36)
            .borderRadius(18)
            .backgroundColor(AppColors.PRIMARY)
            .fontColor(AppColors.WHITE)
            .onClick(() => {
              router.pushUrl({ url: `pages/LoginPage` });
            })
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else if (this.isLoading) {
        Column() {
          LoadingProgress().width(40).height(40)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.hasError) {
        Column({ space: 12 }) {
          Text(this.errorMsg.length > 0 ? this.errorMsg : '加载失败')
            .fontSize(14)
            .fontColor(AppColors.ERROR)
            .textAlign(TextAlign.Center)
          Button('重试')
            .height(36)
            .borderRadius(18)
            .backgroundColor(AppColors.PRIMARY)
            .fontColor(AppColors.WHITE)
            .onClick(async () => {
              await this.loadMessages();
            })
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        this.MessageList()
      }

      if (this.actionMessage.length > 0) {
        Text(this.actionMessage)
          .fontSize(12)
          .fontColor(AppColors.ERROR)
          .backgroundColor('#FEE2E2')
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .borderRadius(8)
          .margin({ left: 12, right: 12, bottom: 6 })
      }

      // 底部输入栏
      if (this.isAuthenticated && !this.hasError) {
        this.InputBar()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8FAFC')
  }

  @Builder
  TopBar() {
    Row() {
      SymbolGlyph($r('sys.symbol.arrow_left'))
        .fontSize(24)
        .fontColor([AppColors.TEXT_PRIMARY])
        .onClick(() => {
          router.back();
        })

      Text(this.chatTitle)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.TEXT_PRIMARY)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      Text('刷新')
        .fontSize(12)
        .fontColor(AppColors.PRIMARY)
        .onClick(async () => {
          await this.loadMessages();
        })
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor(AppColors.CARD_BACKGROUND)
    .shadow({ radius: 2, color: '#00000008', offsetX: 0, offsetY: 1 })
  }

  @Builder
  MessageList() {
    if (this.messages.length === 0) {
      Column() {
        Text('💬').fontSize(48)
        Text('开始聊天吧').fontSize(14).fontColor(AppColors.TEXT_TERTIARY).margin({ top: 8 })
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
    } else {
      List({ scroller: this.scroller }) {
        ForEach(this.messages, (msg: ChatMessage) => {
          ListItem() {
            if (this.isMyMessage(msg)) {
              this.SentMessage(msg)
            } else {
              this.ReceivedMessage(msg)
            }
          }
        }, (msg: ChatMessage) => msg.id)
      }
      .layoutWeight(1)
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .divider({ strokeWidth: 0 })
    }
  }

  @Builder
  SentMessage(msg: ChatMessage) {
    Row() {
      Blank()
      Column({ space: 4 }) {
        Text(msg.content)
          .fontSize(15)
          .fontColor('#FFFFFF')
          .lineHeight(22)

        Text(this.formatTime(msg.createdAt))
          .fontSize(10)
          .fontColor('#FFFFFFCC')
      }
      .constraintSize({ maxWidth: '72%' })
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .backgroundColor(AppColors.PRIMARY)
      .borderRadius({ topLeft: 16, topRight: 4, bottomLeft: 16, bottomRight: 16 })
    }
    .width('100%')
    .padding({ top: 4, bottom: 4 })
  }

  @Builder
  ReceivedMessage(msg: ChatMessage) {
    Row() {
      Column({ space: 4 }) {
        if (msg.senderName.length > 0) {
          Text(msg.senderName)
            .fontSize(11)
            .fontColor(AppColors.TEXT_TERTIARY)
        }

        Text(msg.content)
          .fontSize(15)
          .fontColor(AppColors.TEXT_PRIMARY)
          .lineHeight(22)

        Text(this.formatTime(msg.createdAt))
          .fontSize(10)
          .fontColor(AppColors.TEXT_TERTIARY)
      }
      .constraintSize({ maxWidth: '72%' })
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .backgroundColor(AppColors.CARD_BACKGROUND)
      .borderRadius({ topLeft: 4, topRight: 16, bottomLeft: 16, bottomRight: 16 })

      Blank()
    }
    .width('100%')
    .padding({ top: 4, bottom: 4 })
  }

  @Builder
  SystemMessage(msg: ChatMessage) {
    Row() {
      Text(msg.content)
        .fontSize(12)
        .fontColor(AppColors.TEXT_TERTIARY)
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .padding({ top: 8, bottom: 8 })
  }

  @Builder
  InputBar() {
    Row({ space: 8 }) {
      TextInput({ placeholder: '输入消息...', text: this.inputText })
        .layoutWeight(1)
        .height(40)
        .borderRadius(20)
        .backgroundColor('#F1F5F9')
        .padding({ left: 16, right: 16 })
        .onChange((value: string) => {
          this.inputText = value;
        })
        .onSubmit(() => {
          this.sendMessage();
        })

      Button('发送')
        .height(40)
        .borderRadius(20)
        .backgroundColor(this.inputText.trim() ? AppColors.PRIMARY : '#CBD5E1')
        .fontColor('#FFFFFF')
        .fontSize(14)
        .enabled(!!this.inputText.trim() && !this.isSending)
        .onClick(() => {
          this.sendMessage();
        })
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 8, bottom: 8 })
    .backgroundColor(AppColors.CARD_BACKGROUND)
    .shadow({ radius: 4, color: '#00000008', offsetX: 0, offsetY: -1 })
  }

  private formatTime(iso: string): string {
    if (!iso) return '--:--';
    const date = new Date(iso);
    return date.toLocaleTimeString('zh-CN', { hour: '2-digit', minute: '2-digit', hour12: false });
  }
}
