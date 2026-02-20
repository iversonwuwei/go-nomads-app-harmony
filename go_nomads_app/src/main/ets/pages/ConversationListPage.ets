import { ConversationListTab } from './tabs/ConversationListTab';

/**
 * 会话列表页面
 * 作为 RouteConstants.CONVERSATION_LIST 的可直达页面壳，内部复用 ConversationListTab。
 */
@Entry
@Component
struct ConversationListPage {
  build() {
    Column() {
      ConversationListTab();
    }
    .width('100%')
    .height('100%')
  }
}
