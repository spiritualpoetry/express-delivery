import { CommonRouterParams, DateFormat, HmCard, HmCardItem, HmNavBar } from '@hm/basic'
import { promptAction, router } from '@kit.ArkUI'
import {DelayParamsType,DelayParamsTypeModel}   from '../../models'
import {delay}from  '../../api'
@Entry
@Component
struct Delay {
  @State
  delayForm:DelayParamsTypeModel=new DelayParamsTypeModel({delayReason:'',delayTime:'',id:''})

  @State
  submitting:boolean=false

  @State
  oldTime:string=''

  aboutToAppear(): void {
    const params = router.getParams() as CommonRouterParams
    if (params && params.oldTime) {
      this.oldTime=params.oldTime
    }
    if (params && params.id) {
      this.delayForm.id=params.id
    }
  }

  getBtnEnable(){
    if (!this.submitting && this.delayForm.delayTime && this.delayForm.delayReason.trim() && this.delayForm.id) {
      return true
    }
    return false
  }

  async btnDelay(){
    if (!this.getBtnEnable()) {
      return
    }
    this.submitting=true
    try {
      await delay(this.delayForm)
      promptAction.showToast({message:"延迟提货成功"})
      router.back()
    } catch (error) {
      // 请求封装已显示失败提示，保留表单供重试。
    } finally {
      this.submitting=false
    }
  }

  build() {
    Column(){
     HmNavBar({title:"延迟提货",showBackIcon:true})
      HmCard(){
        HmCardItem({leftTitle:"原定时间",rightText:this.oldTime,showRightIcon:false})
        HmCardItem({leftTitle:"延迟时间",
          rightText:this.delayForm.delayTime || "",
          showBottomBorder:false,
          onRightClick:()=>{
            DatePickerDialog.show({
              useMilitaryTime:true,
              showTime:true,
              onDateAccept:(value:Date)=>{
               this.delayForm.delayTime= DateFormat(value)
              }
            })
        }})
        TextArea({ placeholder: '请输入延迟提货原因',text:this.delayForm.delayReason })
          .maxLength(50)
          .onChange(value=>{
            this.delayForm.delayReason=value
          })
          .backgroundColor($r('app.color.background_page'))
          .margin({
          top: 20
        })
          .borderRadius(8)
          .height(130)
          .placeholderColor($r('app.color.text_secondary'))
          .fontSize(14)
        Text(`${this.delayForm.delayReason?.length || 0}/50`)
          .margin({
            top: -30
          })
          .textAlign(TextAlign.End)
          .width('100%')
          .padding({ right: 15 })
          .fontColor($r('app.color.text_secondary'))
        Row(){
          Button("提交")
            .backgroundColor($r("app.color.primary"))
            .onClick(()=>{
              this.btnDelay()
            })
            .width(207)
            .height(50)
            .enabled(this.getBtnEnable())
        }
        .justifyContent(FlexAlign.Center)
        .padding({
          top: 20,
          bottom:20
        })
      }
    }
    .backgroundColor($r("app.color.background_page"))
    .height("100%")
  }
}
