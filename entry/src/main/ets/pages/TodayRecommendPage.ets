import { FoodStore } from '../store/FoodStore';
import { FoodItem, MealType } from '../model/FoodItem';
import { getTodayDate, getCurrentMealType } from '../common/dateUtils';
import { getMealTypeName, getPriceLevelSymbol, getOriginName } from '../common/constants';
import { getTodayFestival, Festival, getLunarDateString } from '../common/festivals';
import promptAction from '@ohos.promptAction';
import common from '@ohos.app.ability.common';
import Want from '@ohos.app.ability.Want';

@Component
export struct TodayRecommendPage {
  @StorageLink('foodStore') foodStore: FoodStore | null = null;
  @State currentMealType: MealType = MealType.Lunch;
  @State recommendation: FoodItem | null = null;
  @State showRecommendation: boolean = false;
  @State showMeituanDialog: boolean = false;
  @State currentFestival: Festival | null = null;
  @State lunarDateStr: string = '';
  
  aboutToAppear() {
    // 根据当前时间自动设置餐别
    const currentMeal = getCurrentMealType();
    this.currentMealType = currentMeal as MealType;
    
    // 检测当前节日
    this.currentFestival = getTodayFestival();
    
    // 获取农历日期
    this.lunarDateStr = getLunarDateString();
  }
  
  // 获取推荐
  handleGetSuggestion() {
    if (this.foodStore) {
      const result = this.foodStore.getSuggestion(this.currentMealType);
      if (result) {
        this.recommendation = result;
        this.showRecommendation = true;
      } else {
        // 没有可推荐的菜品
        promptAction.showToast({ message: '没有符合条件的菜品，请检查设置或添加更多菜品' });
      }
    }
  }
  
  // 换一个
  handleChangeOne() {
    this.handleGetSuggestion();
  }
  
  // 就吃它
  async handleConfirm() {
    if (this.foodStore) {
      await this.foodStore.confirmSuggestion(this.currentMealType);
      promptAction.showToast({ message: '已记录到历史！' });
      this.showMeituanDialog = true;
    }
  }
  
  // 打开美团搜索
  async openMeituan() {
    if (this.recommendation) {
      const foodName = this.recommendation.name;
      const url = `imeituan://www.meituan.com/search?q=${encodeURIComponent(foodName)}`;
      
      try {
        const context = AppStorage.get<common.UIAbilityContext>('context');
        if (context) {
          const want: Want = {
            action: 'ohos.want.action.viewData',
            uri: url
          };
          await context.startAbility(want);
        }
      } catch (err) {
        promptAction.showToast({ message: '未安装美团或打开失败' });
      }
    }
    this.showMeituanDialog = false;
    this.showRecommendation = false;
    this.recommendation = null;
  }
  
  // 喜欢
  async handleLike() {
    if (this.foodStore) {
      await this.foodStore.likeCurrent();
      promptAction.showToast({ message: '已提升该菜品的推荐权重！' });
    }
  }
  
  // 不再推荐
  async handleDislike() {
    if (this.foodStore) {
      await this.foodStore.dislikeCurrent(this.currentMealType);
      promptAction.showToast({ message: '已标记为不再推荐！' });
      this.showRecommendation = false;
      this.recommendation = null;
    }
  }
  
  @Builder MeituanDialog() {
    Column() {
      Text('🍴')
        .fontSize(48)
        .margin({ bottom: 15 })
      
      Text('是否打开美团搜索？')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: 10 })
      
      if (this.recommendation) {
        Text(`搜索“${this.recommendation.name}”`)
          .fontSize(14)
          .fontColor('#666')
          .margin({ bottom: 25 })
      }
      
      Row() {
        Button('不用了')
          .fontSize(16)
          .backgroundColor('#f0f0f0')
          .fontColor('#333')
          .layoutWeight(1)
          .onClick(() => {
            this.showMeituanDialog = false;
            this.showRecommendation = false;
            this.recommendation = null;
          })
        
        Button('打开美团')
          .fontSize(16)
          .backgroundColor('#ff6b6b')
          .fontColor('#fff')
          .layoutWeight(1)
          .margin({ left: 10 })
          .onClick(() => this.openMeituan())
      }
      .width('100%')
    }
    .width('80%')
    .padding(25)
    .backgroundColor('#fff')
    .borderRadius(15)
  }
  
  build() {
    Column() {
      // 顶部日期和餐别
      Column() {
        // 阳历日期
        Text(getTodayDate())
          .fontSize(16)
          .fontColor('#999')
          .margin({ top: 20 })
        
        // 农历日期
        if (this.lunarDateStr) {
          Text(`农历 ${this.lunarDateStr}`)
            .fontSize(13)
            .fontColor('#bbb')
            .margin({ top: 5 })
        }
        
        Text(getMealTypeName(this.currentMealType))
          .fontSize(32)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 10 })
        
        // 节日提示
        if (this.currentFestival) {
          Row() {
            Text(this.currentFestival.emoji)
              .fontSize(16)
              .margin({ right: 5 })
            Text(`${this.currentFestival.name} · ${this.currentFestival.description}`)
              .fontSize(14)
              .fontColor('#ff6b6b')
          }
          .padding({ left: 15, right: 15, top: 8, bottom: 8 })
          .backgroundColor('#fff0f0')
          .borderRadius(20)
          .margin({ top: 15 })
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      
      // 餐别切换
      Row() {
        Button('早餐')
          .type(ButtonType.Capsule)
          .backgroundColor(this.currentMealType === MealType.Breakfast ? '#ff6b6b' : '#f0f0f0')
          .fontColor(this.currentMealType === MealType.Breakfast ? '#fff' : '#333')
          .fontSize(12)
          .onClick(() => {
            this.currentMealType = MealType.Breakfast;
            this.showRecommendation = false;
          })
        
        Button('午餐')
          .type(ButtonType.Capsule)
          .backgroundColor(this.currentMealType === MealType.Lunch ? '#ff6b6b' : '#f0f0f0')
          .fontColor(this.currentMealType === MealType.Lunch ? '#fff' : '#333')
          .fontSize(12)
          .margin({ left: 8 })
          .onClick(() => {
            this.currentMealType = MealType.Lunch;
            this.showRecommendation = false;
          })
        
        Button('下午茶')
          .type(ButtonType.Capsule)
          .backgroundColor(this.currentMealType === MealType.AfternoonTea ? '#ff6b6b' : '#f0f0f0')
          .fontColor(this.currentMealType === MealType.AfternoonTea ? '#fff' : '#333')
          .fontSize(12)
          .margin({ left: 8 })
          .onClick(() => {
            this.currentMealType = MealType.AfternoonTea;
            this.showRecommendation = false;
          })
        
        Button('晚餐')
          .type(ButtonType.Capsule)
          .backgroundColor(this.currentMealType === MealType.Dinner ? '#ff6b6b' : '#f0f0f0')
          .fontColor(this.currentMealType === MealType.Dinner ? '#fff' : '#333')
          .fontSize(12)
          .margin({ left: 8 })
          .onClick(() => {
            this.currentMealType = MealType.Dinner;
            this.showRecommendation = false;
          })
        
        Button('夜宵')
          .type(ButtonType.Capsule)
          .backgroundColor(this.currentMealType === MealType.Supper ? '#ff6b6b' : '#f0f0f0')
          .fontColor(this.currentMealType === MealType.Supper ? '#fff' : '#333')
          .fontSize(12)
          .margin({ left: 8 })
          .onClick(() => {
            this.currentMealType = MealType.Supper;
            this.showRecommendation = false;
          })
      }
      .margin({ top: 30 })
      
      // 中部推荐卡片
      Column() {
        if (this.showRecommendation && this.recommendation) {
          // 显示推荐结果
          Column() {
            Text(this.recommendation.name)
              .fontSize(36)
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 20 })
            
            // 标签
            Row() {
              ForEach(this.recommendation.tags, (tag: string) => {
                Text(tag)
                  .fontSize(14)
                  .padding({ left: 10, right: 10, top: 5, bottom: 5 })
                  .backgroundColor('#e8f5e9')
                  .borderRadius(12)
                  .margin({ right: 8 })
              })
            }
            .margin({ bottom: 15 })
            
            // 价格和来源
            Row() {
              Text(getPriceLevelSymbol(this.recommendation.priceLevel))
                .fontSize(16)
                .fontColor('#ff9800')
                .margin({ right: 15 })
              
              Text(getOriginName(this.recommendation.origin))
                .fontSize(16)
                .fontColor('#666')
            }
            .margin({ bottom: 20 })
            
            // 操作按钮
            Row() {
              Button('✅ 就吃它')
                .fontSize(14)
                .backgroundColor('#4caf50')
                .onClick(() => this.handleConfirm())
              
              Button('❤️ 喜欢')
                .fontSize(14)
                .backgroundColor('#ff4081')
                .margin({ left: 10 })
                .onClick(() => this.handleLike())
              
              Button('🚫 不再推荐')
                .fontSize(14)
                .backgroundColor('#9e9e9e')
                .margin({ left: 10 })
                .onClick(() => this.handleDislike())
            }
          }
          .width('90%')
          .padding(30)
          .backgroundColor('#fff')
          .borderRadius(20)
          .shadow({ radius: 10, color: '#00000020' })
        } else {
          // 占位图
          Column() {
            Text('🍽️')
              .fontSize(80)
              .margin({ bottom: 20 })
            
            Text('今天吃什么？')
              .fontSize(24)
              .fontColor('#999')
          }
          .width('90%')
          .height(300)
          .justifyContent(FlexAlign.Center)
          .backgroundColor('#fafafa')
          .borderRadius(20)
        }
      }
      .layoutWeight(1)
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      
      // 底部按钮
      Button('帮我选！')
        .width('80%')
        .height(50)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .backgroundColor('#ff6b6b')
        .margin({ bottom: 30 })
        .onClick(() => this.handleGetSuggestion())
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f5f5')
    .bindSheet(this.showMeituanDialog, this.MeituanDialog(), {
      height: 280,
      backgroundColor: Color.Transparent,
      showClose: false,
      onDisappear: () => {
        this.showMeituanDialog = false;
      }
    })
  }
}
