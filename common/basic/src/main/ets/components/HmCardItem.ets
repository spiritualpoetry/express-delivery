@Preview
@Component
struct HmCardItem {
  onRightClick:()=>void =()=>{}
  leftTitle:string="左侧内容"
  showBottomBorder:boolean=true
  showRightIcon:boolean=true
  @Prop
  rightText:string="右侧"
  build() {
    Row(){
      //左侧标题
      Text(this.leftTitle).fontSize(16).fontWeight(400).fontColor($r('app.color.text_primary'))
      Row(){
        if (this.rightText){
          Text(this.rightText)
            .fontSize(16)
            .fontColor($r('app.color.text_secondary'))
        }
        if (this.showRightIcon){
          Image($r('app.media.ic_btn_more'))
            .width(24)
            .height(24)
        }
      }
    }
    .justifyContent(FlexAlign.SpaceBetween)
    .border({
      width:{
        bottom:this.showBottomBorder?1:0
      },color:$r("app.color.background_divider")
    })
    .width("100%")
    .height(60)
  }
}
export  {HmCardItem}