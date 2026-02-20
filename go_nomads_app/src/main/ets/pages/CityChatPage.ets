import { router } from '@kit.ArkUI';

@Entry
@Component
struct CityChatPage {
  @State hasError: boolean = false;

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>;
    const chatId = params?.['chatId'] ?? params?.['cityId'] ?? '';
    if (!chatId) {
      this.hasError = true;
      return;
    }

    router.replaceUrl({
      url: 'pages/ChatPage',
      params: {
        chatId: chatId,
        chatTitle: params?.['chatTitle'] ?? params?.['cityName'] ?? '城市聊天',
      },
    });
  }

  build() {
    Column() {
      if (this.hasError) {
        Column({ space: 10 }) {
          Text('未找到城市会话')
            .fontSize(14)
            .fontColor('#EF4444')
          Button('返回')
            .height(36)
            .onClick(() => { router.back(); })
        }
      } else {
        LoadingProgress().width(36).height(36)
      }
    }
    .width('100%').height('100%').justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
