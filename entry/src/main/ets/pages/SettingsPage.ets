import { FoodStore } from '../store/FoodStore';
import { UserManager } from '../store/UserManager';
import { MealType } from '../model/FoodItem';
import { getMealTypeName } from '../common/constants';
import promptAction from '@ohos.promptAction';
import router from '@ohos.router';

@Component
export struct SettingsPage {
  @StorageLink('foodStore') foodStore: FoodStore | null = null;
  @State noRepeatDays: number = 3;
  @State preferredPriceLevel: number | null = null;
  @State bannedTagsInput: string = '';
  @State currentUser: string = '';
  private userManager: UserManager = UserManager.getInstance();
  
  async aboutToAppear() {
    if (this.foodStore) {
      this.noRepeatDays = this.foodStore.settings.noRepeatDays;
      this.preferredPriceLevel = this.foodStore.settings.preferredPriceLevel;
      this.bannedTagsInput = this.foodStore.settings.bannedTags.join(', ');
    }
    
    // 获取当前用户名
    this.currentUser = await this.userManager.getCurrentUser();
  }
  
  // 登出
  async handleLogout() {
    await this.userManager.logout();
    // 跳转到登录页
    router.replaceUrl({
      url: 'pages/LoginPage'
    });
  }
  
  // 保存设置
  async handleSave() {
    if (!this.foodStore) return;
    
    const bannedTags = this.bannedTagsInput
      .split(',')
      .map(t => t.trim())
      .filter(t => t);
    
    await this.foodStore.updateSettings({
      noRepeatDays: this.noRepeatDays,
      preferredPriceLevel: this.preferredPriceLevel,
      bannedTags: bannedTags
    });
    promptAction.showToast({ message: '设置已保存！' });
  }
  
  // 清空历史记录
  async handleClearHistory() {
    if (this.foodStore) {
      await this.foodStore.clearHistory();
      promptAction.showToast({ message: '历史记录已清空！' });
    }
  }
  
  // 重置所有数据
  async handleResetAll() {
    if (this.foodStore) {
      await this.foodStore.resetAllData();
      this.noRepeatDays = this.foodStore.settings.noRepeatDays;
      this.preferredPriceLevel = this.foodStore.settings.preferredPriceLevel;
      this.bannedTagsInput = this.foodStore.settings.bannedTags.join(', ');
      promptAction.showToast({ message: '已重置为初始状态！' });
    }
  }
  
  build() {
    Scroll() {
      Column() {
        Text('设置')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 20, top: 20, bottom: 20 })
        
        Column({ space: 20 }) {
          // 账号信息
          Column() {
            Text('账号信息')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .alignSelf(ItemAlign.Start)
              .margin({ bottom: 15 })
            
            Row() {
              Text('当前用户')
                .fontSize(14)
                .fontColor('#666')
              
              Text(this.currentUser)
                .fontSize(14)
                .fontColor('#333')
                .fontWeight(FontWeight.Medium)
                .layoutWeight(1)
                .textAlign(TextAlign.End)
            }
            .width('100%')
            .margin({ bottom: 15 })
            
            Button('退出登录')
              .width('100%')
              .fontSize(14)
              .backgroundColor('#ff6b6b')
              .onClick(() => this.handleLogout())
          }
          .width('100%')
          .padding(15)
          .backgroundColor('#fff')
          .borderRadius(10)
          .alignItems(HorizontalAlign.Start)
          
          // 不重复天数
          Column() {
            Row() {
              Text('不重复天数')
                .fontSize(16)
                .layoutWeight(1)
              
              Text(`${this.noRepeatDays} 天`)
                .fontSize(16)
                .fontColor('#666')
            }
            .width('100%')
            .margin({ bottom: 10 })
            
            Slider({
              value: this.noRepeatDays,
              min: 0,
              max: 7,
              step: 1,
              style: SliderStyle.OutSet
            })
              .blockColor('#ff6b6b')
              .trackColor('#e0e0e0')
              .selectedColor('#ff6b6b')
              .onChange((value: number) => {
                this.noRepeatDays = value;
              })
            
            Text('推荐时会避免最近几天吃过的菜品')
              .fontSize(12)
              .fontColor('#999')
              .alignSelf(ItemAlign.Start)
              .margin({ top: 5 })
          }
          .width('100%')
          .padding(15)
          .backgroundColor('#fff')
          .borderRadius(10)
          
          // 价格偏好
          Column() {
            Text('价格偏好')
              .fontSize(16)
              .alignSelf(ItemAlign.Start)
              .margin({ bottom: 10 })
            
            Row() {
              Button('不限制')
                .fontSize(14)
                .backgroundColor(this.preferredPriceLevel === null ? '#ff6b6b' : '#f0f0f0')
                .fontColor(this.preferredPriceLevel === null ? '#fff' : '#333')
                .onClick(() => this.preferredPriceLevel = null)
              
              Button('¥')
                .fontSize(14)
                .backgroundColor(this.preferredPriceLevel === 1 ? '#ff9800' : '#f0f0f0')
                .fontColor(this.preferredPriceLevel === 1 ? '#fff' : '#333')
                .margin({ left: 10 })
                .onClick(() => this.preferredPriceLevel = 1)
              
              Button('¥¥')
                .fontSize(14)
                .backgroundColor(this.preferredPriceLevel === 2 ? '#ff9800' : '#f0f0f0')
                .fontColor(this.preferredPriceLevel === 2 ? '#fff' : '#333')
                .margin({ left: 10 })
                .onClick(() => this.preferredPriceLevel = 2)
              
              Button('¥¥¥')
                .fontSize(14)
                .backgroundColor(this.preferredPriceLevel === 3 ? '#ff9800' : '#f0f0f0')
                .fontColor(this.preferredPriceLevel === 3 ? '#fff' : '#333')
                .margin({ left: 10 })
                .onClick(() => this.preferredPriceLevel = 3)
            }
            
            Text('设置后会优先推荐该价格档位的菜品')
              .fontSize(12)
              .fontColor('#999')
              .alignSelf(ItemAlign.Start)
              .margin({ top: 10 })
          }
          .width('100%')
          .padding(15)
          .backgroundColor('#fff')
          .borderRadius(10)
          .alignItems(HorizontalAlign.Start)
          
          // 禁用标签
          Column() {
            Text('口味禁忌')
              .fontSize(16)
              .alignSelf(ItemAlign.Start)
              .margin({ bottom: 10 })
            
            TextInput({
              placeholder: '输入不喜欢的标签，用逗号分隔，如：辣, 甜',
              text: this.bannedTagsInput
            })
              .onChange((value) => {
                this.bannedTagsInput = value;
              })
            
            Text('带有这些标签的菜品将不会被推荐')
              .fontSize(12)
              .fontColor('#999')
              .alignSelf(ItemAlign.Start)
              .margin({ top: 10 })
          }
          .width('100%')
          .padding(15)
          .backgroundColor('#fff')
          .borderRadius(10)
          
          // 保存按钮
          Button('保存设置')
            .width('100%')
            .height(50)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .backgroundColor('#4caf50')
            .onClick(() => this.handleSave())
          
          // 危险操作区域
          Column() {
            Text('危险操作')
              .fontSize(16)
              .fontColor('#f44336')
              .fontWeight(FontWeight.Bold)
              .alignSelf(ItemAlign.Start)
              .margin({ bottom: 15 })
            
            Button('清空历史记录')
              .width('100%')
              .fontSize(14)
              .backgroundColor('#ff9800')
              .margin({ bottom: 10 })
              .onClick(() => this.handleClearHistory())
            
            Button('重置所有数据')
              .width('100%')
              .fontSize(14)
              .backgroundColor('#f44336')
              .onClick(() => this.handleResetAll())
          }
          .width('100%')
          .padding(15)
          .backgroundColor('#fff3e0')
          .borderRadius(10)
          .alignItems(HorizontalAlign.Start)
        }
        .width('90%')
        .margin({ left: '5%', right: '5%', bottom: 20 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f5f5')
  }
}
