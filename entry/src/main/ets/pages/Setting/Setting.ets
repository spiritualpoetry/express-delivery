import { HmCard, HmCardItem, HmConfirm, HmNavBar, TOKEN_KEY, UserSettingClass } from '@hm/basic'
import { router } from '@kit.ArkUI'

@Entry
@Component
struct Setting {
  confirm:CustomDialogController=new CustomDialogController({
    builder:HmConfirm({
      buttonsList:[{
          text:'取消',
          fontsize:14,
          fontcolor:$r("app.color.text_secondary")},
        {
          text:'确定',
          fontsize:14,
          fontcolor:$r("app.color.primary"),
          action:()=>{
            this.logout()
          }
        }]
    }),
    alignment:DialogAlignment.Center,
    customStyle:true
  })
  //封装一个退出登录方法
  logout(){
    //删除token
    AppStorage.set(TOKEN_KEY,"")//清空全局token
    new UserSettingClass(getContext()).setUserToken("")//清空首选项
    router.replaceUrl({
      url:'pages/Login/Login'
    })
  }
  build() {
    Column(){
      HmNavBar({title:'系统设置'},)
      HmCard(){
        HmCardItem({leftTitle:"换绑手机",rightText:""})
        HmCardItem({leftTitle:"修改密码",rightText:""})
        HmCardItem({leftTitle:"消息通知设置",rightText:""})
        HmCardItem({leftTitle:"清理缓存",rightText:"",showBottomBorder:false})
      }
      Row(){
        Button("退出", { type: ButtonType.Normal })
          .backgroundColor($r('app.color.white'))
          .fontColor($r("app.color.text_primary"))
          .width('100%')
          .borderRadius(8)
          .height(60)
      }.width('100%')
      .justifyContent(FlexAlign.Center)
      .margin({ top: 20})
      .padding({left:15,right:15})
      .onClick(()=>{
        this.confirm.open()
      })
    }
    .width("100%")
    .height("100%")
    .backgroundColor($r("app.color.background_page"))
  }
}