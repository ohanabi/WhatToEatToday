// 餐别枚举
export enum MealType {
  Breakfast = 'breakfast',
  Lunch = 'lunch',
  AfternoonTea = 'afternoontea',
  Dinner = 'dinner',
  Supper = 'supper', // 夜宵
}

// 菜品来源
export type FoodOrigin = 'home' | 'restaurant' | 'takeaway';

// 菜品数据模型
export interface FoodItem {
  id: number;
  name: string;             // 菜名，如 "热干面"
  mealType: MealType;       // 适合的餐别
  tags: string[];           // 例如 ["辣", "面食", "汤", "武汉"]
  priceLevel: number;       // 1, 2, 3 代表 ¥ / ¥¥ / ¥¥¥
  origin: FoodOrigin;       // 在家做 / 外面吃 / 外卖
  likeScore: number;        // 用户喜好得分，初始可为 0~5
  enabled: boolean;         // 是否参与推荐
  createdAt: string;        // 创建时间 ISO 字符串
  updatedAt?: string;
}
