@Preview
@CustomDialog
@Component
struct HmConfirm {
  controller:CustomDialogController
  //两部分内容 确定内容 按钮
  message:string="确定要退出吗"
  //接受的按钮类型
  buttonsList:HmConfirmButton[]=[{
    text:'确定',
    fontsize:14,
    fontcolor:$r("app.color.text_secondary")
  }]
  build() {
    Row(){
      Column(){
        Row(){
          Text(this.message)
            .fontSize(16)
            .fontColor($r("app.color.text_primary"))
        }
        .justifyContent(FlexAlign.Center)
        .border({
          width:{
            bottom:0.8
          } ,
          color:$r("app.color.background_divider")//边框色
        })
        .width("100%")
        .height(88)

        Row(){
          ForEach(this.buttonsList,(item:HmConfirmButton,index:number)=>{
            Text(item.text)
              .height("100%")
              .fontColor(item.fontcolor||$r("app.color.text_secondary"))
              .fontSize(item.fontsize || 16 )
              .layoutWeight(1)//按钮撑满整个空间
              .textAlign(TextAlign.Center)
              .border({
                color:$r("app.color.background_divider"),
                width:{
                  right:index!==this.buttonsList.length-1?0.8:0
                }
              })
              .onClick(async () => {
                if(item.action) {
                  await item.action()
                }
                this.controller.close()
              })
          })
        }
        .width("100%")
        .height(50)
      }
      .width(278)
      .borderRadius(12)
      .backgroundColor($r("app.color.white"))}
  }
}
//按钮的类型
class HmConfirmButton{
  text:string=""
  fontsize:number=16
  fontcolor:ResourceStr=""
  action?: () => void = () => {}
}
export {HmConfirm}