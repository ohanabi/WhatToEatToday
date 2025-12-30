import { UserManager } from '../store/UserManager';
import promptAction from '@ohos.promptAction';
import router from '@ohos.router';

@Entry
@Component
struct LoginPage {
  @State username: string = '';
  @State password: string = '';
  @State isLogin: boolean = true; // true=登录模式, false=注册模式
  @State isLoading: boolean = false;
  private userManager: UserManager = UserManager.getInstance();
  
  async handleSubmit() {
    if (this.isLoading) return;
    
    this.isLoading = true;
    
    try {
      if (this.isLogin) {
        // 登录
        const result = await this.userManager.login(this.username, this.password);
        if (result.success) {
          promptAction.showToast({ message: result.message });
          // 跳转到主页
          router.replaceUrl({
            url: 'pages/Index'
          });
        } else {
          promptAction.showToast({ message: result.message });
        }
      } else {
        // 注册
        const result = await this.userManager.register(this.username, this.password);
        if (result.success) {
          promptAction.showToast({ message: result.message + '，请登录' });
          this.isLogin = true;
          this.password = '';
        } else {
          promptAction.showToast({ message: result.message });
        }
      }
    } finally {
      this.isLoading = false;
    }
  }
  
  build() {
    Column() {
      // Logo和标题
      Column() {
        Text('🍽️')
          .fontSize(64)
          .margin({ bottom: 20 })
        
        Text('今天吃什么')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 10 })
        
        Text(this.isLogin ? '登录您的账号' : '注册新账号')
          .fontSize(14)
          .fontColor('#999')
      }
      .margin({ top: 100, bottom: 60 })
      
      // 输入框
      Column() {
        // 用户名
        Column() {
          Text('用户名')
            .fontSize(14)
            .fontColor('#333')
            .alignSelf(ItemAlign.Start)
            .margin({ bottom: 8 })
          
          TextInput({ placeholder: '请输入用户名', text: this.username })
            .height(48)
            .fontSize(16)
            .backgroundColor('#f5f5f5')
            .borderRadius(8)
            .onChange((value) => {
              this.username = value;
            })
        }
        .width('100%')
        .margin({ bottom: 20 })
        
        // 密码
        Column() {
          Text('密码')
            .fontSize(14)
            .fontColor('#333')
            .alignSelf(ItemAlign.Start)
            .margin({ bottom: 8 })
          
          TextInput({ placeholder: '请输入密码', text: this.password })
            .height(48)
            .fontSize(16)
            .type(InputType.Password)
            .backgroundColor('#f5f5f5')
            .borderRadius(8)
            .onChange((value) => {
              this.password = value;
            })
        }
        .width('100%')
        .margin({ bottom: 30 })
        
        // 提交按钮
        Button(this.isLogin ? '登录' : '注册')
          .width('100%')
          .height(48)
          .fontSize(16)
          .backgroundColor('#ff6b6b')
          .borderRadius(8)
          .enabled(!this.isLoading)
          .opacity(this.isLoading ? 0.6 : 1)
          .onClick(() => this.handleSubmit())
        
        // 切换模式
        Row() {
          Text(this.isLogin ? '还没有账号？' : '已有账号？')
            .fontSize(14)
            .fontColor('#666')
          
          Text(this.isLogin ? '立即注册' : '立即登录')
            .fontSize(14)
            .fontColor('#ff6b6b')
            .margin({ left: 5 })
            .onClick(() => {
              this.isLogin = !this.isLogin;
              this.password = '';
            })
        }
        .margin({ top: 20 })
      }
      .width('85%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#fff')
  }
}
