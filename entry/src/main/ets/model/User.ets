// 用户模型
export interface User {
  username: string;
  password: string;
  createdAt: number;
}

export interface LoginInfo {
  isLoggedIn: boolean;
  currentUser: string;
}
