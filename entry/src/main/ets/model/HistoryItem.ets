import { MealType } from './FoodItem';

// 历史记录数据模型
export interface HistoryItem {
  id: number;
  date: string;             // "2025-12-09"
  mealType: MealType;
  foodId: number;
  foodName: string;         // 冗余存储菜名，避免菜品删除后历史记录无法显示
  confirmed: boolean;       // 用户是否点击"就吃它"
  liked: boolean;           // 是否点赞
  disliked: boolean;        // 是否踩雷/不再推荐
  createdAt: string;
}
