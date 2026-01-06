import { FoodStore } from '../store/FoodStore';
import { HistoryItem } from '../model/HistoryItem';
import { getMealTypeName } from '../common/constants';
import { formatDate } from '../common/dateUtils';

@Component
export struct HistoryPage {
  @StorageLink('foodStore') foodStore: FoodStore | null = null;
  @State selectedDate: string = '';
  
  // 按日期分组历史记录
  getGroupedHistory(): Map<string, HistoryItem[]> {
    if (!this.foodStore) return new Map();
    
    const grouped = new Map<string, HistoryItem[]>();
    
    // 过滤和分组
    let history = this.foodStore.history.filter(item => item.confirmed);
    
    if (this.selectedDate) {
      history = history.filter(item => item.date === this.selectedDate);
    }
    
    // 按日期分组，倒序排列
    history.sort((a, b) => b.date.localeCompare(a.date));
    
    history.forEach(item => {
      if (!grouped.has(item.date)) {
        grouped.set(item.date, []);
      }
      grouped.get(item.date)!.push(item);
    });
    
    return grouped;
  }
  
  // 获取所有日期列表（用于筛选）
  getAllDates(): string[] {
    if (!this.foodStore) return [];
    
    const dates = new Set<string>();
    this.foodStore.history.forEach(item => {
      if (item.confirmed) {
        dates.add(item.date);
      }
    });
    
    return Array.from(dates).sort((a, b) => b.localeCompare(a));
  }
  
  build() {
    Column() {
      // 标题
      Row() {
        Text('历史记录')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
        
        Blank()
        
        // 显示历史记录总数
        Text(`共${this.foodStore?.history.length || 0}条`)
          .fontSize(14)
          .fontColor('#666')
          .margin({ right: 10 })
        
        if (this.selectedDate) {
          Button('清除筛选')
            .fontSize(14)
            .backgroundColor('#9e9e9e')
            .onClick(() => {
              this.selectedDate = '';
            })
        }
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 20, bottom: 10 })
      
      // 日期筛选（简单的按钮列表）
      if (!this.selectedDate && this.getAllDates().length > 0) {
        Column() {
          Text('快速筛选日期')
            .fontSize(14)
            .fontColor('#666')
            .alignSelf(ItemAlign.Start)
            .margin({ left: 20, bottom: 10 })
          
          Scroll() {
            Row() {
              ForEach(this.getAllDates().slice(0, 10), (date: string) => {
                Button(formatDate(date))
                  .fontSize(12)
                  .backgroundColor('#e3f2fd')
                  .fontColor('#1976d2')
                  .margin({ right: 8 })
                  .onClick(() => {
                    this.selectedDate = date;
                  })
              })
            }
            .padding({ left: 20, right: 20 })
          }
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)
          .width('100%')
        }
        .margin({ bottom: 15 })
      }
      
      // 历史记录列表
      if (this.getGroupedHistory().size === 0) {
        Column() {
          Text('📝')
            .fontSize(60)
            .margin({ bottom: 10 })
          Text('暂无历史记录')
            .fontSize(16)
            .fontColor('#999')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        List({ space: 15 }) {
          ForEach(Array.from(this.getGroupedHistory().entries()), (entry: [string, HistoryItem[]]) => {
            ListItem() {
              Column() {
                // 日期标题
                Row() {
                  Text(formatDate(entry[0]))
                    .fontSize(18)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#ff6b6b')
                  
                  Text(entry[0])
                    .fontSize(12)
                    .fontColor('#999')
                    .margin({ left: 10 })
                }
                .width('100%')
                .margin({ bottom: 10 })
                
                // 该日期下的记录
                Column({ space: 8 }) {
                  ForEach(entry[1], (item: HistoryItem) => {
                    Row() {
                      Column() {
                        Text(item.foodName)
                          .fontSize(16)
                          .fontWeight(FontWeight.Medium)
                        
                        Text(getMealTypeName(item.mealType))
                          .fontSize(12)
                          .fontColor('#666')
                          .margin({ top: 3 })
                      }
                      .alignItems(HorizontalAlign.Start)
                      .layoutWeight(1)
                      
                      // 点赞/踩雷状态
                      if (item.liked) {
                        Text('❤️')
                          .fontSize(20)
                      }
                      if (item.disliked) {
                        Text('🚫')
                          .fontSize(20)
                      }
                    }
                    .width('100%')
                    .padding(12)
                    .backgroundColor('#fafafa')
                    .borderRadius(8)
                  })
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
        .margin({ top: 10, left: '5%', right: '5%' })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f5f5')
  }
}
