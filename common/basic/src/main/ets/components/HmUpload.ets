import picker from "@ohos.file.picker"

@Component
@Entry
struct HmUpload {
  title:string="请拍照上传回单凭证"//标题
  maxNumber:number=3//最大选择数量
  @State
  imgList:string[]=[]
  async selectImg(){
    const photo=new picker.PhotoViewPicker()
    const result = await photo.select({
      MIMEType:picker.PhotoViewMIMETypes.IMAGE_TYPE,
      maxSelectNumber:this.maxNumber
    })
  }
  build() {
    Column(){
      Text(this.title).
        fontSize(14)
        .fontColor($r("app.color.text_primary"))
        .margin({
          top:16,
          bottom:16
        })
      Row(){
        Image($r("app.media.ic_add_img"))
          .width(30)
          .height(30)
      }
      .onClick(()=>{
        this.selectImg()
      })
      .justifyContent(FlexAlign.Center)
      .borderRadius(4)
      .width(100)
      .height(100)
      .backgroundColor($r("app.color.background_page"))
    }
    .alignItems(HorizontalAlign.Start)
    .width("100%")

  }
}
export {HmUpload}