import preferences from '@ohos.data.preferences';
import { FoodItem, MealType, FoodOrigin } from '../model/FoodItem';
import { HistoryItem } from '../model/HistoryItem';
import { UserSettings } from '../model/UserSettings';
import { STORAGE_KEYS } from '../common/constants';
import { getTodayDate, getCurrentISOString, getDaysDiff } from '../common/dateUtils';
import { getTodayFestival, Festival } from '../common/festivals';

// 数据存储和推荐算法管理类
interface FoodSeed {
  name: string;
  tags: string[];
  priceLevel: number;
  origin: FoodOrigin;
  mealType: MealType;
}

function createFoodSeed(name: string, tags: string[], priceLevel: number, origin: FoodOrigin, mealType: MealType): FoodSeed {
  return { name: name, tags: tags, priceLevel: priceLevel, origin: origin, mealType: mealType };
}

interface ScoredCandidate {
  food: FoodItem;
  score: number;
}

interface UserPreference {
  likedTags: Map<string, number>;
  likedPrices: Map<number, number>;
  likedOrigins: Map<FoodOrigin, number>;
  totalLikes: number;
}

export interface AddFoodInput {
  name: string;
  mealType: MealType;
  tags: string[];
  priceLevel: number;
  origin: FoodOrigin;
  likeScore: number;
  enabled: boolean;
}

export interface UpdateFoodInput {
  name?: string;
  mealType?: MealType;
  tags?: string[];
  priceLevel?: number;
  origin?: FoodOrigin;
  likeScore?: number;
  enabled?: boolean;
}

export interface UpdateSettingsInput {
  noRepeatDays?: number;
  preferredPriceLevel?: number | null;
  bannedTags?: string[];
  defaultMealType?: MealType;
}

export class FoodStore {
  private context: Context;
  private preferences?: preferences.Preferences;
  private currentUser: string = ''; // 当前用户名
  
  // 数据
  foods: FoodItem[] = [];
  history: HistoryItem[] = [];
  settings: UserSettings = {
    noRepeatDays: 3,
    preferredPriceLevel: null,
    bannedTags: [],
    defaultMealType: MealType.Lunch
  };
  
  currentSuggestion: FoodItem | null = null;
  private randomCounter: number = 0;
  
  constructor(context: Context) {
    this.context = context;
  }
  
  // 初始化存储，传入用户名
  async init(username: string): Promise<void> {
    try {
      this.currentUser = username;
      this.preferences = await preferences.getPreferences(this.context, `WhatToEatData_${username}`);
      await this.loadFromStorage();
      
      // 强制重新初始化默认数据（因为新增了很多菜品）
      // 检查是否需要更新：如果食物数量少于120个，说明是旧版本数据
      if (this.foods.length < 120) {
        this.initDefaultFoods();
        await this.saveToStorage();
      }
    } catch (err) {
      console.error('FoodStore init error:', err);
    }
  }
  
  // 从存储加载数据
  async loadFromStorage(): Promise<void> {
    if (!this.preferences) return;
    
    try {
      const foodsStr = await this.preferences.get(STORAGE_KEYS.FOODS, '[]');
      const historyStr = await this.preferences.get(STORAGE_KEYS.HISTORY, '[]');
      const settingsStr = await this.preferences.get(STORAGE_KEYS.SETTINGS, '');
      
      this.foods = JSON.parse(foodsStr as string);
      this.history = JSON.parse(historyStr as string);
      
      if (settingsStr) {
        this.settings = JSON.parse(settingsStr as string);
      }
    } catch (err) {
      console.error('Load from storage error:', err);
    }
  }
  
  // 保存数据到存储
  async saveToStorage(): Promise<void> {
    if (!this.preferences) return;
    
    try {
      await this.preferences.put(STORAGE_KEYS.FOODS, JSON.stringify(this.foods));
      await this.preferences.put(STORAGE_KEYS.HISTORY, JSON.stringify(this.history));
      await this.preferences.put(STORAGE_KEYS.SETTINGS, JSON.stringify(this.settings));
      await this.preferences.flush();
    } catch (err) {
      console.error('Save to storage error:', err);
    }
  }
  
  // 初始化默认菜品数据（避免使用 spread/as const 以兼容 ArkTS）
  private initDefaultFoods(): void {
    const now = getCurrentISOString();
    let id = 1;

    const seeds: FoodSeed[] = new Array<FoodSeed>();

    // 早餐
    seeds.push(createFoodSeed('热干面', ['辣', '面食', '武汉'], 1, 'restaurant', MealType.Breakfast));
    seeds.push(createFoodSeed('豆浆油条', ['传统', '清淡'], 1, 'restaurant', MealType.Breakfast));
    seeds.push(createFoodSeed('包子', ['主食', '清淡'], 1, 'restaurant', MealType.Breakfast));
    seeds.push(createFoodSeed('牛奶麦片', ['营养', '快捷'], 1, 'home', MealType.Breakfast));
    seeds.push(createFoodSeed('煎饼果子', ['传统', '快捷'], 1, 'restaurant', MealType.Breakfast));
    seeds.push(createFoodSeed('肠粉', ['清淡', '广式'], 1, 'restaurant', MealType.Breakfast));
    seeds.push(createFoodSeed('鸡蛋灌饼', ['传统', '主食'], 1, 'restaurant', MealType.Breakfast));
    seeds.push(createFoodSeed('小笼包', ['传统', '上海'], 2, 'restaurant', MealType.Breakfast));
    seeds.push(createFoodSeed('粥', ['清淡', '养生'], 1, 'restaurant', MealType.Breakfast));
    seeds.push(createFoodSeed('馄饨', ['汤', '传统'], 1, 'restaurant', MealType.Breakfast));
    seeds.push(createFoodSeed('三明治', ['西式', '快捷'], 2, 'takeaway', MealType.Breakfast));
    seeds.push(createFoodSeed('烧麦', ['传统', '主食'], 1, 'restaurant', MealType.Breakfast));
    seeds.push(createFoodSeed('鸡蛋羹', ['清淡', '营养'], 1, 'home', MealType.Breakfast));
    seeds.push(createFoodSeed('生煎包', ['传统', '上海'], 2, 'restaurant', MealType.Breakfast));
    seeds.push(createFoodSeed('面包牛奶', ['西式', '快捷'], 1, 'home', MealType.Breakfast));

    // 午餐
    seeds.push(createFoodSeed('黄焖鸡米饭', ['肉类', '米饭'], 2, 'restaurant', MealType.Lunch));
    seeds.push(createFoodSeed('番茄鸡蛋盖饭', ['清淡', '米饭'], 1, 'restaurant', MealType.Lunch));
    seeds.push(createFoodSeed('麻辣烫', ['辣', '汤', '蔬菜'], 2, 'restaurant', MealType.Lunch));
    seeds.push(createFoodSeed('沙拉', ['健康', '蔬菜', '清淡'], 2, 'restaurant', MealType.Lunch));
    seeds.push(createFoodSeed('兰州拉面', ['面食', '清真'], 1, 'restaurant', MealType.Lunch));
    seeds.push(createFoodSeed('麻辣香锅', ['辣', '重口'], 2, 'restaurant', MealType.Lunch));
    seeds.push(createFoodSeed('炒河粉', ['面食', '广式'], 1, 'restaurant', MealType.Lunch));
    seeds.push(createFoodSeed('盖浇饭', ['米饭', '快捷'], 1, 'restaurant', MealType.Lunch));
    seeds.push(createFoodSeed('沙县小吃', ['传统', '快捷'], 1, 'restaurant', MealType.Lunch));
    seeds.push(createFoodSeed('米线', ['汤', '云南'], 1, 'restaurant', MealType.Lunch));
    seeds.push(createFoodSeed('饺子', ['传统', '主食'], 1, 'restaurant', MealType.Lunch));
    seeds.push(createFoodSeed('煲仔饭', ['米饭', '广式'], 2, 'restaurant', MealType.Lunch));
    seeds.push(createFoodSeed('酸菜鱼', ['鱼', '酸辣'], 2, 'restaurant', MealType.Lunch));
    seeds.push(createFoodSeed('宫保鸡丁', ['肉类', '川菜'], 2, 'restaurant', MealType.Lunch));
    seeds.push(createFoodSeed('红烧肉', ['肉类', '重口'], 2, 'restaurant', MealType.Lunch));
    seeds.push(createFoodSeed('便当', ['快捷', '日料'], 2, 'takeaway', MealType.Lunch));
    seeds.push(createFoodSeed('汉堡', ['西式', '快餐'], 2, 'takeaway', MealType.Lunch));
    seeds.push(createFoodSeed('炒面', ['面食', '快捷'], 1, 'restaurant', MealType.Lunch));
    seeds.push(createFoodSeed('刀削面', ['面食', '山西'], 1, 'restaurant', MealType.Lunch));
    seeds.push(createFoodSeed('盖码面', ['面食', '汤'], 1, 'restaurant', MealType.Lunch));

    // 下午茶
    seeds.push(createFoodSeed('奶茶', ['饮品', '甜'], 1, 'takeaway', MealType.AfternoonTea));
    seeds.push(createFoodSeed('咖啡', ['饮品', '提神'], 2, 'restaurant', MealType.AfternoonTea));
    seeds.push(createFoodSeed('蛋糕', ['甜点', '烘焙'], 2, 'restaurant', MealType.AfternoonTea));
    seeds.push(createFoodSeed('甜甜圈', ['甜点', '油炸'], 1, 'takeaway', MealType.AfternoonTea));
    seeds.push(createFoodSeed('曲奇饼干', ['甜点', '烘焙'], 1, 'takeaway', MealType.AfternoonTea));
    seeds.push(createFoodSeed('水果茶', ['饮品', '健康'], 2, 'restaurant', MealType.AfternoonTea));
    seeds.push(createFoodSeed('冰淇淋', ['甜点', '冷饮'], 2, 'takeaway', MealType.AfternoonTea));
    seeds.push(createFoodSeed('泡芙', ['甜点', '烘焙'], 2, 'restaurant', MealType.AfternoonTea));
    seeds.push(createFoodSeed('珍珠奶茶', ['饮品', '甜'], 1, 'takeaway', MealType.AfternoonTea));
    seeds.push(createFoodSeed('马卡龙', ['甜点', '烘焙'], 3, 'restaurant', MealType.AfternoonTea));
    seeds.push(createFoodSeed('提拉米苏', ['甜点', '烘焙'], 3, 'restaurant', MealType.AfternoonTea));
    seeds.push(createFoodSeed('芝士蛋糕', ['甜点', '烘焙'], 2, 'restaurant', MealType.AfternoonTea));
    seeds.push(createFoodSeed('拿铁', ['饮品', '咖啡'], 2, 'restaurant', MealType.AfternoonTea));
    seeds.push(createFoodSeed('卡布奇诺', ['饮品', '咖啡'], 2, 'restaurant', MealType.AfternoonTea));
    seeds.push(createFoodSeed('抹茶拿铁', ['饮品', '甜'], 2, 'restaurant', MealType.AfternoonTea));
    seeds.push(createFoodSeed('布朗尼', ['甜点', '巧克力'], 2, 'restaurant', MealType.AfternoonTea));
    seeds.push(createFoodSeed('松饼', ['甜点', '烘焙'], 2, 'restaurant', MealType.AfternoonTea));
    seeds.push(createFoodSeed('华夫饼', ['甜点', '烘焙'], 2, 'restaurant', MealType.AfternoonTea));
    seeds.push(createFoodSeed('芒果班戟', ['甜点', '水果'], 2, 'restaurant', MealType.AfternoonTea));
    seeds.push(createFoodSeed('杨枝甘露', ['甜品', '港式'], 2, 'restaurant', MealType.AfternoonTea));
    seeds.push(createFoodSeed('双皮奶', ['甜品', '广式'], 1, 'restaurant', MealType.AfternoonTea));
    seeds.push(createFoodSeed('龟苓膏', ['甜品', '健康'], 1, 'restaurant', MealType.AfternoonTea));
    seeds.push(createFoodSeed('红豆沙', ['甜品', '传统'], 1, 'restaurant', MealType.AfternoonTea));
    seeds.push(createFoodSeed('绿豆沙', ['甜品', '清凉'], 1, 'restaurant', MealType.AfternoonTea));
    seeds.push(createFoodSeed('酸奶', ['饮品', '健康'], 1, 'takeaway', MealType.AfternoonTea));

    // 晚餐
    seeds.push(createFoodSeed('烤肉拌饭', ['肉类', '米饭'], 2, 'restaurant', MealType.Dinner));
    seeds.push(createFoodSeed('寿司', ['日料', '海鲜'], 3, 'restaurant', MealType.Dinner));
    seeds.push(createFoodSeed('披萨', ['西餐', '快餐'], 2, 'takeaway', MealType.Dinner));
    seeds.push(createFoodSeed('小龙虾', ['辣', '海鲜', '夏季'], 3, 'restaurant', MealType.Dinner));
    seeds.push(createFoodSeed('火锅', ['辣', '重口', '聚餐'], 3, 'restaurant', MealType.Dinner));
    seeds.push(createFoodSeed('烤鱼', ['鱼', '辣'], 2, 'restaurant', MealType.Dinner));
    seeds.push(createFoodSeed('牛排', ['西餐', '肉类'], 3, 'restaurant', MealType.Dinner));
    seeds.push(createFoodSeed('韩式烤肉', ['肉类', '韩式'], 3, 'restaurant', MealType.Dinner));
    seeds.push(createFoodSeed('串串香', ['辣', '川菜'], 2, 'restaurant', MealType.Dinner));
    seeds.push(createFoodSeed('日式料理', ['日料', '清淡'], 3, 'restaurant', MealType.Dinner));
    seeds.push(createFoodSeed('意大利面', ['西餐', '面食'], 2, 'restaurant', MealType.Dinner));
    seeds.push(createFoodSeed('炸酱面', ['面食', '重口'], 1, 'restaurant', MealType.Dinner));
    seeds.push(createFoodSeed('烤串', ['肉类', '辣'], 2, 'restaurant', MealType.Dinner));
    seeds.push(createFoodSeed('泰餐', ['东南亚', '酸辣'], 2, 'restaurant', MealType.Dinner));
    seeds.push(createFoodSeed('铁板烧', ['肉类', '日式'], 3, 'restaurant', MealType.Dinner));
    seeds.push(createFoodSeed('螺蛳粉', ['辣', '重口', '广西'], 2, 'restaurant', MealType.Dinner));
    seeds.push(createFoodSeed('石锅拌饭', ['米饭', '韩式'], 2, 'restaurant', MealType.Dinner));
    seeds.push(createFoodSeed('牛肉面', ['面食', '汤'], 2, 'restaurant', MealType.Dinner));
    seeds.push(createFoodSeed('炒菜', ['家常', '蔬菜'], 2, 'restaurant', MealType.Dinner));
    seeds.push(createFoodSeed('海鲜大咖', ['海鲜', '重口'], 3, 'restaurant', MealType.Dinner));

    // 夜宵
    seeds.push(createFoodSeed('烧烤', ['肉类', '辣'], 2, 'restaurant', MealType.Supper));
    seeds.push(createFoodSeed('炸鸡', ['快餐', '油炸'], 2, 'takeaway', MealType.Supper));
    seeds.push(createFoodSeed('方便面', ['快捷', '主食'], 1, 'home', MealType.Supper));
    seeds.push(createFoodSeed('麻辣小龙虾', ['辣', '海鲜'], 3, 'restaurant', MealType.Supper));
    seeds.push(createFoodSeed('炒年糕', ['主食', '韩式'], 1, 'restaurant', MealType.Supper));
    seeds.push(createFoodSeed('关东煮', ['汤', '清淡'], 1, 'restaurant', MealType.Supper));
    seeds.push(createFoodSeed('煎饺', ['主食', '传统'], 1, 'restaurant', MealType.Supper));
    seeds.push(createFoodSeed('炒饭', ['米饭', '快捷'], 1, 'restaurant', MealType.Supper));
    seeds.push(createFoodSeed('粥', ['清淡', '养生'], 1, 'restaurant', MealType.Supper));
    seeds.push(createFoodSeed('汉堡薯条', ['西式', '快餐'], 2, 'takeaway', MealType.Supper));
    seeds.push(createFoodSeed('鸭血粉丝汤', ['汤', '南京'], 2, 'restaurant', MealType.Supper));
    seeds.push(createFoodSeed('海鲜粥', ['清淡', '海鲜'], 2, 'restaurant', MealType.Supper));
    seeds.push(createFoodSeed('生蚝', ['海鲜', '烧烤'], 3, 'restaurant', MealType.Supper));
    seeds.push(createFoodSeed('炒面', ['面食', '快捷'], 1, 'restaurant', MealType.Supper));
    seeds.push(createFoodSeed('烤冷面', ['主食', '东北'], 1, 'restaurant', MealType.Supper));

    // 节日特色食物（可多餐类）
    seeds.push(createFoodSeed('粽子', ['传统', '节日', '端午'], 1, 'restaurant', MealType.Breakfast));
    seeds.push(createFoodSeed('月饼', ['甜点', '节日', '中秋'], 2, 'restaurant', MealType.AfternoonTea));
    seeds.push(createFoodSeed('汤圆', ['甜点', '节日', '元宵'], 1, 'restaurant', MealType.Breakfast));
    seeds.push(createFoodSeed('年糕', ['主食', '节日', '春节'], 1, 'restaurant', MealType.Lunch));
    seeds.push(createFoodSeed('春卷', ['传统', '节日', '春节'], 1, 'restaurant', MealType.Lunch));
    seeds.push(createFoodSeed('八宝饭', ['甜点', '节日', '春节'], 2, 'restaurant', MealType.Dinner));
    seeds.push(createFoodSeed('青团', ['甜点', '节日', '清明'], 1, 'restaurant', MealType.AfternoonTea));
    seeds.push(createFoodSeed('大闸蟹', ['海鲜', '节日', '中秋'], 3, 'restaurant', MealType.Dinner));
    seeds.push(createFoodSeed('腊八粥', ['汤', '节日', '腊八'], 1, 'restaurant', MealType.Breakfast));
    seeds.push(createFoodSeed('元宵', ['甜点', '节日', '元宵节'], 1, 'restaurant', MealType.AfternoonTea));
    seeds.push(createFoodSeed('重阳糕', ['甜点', '节日', '重阳'], 1, 'restaurant', MealType.AfternoonTea));
    seeds.push(createFoodSeed('灶糖', ['甜点', '节日', '小年'], 1, 'restaurant', MealType.AfternoonTea));
    seeds.push(createFoodSeed('佛跳墙', ['汤', '节日', '春节'], 3, 'restaurant', MealType.Dinner));
    seeds.push(createFoodSeed('羊肉汤', ['汤', '节日', '冬至'], 2, 'restaurant', MealType.Dinner));
    seeds.push(createFoodSeed('咸鸭蛋', ['传统', '节日', '端午'], 1, 'restaurant', MealType.Breakfast));
    seeds.push(createFoodSeed('黄鳝', ['海鲜', '节日', '端午'], 2, 'restaurant', MealType.Dinner));
    seeds.push(createFoodSeed('南瓜派', ['甜点', '节日', '万圣节'], 2, 'restaurant', MealType.AfternoonTea));
    seeds.push(createFoodSeed('火鸡', ['肉类', '节日', '圣诞'], 3, 'restaurant', MealType.Dinner));
    seeds.push(createFoodSeed('烤鸡', ['肉类', '节日'], 2, 'restaurant', MealType.Dinner));
    seeds.push(createFoodSeed('巧克力', ['甜点', '节日', '情人节'], 2, 'takeaway', MealType.AfternoonTea));
    seeds.push(createFoodSeed('鱼', ['海鲜', '节日', '春节'], 2, 'restaurant', MealType.Dinner));
    seeds.push(createFoodSeed('柚子', ['水果', '节日', '中秋'], 1, 'takeaway', MealType.AfternoonTea));
    seeds.push(createFoodSeed('薯条', ['快餐', '西式'], 1, 'takeaway', MealType.Supper));
    seeds.push(createFoodSeed('巧果', ['甜点', '节日', '七夕'], 1, 'restaurant', MealType.AfternoonTea));
    seeds.push(createFoodSeed('菊花酒', ['饮品', '节日', '重阳'], 2, 'restaurant', MealType.Dinner));
    seeds.push(createFoodSeed('艾草糕', ['甜点', '节日', '清明'], 1, 'restaurant', MealType.AfternoonTea));
    seeds.push(createFoodSeed('红酒', ['饮品', '节日', '情人节'], 3, 'restaurant', MealType.Dinner));
    seeds.push(createFoodSeed('北京烤鸭', ['肉类', '节日', '国庆'], 3, 'restaurant', MealType.Dinner));
    seeds.push(createFoodSeed('奶茶', ['饮品', '甜'], 1, 'takeaway', MealType.Supper));
    seeds.push(createFoodSeed('水果拼盘', ['健康', '清淡'], 2, 'home', MealType.Supper));
    seeds.push(createFoodSeed('小龙虾', ['辣', '海鲜'], 3, 'restaurant', MealType.Supper));
    seeds.push(createFoodSeed('麻辣小龙虾', ['辣', '重口', '海鲜'], 3, 'restaurant', MealType.Supper));
    seeds.push(createFoodSeed('冒菜', ['辣', '汤'], 2, 'restaurant', MealType.Supper));
    seeds.push(createFoodSeed('关东煮', ['清淡', '日式'], 1, 'takeaway', MealType.Supper));
    seeds.push(createFoodSeed('煎饼', ['传统', '快捷'], 1, 'restaurant', MealType.Supper));
    seeds.push(createFoodSeed('烤冷面', ['传统', '东北'], 1, 'restaurant', MealType.Supper));
    seeds.push(createFoodSeed('酸辣粉', ['辣', '酸辣'], 1, 'restaurant', MealType.Supper));
    seeds.push(createFoodSeed('臭豆腐', ['传统', '重口'], 1, 'restaurant', MealType.Supper));
    seeds.push(createFoodSeed('章鱼小丸子', ['小吃', '日式'], 1, 'takeaway', MealType.Supper));
    seeds.push(createFoodSeed('肉夹馍', ['传统', '西安'], 1, 'restaurant', MealType.Supper));
    seeds.push(createFoodSeed('烤肠', ['快捷', '肉类'], 1, 'takeaway', MealType.Supper));

    // 随机打乱种子数组，让初始化时的喜好分数随机分布
    for (let i = seeds.length - 1; i > 0; i = i - 1) {
      const randomValue = (new Date().getTime() + i * 137 + now.length * 23) % (i + 1);
      const j = randomValue;
      const temp = seeds[i];
      seeds[i] = seeds[j];
      seeds[j] = temp;
    }

    const foodsResult: FoodItem[] = new Array<FoodItem>();
    for (let i = 0; i < seeds.length; i++) {
      const seed = seeds[i];
      // 随机分配初始喜好分数 (2-4)，让推荐更多样化
      const randomLikeScore = 2 + ((new Date().getTime() + i * 73) % 3);
      const newFood: FoodItem = {
        id: id,
        name: seed.name,
        mealType: seed.mealType,
        tags: seed.tags,
        priceLevel: seed.priceLevel,
        origin: seed.origin,
        likeScore: randomLikeScore,
        enabled: true,
        createdAt: now
      };
      foodsResult.push(newFood);
      id += 1;
    }

    this.foods = foodsResult;
  }
  
  // 获取推荐结果（智能学习版）
  getSuggestion(mealType: MealType): FoodItem | null {
    // 增加随机计数器，确保每次调用结果不同
    this.randomCounter = this.randomCounter + 1;
    
    // 1. 过滤阶段 - 基础过滤
    let candidates = this.foods.filter(food => {
      // 按餐别过滤
      if (food.mealType !== mealType) return false;
      
      // 过滤禁用的菜品
      if (!food.enabled) return false;
      
      // 过滤命中禁用标签的菜品
      if (food.tags.some(tag => this.settings.bannedTags.includes(tag))) {
        return false;
      }
      
      return true;
    });
    
    // 如果基础过滤后没有候选项，返回null
    if (candidates.length === 0) {
      return null;
    }
    
    // 2. 尝试过滤最近吃过的
    const recentHistory = this.getRecentHistory(mealType, this.settings.noRepeatDays);
    const candidatesWithoutRecent = candidates.filter(food => {
      return !recentHistory.some(h => h.foodId === food.id);
    });
    
    // 如果过滤后还有足够候选项，使用过滤后的；否则使用全部候选项
    if (candidatesWithoutRecent.length > 0) {
      candidates = candidatesWithoutRecent;
    }
    
    // 3. 智能学习：分析用户喜好并计算相似度权重
    const userPreference = this.analyzeUserPreference();
    const scoredCandidates: ScoredCandidate[] = [];
    
    for (let i = 0; i < candidates.length; i++) {
      const food = candidates[i];
      const similarityScore = this.calculateSimilarityScore(food, userPreference);
      scoredCandidates.push({ food: food, score: similarityScore });
    }
    
    // 4. 使用加权随机选择
    this.currentSuggestion = this.weightedRandomSelect(scoredCandidates);
    
    return this.currentSuggestion;
  }
  
  // 分析用户喜好偏好
  private analyzeUserPreference(): UserPreference {
    const likedTags: Map<string, number> = new Map();
    const likedPrices: Map<number, number> = new Map();
    const likedOrigins: Map<FoodOrigin, number> = new Map();
    let totalLikes = 0;
    
    // 遍历历史记录，统计喜欢的食物特征
    this.history.forEach(item => {
      if (item.liked) {
        totalLikes++;
        const food = this.foods.find(f => f.id === item.foodId);
        if (food) {
          // 统计标签
          food.tags.forEach(tag => {
            const count = likedTags.get(tag) || 0;
            likedTags.set(tag, count + 1);
          });
          
          // 统计价格
          const priceCount = likedPrices.get(food.priceLevel) || 0;
          likedPrices.set(food.priceLevel, priceCount + 1);
          
          // 统计来源
          const originCount = likedOrigins.get(food.origin) || 0;
          likedOrigins.set(food.origin, originCount + 1);
        }
      }
    });
    
    return {
      likedTags: likedTags,
      likedPrices: likedPrices,
      likedOrigins: likedOrigins,
      totalLikes: totalLikes
    };
  }
  
  // 计算食物与用户偏好的相似度得分
  private calculateSimilarityScore(food: FoodItem, preference: UserPreference): number {
    // 检测当前是否是节日
    const festival = getTodayFestival();
    
    if (preference.totalLikes === 0) {
      // 没有喜好数据时，返回随机权重（0.5-1.5）
      const timestamp = new Date().getTime();
      const randomSeed = (timestamp + food.id * 997 + this.randomCounter * 1723) % 1000;
      let score = 0.5 + (randomSeed / 1000);
      
      // 节日食物加权
      if (festival && this.isFestivalFood(food, festival)) {
        score = score * 3.0; // 节日食物权重提升3倍
      }
      
      return score;
    }
    
    let score = 1.0; // 基础分数
    
    // 标签匹配加分（权重40%）
    let tagScore = 0;
    let matchedTags = 0;
    food.tags.forEach(tag => {
      const likeCount = preference.likedTags.get(tag) || 0;
      if (likeCount > 0) {
        tagScore += likeCount / preference.totalLikes;
        matchedTags++;
      }
    });
    if (food.tags.length > 0) {
      tagScore = tagScore / food.tags.length;
    }
    score += tagScore * 0.4;
    
    // 价格匹配加分（权重20%）
    const priceCount = preference.likedPrices.get(food.priceLevel) || 0;
    const priceScore = priceCount / preference.totalLikes;
    score += priceScore * 0.2;
    
    // 来源匹配加分（权重20%）
    const originCount = preference.likedOrigins.get(food.origin) || 0;
    const originScore = originCount / preference.totalLikes;
    score += originScore * 0.2;
    
    // 添加随机因子（权重20%），避免推荐过于单一
    const timestamp = new Date().getTime();
    const randomSeed = (timestamp + food.id * 997 + this.randomCounter * 1723) % 1000;
    const randomFactor = randomSeed / 1000;
    score += randomFactor * 0.2;
    
    // 节日食物特别加权
    if (festival && this.isFestivalFood(food, festival)) {
      score = score * 2.5; // 节日食物权重提升2.5倍
    }
    
    return score;
  }
  
  // 判断是否为节日推荐食物
  private isFestivalFood(food: FoodItem, festival: Festival): boolean {
    return festival.recommendedFoods.includes(food.name);
  }
  
  // 加权随机选择
  private weightedRandomSelect(scoredCandidates: ScoredCandidate[]): FoodItem | null {
    if (scoredCandidates.length === 0) return null;
    
    // 计算总权重
    let totalWeight = 0;
    for (let i = 0; i < scoredCandidates.length; i++) {
      totalWeight += scoredCandidates[i].score;
    }
    
    // 生成随机值
    const timestamp = new Date().getTime();
    const randomSeed = (timestamp + this.randomCounter * 2053) % 10000;
    const randomValue = (randomSeed / 10000) * totalWeight;
    
    // 加权选择
    let currentWeight = 0;
    for (let i = 0; i < scoredCandidates.length; i++) {
      currentWeight += scoredCandidates[i].score;
      if (randomValue <= currentWeight) {
        return scoredCandidates[i].food;
      }
    }
    
    // 兜底：返回最后一个
    return scoredCandidates[scoredCandidates.length - 1].food;
  }
  
  // 计算菜品推荐得分（已弃用，保留用于兼容）
  private calculateScore(food: FoodItem): number {
    // 权重配置
    const w_like = 0.4;
    const w_random = 0.4;
    const w_price = 0.2;
    
    // 喜好得分归一化 (0-5 -> 0-1)
    const likeScoreNorm = food.likeScore / 5;
    
    // 随机因子：结合时间戳、食物ID和计数器增加随机性
    const timestamp = new Date().getTime();
    const randomSeed = (timestamp + food.id * 997 + this.randomCounter * 1723) * food.id;
    const randomFactor = ((randomSeed % 10000) / 10000);
    
    // 价格得分
    let priceScore = 0.5; // 默认中等
    if (this.settings.preferredPriceLevel !== null) {
      priceScore = (food.priceLevel === this.settings.preferredPriceLevel) ? 1 : 0.3;
    } else {
      priceScore = 1; // 不限制价格时，所有价格档位都给满分
    }
    
    // 计算总分
    const totalScore = w_like * likeScoreNorm + w_random * randomFactor + w_price * priceScore;
    
    return totalScore;
  }
  
  // 获取最近的历史记录
  private getRecentHistory(mealType: MealType, days: number): HistoryItem[] {
    const today = getTodayDate();
    return this.history.filter(item => {
      if (item.mealType !== mealType) return false;
      const daysDiff = getDaysDiff(item.date, today);
      return daysDiff < days;
    });
  }
  
  // 确认推荐（点击"就吃它"）
  async confirmSuggestion(mealType: MealType): Promise<void> {
    if (!this.currentSuggestion) return;
    
    const historyItem: HistoryItem = {
      id: this.history.length + 1,
      date: getTodayDate(),
      mealType: mealType,
      foodId: this.currentSuggestion.id,
      foodName: this.currentSuggestion.name,
      confirmed: true,
      liked: false,
      disliked: false,
      createdAt: getCurrentISOString()
    };
    
    this.history.push(historyItem);
    await this.saveToStorage();
  }
  
  // 点赞当前推荐
  async likeCurrent(): Promise<void> {
    if (!this.currentSuggestion) return;
    
    const food = this.foods.find(f => f.id === this.currentSuggestion!.id);
    if (food && food.likeScore < 5) {
      food.likeScore += 1;
      food.updatedAt = getCurrentISOString();
      await this.saveToStorage();
    }
  }
  
  // 踩雷当前推荐（不再推荐）
  async dislikeCurrent(mealType: MealType): Promise<void> {
    if (!this.currentSuggestion) return;
    
    const food = this.foods.find(f => f.id === this.currentSuggestion!.id);
    if (food) {
      food.enabled = false;
      food.updatedAt = getCurrentISOString();
      
      // 记录到历史
      const historyItem: HistoryItem = {
        id: this.history.length + 1,
        date: getTodayDate(),
        mealType: mealType,
        foodId: food.id,
        foodName: food.name,
        confirmed: false,
        liked: false,
        disliked: true,
        createdAt: getCurrentISOString()
      };
      
      this.history.push(historyItem);
      await this.saveToStorage();
    }
  }
  
  // CRUD 操作：添加菜品
  async addFood(food: AddFoodInput): Promise<void> {
    let maxId = 0;
    for (let i = 0; i < this.foods.length; i++) {
      if (this.foods[i].id > maxId) {
        maxId = this.foods[i].id;
      }
    }

    const newFood: FoodItem = {
      id: maxId + 1,
      name: food.name,
      mealType: food.mealType,
      tags: food.tags,
      priceLevel: food.priceLevel,
      origin: food.origin,
      likeScore: food.likeScore,
      enabled: food.enabled,
      createdAt: getCurrentISOString()
    };
    
    this.foods.push(newFood);
    await this.saveToStorage();
  }
  
  // CRUD 操作：更新菜品
  async updateFood(id: number, updates: UpdateFoodInput): Promise<void> {
    const food = this.foods.find(f => f.id === id);
    if (food) {
      if (updates.name !== undefined) food.name = updates.name;
      if (updates.mealType !== undefined) food.mealType = updates.mealType;
      if (updates.tags !== undefined) food.tags = updates.tags;
      if (updates.priceLevel !== undefined) food.priceLevel = updates.priceLevel;
      if (updates.origin !== undefined) food.origin = updates.origin;
      if (updates.likeScore !== undefined) food.likeScore = updates.likeScore;
      if (updates.enabled !== undefined) food.enabled = updates.enabled;
      food.updatedAt = getCurrentISOString();
      await this.saveToStorage();
    }
  }
  
  // CRUD 操作：删除菜品
  async deleteFood(id: number): Promise<void> {
    this.foods = this.foods.filter(f => f.id !== id);
    await this.saveToStorage();
  }
  
  // 更新设置
  async updateSettings(settings: UpdateSettingsInput): Promise<void> {
    if (settings.noRepeatDays !== undefined) this.settings.noRepeatDays = settings.noRepeatDays;
    if (settings.preferredPriceLevel !== undefined) this.settings.preferredPriceLevel = settings.preferredPriceLevel;
    if (settings.bannedTags !== undefined) this.settings.bannedTags = settings.bannedTags;
    if (settings.defaultMealType !== undefined) this.settings.defaultMealType = settings.defaultMealType;
    await this.saveToStorage();
  }
  
  // 清空历史记录
  async clearHistory(): Promise<void> {
    this.history = [];
    await this.saveToStorage();
  }
  
  // 重置所有数据
  async resetAllData(): Promise<void> {
    this.foods = [];
    this.history = [];
    this.settings = {
      noRepeatDays: 3,
      preferredPriceLevel: null,
      bannedTags: [],
      defaultMealType: MealType.Lunch
    };
    this.currentSuggestion = null;
    
    this.initDefaultFoods();
    await this.saveToStorage();
  }
}
