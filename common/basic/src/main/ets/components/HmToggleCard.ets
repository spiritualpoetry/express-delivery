@Component
struct HmToggleCard {
  title: string = "基本信息"
  @State
  toggleCard: boolean = true // 是否展示
  // 尾随闭包
  @BuilderParam
  CardContent: () => void
  build() {
    Column() {
      Column() {
        Row () {
          Text(this.title)
            .fontSize(16)
            .fontColor($r("app.color.text_primary"))
            .fontWeight(500)
          Image(this.toggleCard ? $r("app.media.ic_btn_cut") :  $r("app.media.ic_btn_add"))
            .width(24)
            .aspectRatio(1)
            .onClick(() => {
              animateTo({ duration: 300 }, () => {
                this.toggleCard = !this.toggleCard
              })

            })
        }
        .width("100%")
        .height(50)
        .justifyContent(FlexAlign.SpaceBetween)
        if(this.toggleCard && this.CardContent) {
          this.CardContent()
        }
      }
      .backgroundColor($r("app.color.white"))
      .borderRadius(10)
      .padding({
        left: 18,
        right: 18,
        bottom:18
      })

    }
    .padding(10)

  }
}
export { HmToggleCard }



// @Component
// struct HmToggleCard {
//   title:string="基本信息"
//   @State
//   toggleCard:boolean=true //是否展开
//
//   //尾随闭包
//   @BuilderParam
//   CardContent:()=>void
//
//   build() {
//     Column(){
//       Row(){
//         Text(this.title)
//           .fontSize(16)
//           .fontColor($r('app.color.text_primary'))
//           .fontWeight(500)
//         Image(this.toggleCard?$r("app.media.ic_btn_cut"):$r("app.media.ic_btn_add"))
//           .width(24)
//           .aspectRatio(1)//宽高比1
//           .onClick(()=>{
//             this.toggleCard=!this.toggleCard
//           })
//       }
//       .width("100%")
//       .height(50)
//       .justifyContent(FlexAlign.SpaceBetween) //两端对齐
//       if (this.toggleCard && this.CardContent){
//         this.CardContent()
//       }
//     }
//     .padding(20)
//   }
// }
// export {HmToggleCard}