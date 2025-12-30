import preferences from '@ohos.data.preferences';
import { User, LoginInfo } from '../model/User';

// 操作结果接口
export interface OperationResult {
  success: boolean;
  message: string;
}

// 用户管理类
export class UserManager {
  private static instance: UserManager | null = null;
  private context: Context | null = null;
  private dataStore: preferences.Preferences | null = null;
  
  private constructor() {}
  
  static getInstance(): UserManager {
    if (!UserManager.instance) {
      UserManager.instance = new UserManager();
    }
    return UserManager.instance;
  }
  
  // 初始化
  async init(context: Context): Promise<void> {
    this.context = context;
    this.dataStore = await preferences.getPreferences(context, 'users_data');
  }
  
  // 注册
  async register(username: string, password: string): Promise<OperationResult> {
    if (!this.dataStore) {
      const result: OperationResult = { success: false, message: '系统未初始化' };
      return result;
    }
    
    if (!username || !password) {
      const result: OperationResult = { success: false, message: '用户名和密码不能为空' };
      return result;
    }
    
    if (username.length < 3 || username.length > 20) {
      const result: OperationResult = { success: false, message: '用户名长度应为3-20个字符' };
      return result;
    }
    
    if (password.length < 6) {
      const result: OperationResult = { success: false, message: '密码长度至少6个字符' };
      return result;
    }
    
    // 检查用户是否已存在
    const userKey = `user_${username}`;
    const existingUser = await this.dataStore.get(userKey, '');
    if (existingUser) {
      const result: OperationResult = { success: false, message: '用户名已存在' };
      return result;
    }
    
    // 创建新用户
    const user: User = {
      username: username,
      password: password,
      createdAt: Date.now()
    };
    
    await this.dataStore.put(userKey, JSON.stringify(user));
    await this.dataStore.flush();
    
    const result: OperationResult = { success: true, message: '注册成功' };
    return result;
  }
  
  // 登录
  async login(username: string, password: string): Promise<OperationResult> {
    if (!this.dataStore) {
      const result: OperationResult = { success: false, message: '系统未初始化' };
      return result;
    }
    
    if (!username || !password) {
      const result: OperationResult = { success: false, message: '用户名和密码不能为空' };
      return result;
    }
    
    // 查找用户
    const userKey = `user_${username}`;
    const userStr = await this.dataStore.get(userKey, '') as string;
    
    if (!userStr) {
      const result: OperationResult = { success: false, message: '用户不存在' };
      return result;
    }
    
    const user: User = JSON.parse(userStr);
    
    if (user.password !== password) {
      const result: OperationResult = { success: false, message: '密码错误' };
      return result;
    }
    
    // 保存登录状态
    const loginInfo: LoginInfo = {
      isLoggedIn: true,
      currentUser: username
    };
    
    await this.dataStore.put('login_info', JSON.stringify(loginInfo));
    await this.dataStore.flush();
    
    const result: OperationResult = { success: true, message: '登录成功' };
    return result;
  }
  
  // 登出
  async logout(): Promise<void> {
    if (!this.dataStore) return;
    
    const loginInfo: LoginInfo = {
      isLoggedIn: false,
      currentUser: ''
    };
    
    await this.dataStore.put('login_info', JSON.stringify(loginInfo));
    await this.dataStore.flush();
  }
  
  // 获取登录状态
  async getLoginInfo(): Promise<LoginInfo> {
    if (!this.dataStore) {
      const info: LoginInfo = { isLoggedIn: false, currentUser: '' };
      return info;
    }
    
    const loginInfoStr = await this.dataStore.get('login_info', '') as string;
    
    if (!loginInfoStr) {
      const info: LoginInfo = { isLoggedIn: false, currentUser: '' };
      return info;
    }
    
    return JSON.parse(loginInfoStr);
  }
  
  // 获取当前用户名
  async getCurrentUser(): Promise<string> {
    const loginInfo = await this.getLoginInfo();
    return loginInfo.currentUser;
  }
  
  // 检查是否已登录
  async isLoggedIn(): Promise<boolean> {
    const loginInfo = await this.getLoginInfo();
    return loginInfo.isLoggedIn;
  }
}
