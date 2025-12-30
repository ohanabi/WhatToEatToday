import { MealType } from './FoodItem';

// 用户设置数据模型
export interface UserSettings {
  noRepeatDays: number;     // 不重复天数，默认 3
  preferredPriceLevel: number | null; // null 表示不限制
  bannedTags: string[];     // 禁用标签，如 ["辣", "甜"] 等
  defaultMealType: MealType;
}
