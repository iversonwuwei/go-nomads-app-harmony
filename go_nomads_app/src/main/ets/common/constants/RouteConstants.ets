/**
 * 路由常量 - 对应 Flutter 端 AppRoutes
 */
export class RouteConstants {
  // ============================================================
  // 启动 & 认证
  // ============================================================
  static readonly SPLASH: string = 'SplashPage';
  static readonly LOGIN: string = 'LoginPage';
  static readonly REGISTER: string = 'RegisterPage';

  // ============================================================
  // 主框架
  // ============================================================
  static readonly MAIN: string = 'MainPage';
  static readonly HOME: string = 'HomePage';

  // ============================================================
  // 城市相关
  // ============================================================
  static readonly CITY_LIST: string = 'CityListPage';
  static readonly CITY_DETAIL: string = 'CityDetailPage';
  static readonly CITY_SEARCH: string = 'CitySearchPage';
  static readonly FAVORITES: string = 'FavoritesPage';
  static readonly GLOBAL_MAP: string = 'GlobalMapPage';
  static readonly ADD_REVIEW: string = 'AddReviewPage';
  static readonly ADD_COST: string = 'AddCostPage';
  static readonly ADD_PROS_CONS: string = 'AddProsConsPage';

  // ============================================================
  // 活动相关
  // ============================================================
  static readonly MEETUP_LIST: string = 'MeetupListPage';
  static readonly MEETUP_DETAIL: string = 'MeetupDetailPage';
  static readonly CREATE_MEETUP: string = 'CreateMeetupPage';
  static readonly MY_MEETUPS: string = 'MyMeetupsPage';

  // ============================================================
  // 共享办公
  // ============================================================
  static readonly COWORKING_LIST: string = 'CoworkingListPage';
  static readonly COWORKING_DETAIL: string = 'CoworkingDetailPage';
  static readonly ADD_COWORKING: string = 'AddCoworkingPage';

  // ============================================================
  // 酒店
  // ============================================================
  static readonly HOTEL_LIST: string = 'HotelListPage';
  static readonly HOTEL_DETAIL: string = 'HotelDetailPage';

  // ============================================================
  // 创新项目
  // ============================================================
  static readonly INNOVATION_LIST: string = 'InnovationListPage';
  static readonly INNOVATION_DETAIL: string = 'InnovationDetailPage';

  // ============================================================
  // 聊天
  // ============================================================
  static readonly CONVERSATION_LIST: string = 'ConversationListPage';
  static readonly DIRECT_CHAT: string = 'DirectChatPage';
  static readonly CITY_CHAT: string = 'CityChatPage';

  // ============================================================
  // AI 聊天
  // ============================================================
  static readonly AI_CHAT: string = 'AIChatPage';

  // ============================================================
  // 旅行计划
  // ============================================================
  static readonly TRAVEL_PLAN: string = 'TravelPlanPage';
  static readonly CREATE_TRAVEL_PLAN: string = 'CreateTravelPlanPage';
  static readonly TRAVEL_HISTORY: string = 'TravelHistoryPage';
  static readonly VISITED_PLACES: string = 'VisitedPlacesPage';

  // ============================================================
  // 用户相关
  // ============================================================
  static readonly PROFILE: string = 'ProfilePage';
  static readonly PROFILE_EDIT: string = 'ProfileEditPage';
  static readonly USER_PROFILE: string = 'UserProfilePage';
  static readonly EDIT_BASIC_INFO: string = 'EditBasicInfoPage';
  static readonly EDIT_INTERESTS: string = 'EditInterestsPage';
  static readonly EDIT_SKILLS: string = 'EditSkillsPage';
  static readonly EDIT_SOCIAL_LINKS: string = 'EditSocialLinksPage';

  // ============================================================
  // 通知
  // ============================================================
  static readonly NOTIFICATIONS: string = 'NotificationsPage';

  // ============================================================
  // 社区
  // ============================================================
  static readonly COMMUNITY: string = 'CommunityPage';

  // ============================================================
  // 法律
  // ============================================================
  static readonly TERMS_OF_SERVICE: string = 'TermsOfServicePage';
  static readonly COMMUNITY_GUIDELINES: string = 'CommunityGuidelinesPage';
  static readonly PRIVACY_POLICY: string = 'PrivacyPolicyPage';
  static readonly SETTINGS: string = 'SettingsPage';

  // ============================================================
  // 会员
  // ============================================================
  static readonly MEMBERSHIP_PLAN: string = 'MembershipPlanPage';

  /**
   * 不需要认证的路由白名单
   */
  static readonly PUBLIC_ROUTES: string[] = [
    RouteConstants.SPLASH,
    RouteConstants.LOGIN,
    RouteConstants.REGISTER,
    RouteConstants.HOME,
    RouteConstants.TERMS_OF_SERVICE,
    RouteConstants.COMMUNITY_GUIDELINES,
  ];

  /**
   * 检查路由是否需要认证
   */
  static requiresAuth(route: string): boolean {
    return !RouteConstants.PUBLIC_ROUTES.includes(route);
  }
}
