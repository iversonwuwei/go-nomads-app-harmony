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
    this.loadMessages();
  }

  async loadMessages(): Promise<void> {
    this.isLoading = true;
    try {
      const chatService = ChatService.getInstance();
      const messages = await chatService.getMessages(this.chatId, 1, 50);
      this.messages = messages;
      this.scrollToBottom();
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ 加载消息失败: %{public}s', (err as Error).message);
    } finally {
      this.isLoading = false;
    }
  }

  async sendMessage(): Promise<void> {
    const text = this.inputText.trim();
    if (!text || this.isSending) return;

    this.isSending = true;
    const authUser = AuthStore.getInstance().currentUser;
    const tempMsg: ChatMessage = {
      id: `temp_${Date.now()}`,
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
      await chatService.sendMessage(this.chatId, text);
    } catch (err) {
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
      if (this.isLoading) {
        Column() {
          LoadingProgress().width(40).height(40)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        this.MessageList()
      }

      // 底部输入栏
      this.InputBar()
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

      // 更多操作
      Text('⋯')
        .fontSize(22)
        .fontColor(AppColors.TEXT_PRIMARY)
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
      Column() {
        Text(msg.content)
          .fontSize(15)
          .fontColor('#FFFFFF')
          .lineHeight(22)
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
      Column() {
        Text(msg.content)
          .fontSize(15)
          .fontColor(AppColors.TEXT_PRIMARY)
          .lineHeight(22)
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
}
