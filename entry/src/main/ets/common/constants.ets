import { MealType, FoodOrigin } from '../model/FoodItem';

// 存储键名常量
export interface StorageKeys {
  FOODS: string;
  HISTORY: string;
  SETTINGS: string;
}

export const STORAGE_KEYS: StorageKeys = {
  FOODS: 'foods',
  HISTORY: 'history',
  SETTINGS: 'settings'
};

// 餐别中文名称
export function getMealTypeName(mealType: MealType): string {
  switch (mealType) {
    case MealType.Breakfast:
      return '早餐';
    case MealType.Lunch:
      return '午餐';
    case MealType.AfternoonTea:
      return '下午茶';
    case MealType.Dinner:
      return '晚餐';
    case MealType.Supper:
      return '夜宵';
    default:
      return '';
  }
}

// 价格档位符号
export function getPriceLevelSymbol(price: number): string {
  if (price === 1) return '¥';
  if (price === 2) return '¥¥';
  if (price === 3) return '¥¥¥';
  return '';
}

// 来源中文名称
export function getOriginName(origin: FoodOrigin): string {
  switch (origin) {
    case 'home':
      return '在家做';
    case 'restaurant':
      return '堂食';
    case 'takeaway':
      return '外卖';
    default:
      return '';
  }
}
