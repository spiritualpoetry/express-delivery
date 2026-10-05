import picker from "@ohos.file.picker"
import { ImageList } from "../models"
import { HmPreview } from "./HmPreview"
import { fileIo } from "@kit.CoreFileKit"
import { util } from "@kit.ArkTS"
import request from "@ohos.request"
import { uploadImage } from "../api/upload"

//上传的组件，并不完成上传的业务 选择图片 用来交互
@Component
@Preview
struct HmUpload {
  //是否可操控可上传删除
  @Prop
  canUpload:boolean=true

  title:string="请拍照上传回单凭证"//标题
  maxNumber:number=6//最大选择数量
  @Prop
  imgList:ImageList[]=[]

  index:number=-1
  private selecting: boolean = false
  //当列表发生变化通知父组件
  onListChange:(list:ImageList[])=>void=()=>{}

  preview:CustomDialogController=new CustomDialogController({
    builder:HmPreview({
      urls:this.imgList.map(Item=>Item.url),
      selectIndex:this.index
    }),
    customStyle:true,
  })
  async selectImg(){
    const remaining = this.maxNumber - this.imgList.length
    if (this.selecting || !this.canUpload || remaining <= 0) { return }
    this.selecting = true
    try {
    const photo=new picker.PhotoViewPicker()
    const result = await photo.select({
      MIMEType:picker.PhotoViewMIMETypes.IMAGE_TYPE,
      maxSelectNumber:remaining
    })
    if (this.canUpload && result.photoUris.length) {
      //追加操作
      this.imgList=this.imgList.concat(result.photoUris.map(url=>({
        url
      } as ImageList)))
      this.onListChange(this.imgList)//传出imgList通过onListChange给父组件
    }
    } catch (error) {
      AlertDialog.show({ message: '选择图片失败，请重试' })
    } finally {
      this.selecting = false
    }
  }

  build() {
    Column(){
      Text(this.title)
        .fontSize(14)
        .fontColor($r("app.color.text_primary"))
        .margin({
          top:16,
          bottom:16
        })
      Grid(){
        ForEach(this.imgList,(item:ImageList,index:number)=>{
          GridItem(){
            Stack({alignContent:Alignment.TopEnd}){
              Image(item.url)
                .onClick(()=>{
                  this.index=index
                  this.preview.open()

                })
                .width(100)
                .height(100)
                .borderRadius(4)
              if (this.canUpload) {
                Image($r("app.media.ic_btn_delete"))
                  .width(30)
                  .height(30)
                  .onClick(()=>{
                    this.imgList.splice(index,1)//删除一个
                    this.onListChange(this.imgList)//通知父组件
                  })
              }
            }
          }
        })
        //显示上传按钮，在没达到最大上传图片数量时可以显示按钮
        if (this.imgList.length < this.maxNumber && this.canUpload) {
          GridItem() {
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
        }
      }
      .rowsGap(10)
      .columnsGap(10)
      .height(Math.ceil(this.maxNumber/3)*110)
      .columnsTemplate("1fr 1fr 1fr")

    }
    .alignItems(HorizontalAlign.Start)
    .width("100%")
  }
}

//上传方法
  const  UploadFile= async (list:ImageList[])=>{
  //因为上传文件  只能从沙箱文件中拷贝，所以我们需要把传过来的所有图片拷贝到沙箱
  let saveDir=getContext().cacheDir//存储的目录
  const fileParams:request.File[]=[]//要提交的参数
  const tempPaths: string[] = []
  try {
  list.forEach(item=>{
    const  file = fileIo.openSync( item.url ,fileIo.OpenMode.READ_ONLY )//读取相册的文件
    //将文件拷贝到沙箱目录
    //相册的地址
    const uniqueName = util.generateRandomUUID()+".jpg"
    const tempPath = saveDir+"/"+uniqueName
    tempPaths.push(tempPath)
    try {
      fileIo.copyFileSync(file.fd,tempPath) //将相册文件拷贝到沙箱
    } finally {
      fileIo.closeSync(file.fd)
    }
    //需要生成参数
    fileParams.push({
      filename:uniqueName,//文件名称
      name:'file',//接口的参数名称
      type:'jpg',//文件的后缀
      uri:`internal://cache/${uniqueName}`//
    })
  })

    //将参数上传
    const result =  await uploadImage(getContext(),fileParams) // 调用上传接口
    return result //将上传结果返回上一层
    //第二种写法
    //return await uploadImage(getContext(),fileParams)
  } finally {
    tempPaths.forEach((path: string) => {
      try { fileIo.unlinkSync(path) } catch (error) {
        // 不让临时文件清理错误覆盖原始上传结果。
      }
    })
  }
}

export {UploadFile}
export {HmUpload}
