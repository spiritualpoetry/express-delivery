import { HmLoading, CommonRouterParams, HmNavBar, HmToggleCard ,HmUpload, ImageList, UploadFile} from '@hm/basic';
import { promptAction, PromptAction, router } from '@kit.ArkUI';
import { TaskDetailInfo, TaskDetailInfoModel } from '../../models/task_detail';
import {getTaskDetail as GTD , pick_Up,deliver} from "../../api";
import HmSkeleton from '@hm/basic/src/main/ets/components/HmSkeleton';
import { PickUpParamsModel, TaskTypeEnum ,DeliverParamsTypeModel} from '../../models';


@Entry
@Component
struct TaskDetail {
  loading:CustomDialogController = new CustomDialogController({
    builder:HmLoading({title:"数据处理中..."}),
    customStyle:true
  })

  scroller:Scroller=new Scroller()

  @Builder
  getBaseContentItem(item: BaseBuilderClass) {
    Row() {
      Text(item.title).fontSize(14).fontColor($r('app.color.text_secondary'))
        .lineHeight(20)
      Row() {
        Text(item.value).fontSize(14).fontColor($r('app.color.text_secondary'))
        if (item.icon) {
          Image(item.icon).width(24).height(24)
        }
      }
    }.justifyContent(FlexAlign.SpaceBetween).width('100%').margin({
      top: 14
    })
  }
  // 获取基础信息

  @Builder
  getBaseContent() {
    Row() {
      Column() {
        Row() {
          Text("起").baseTextOneStyle()
          Text(this.taskDetailData.startAddress).baseTextTwoStyle()
        }.margin({ top: 21 })
        Row() {
          Text("止").baseTextOneStyle().backgroundColor($r('app.color.primary'))
          Text(this.taskDetailData.endAddress).baseTextTwoStyle()
        }.margin({ top: 14.5 })
      }.alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({
        right: 20
      })

      Column() {
        Image($r("app.media.ic_navigation")).width(22).height(22)
        Text("开始导航").fontSize(14).margin({ top: 10, bottom: 10 })
      }.justifyContent(FlexAlign.SpaceBetween)
      .margin({
        top: 20
      })

    }.justifyContent(FlexAlign.SpaceBetween).alignItems(VerticalAlign.Center).width('100%')

    Divider().vertical(false).height(2).color($r('app.color.background_divider')).margin({ left: 8, right: 8, top: 21 })
    this.getBaseContentItem({
      title: '任务编号',
      value: this.taskDetailData.transportTaskId
    })
    this.getBaseContentItem({
      title: '联系人',
      value: this.taskDetailData.startHandoverName
    })
    this.getBaseContentItem({
      title: '联系电话',
      value: this.taskDetailData.startHandoverPhone,
      icon: $r('app.media.ic_phone')
    })
    this.getBaseContentItem({
      title: '提货时间',
      value: this.taskDetailData.planDepartureTime
    })
    this.getBaseContentItem({
      title: '预计送达时间',
      value: this.taskDetailData.planArrivalTime
    })

  }

  // 司机信息
  @Builder
  getDriverContent() {
    Row() {
      Text(`车牌号`).fontSize(14).fontColor($r('app.color.text_secondary'))
        .lineHeight(20)
      Text(this.taskDetailData.licensePlate).fontSize(14).fontColor($r('app.color.text_secondary'))
    }.justifyContent(FlexAlign.SpaceBetween).width('100%').margin({
      top: 14
    })

    Row() {
      Text(`司机姓名`).fontSize(14).fontColor($r('app.color.text_secondary'))
        .lineHeight(20)
      Text(this.taskDetailData.driverName).fontSize(14).fontColor($r('app.color.text_secondary'))
    }.justifyContent(FlexAlign.SpaceBetween).width('100%').margin({
      top: 14
    })
  }
  // 运输路线
  @Builder
  getTransLineContent() {
    Row() {
      Column() {
        Text(this.taskDetailData.startProvince).fontSize(16).fontColor($r('app.color.text_primary')).lineHeight(22).fontWeight(600)
        Text(this.taskDetailData.startCity).fontSize(14).lineHeight(22)
      }.width(50)

      Image($r("app.media.ic_right_arrow")).width(36).height(16)
      Column() {
        Text(this.taskDetailData.endProvince).fontSize(16).fontColor($r('app.color.text_primary')).lineHeight(22).fontWeight(600)
        Text(this.taskDetailData.endCity).fontSize(14).lineHeight(22)
      }.width(50)
    }.justifyContent(FlexAlign.SpaceBetween).alignItems(VerticalAlign.Center).width('100%').padding({
      left: 60,
      right: 60
    })
  }
  //提货信息
  @Builder
  getPickUpContent(){
    //link修饰符只能修饰一层数据
    HmUpload({title:"请拍照上传回单凭证",
      imgList:this.taskDetailData.cargoPickUpPictureList || [],
      onListChange:(list:ImageList[])=>{
        this.taskDetailData.cargoPickUpPictureList=list
      },
      canUpload:this.taskDetailData.status===TaskTypeEnum.Waiting
    })
    HmUpload({title:"请拍照上传回单照片",
      imgList:this.taskDetailData.cargoPictureList || [],
      onListChange:(list:ImageList[])=>{
        this.taskDetailData.cargoPictureList=list
      },
      canUpload:this.taskDetailData.status===TaskTypeEnum.Waiting
    })
  }
  //交货信息
  @Builder
  getDeliverContent(){
    //link修饰符只能修饰一层数据
    HmUpload({title:"请拍照上传交货回单凭证",
      imgList:this.taskDetailData.certificatePictureList || [],
      onListChange:(list:ImageList[])=>{
        this.taskDetailData.certificatePictureList=list
      },
      canUpload:this.taskDetailData.status===TaskTypeEnum.Line
    })
    HmUpload({title:"请拍照上传交货回单照片",
      imgList:this.taskDetailData.deliverPictureList || [],
      onListChange:(list:ImageList[])=>{
        this.taskDetailData.deliverPictureList=list
      },
      canUpload:this.taskDetailData.status===TaskTypeEnum.Line
    })
  }

  @State
  taskDetailData:TaskDetailInfoModel=new TaskDetailInfoModel({}as TaskDetailInfo)

  aboutToAppear(): void {
    const params =router.getParams() as CommonRouterParams
    if (params && params.id) {
      this.getTaskDetail(params.id)
    }
  }

  async getTaskDetail(id:string){
    this.taskDetailData=await GTD(id)
  }
  //封装一个去提货的方法
  async btnPickUp(){
    this.loading.open()
    const  cargoPickUpPictureList=  await UploadFile(this.taskDetailData.cargoPickUpPictureList)//传入提货凭证
    const cargoPictureList= await  UploadFile(this.taskDetailData.cargoPictureList)//
    //提货操作
    await pick_Up(
      new PickUpParamsModel({
        id:this.taskDetailData.id,
        cargoPickUpPictureList,
        cargoPictureList
      }))
    //重新获取数据

    this.getTaskDetail(this.taskDetailData.id)//重新拉取数据
    //滚动到顶部
    this.scroller.scrollEdge(Edge.Top)
    this.loading.close()
    promptAction.showToast({message:'提货成功'})
  }

  //封装一个去交货的方法
  async btnDeliver(){
    this.loading.open()
    const  certificatePictureList=  await UploadFile(this.taskDetailData.certificatePictureList)
    const deliverPictureList= await  UploadFile(this.taskDetailData.deliverPictureList)
    //交货操作
    await deliver(
      new DeliverParamsTypeModel({
        id:this.taskDetailData.id,
        certificatePictureList,
        deliverPictureList
      }))
    //重新获取数据

    this.getTaskDetail(this.taskDetailData.id)//重新拉取数据
    //滚动到顶部
    this.scroller.scrollEdge(Edge.Top)
    this.loading.close()
    promptAction.showToast({message:'交货成功'})
  }

  // 底部按钮结构
  @Builder
  getBottomBtn() {
    //已完成不显示任何按钮
    Row() {
      if (this.taskDetailData.status===TaskTypeEnum.Waiting) {
        Button("延迟收货", { type: ButtonType.Capsule })
          .backgroundColor($r('app.color.btn_gray'))
          .fontColor($r('app.color.text_primary'))
          .fontSize(16)
          .height(50)
          .width(125)
        Button("提货", { type: ButtonType.Capsule })
          .enabled(this.getPickUpState())
          .backgroundColor($r('app.color.primary_disabled'))
          .fontColor($r('app.color.white'))
          .height(50)
          .flexGrow(1)
          .margin({ left: 13 })
          .onClick(()=>{
            this.btnPickUp()
          })
      }else if (this.taskDetailData.status===TaskTypeEnum.Line) {
        Button("上报异常", { type: ButtonType.Capsule })
          .backgroundColor($r('app.color.btn_gray'))
          .fontColor($r('app.color.text_primary'))
          .fontSize(16)
          .height(50)
          .width(125)
        Button("交货", { type: ButtonType.Capsule })
          .onClick(()=>{
            this.btnDeliver()
          })
          .backgroundColor($r('app.color.primary_disabled'))
          .fontColor($r('app.color.white'))
          .height(50)
          .enabled(this.getDeliverState())
          .flexGrow(1)
          .margin({ left: 13 })
      }else if(this.taskDetailData.status===TaskTypeEnum.Delivered){
        Row() {
          // 已交付显示回车登记
          Button("回车登记", { type: ButtonType.Capsule })
            .backgroundColor($r('app.color.primary'))
            .fontColor($r('app.color.white'))
            .height(50)
            .width('80%')
        }.width('100%').justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
    .padding({ left: 15, right: 15 })
    .height(70).
    justifyContent(FlexAlign.SpaceBetween).
    alignItems(VerticalAlign.Center)
    .backgroundColor($r('app.color.white'))
  }

  //控制提货按钮的可用性
  getPickUpState(){
   //凭证和货品有图片  可用
    if (this.taskDetailData.cargoPickUpPictureList?.length
      && this.taskDetailData.cargoPickUpPictureList?.every(item=>!!item.url)
      && this.taskDetailData.cargoPictureList?.length
      && this.taskDetailData.cargoPictureList?.every(item=>!!item.url)) {
      return true
    }
    return false
  }

  //控制交货按钮的可用性
  getDeliverState(){
    //凭证和货品有图片  可用
    if (this.taskDetailData.deliverPictureList?.length
      && this.taskDetailData.deliverPictureList?.every(item=>!!item.url)
      && this.taskDetailData.certificatePictureList?.length
      && this.taskDetailData.certificatePictureList?.every(item=>!!item.url)) {
      return true
    }
    return false
  }

  build() {
    Column(){
      if (this.taskDetailData.id){
        //说明数据加载出来了
        HmNavBar({title:'任务详情'})
        Scroll(this.scroller){
          Column(){
            HmToggleCard({title:'基本信息'}){
              this.getBaseContent()
            }
            HmToggleCard({title:"车辆运输信息"}){
              this.getDriverContent()
            }
            HmToggleCard({title:"运输路线"}){
              this.getTransLineContent()
            }

            if (this.taskDetailData.status===TaskTypeEnum.Waiting
              || this.taskDetailData.status===TaskTypeEnum.Delivered) {
              HmToggleCard({title:"提货信息"}){
                //放置上传组件 基础组件
                this.getPickUpContent()
              }
            }
            if (this.taskDetailData.status===TaskTypeEnum.Line
              || this.taskDetailData.status===TaskTypeEnum.Delivered) {
              HmToggleCard({title:"交货信息"}){
                //放置上传组件 基础组件
                this.getDeliverContent()
              }
            }
          }
        }
        .padding({
          bottom:50
        })
        .layoutWeight(1)
        this.getBottomBtn()
      }else {
        //显示骨架屏
        HmSkeleton({count:4,showAvatar:true})
      }
    }
    .backgroundColor("#F4F4F4")
    .height('100%')
    .width('100%')
  }
}

@Extend(Text) function baseTextOneStyle() {
  .fontSize(12)
  .fontColor($r('app.color.white'))
  .backgroundColor($r('app.color.text_primary'))
  .width(22)
  .height(22)
  .borderRadius(11)
  .textAlign(TextAlign.Center)
}

@Extend(Text) function baseTextTwoStyle() {
  .margin({ left: 11.5 }).fontColor($r('app.color.text_secondary')).fontSize(14).lineHeight(20)
}

class BaseBuilderClass {
  title: string = ""
  value: string = ""
  icon?: ResourceStr = ""
}