import { CityRecommendation, Question, TripReport } from '../models/Community';

export class CommunityService {
  private static instance: CommunityService | null = null;
  private tripReports: TripReport[] = [];
  private recommendations: CityRecommendation[] = [];
  private questions: Question[] = [];

  private constructor() {
    this.tripReports = [
      {
        id: '1', userId: 'u1', userName: 'Sarah Chen', city: 'Chiang Mai', country: 'Thailand',
        overallRating: 4.8, title: '在清迈的一个月 - 数字游民天堂',
        content: '生活成本低、网速快、社区活跃，适合远程工作。',
        likes: 234, comments: 45, isLiked: false, createdAt: new Date(Date.now() - 25 * 86400000).toISOString(),
      },
      {
        id: '2', userId: 'u2', userName: 'Marco Silva', city: 'Lisbon', country: 'Portugal',
        overallRating: 4.5, title: '里斯本 - 欧洲游民中心',
        content: '文化丰富、活动多、交通方便，住宿成本偏高。',
        likes: 189, comments: 32, isLiked: false, createdAt: new Date(Date.now() - 55 * 86400000).toISOString(),
      },
    ];

    this.recommendations = [
      { id: 'r1', city: 'Chiang Mai', name: 'Punspace Nimman', category: 'Coworking', description: '网络稳定，氛围友好。', rating: 4.7, reviewCount: 120, tags: ['WiFi', '24h'], upvotes: 96 },
      { id: 'r2', city: 'Lisbon', name: 'Hello, Kristof', category: 'Cafe', description: '适合办公的精品咖啡店。', rating: 4.6, reviewCount: 88, tags: ['Coffee', 'Quiet'], upvotes: 71 },
    ];

    this.questions = [
      { id: 'q1', userId: 'u3', userName: 'Amy', city: 'Bali', title: '巴厘岛雨季还适合办公吗？', content: '主要担心网速和通勤。', tags: ['Weather', 'Internet'], upvotes: 32, answerCount: 6, isUpvoted: false, createdAt: new Date(Date.now() - 3 * 86400000).toISOString() },
      { id: 'q2', userId: 'u4', userName: 'Leo', city: 'Tokyo', title: '东京长期合租推荐区域？', content: '希望靠近联合办公空间。', tags: ['Housing'], upvotes: 24, answerCount: 4, isUpvoted: false, createdAt: new Date(Date.now() - 6 * 86400000).toISOString() },
    ];
  }

  static getInstance(): CommunityService {
    if (!CommunityService.instance) {
      CommunityService.instance = new CommunityService();
    }
    return CommunityService.instance;
  }

  async getTripReports(): Promise<TripReport[]> {
    const list: TripReport[] = [];
    for (let i = 0; i < this.tripReports.length; i++) {
      list.push(this.tripReports[i]);
    }
    return list;
  }

  async getRecommendations(category: string = 'All'): Promise<CityRecommendation[]> {
    if (category === 'All') {
      const all: CityRecommendation[] = [];
      for (let i = 0; i < this.recommendations.length; i++) {
        all.push(this.recommendations[i]);
      }
      return all;
    }
    return this.recommendations.filter((item) => item.category === category);
  }

  async getQuestions(): Promise<Question[]> {
    const list: Question[] = [];
    for (let i = 0; i < this.questions.length; i++) {
      list.push(this.questions[i]);
    }
    return list;
  }

  toggleLikeTripReport(id: string): TripReport[] {
    this.tripReports = this.tripReports.map((item) => {
      if (item.id !== id) return item;
      const nextLiked = !item.isLiked;
      const updated: TripReport = {
        id: item.id,
        userId: item.userId,
        userName: item.userName,
        city: item.city,
        country: item.country,
        overallRating: item.overallRating,
        title: item.title,
        content: item.content,
        likes: nextLiked ? item.likes + 1 : item.likes - 1,
        comments: item.comments,
        isLiked: nextLiked,
        createdAt: item.createdAt,
      };
      return updated;
    });
    const list: TripReport[] = [];
    for (let i = 0; i < this.tripReports.length; i++) {
      list.push(this.tripReports[i]);
    }
    return list;
  }

  toggleUpvoteQuestion(id: string): Question[] {
    this.questions = this.questions.map((item) => {
      if (item.id !== id) return item;
      const nextUpvoted = !item.isUpvoted;
      const updated: Question = {
        id: item.id,
        userId: item.userId,
        userName: item.userName,
        city: item.city,
        title: item.title,
        content: item.content,
        tags: item.tags,
        upvotes: nextUpvoted ? item.upvotes + 1 : item.upvotes - 1,
        answerCount: item.answerCount,
        isUpvoted: nextUpvoted,
        createdAt: item.createdAt,
      };
      return updated;
    });
    const list: Question[] = [];
    for (let i = 0; i < this.questions.length; i++) {
      list.push(this.questions[i]);
    }
    return list;
  }
}
