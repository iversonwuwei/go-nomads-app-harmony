/**
 * 创新项目模型 — 对应 Flutter innovation_project.dart
 */
export interface InnovationProject {
  id: number;
  uuid?: string;
  projectName: string;
  elevatorPitch: string;
  problem: string;
  solution: string;
  targetAudience: string;
  productType: string;
  keyFeatures: string;
  competitiveAdvantage: string;
  businessModel: string;
  marketOpportunity: string;
  currentStatus: string;
  team: TeamMember[];
  ask: string;
  createdAt: string;
  updatedAt?: string;
  userId: number;
  creatorUuid?: string;
  userName?: string;
  userAvatar?: string;
  imageUrl?: string;
  viewCount?: number;
  likeCount?: number;
  commentCount?: number;
  isLiked?: boolean;
  canEdit?: boolean;
}

export interface TeamMember {
  name: string;
  role: string;
  avatar?: string;
}

export class InnovationHelper {
  static statusLabel(status: string): string {
    switch (status.toLowerCase()) {
      case 'idea': return '💡 创意';
      case 'validation': return '🔍 验证中';
      case 'mvp': return '🚀 MVP';
      case 'growth': return '📈 增长期';
      case 'scaling': return '🌍 规模化';
      default: return status;
    }
  }

  static productTypeLabel(type: string): string {
    switch (type.toLowerCase()) {
      case 'saas': return 'SaaS';
      case 'marketplace': return '平台';
      case 'mobile_app': return '移动应用';
      case 'hardware': return '硬件';
      case 'service': return '服务';
      default: return type;
    }
  }
}
