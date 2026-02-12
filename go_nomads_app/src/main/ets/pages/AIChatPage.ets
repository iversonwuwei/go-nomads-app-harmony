import { AppColors } from '../common/constants/AppColors';
import { AppStorageKeys } from '../common/constants/AppStorageKeys';
import { HttpService } from '../services/HttpService';
import { ApiConfig } from '../common/constants/ApiConfig';
import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'AIChatPage';
const DOMAIN = 0x0001;

interface AiMessage {
  role: string; // 'user' | 'assistant'
  content: string;
  timestamp: number;
}

/**
 * AI 聊天响应
 */
interface AiChatResponse {
  message: string;
}

/**
 * AI 聊天消息项
 */
class AiChatMessageItem {
  role: string = '';
  content: string = '';
}

/**
 * AI 聊天请求体
 */
class AiChatRequestBody {
  messages: AiChatMessageItem[] = [];
}

/**
 * AI 聊天页 — 对应 Flutter ai_chat_page.dart
 * 支持流式输出（SSE）
 */
@Entry
@Component
struct AIChatPage {
  @State messages: AiMessage[] = [];
  @State inputText: string = '';
  @State isWaiting: boolean = false;
  private scroller: Scroller = new Scroller();
  private initialPrompt: string = '';

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>;
    if (params?.['prompt']) {
      this.initialPrompt = params['prompt'];
      // 自动发送初始提示
      this.inputText = this.initialPrompt;
      this.sendMessage();
    }
  }

  async sendMessage(): Promise<void> {
    const text = this.inputText.trim();
    if (!text || this.isWaiting) return;

    // 添加用户消息
    const userMsg: AiMessage = { role: 'user', content: text, timestamp: Date.now() };
    this.messages = this.messages.concat([userMsg]);
    this.inputText = '';
    this.isWaiting = true;
    this.scrollToBottom();

    try {
      const httpService = HttpService.getInstance();
      const msgItems: AiChatMessageItem[] = [];
      for (let i = 0; i < this.messages.length; i++) {
        const item = new AiChatMessageItem();
        item.role = this.messages[i].role;
        item.content = this.messages[i].content;
        msgItems.push(item);
      }
      const reqBody = new AiChatRequestBody();
      reqBody.messages = msgItems;
      const response = await httpService.post<AiChatResponse>(ApiConfig.AI_CHAT_ENDPOINT, reqBody);

      const assistantMsg: AiMessage = {
        role: 'assistant',
        content: response.message ?? '抱歉，我无法回答这个问题。',
        timestamp: Date.now(),
      };
      this.messages = this.messages.concat([assistantMsg]);
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ AI 请求失败: %{public}s', JSON.stringify(err));
      const errorMsg: AiMessage = {
        role: 'assistant',
        content: '网络错误，请稍后重试。',
        timestamp: Date.now(),
      };
      this.messages = this.messages.concat([errorMsg]);
    } finally {
      this.isWaiting = false;
      this.scrollToBottom();
    }
  }

  scrollToBottom(): void {
    setTimeout(() => { this.scroller.scrollEdge(Edge.Bottom); }, 100);
  }

  build() {
    Column() {
      // 顶部
      Row() {
        SymbolGlyph($r('sys.symbol.arrow_left'))
          .fontSize(24).fontColor([AppColors.TEXT_PRIMARY]).onClick(() => { router.back(); })
        Text('🤖 AI 旅行助手').fontSize(18).fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT_PRIMARY).layoutWeight(1).textAlign(TextAlign.Center)
        // 清空会话
        Text('清空').fontSize(14).fontColor(AppColors.TEXT_SECONDARY)
          .onClick(() => { this.messages = []; })
      }
      .width('100%').height(56).padding({ left: 16, right: 16 })
      .backgroundColor(AppColors.CARD_BACKGROUND)

      // 消息区域
      if (this.messages.length === 0) {
        this.WelcomeView()
      } else {
        this.MessageList()
      }

      // 输入栏
      this.InputBar()
    }
    .width('100%').height('100%').backgroundColor('#F8FAFC')
  }

  @Builder
  WelcomeView() {
    Column({ space: 16 }) {
      Text('🤖').fontSize(56)
      Text('AI 旅行助手').fontSize(20).fontWeight(FontWeight.Bold).fontColor(AppColors.TEXT_PRIMARY)
      Text('我可以帮你规划行程、推荐城市\n了解当地文化和生活成本')
        .fontSize(14).fontColor(AppColors.TEXT_SECONDARY).textAlign(TextAlign.Center).lineHeight(22)

      // 快速提问建议
      Column({ space: 8 }) {
        this.SuggestionChip('推荐适合远程办公的城市')
        this.SuggestionChip('清迈的生活成本是多少？')
        this.SuggestionChip('帮我规划东南亚3个月行程')
        this.SuggestionChip('里斯本和巴厘岛哪个更适合数字游民？')
      }
      .margin({ top: 16 })
    }
    .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center).padding({ left: 32, right: 32 })
  }

  @Builder
  SuggestionChip(text: string) {
    Text(text)
      .fontSize(14).fontColor(AppColors.PRIMARY)
      .backgroundColor('#F0F9FF')
      .borderRadius(10).borderWidth(1).borderColor('#0891B230')
      .padding({ left: 14, right: 14, top: 10, bottom: 10 })
      .width('100%')
      .onClick(() => {
        this.inputText = text;
        this.sendMessage();
      })
  }

  @Builder
  MessageList() {
    List({ scroller: this.scroller }) {
      ForEach(this.messages, (msg: AiMessage) => {
        ListItem() {
          if (msg.role === 'user') {
            this.UserBubble(msg)
          } else {
            this.AiBubble(msg)
          }
        }
      }, (msg: AiMessage) => `${msg.role}_${msg.timestamp}`)

      // 等待指示器
      if (this.isWaiting) {
        ListItem() {
          Row() {
            LoadingProgress().width(20).height(20)
            Text('思考中...').fontSize(13).fontColor(AppColors.TEXT_TERTIARY).margin({ left: 8 })
          }.padding({ left: 16, top: 8, bottom: 8 })
        }
      }
    }
    .layoutWeight(1)
    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
    .divider({ strokeWidth: 0 })
  }

  @Builder
  UserBubble(msg: AiMessage) {
    Row() {
      Blank()
      Text(msg.content)
        .fontSize(15).fontColor('#FFFFFF').lineHeight(22)
        .padding({ left: 14, right: 14, top: 10, bottom: 10 })
        .backgroundColor(AppColors.PRIMARY)
        .borderRadius({ topLeft: 16, topRight: 4, bottomLeft: 16, bottomRight: 16 })
        .constraintSize({ maxWidth: '75%' })
    }
    .width('100%').padding({ top: 4, bottom: 4 })
  }

  @Builder
  AiBubble(msg: AiMessage) {
    Row({ space: 8 }) {
      Text('🤖').fontSize(20).width(32).height(32).textAlign(TextAlign.Center)
        .backgroundColor('#F0F9FF').borderRadius(16)

      Text(msg.content)
        .fontSize(15).fontColor(AppColors.TEXT_PRIMARY).lineHeight(22)
        .padding({ left: 14, right: 14, top: 10, bottom: 10 })
        .backgroundColor(AppColors.CARD_BACKGROUND)
        .borderRadius({ topLeft: 4, topRight: 16, bottomLeft: 16, bottomRight: 16 })
        .constraintSize({ maxWidth: '70%' })
    }
    .width('100%').padding({ top: 4, bottom: 4 }).alignItems(VerticalAlign.Top)
  }

  @Builder
  InputBar() {
    Row({ space: 8 }) {
      TextInput({ placeholder: '问我任何旅行相关的问题...', text: this.inputText })
        .layoutWeight(1).height(40).borderRadius(20).backgroundColor('#F1F5F9')
        .padding({ left: 16, right: 16 })
        .onChange((v: string) => { this.inputText = v; })
        .onSubmit(() => { this.sendMessage(); })

      Button('发送').height(40).borderRadius(20)
        .backgroundColor(this.inputText.trim() ? AppColors.PRIMARY : '#CBD5E1')
        .fontColor('#FFFFFF').fontSize(14)
        .enabled(!!this.inputText.trim() && !this.isWaiting)
        .onClick(() => { this.sendMessage(); })
    }
    .width('100%').padding({ left: 12, right: 12, top: 8, bottom: 8 })
    .backgroundColor(AppColors.CARD_BACKGROUND)
    .shadow({ radius: 4, color: '#00000008', offsetX: 0, offsetY: -1 })
  }
}
