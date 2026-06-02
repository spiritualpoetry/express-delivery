@Component
struct HmCard {
  @BuilderParam
  HmCardFn:()=>void
  build() {
    Column(){
      Column(){
        if (this.HmCardFn){
          this.HmCardFn()
        }
      }
      .width('100%')
      .borderRadius(15)
      .backgroundColor($r('app.color.white'))
      .padding({
        left:15,
        right:15
      })
    }
    .padding(15)
    .width('100%')
  }
}
export {HmCard}