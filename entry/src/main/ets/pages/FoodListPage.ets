import { FoodStore } from '../store/FoodStore';
import { FoodItem, MealType, FoodOrigin } from '../model/FoodItem';
import { getMealTypeName, getPriceLevelSymbol, getOriginName } from '../common/constants';
import promptAction from '@ohos.promptAction';

@Component
export struct FoodListPage {
  @StorageLink('foodStore') foodStore: FoodStore | null = null;
  @State searchText: string = '';
  @State showAddDialog: boolean = false;
  @State editingFood: FoodItem | null = null;
  @State filterMealType: string = 'all'; // 'all' | MealType
  @State foodsList: FoodItem[] = []; // 本地食物列表副本
  
  aboutToAppear() {
    this.refreshFoodsList();
  }
  
  // 刷新食物列表
  refreshFoodsList() {
    if (this.foodStore) {
      this.foodsList = [...this.foodStore.foods];
    }
  }
  
  // 新增/编辑表单数据
  @State formName: string = '';
  @State formMealType: MealType = MealType.Lunch;
  @State formTags: string = '';
  @State formPriceLevel: number = 2;
  @State formOrigin: FoodOrigin = 'restaurant';
  
  // 获取过滤后的菜品列表
  getFilteredFoods(): FoodItem[] {
    let foods = this.foodsList;
    
    // 按餐别筛选
    if (this.filterMealType !== 'all') {
      foods = foods.filter(food => food.mealType === this.filterMealType);
    }
    
    // 按搜索文本筛选
    if (this.searchText) {
      const searchLower = this.searchText.toLowerCase();
      foods = foods.filter(food => 
        food.name.toLowerCase().includes(searchLower) ||
        food.tags.some(tag => tag.toLowerCase().includes(searchLower))
      );
    }
    
    return foods;
  }
  
  // 打开新增对话框
  openAddDialog() {
    this.editingFood = null;
    this.formName = '';
    this.formMealType = MealType.Lunch;
    this.formTags = '';
    this.formPriceLevel = 2;
    this.formOrigin = 'restaurant';
    this.showAddDialog = true;
  }
  
  // 打开编辑对话框
  openEditDialog(food: FoodItem) {
    this.editingFood = food;
    this.formName = food.name;
    this.formMealType = food.mealType;
    this.formTags = food.tags.join(', ');
    this.formPriceLevel = food.priceLevel;
    this.formOrigin = food.origin;
    this.showAddDialog = true;
  }
  
  // 保存菜品
  async handleSave() {
    if (!this.foodStore || !this.formName.trim()) {
      return;
    }
    
    const tags = this.formTags.split(',').map(t => t.trim()).filter(t => t);
    
    if (this.editingFood) {
      // 更新
      await this.foodStore.updateFood(this.editingFood.id, {
        name: this.formName,
        mealType: this.formMealType,
        tags: tags,
        priceLevel: this.formPriceLevel,
        origin: this.formOrigin
      });
    } else {
      // 新增
      await this.foodStore.addFood({
        name: this.formName,
        mealType: this.formMealType,
        tags: tags,
        priceLevel: this.formPriceLevel,
        origin: this.formOrigin,
        likeScore: 3,
        enabled: true
      });
    }
    
    this.showAddDialog = false;
    this.refreshFoodsList(); // 刷新列表
  }
  
  // 删除菜品
  async handleDelete(food: FoodItem) {
    if (this.foodStore) {
      await this.foodStore.deleteFood(food.id);
      promptAction.showToast({ message: `${food.name} 已删除` });
      this.refreshFoodsList(); // 刷新列表
    }
  }
  
  // 切换启用状态
  toggleEnabled(food: FoodItem) {
    if (this.foodStore) {
      // 在本地列表中找到并更新
      const index = this.foodsList.findIndex(f => f.id === food.id);
      if (index !== -1) {
        this.foodsList[index].enabled = !this.foodsList[index].enabled;
        // 创建新数组触发UI更新
        this.foodsList = [...this.foodsList];
        // 异步保存到存储
        this.foodStore.updateFood(food.id, {
          enabled: this.foodsList[index].enabled
        });
      }
    }
  }
  
  @Builder AddEditDialog() {
    Column() {
      // 标题栏
      Row() {
        Text(this.editingFood ? '编辑菜品' : '新增菜品')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
        
        Text('✕')
          .fontSize(24)
          .fontColor('#999')
          .onClick(() => {
            this.showAddDialog = false;
          })
      }
      .width('100%')
      .margin({ bottom: 20 })
      
      // 菜名
      Column() {
        Text('菜名')
          .fontSize(14)
          .alignSelf(ItemAlign.Start)
          .margin({ bottom: 5 })
        TextInput({ placeholder: '请输入菜名', text: this.formName })
          .onChange((value) => {
            this.formName = value;
          })
      }
      .width('100%')
      .margin({ bottom: 15 })
      
      // 餐别
      Column() {
        Text('餐别')
          .fontSize(14)
          .alignSelf(ItemAlign.Start)
          .margin({ bottom: 5 })
        Row() {
          Button('早餐')
            .fontSize(11)
            .backgroundColor(this.formMealType === MealType.Breakfast ? '#ff6b6b' : '#f0f0f0')
            .fontColor(this.formMealType === MealType.Breakfast ? '#fff' : '#333')
            .onClick(() => this.formMealType = MealType.Breakfast)
          Button('午餐')
            .fontSize(11)
            .backgroundColor(this.formMealType === MealType.Lunch ? '#ff6b6b' : '#f0f0f0')
            .fontColor(this.formMealType === MealType.Lunch ? '#fff' : '#333')
            .margin({ left: 5 })
            .onClick(() => this.formMealType = MealType.Lunch)
          Button('下午茶')
            .fontSize(11)
            .backgroundColor(this.formMealType === MealType.AfternoonTea ? '#ff6b6b' : '#f0f0f0')
            .fontColor(this.formMealType === MealType.AfternoonTea ? '#fff' : '#333')
            .margin({ left: 5 })
            .onClick(() => this.formMealType = MealType.AfternoonTea)
          Button('晚餐')
            .fontSize(11)
            .backgroundColor(this.formMealType === MealType.Dinner ? '#ff6b6b' : '#f0f0f0')
            .fontColor(this.formMealType === MealType.Dinner ? '#fff' : '#333')
            .margin({ left: 5 })
            .onClick(() => this.formMealType = MealType.Dinner)
          Button('夜宵')
            .fontSize(11)
            .backgroundColor(this.formMealType === MealType.Supper ? '#ff6b6b' : '#f0f0f0')
            .fontColor(this.formMealType === MealType.Supper ? '#fff' : '#333')
            .margin({ left: 5 })
            .onClick(() => this.formMealType = MealType.Supper)
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .margin({ bottom: 15 })
      
      // 标签
      Column() {
        Text('标签（用逗号分隔）')
          .fontSize(14)
          .alignSelf(ItemAlign.Start)
          .margin({ bottom: 5 })
        TextInput({ placeholder: '例如: 辣, 面食, 汤', text: this.formTags })
          .onChange((value) => {
            this.formTags = value;
          })
      }
      .width('100%')
      .margin({ bottom: 15 })
      
      // 价格档位
      Column() {
        Text('价格档位')
          .fontSize(14)
          .alignSelf(ItemAlign.Start)
          .margin({ bottom: 5 })
        Row() {
          Button('¥')
            .fontSize(12)
            .backgroundColor(this.formPriceLevel === 1 ? '#ff9800' : '#f0f0f0')
            .fontColor(this.formPriceLevel === 1 ? '#fff' : '#333')
            .onClick(() => this.formPriceLevel = 1)
          Button('¥¥')
            .fontSize(12)
            .backgroundColor(this.formPriceLevel === 2 ? '#ff9800' : '#f0f0f0')
            .fontColor(this.formPriceLevel === 2 ? '#fff' : '#333')
            .margin({ left: 10 })
            .onClick(() => this.formPriceLevel = 2)
          Button('¥¥¥')
            .fontSize(12)
            .backgroundColor(this.formPriceLevel === 3 ? '#ff9800' : '#f0f0f0')
            .fontColor(this.formPriceLevel === 3 ? '#fff' : '#333')
            .margin({ left: 10 })
            .onClick(() => this.formPriceLevel = 3)
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .margin({ bottom: 15 })
      
      // 来源
      Column() {
        Text('来源')
          .fontSize(14)
          .alignSelf(ItemAlign.Start)
          .margin({ bottom: 5 })
        Row() {
          Button('在家做')
            .fontSize(12)
            .backgroundColor(this.formOrigin === 'home' ? '#4caf50' : '#f0f0f0')
            .fontColor(this.formOrigin === 'home' ? '#fff' : '#333')
            .onClick(() => this.formOrigin = 'home')
          Button('堂食')
            .fontSize(12)
            .backgroundColor(this.formOrigin === 'restaurant' ? '#4caf50' : '#f0f0f0')
            .fontColor(this.formOrigin === 'restaurant' ? '#fff' : '#333')
            .margin({ left: 10 })
            .onClick(() => this.formOrigin = 'restaurant')
          Button('外卖')
            .fontSize(12)
            .backgroundColor(this.formOrigin === 'takeaway' ? '#4caf50' : '#f0f0f0')
            .fontColor(this.formOrigin === 'takeaway' ? '#fff' : '#333')
            .margin({ left: 10 })
            .onClick(() => this.formOrigin = 'takeaway')
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .margin({ bottom: 20 })
      
      // 按钮
      Row() {
        Button('取消')
          .fontSize(14)
          .backgroundColor('#9e9e9e')
          .onClick(() => {
            this.showAddDialog = false;
          })
        
        Button('保存')
          .fontSize(14)
          .backgroundColor('#ff6b6b')
          .margin({ left: 10 })
          .onClick(() => this.handleSave())
      }
    }
    .width('90%')
    .padding(20)
    .backgroundColor('#fff')
    .borderRadius(10)
  }
  
  build() {
    Column() {
      // 标题和搜索
      Column() {
        Row() {
          Text('菜品管理')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
          
          Blank()
          
          Button('+ 新增')
            .fontSize(14)
            .backgroundColor('#ff6b6b')
            .onClick(() => this.openAddDialog())
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 20 })
        
        Search({ placeholder: '搜索菜名或标签', value: this.searchText })
          .width('90%')
          .margin({ top: 15, bottom: 10 })
          .onChange((value) => {
            this.searchText = value;
          })
        
        // 时间段筛选按钮
        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
          Button('全部')
            .fontSize(12)
            .backgroundColor(this.filterMealType === 'all' ? '#ff6b6b' : '#f0f0f0')
            .fontColor(this.filterMealType === 'all' ? '#fff' : '#333')
            .margin(5)
            .onClick(() => {
              this.filterMealType = 'all';
            })
          Button('早餐')
            .fontSize(12)
            .backgroundColor(this.filterMealType === MealType.Breakfast ? '#ff6b6b' : '#f0f0f0')
            .fontColor(this.filterMealType === MealType.Breakfast ? '#fff' : '#333')
            .margin(5)
            .onClick(() => {
              this.filterMealType = MealType.Breakfast;
            })
          Button('午餐')
            .fontSize(12)
            .backgroundColor(this.filterMealType === MealType.Lunch ? '#ff6b6b' : '#f0f0f0')
            .fontColor(this.filterMealType === MealType.Lunch ? '#fff' : '#333')
            .margin(5)
            .onClick(() => {
              this.filterMealType = MealType.Lunch;
            })
          Button('下午茶')
            .fontSize(12)
            .backgroundColor(this.filterMealType === MealType.AfternoonTea ? '#ff6b6b' : '#f0f0f0')
            .fontColor(this.filterMealType === MealType.AfternoonTea ? '#fff' : '#333')
            .margin(5)
            .onClick(() => {
              this.filterMealType = MealType.AfternoonTea;
            })
          Button('晚餐')
            .fontSize(12)
            .backgroundColor(this.filterMealType === MealType.Dinner ? '#ff6b6b' : '#f0f0f0')
            .fontColor(this.filterMealType === MealType.Dinner ? '#fff' : '#333')
            .margin(5)
            .onClick(() => {
              this.filterMealType = MealType.Dinner;
            })
          Button('夜宵')
            .fontSize(12)
            .backgroundColor(this.filterMealType === MealType.Supper ? '#ff6b6b' : '#f0f0f0')
            .fontColor(this.filterMealType === MealType.Supper ? '#fff' : '#333')
            .margin(5)
            .onClick(() => {
              this.filterMealType = MealType.Supper;
            })
        }
        .width('90%')
        .padding({ left: 5, right: 5 })
      }
      
      // 菜品列表
      List({ space: 10 }) {
        ForEach(this.getFilteredFoods(), (food: FoodItem) => {
          ListItem() {
            Row() {
              // 启用/禁用图标
              Text(food.enabled ? '✓' : '✕')
                .fontSize(16)
                .fontColor(food.enabled ? '#4caf50' : '#999')
                .width(28)
                .height(28)
                .textAlign(TextAlign.Center)
                .backgroundColor(food.enabled ? '#e8f5e9' : '#f5f5f5')
                .borderRadius(14)
                .margin({ right: 10 })
                .padding({ bottom: 2 })
                .onClick(() => {
                  this.toggleEnabled(food);
                })
              
              // 菜品信息
              Column() {
                Text(food.name)
                  .fontSize(18)
                  .fontWeight(FontWeight.Medium)
                  .margin({ bottom: 5 })
                
                Row() {
                  Text(getMealTypeName(food.mealType))
                    .fontSize(12)
                    .fontColor('#666')
                    .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                    .backgroundColor('#e3f2fd')
                    .borderRadius(8)
                    .margin({ right: 5 })
                  
                  ForEach(food.tags.slice(0, 2), (tag: string) => {
                    Text(tag)
                      .fontSize(12)
                      .fontColor('#666')
                      .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                      .backgroundColor('#f5f5f5')
                      .borderRadius(8)
                      .margin({ right: 5 })
                  })
                  
                  if (food.tags.length > 2) {
                    Text(`+${food.tags.length - 2}`)
                      .fontSize(12)
                      .fontColor('#999')
                      .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                      .backgroundColor('#f5f5f5')
                      .borderRadius(8)
                  }
                }
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
              .margin({ right: 10 })
              .onClick(() => this.openEditDialog(food))
              
              // 操作按钮
              Row() {
                Button('编辑')
                  .fontSize(12)
                  .backgroundColor('#2196f3')
                  .onClick(() => this.openEditDialog(food))
                  .width(60)
                
                Button('删除')
                  .fontSize(12)
                  .backgroundColor('#f44336')
                  .onClick(() => this.handleDelete(food))
                  .width(60)
                  .margin({ left: 5 })
              }
            }
            .width('100%')
            .padding(15)
            .backgroundColor('#fff')
            .borderRadius(10)
          }
        })
      }
      .width('90%')
      .layoutWeight(1)
      .margin({ top: 10 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f5f5')
    .bindSheet(this.showAddDialog, this.AddEditDialog(), {
      height: 600,
      backgroundColor: Color.Transparent,
      showClose: false,
      onDisappear: () => {
        this.showAddDialog = false;
      }
    })
  }
}
