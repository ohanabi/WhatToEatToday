import { FoodStore } from '../store/FoodStore';
import { UserManager } from '../store/UserManager';
import { TodayRecommendPage } from './TodayRecommendPage';
import { FoodListPage } from './FoodListPage';
import { HistoryPage } from './HistoryPage';
import { StatsPage } from './StatsPage';
import { SettingsPage } from './SettingsPage';
import router from '@ohos.router';

@Entry
@Component
struct Index {
  @StorageLink('foodStore') foodStore: FoodStore | null = null;
  @StorageLink('currentTabIndex') currentTabIndex: number = 0;
  @State currentUser: string = '';
  private userManager: UserManager = UserManager.getInstance();
  
  async aboutToAppear() {
    const context = getContext(this) as Context;
    
    // 保存 context 到 AppStorage，供其他页面使用
    AppStorage.setOrCreate('context', context);
    
    // 初始化UserManager
    await this.userManager.init(context);
    
    // 检查登录状态
    const isLoggedIn = await this.userManager.isLoggedIn();
    if (!isLoggedIn) {
      // 未登录，跳转到登录页
      router.replaceUrl({
        url: 'pages/LoginPage'
      });
      return;
    }
    
    // 获取当前用户名
    this.currentUser = await this.userManager.getCurrentUser();
    
    // 初始化 FoodStore（传入用户名）
    const store = new FoodStore(context);
    await store.init(this.currentUser);
    
    // 存储到 AppStorage
    AppStorage.setOrCreate('foodStore', store);
    this.foodStore = store;
  }

  @Builder TabBuilder(index: number, name: string, icon: string) {
    Column() {
      Text(icon)
        .fontSize(22)
        .margin({ bottom: 2 })
      Text(name)
        .fontSize(10)
        .fontColor(this.currentTabIndex === index ? '#ff6b6b' : '#666')
    }
    .width('20%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.currentTabIndex = index;
    })
  }

  build() {
    Column() {
      // TabContent 区域
      Column() {
        if (this.currentTabIndex === 0) {
          TodayRecommendPage()
        } else if (this.currentTabIndex === 1) {
          FoodListPage()
        } else if (this.currentTabIndex === 2) {
          HistoryPage()
        } else if (this.currentTabIndex === 3) {
          StatsPage()
        } else if (this.currentTabIndex === 4) {
          SettingsPage()
        }
      }
      .width('100%')
      .layoutWeight(1)
      
      // 底部 TabBar
      Row() {
        this.TabBuilder(0, '推荐', '🍽️')
        this.TabBuilder(1, '菜品', '📋')
        this.TabBuilder(2, '历史', '📅')
        this.TabBuilder(3, '统计', '📊')
        this.TabBuilder(4, '设置', '⚙️')
      }
      .width('100%')
      .height(56)
      .backgroundColor('#fff')
      .shadow({ radius: 8, color: '#00000010', offsetY: -2 })
      .justifyContent(FlexAlign.SpaceAround)
    }
    .width('100%')
    .height('100%')
  }
}