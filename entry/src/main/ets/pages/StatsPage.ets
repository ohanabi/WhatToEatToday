import { FoodStore } from '../store/FoodStore';
import { MealType } from '../model/FoodItem';
import { getMealTypeName, getPriceLevelSymbol } from '../common/constants';

interface TopFoodStat {
  name: string;
  count: number;
  likeCount: number;
}

interface MealTypeStat {
  mealType: MealType;
  count: number;
  percentage: number;
}

interface PriceStat {
  priceLevel: number;
  count: number;
  percentage: number;
}

interface TagStat {
  tag: string;
  count: number;
}

interface FoodCountData {
  count: number;
  likeCount: number;
}

@Component
export struct StatsPage {
  @StorageLink('foodStore') foodStore: FoodStore | null = null;
  @State topFoods: TopFoodStat[] = [];
  @State mealTypeStats: MealTypeStat[] = [];
  @State priceStats: PriceStat[] = [];
  @State tagStats: TagStat[] = [];
  @State totalCount: number = 0;
  
  aboutToAppear() {
    this.calculateStats();
  }
  
  // 计算所有统计数据
  calculateStats() {
    if (!this.foodStore) return;
    
    const history = this.foodStore.history;
    this.totalCount = history.length;
    
    if (this.totalCount === 0) return;
    
    // 1. 计算最爱TOP10
    this.calculateTopFoods();
    
    // 2. 计算餐别分布
    this.calculateMealTypeStats();
    
    // 3. 计算价格分布
    this.calculatePriceStats();
    
    // 4. 计算标签统计
    this.calculateTagStats();
  }
  
  // 计算最爱TOP10
  calculateTopFoods() {
    if (!this.foodStore) return;
    
    const foodCountMap: Map<string, FoodCountData> = new Map();
    
    this.foodStore.history.forEach((item) => {
      const existing = foodCountMap.get(item.foodName);
      if (existing) {
        existing.count++;
        if (item.liked) {
          existing.likeCount++;
        }
      } else {
        const newData: FoodCountData = {
          count: 1,
          likeCount: item.liked ? 1 : 0
        };
        foodCountMap.set(item.foodName, newData);
      }
    });
    
    const topList: TopFoodStat[] = [];
    foodCountMap.forEach((value, key) => {
      topList.push({
        name: key,
        count: value.count,
        likeCount: value.likeCount
      });
    });
    
    topList.sort((a, b) => {
      if (b.count !== a.count) {
        return b.count - a.count;
      }
      return b.likeCount - a.likeCount;
    });
    
    this.topFoods = topList.slice(0, 10);
  }
  
  // 计算餐别分布
  calculateMealTypeStats() {
    if (!this.foodStore) return;
    
    const mealTypeCountMap: Map<MealType, number> = new Map();
    
    this.foodStore.history.forEach((item) => {
      const count = mealTypeCountMap.get(item.mealType) || 0;
      mealTypeCountMap.set(item.mealType, count + 1);
    });
    
    const statsList: MealTypeStat[] = [];
    mealTypeCountMap.forEach((count, mealType) => {
      statsList.push({
        mealType: mealType,
        count: count,
        percentage: Math.round((count / this.totalCount) * 100)
      });
    });
    
    statsList.sort((a, b) => b.count - a.count);
    this.mealTypeStats = statsList;
  }
  
  // 计算价格分布
  calculatePriceStats() {
    if (!this.foodStore) return;
    
    const priceCountMap: Map<number, number> = new Map();
    
    this.foodStore.history.forEach((item) => {
      const food = this.foodStore!.foods.find(f => f.name === item.foodName);
      if (food) {
        const count = priceCountMap.get(food.priceLevel) || 0;
        priceCountMap.set(food.priceLevel, count + 1);
      }
    });
    
    const statsList: PriceStat[] = [];
    priceCountMap.forEach((count, priceLevel) => {
      statsList.push({
        priceLevel: priceLevel,
        count: count,
        percentage: Math.round((count / this.totalCount) * 100)
      });
    });
    
    statsList.sort((a, b) => a.priceLevel - b.priceLevel);
    this.priceStats = statsList;
  }
  
  // 计算标签统计
  calculateTagStats() {
    if (!this.foodStore) return;
    
    const tagCountMap: Map<string, number> = new Map();
    
    this.foodStore.history.forEach((item) => {
      const food = this.foodStore!.foods.find(f => f.name === item.foodName);
      if (food) {
        food.tags.forEach(tag => {
          const count = tagCountMap.get(tag) || 0;
          tagCountMap.set(tag, count + 1);
        });
      }
    });
    
    const statsList: TagStat[] = [];
    tagCountMap.forEach((count, tag) => {
      statsList.push({ tag: tag, count: count });
    });
    
    statsList.sort((a, b) => b.count - a.count);
    this.tagStats = statsList.slice(0, 15);
  }
  
  build() {
    Scroll() {
      Column() {
        Text('数据统计')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 20, top: 20, bottom: 20 })
        
        if (this.totalCount === 0) {
          Column() {
            Text('📊')
              .fontSize(48)
              .margin({ bottom: 10 })
            Text('暂无数据')
              .fontSize(16)
              .fontColor('#999')
            Text('开始使用推荐功能，这里将展示你的饮食数据分析')
              .fontSize(12)
              .fontColor('#bbb')
              .margin({ top: 5 })
              .textAlign(TextAlign.Center)
          }
          .width('100%')
          .padding(40)
        } else {
          Column({ space: 15 }) {
            // 总览卡片
            Column() {
              Text('总览')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .alignSelf(ItemAlign.Start)
                .margin({ bottom: 15 })
              
              Row() {
                Column() {
                  Text(`${this.totalCount}`)
                    .fontSize(28)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#ff6b6b')
                  Text('总记录数')
                    .fontSize(12)
                    .fontColor('#999')
                    .margin({ top: 5 })
                }
                .layoutWeight(1)
                
                Column() {
                  Text(`${this.topFoods.length > 0 ? this.topFoods[0].name : '-'}`)
                    .fontSize(18)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#4caf50')
                  Text('最爱食物')
                    .fontSize(12)
                    .fontColor('#999')
                    .margin({ top: 5 })
                }
                .layoutWeight(1)
                
                Column() {
                  Text(`${this.mealTypeStats.length > 0 ? getMealTypeName(this.mealTypeStats[0].mealType) : '-'}`)
                    .fontSize(18)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#2196f3')
                  Text('最常吃的餐')
                    .fontSize(12)
                    .fontColor('#999')
                    .margin({ top: 5 })
                }
                .layoutWeight(1)
              }
            }
            .width('100%')
            .padding(20)
            .backgroundColor('#fff')
            .borderRadius(10)
            
            // 最爱TOP10
            Column() {
              Text('🏆 最爱食物 TOP10')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .alignSelf(ItemAlign.Start)
                .margin({ bottom: 15 })
              
              if (this.topFoods.length === 0) {
                Text('暂无数据')
                  .fontSize(14)
                  .fontColor('#999')
                  .alignSelf(ItemAlign.Center)
                  .margin({ top: 20, bottom: 20 })
              } else {
                Column({ space: 10 }) {
                  ForEach(this.topFoods, (item: TopFoodStat, index: number) => {
                    Row() {
                      Text(`${index + 1}`)
                        .fontSize(16)
                        .fontWeight(FontWeight.Bold)
                        .fontColor(index < 3 ? '#ff6b6b' : '#999')
                        .width(30)
                      
                      Text(item.name)
                        .fontSize(14)
                        .layoutWeight(1)
                        .margin({ left: 10 })
                      
                      Row() {
                        Text(`${item.count}次`)
                          .fontSize(12)
                          .fontColor('#666')
                        if (item.likeCount > 0) {
                          Text(`❤️ ${item.likeCount}`)
                            .fontSize(12)
                            .fontColor('#ff6b6b')
                            .margin({ left: 10 })
                        }
                      }
                    }
                    .width('100%')
                    .padding({ top: 8, bottom: 8 })
                  })
                }
              }
            }
            .width('100%')
            .padding(20)
            .backgroundColor('#fff')
            .borderRadius(10)
            .alignItems(HorizontalAlign.Start)
            
            // 餐别分布
            Column() {
              Text('🍽️ 餐别分布')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .alignSelf(ItemAlign.Start)
                .margin({ bottom: 15 })
              
              Column({ space: 12 }) {
                ForEach(this.mealTypeStats, (item: MealTypeStat) => {
                  Column() {
                    Row() {
                      Text(getMealTypeName(item.mealType))
                        .fontSize(14)
                        .layoutWeight(1)
                      
                      Text(`${item.count}次 (${item.percentage}%)`)
                        .fontSize(12)
                        .fontColor('#666')
                    }
                    .width('100%')
                    .margin({ bottom: 8 })
                    
                    // 进度条
                    Row()
                      .width(`${item.percentage}%`)
                      .height(6)
                      .backgroundColor('#ff6b6b')
                      .borderRadius(3)
                  }
                  .width('100%')
                  .alignItems(HorizontalAlign.Start)
                })
              }
            }
            .width('100%')
            .padding(20)
            .backgroundColor('#fff')
            .borderRadius(10)
            .alignItems(HorizontalAlign.Start)
            
            // 价格分布
            Column() {
              Text('💰 价格分布')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .alignSelf(ItemAlign.Start)
                .margin({ bottom: 15 })
              
              Column({ space: 12 }) {
                ForEach(this.priceStats, (item: PriceStat) => {
                  Column() {
                    Row() {
                      Text(getPriceLevelSymbol(item.priceLevel))
                        .fontSize(14)
                        .layoutWeight(1)
                      
                      Text(`${item.count}次 (${item.percentage}%)`)
                        .fontSize(12)
                        .fontColor('#666')
                    }
                    .width('100%')
                    .margin({ bottom: 8 })
                    
                    // 进度条
                    Row()
                      .width(`${item.percentage}%`)
                      .height(6)
                      .backgroundColor('#ff9800')
                      .borderRadius(3)
                  }
                  .width('100%')
                  .alignItems(HorizontalAlign.Start)
                })
              }
            }
            .width('100%')
            .padding(20)
            .backgroundColor('#fff')
            .borderRadius(10)
            .alignItems(HorizontalAlign.Start)
            
            // 口味偏好
            Column() {
              Text('🏷️ 口味偏好 TOP15')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .alignSelf(ItemAlign.Start)
                .margin({ bottom: 15 })
              
              if (this.tagStats.length === 0) {
                Text('暂无数据')
                  .fontSize(14)
                  .fontColor('#999')
                  .alignSelf(ItemAlign.Center)
                  .margin({ top: 20, bottom: 20 })
              } else {
                Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
                  ForEach(this.tagStats, (item: TagStat) => {
                    Row() {
                      Text(item.tag)
                        .fontSize(14)
                      Text(`${item.count}`)
                        .fontSize(12)
                        .fontColor('#666')
                        .margin({ left: 5 })
                    }
                    .padding({ left: 12, right: 12, top: 8, bottom: 8 })
                    .backgroundColor('#e3f2fd')
                    .borderRadius(16)
                    .margin(5)
                  })
                }
              }
            }
            .width('100%')
            .padding(20)
            .backgroundColor('#fff')
            .borderRadius(10)
            .alignItems(HorizontalAlign.Start)
          }
          .width('90%')
          .margin({ left: '5%', right: '5%', bottom: 20 })
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f5f5')
  }
}
