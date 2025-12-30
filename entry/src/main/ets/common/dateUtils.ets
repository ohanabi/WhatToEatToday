// 获取今日日期字符串 YYYY-MM-DD
export function getTodayDate(): string {
  const date = new Date();
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

// 获取当前时间戳的 ISO 字符串
export function getCurrentISOString(): string {
  return new Date().toISOString();
}

// 计算两个日期之间的天数差
export function getDaysDiff(date1: string, date2: string): number {
  const d1 = new Date(date1);
  const d2 = new Date(date2);
  const diffTime = Math.abs(d2.getTime() - d1.getTime());
  const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
  return diffDays;
}

// 根据当前时间自动判断餐别
export function getCurrentMealType(): string {
  const hour = new Date().getHours();
  
  if (hour >= 6 && hour < 10) {
    return 'breakfast'; // 早餐 6:00-10:00
  } else if (hour >= 10 && hour < 14) {
    return 'lunch'; // 午餐 10:00-14:00
  } else if (hour >= 14 && hour < 17) {
    return 'afternoontea'; // 下午茶 14:00-17:00
  } else if (hour >= 17 && hour < 21) {
    return 'dinner'; // 晚餐 17:00-21:00
  } else {
    return 'supper'; // 夜宵 21:00-6:00
  }
}

// 格式化日期显示 (YYYY-MM-DD -> MM月DD日)
export function formatDate(dateStr: string): string {
  const parts = dateStr.split('-');
  if (parts.length === 3) {
    return `${parts[1]}月${parts[2]}日`;
  }
  return dateStr;
}
