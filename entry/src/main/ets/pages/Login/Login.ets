import { LoginForm, LoginFormModel } from '../../models'
import {login} from '../../api'
import { TOKEN_KEY, UserSettingClass } from '@hm/basic'
import router from '@ohos.router'
import { promptAction } from '@kit.ArkUI'

@Entry
@Component
struct Login {

  @State
  loading:boolean=false

  @State
  accountForm:LoginFormModel= new LoginFormModel({
    account:'hongmeng',
    password:'123456'
  } as LoginForm)

  @Styles
  loginStyle() {
    .backgroundColor('#fff')
    .border({ color: $r('app.color.background_divider'), width: { bottom: 1 } })
    .width('100%')
    .height(58)
    .borderRadius(0)
  }

  getBtnEnable(){
    if (this.accountForm.password && this.accountForm.account) {
      return true
    }else {
      return false
    }
  }

  // 调用登录接口
  async login() {
    // console.log('12345678')//!!!!!!!!!!!!!
    // this.loading = true
    // const token = await login(this.accountForm)
    // console.log(token)
    // AppStorage.setOrCreate(TOKEN_KEY, token) // 写入全局状态
    // new UserSettingClass(getContext(this)).setUserToken(token) // 存入首选项
    // this.loading = false
    // router.replaceUrl({
    //   url: 'pages/Index'
    // })


    try {
      this.loading = true
      const token = await login(this.accountForm)
      AppStorage.setOrCreate(TOKEN_KEY, token) // 写入全局状态
      new UserSettingClass(getContext(this)).setUserToken(token) // 存入首选项
      console.log('准备执行跳转...');

      setTimeout(() => {
        console.log('setTimeout 内执行 router.pushUrl');
        router.pushUrl({
          url: 'pages/Index/Index'
        }, (err) => {          // ← 加回调看错误
          if (err) {
            console.error('跳转失败:', err);
          } else {
            console.log('跳转成功！');
          }
        });
      }, 150);
    }catch (error) {
      console.error('登录异常详情:', error);   // ← 重点看这里
      promptAction.showToast({ message: '登录失败: ' + error });
    } finally {
      this.loading = false
    }
  }

  build() {
    Column() {
      // 顶部标题
      Text("小时达").fontColor($r('app.color.text_primary')).fontSize(18).height(25)
      // 账号登录
      Row() {
        Text('账号登录').fontColor($r('app.color.text_primary')).fontSize(24).fontWeight(FontWeight.Bold)
        Row() {
          Text("账号登录").fontColor($r('app.color.primary')).fontSize(16).fontWeight(FontWeight.Bold)
          Image($r("app.media.ic_angle")).width(10).height(10).margin({ left: 5 })
        }
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ top: 50, bottom: 50 })

      // 用户名输入框
      TextInput({ placeholder: '请输入账号' ,text:this.accountForm.account})
        .loginStyle()
        .onChange((value)=>{
          this.accountForm.account=value
        })

      // 密码框
      TextInput({ placeholder: '请输入密码',text:this.accountForm.password })
        .loginStyle()
        .type(InputType.Password) // 密码框
        .showPasswordIcon(true) // 显示密码按钮
        .onChange((value)=>{
          console.log("dayin 打印")
          console.log(this.accountForm.account.toString())
          this.accountForm.password=value
        })
      // 登录按钮
      Button({ type: ButtonType.Capsule }) {
        Row() {
          if (this.loading){
            LoadingProgress().width(20).height(20).margin({ right: 12 }).color($r('app.color.white'))
          }
          Text('登录').fontColor($r('app.color.white'))
        }
      }
      .onClick(() => {
        console.log('账号:', this.accountForm.account)
        console.log('密码:', this.accountForm.password)
        this.login()
      })
      .enabled(this.getBtnEnable())
      .backgroundColor($r('app.color.primary'))
      .width('100%')
      .height(50)
      .margin({ top: 50 })
    }
    .padding({ left: 32, right: 32 })
    .margin({ top: 40 })
  }
}