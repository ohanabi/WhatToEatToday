// 节日配置和检测
import { i18n } from '@kit.LocalizationKit';

export interface Festival {
  name: string;
  description: string;
  emoji: string;
  recommendedFoods: string[]; // 推荐的食物名称
  startDate: string; // MM-DD 格式（阳历）或农历月日
  endDate: string; // MM-DD 格式（阳历）或农历月日
  type: 'traditional' | 'modern';
  isLunar: boolean; // 是否为农历节日
  lunarMonth?: number; // 农历月份（1-12）
  lunarDay?: number; // 农历日期（1-30）
  lunarDayRange?: number; // 农历日期范围（例如春节持续7天）
}

interface LunarDateInfo {
  year: number;
  month: number;
  day: number;
}

// 农历数据表（每年12/13个月的天数）
// 数据格式：16进制，每4位表示一个月，0x为29天，0x1为30天
const lunarInfo: number[] = [
  0x04bd8, 0x04ae0, 0x0a570, 0x054d5, 0x0d260, 0x0d950, 0x16554, 0x056a0, 0x09ad0, 0x055d2, // 1900-1909
  0x04ae0, 0x0a5b6, 0x0a4d0, 0x0d250, 0x1d255, 0x0b540, 0x0d6a0, 0x0ada2, 0x095b0, 0x14977, // 1910-1919
  0x04970, 0x0a4b0, 0x0b4b5, 0x06a50, 0x06d40, 0x1ab54, 0x02b60, 0x09570, 0x052f2, 0x04970, // 1920-1929
  0x06566, 0x0d4a0, 0x0ea50, 0x16a95, 0x05ad0, 0x02b60, 0x186e3, 0x092e0, 0x1c8d7, 0x0c950, // 1930-1939
  0x0d4a0, 0x1d8a6, 0x0b550, 0x056a0, 0x1a5b4, 0x025d0, 0x092d0, 0x0d2b2, 0x0a950, 0x0b557, // 1940-1949
  0x06ca0, 0x0b550, 0x15355, 0x04da0, 0x0a5b0, 0x14573, 0x052b0, 0x0a9a8, 0x0e950, 0x06aa0, // 1950-1959
  0x0aea6, 0x0ab50, 0x04b60, 0x0aae4, 0x0a570, 0x05260, 0x0f263, 0x0d950, 0x05b57, 0x056a0, // 1960-1969
  0x096d0, 0x04dd5, 0x04ad0, 0x0a4d0, 0x0d4d4, 0x0d250, 0x0d558, 0x0b540, 0x0b6a0, 0x195a6, // 1970-1979
  0x095b0, 0x049b0, 0x0a974, 0x0a4b0, 0x0b27a, 0x06a50, 0x06d40, 0x0af46, 0x0ab60, 0x09570, // 1980-1989
  0x04af5, 0x04970, 0x064b0, 0x074a3, 0x0ea50, 0x06b58, 0x055c0, 0x0ab60, 0x096d5, 0x092e0, // 1990-1999
  0x0c960, 0x0d954, 0x0d4a0, 0x0da50, 0x07552, 0x056a0, 0x0abb7, 0x025d0, 0x092d0, 0x0cab5, // 2000-2009
  0x0a950, 0x0b4a0, 0x0baa4, 0x0ad50, 0x055d9, 0x04ba0, 0x0a5b0, 0x15176, 0x052b0, 0x0a930, // 2010-2019
  0x07954, 0x06aa0, 0x0ad50, 0x05b52, 0x04b60, 0x0a6e6, 0x0a4e0, 0x0d260, 0x0ea65, 0x0d530, // 2020-2029
  0x05aa0, 0x076a3, 0x096d0, 0x04bd7, 0x04ad0, 0x0a4d0, 0x1d0b6, 0x0d250, 0x0d520, 0x0dd45  // 2030-2039
];

// 公历转农历
function solarToLunar(solarYear: number, solarMonth: number, solarDay: number): LunarDateInfo | null {
  try {
    // 基准日期：1900年1月31日是农历1900年正月初一
    const baseDate = new Date(1900, 0, 31);
    const targetDate = new Date(solarYear, solarMonth - 1, solarDay);
    
    // 计算天数差
    let offset = Math.floor((targetDate.getTime() - baseDate.getTime()) / 86400000);
    
    let lunarYear = 1900;
    let daysInYear = 0;
    
    // 计算农历年份
    for (let i = 1900; i < 2100 && offset > 0; i++) {
      daysInYear = getLunarYearDays(i);
      if (offset < daysInYear) {
        lunarYear = i;
        break;
      }
      offset -= daysInYear;
    }
    
    // 计算农历月份
    let leapMonth = getLeapMonth(lunarYear);
    let isLeap = false;
    let lunarMonth = 1;
    let daysInMonth = 0;
    
    for (let i = 1; i <= 12; i++) {
      // 闰月
      if (leapMonth > 0 && i === leapMonth + 1 && !isLeap) {
        i--;
        isLeap = true;
        daysInMonth = getLeapMonthDays(lunarYear);
      } else {
        daysInMonth = getLunarMonthDays(lunarYear, i);
      }
      
      if (offset < daysInMonth) {
        lunarMonth = i;
        break;
      }
      
      offset -= daysInMonth;
      
      if (isLeap && i === leapMonth + 1) {
        isLeap = false;
      }
    }
    
    let lunarDay = offset + 1;
    
    return {
      year: lunarYear,
      month: lunarMonth,
      day: lunarDay
    };
  } catch (err) {
    console.error('农历转换失败:', err);
    return null;
  }
}

// 获取农历年份的总天数
function getLunarYearDays(year: number): number {
  let sum = 348;
  for (let i = 0x8000; i > 0x8; i >>= 1) {
    sum += (lunarInfo[year - 1900] & i) ? 1 : 0;
  }
  return sum + getLeapMonthDays(year);
}

// 获取农历年份的闰月天数
function getLeapMonthDays(year: number): number {
  if (getLeapMonth(year)) {
    return (lunarInfo[year - 1900] & 0x10000) ? 30 : 29;
  }
  return 0;
}

// 获取农历年份的闰月月份（0表示无闰月）
function getLeapMonth(year: number): number {
  return lunarInfo[year - 1900] & 0xf;
}

// 获取农历月份的天数
function getLunarMonthDays(year: number, month: number): number {
  return (lunarInfo[year - 1900] & (0x10000 >> month)) ? 30 : 29;
}

// 获取当前农历日期
function getLunarDate(): LunarDateInfo | null {
  try {
    const now = new Date();
    const lunar = solarToLunar(now.getFullYear(), now.getMonth() + 1, now.getDate());
    
    if (lunar) {
      console.info(`阳历: ${now.getFullYear()}-${now.getMonth() + 1}-${now.getDate()}`);
      console.info(`农历: ${lunar.year}年${lunar.month}月${lunar.day}日`);
    }
    
    return lunar;
  } catch (err) {
    console.error('获取农历日期失败:', err);
    return null;
  }
}

// 判断是否在农历日期范围内
function isInLunarRange(currentMonth: number, currentDay: number, 
                       targetMonth: number, targetDay: number, dayRange: number): boolean {
  if (currentMonth !== targetMonth) return false;
  
  if (dayRange === 1) {
    return currentDay === targetDay;
  } else {
    // 处理跨月情况（理论上春节可能跨月，但实际很少见）
    return currentDay >= targetDay && currentDay < targetDay + dayRange;
  }
}

// 节日配置列表
const festivals: Festival[] = [
  // 传统节日（农历）
  {
    name: '除夕',
    description: '辞旧迎新，守岁团圆',
    emoji: '🎆',
    recommendedFoods: ['饺子', '鱼', '年糕', '春卷', '红烧肉', '佛跳墙', '八宝饭'],
    startDate: '',
    endDate: '',
    type: 'traditional',
    isLunar: true,
    lunarMonth: 12,
    lunarDay: 30, // 腊月三十（或二十九）
    lunarDayRange: 1
  },
  {
    name: '春节',
    description: '新春佳节，阖家团圆',
    emoji: '🎊',
    recommendedFoods: ['饺子', '汤圆', '年糕', '鱼', '红烧肉', '春卷', '八宝饭', '佛跳墙'],
    startDate: '',
    endDate: '',
    type: 'traditional',
    isLunar: true,
    lunarMonth: 1,
    lunarDay: 1, // 正月初一到初七
    lunarDayRange: 7
  },
  {
    name: '元宵节',
    description: '正月十五闹元宵',
    emoji: '🏮',
    recommendedFoods: ['汤圆', '元宵'],
    startDate: '',
    endDate: '',
    type: 'traditional',
    isLunar: true,
    lunarMonth: 1,
    lunarDay: 15,
    lunarDayRange: 1
  },
  {
    name: '端午节',
    description: '龙舟竞渡，粽香四溢',
    emoji: '🐉',
    recommendedFoods: ['粽子', '咸鸭蛋', '黄鳝'],
    startDate: '',
    endDate: '',
    type: 'traditional',
    isLunar: true,
    lunarMonth: 5,
    lunarDay: 5,
    lunarDayRange: 1
  },
  {
    name: '七夕节',
    description: '鹊桥相会，浪漫佳节',
    emoji: '💝',
    recommendedFoods: ['巧果', '巧克力', '蛋糕', '牛排', '披萨'],
    startDate: '',
    endDate: '',
    type: 'traditional',
    isLunar: true,
    lunarMonth: 7,
    lunarDay: 7,
    lunarDayRange: 1
  },
  {
    name: '中秋节',
    description: '月圆人团圆',
    emoji: '🥮',
    recommendedFoods: ['月饼', '大闸蟹', '柚子'],
    startDate: '',
    endDate: '',
    type: 'traditional',
    isLunar: true,
    lunarMonth: 8,
    lunarDay: 15,
    lunarDayRange: 1
  },
  {
    name: '重阳节',
    description: '登高赏菊，敬老爱老',
    emoji: '🌼',
    recommendedFoods: ['重阳糕', '菊花酒'],
    startDate: '',
    endDate: '',
    type: 'traditional',
    isLunar: true,
    lunarMonth: 9,
    lunarDay: 9,
    lunarDayRange: 1
  },
  {
    name: '腊八节',
    description: '腊八腊八，冻掉下巴',
    emoji: '🥣',
    recommendedFoods: ['腊八粥'],
    startDate: '',
    endDate: '',
    type: 'traditional',
    isLunar: true,
    lunarMonth: 12,
    lunarDay: 8,
    lunarDayRange: 1
  },
  {
    name: '小年',
    description: '扫尘送灶，迎新纳福',
    emoji: '🧹',
    recommendedFoods: ['灶糖', '年糕', '饺子'],
    startDate: '',
    endDate: '',
    type: 'traditional',
    isLunar: true,
    lunarMonth: 12,
    lunarDay: 23,
    lunarDayRange: 1
  },
  
  // 传统节日（阳历）
  {
    name: '清明节',
    description: '踏青扫墓，缅怀先人',
    emoji: '🌸',
    recommendedFoods: ['青团', '艾草糕'],
    startDate: '04-04',
    endDate: '04-06',
    type: 'traditional',
    isLunar: false
  },
  {
    name: '冬至',
    description: '数九寒冬始，温暖在心间',
    emoji: '☃️',
    recommendedFoods: ['饺子', '汤圆', '羊肉汤', '火锅'],
    startDate: '12-21',
    endDate: '12-23',
    type: 'traditional',
    isLunar: false
  },
  
  // 现代节日
  {
    name: '元旦',
    description: '新年新气象',
    emoji: '🎉',
    recommendedFoods: ['火锅', '烧烤', '披萨', '汉堡', '蛋糕'],
    startDate: '01-01',
    endDate: '01-03',
    type: 'modern',
    isLunar: false
  },
  {
    name: '情人节',
    description: '浪漫之夜',
    emoji: '💕',
    recommendedFoods: ['牛排', '意大利面', '披萨', '蛋糕', '巧克力', '红酒'],
    startDate: '02-14',
    endDate: '02-14',
    type: 'modern',
    isLunar: false
  },
  {
    name: '劳动节',
    description: '劳动最光荣',
    emoji: '🎈',
    recommendedFoods: ['烧烤', '火锅', '小龙虾', '烤肉'],
    startDate: '05-01',
    endDate: '05-05',
    type: 'modern',
    isLunar: false
  },
  {
    name: '儿童节',
    description: '童心未泯',
    emoji: '🍭',
    recommendedFoods: ['汉堡', '披萨', '炸鸡', '薯条', '冰淇淋', '蛋糕', '甜甜圈'],
    startDate: '06-01',
    endDate: '06-01',
    type: 'modern',
    isLunar: false
  },
  {
    name: '国庆节',
    description: '普天同庆',
    emoji: '🇨🇳',
    recommendedFoods: ['火锅', '烧烤', '北京烤鸭', '小龙虾'],
    startDate: '10-01',
    endDate: '10-07',
    type: 'modern',
    isLunar: false
  },
  {
    name: '万圣节',
    description: 'Trick or Treat',
    emoji: '🎃',
    recommendedFoods: ['南瓜派', '披萨', '汉堡', '炸鸡'],
    startDate: '10-31',
    endDate: '10-31',
    type: 'modern',
    isLunar: false
  },
  {
    name: '感恩节',
    description: '感恩有你',
    emoji: '🦃',
    recommendedFoods: ['烤鸡', '火鸡', '南瓜派', '牛排'],
    startDate: '11-28', // 近似
    endDate: '11-28',
    type: 'modern',
    isLunar: false
  },
  {
    name: '平安夜',
    description: '平安喜乐',
    emoji: '🎄',
    recommendedFoods: ['烤鸡', '牛排', '披萨', '蛋糕', '火鸡'],
    startDate: '12-24',
    endDate: '12-24',
    type: 'modern',
    isLunar: false
  },
  {
    name: '圣诞节',
    description: 'Merry Christmas',
    emoji: '🎅',
    recommendedFoods: ['烤鸡', '牛排', '火鸡', '披萨', '蛋糕'],
    startDate: '12-25',
    endDate: '12-25',
    type: 'modern',
    isLunar: false
  }
];

// 获取当前日期的节日
export function getTodayFestival(): Festival | null {
  const now = new Date();
  const month = now.getMonth() + 1;
  const day = now.getDate();
  const todayStr = `${month.toString().padStart(2, '0')}-${day.toString().padStart(2, '0')}`;
  
  // 获取农历日期
  const lunarDate = getLunarDate();
  console.info(`检测节日 - 阳历: ${todayStr}, 农历: ${lunarDate ? `${lunarDate.month}月${lunarDate.day}日` : 'null'}`);
  
  // 先检查阳历节日（优先级高）
  for (let i = 0; i < festivals.length; i++) {
    const festival = festivals[i];
    
    if (!festival.isLunar) {
      // 阳历节日：直接比较
      if (isDateInRange(todayStr, festival.startDate, festival.endDate)) {
        console.info(`匹配到阳历节日: ${festival.name}`);
        return festival;
      }
    }
  }
  
  // 再检查农历节日
  for (let i = 0; i < festivals.length; i++) {
    const festival = festivals[i];
    
    if (festival.isLunar) {
      // 农历节日：使用实时农历日期判断
      if (lunarDate && festival.lunarMonth !== undefined && 
          festival.lunarDay !== undefined && festival.lunarDayRange !== undefined) {
        
        // 特殊处理除夕（腊月最后一天，可能是29或30）
        if (festival.name === '除夕') {
          if (lunarDate.month === 12) {
            // 获取下个月初一来判断是否是除夕
            const tomorrow = new Date(now);
            tomorrow.setDate(tomorrow.getDate() + 1);
            const calendar = i18n.getCalendar('chinese');
            calendar.setTime(tomorrow);
            const tomorrowLunarMonth = (calendar.get('month') as number) + 1;
            const tomorrowLunarDay = calendar.get('date') as number;
            
            // 如果明天是正月初一，今天就是除夕
            if (tomorrowLunarMonth === 1 && tomorrowLunarDay === 1) {
              console.info(`匹配到农历节日: ${festival.name}`);
              return festival;
            }
          }
        } else {
          // 其他农历节日正常判断
          if (isInLunarRange(lunarDate.month, lunarDate.day, 
                            festival.lunarMonth, festival.lunarDay, festival.lunarDayRange)) {
            console.info(`匹配到农历节日: ${festival.name}`);
            return festival;
          }
        }
      }
    }
  }
  
  console.info('未匹配到任何节日');
  return null;
}

// 判断日期是否在范围内
function isDateInRange(dateStr: string, startStr: string, endStr: string): boolean {
  const date = parseMMDD(dateStr);
  const start = parseMMDD(startStr);
  const end = parseMMDD(endStr);
  
  // 处理跨年情况（如春节）
  if (start > end) {
    return date >= start || date <= end;
  }
  
  return date >= start && date <= end;
}

// 解析 MM-DD 格式为数字（用于比较）
function parseMMDD(mmdd: string): number {
  const parts = mmdd.split('-');
  const month = parseInt(parts[0]);
  const day = parseInt(parts[1]);
  return month * 100 + day;
}

// 获取所有节日列表
export function getAllFestivals(): Festival[] {
  return festivals;
}

// 根据名称获取节日
export function getFestivalByName(name: string): Festival | null {
  for (let i = 0; i < festivals.length; i++) {
    if (festivals[i].name === name) {
      return festivals[i];
    }
  }
  return null;
}

// 获取农历日期字符串（供UI显示）
export function getLunarDateString(): string {
  const lunarDate = getLunarDate();
  if (!lunarDate) {
    return '';
  }
  
  // 农历月份名称
  const monthNames = ['', '正月', '二月', '三月', '四月', '五月', '六月', 
                      '七月', '八月', '九月', '十月', '冬月', '腊月'];
  
  // 农历日期名称
  const dayNames = ['', '初一', '初二', '初三', '初四', '初五', '初六', '初七', '初八', '初九', '初十',
                    '十一', '十二', '十三', '十四', '十五', '十六', '十七', '十八', '十九', '二十',
                    '廿一', '廿二', '廿三', '廿四', '廿五', '廿六', '廿七', '廿八', '廿九', '三十'];
  
  const monthName = lunarDate.month <= 12 ? monthNames[lunarDate.month] : `${lunarDate.month}月`;
  const dayName = lunarDate.day <= 30 ? dayNames[lunarDate.day] : `${lunarDate.day}日`;
  
  return `${monthName}${dayName}`;
}
