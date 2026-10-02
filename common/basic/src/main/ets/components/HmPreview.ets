@CustomDialog
@Component
struct HmPreview {
  controller:CustomDialogController
  //支持多张图片预览 给多张地址给一个需要预览的索引
  urls:string[]=[]
  selectIndex:number=-1
  build() {
    Column(){
      Swiper(){
        ForEach(this.urls,(url:string)=>{
          Image(url)
            .width("100%")
            .onClick(()=>{
              this.controller.close()
            })
        })
      }
      .indicator(false)
      .index(this.selectIndex)//当前要看的图片
    }
    .justifyContent(FlexAlign.Center)
    .width("100%")
    .height("100%")
    .backgroundColor($r("app.color.black"))
  }
}
export {HmPreview}