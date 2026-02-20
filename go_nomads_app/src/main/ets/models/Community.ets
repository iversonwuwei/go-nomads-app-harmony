export interface TripReport {
  id: string;
  userId: string;
  userName: string;
  city: string;
  country: string;
  overallRating: number;
  title: string;
  content: string;
  likes: number;
  comments: number;
  isLiked: boolean;
  createdAt: string;
}

export interface CityRecommendation {
  id: string;
  city: string;
  name: string;
  category: string;
  description: string;
  rating: number;
  reviewCount: number;
  tags: string[];
  upvotes: number;
}

export interface Question {
  id: string;
  userId: string;
  userName: string;
  city: string;
  title: string;
  content: string;
  tags: string[];
  upvotes: number;
  answerCount: number;
  isUpvoted: boolean;
  createdAt: string;
}
