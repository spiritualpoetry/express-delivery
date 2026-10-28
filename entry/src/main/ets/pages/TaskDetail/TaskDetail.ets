import { HmLoading, CommonRouterParams, HmNavBar, HmToggleCard, HmUpload, ImageList, UploadFile, } from '@hm/basic';
import { promptAction, PromptAction, router } from '@kit.ArkUI';
import { TaskDetailInfo, TaskDetailInfoModel } from '../../models/task_detail';
import { getTaskDetail as GTD, pick_Up, deliver } from "../../api";
import HmSkeleton from '@hm/basic/src/main/ets/components/HmSkeleton';
import { PickUpParamsModel, TaskTypeEnum, DeliverParamsTypeModel, ExceptionList } from '../../models';
import common from '@ohos.app.ability.common';
import call from '@ohos.telephony.call'
import { MessageEvents, worker } from '@kit.ArkTS';
import { fileIo } from '@kit.CoreFileKit';

interface CompressResult {
  files: ImageList[]
  error?: string
}


@Entry
@Component
struct TaskDetail {
  @State submitting: boolean = false
  loading: CustomDialogController = new CustomDialogController({
    builder: HmLoading({ title: "数据处理中..." }),
    customStyle: true
  })
  //详情数据
  @State
  taskDetailData: TaskDetailInfoModel = new TaskDetailInfoModel({} as TaskDetailInfo)
  scroller: Scroller = new Scroller()

  @Builder
  getBaseContentItem(item: BaseBuilderClass) {
    Row() {
      Text(item.title).fontSize(14).fontColor($r('app.color.text_secondary'))
        .lineHeight(20)
      Row() {
        Text(item.value).fontSize(14).fontColor($r('app.color.text_secondary'))
        if (item.icon) {
          Image(item.icon).width(24).height(24)
            .onClick(() => {
              item.iconClick && item.iconClick()
            })
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

      //只有在途中才会显示开始导航按钮
      if (this.taskDetailData.status === TaskTypeEnum.Line) {
        Column() {
          Image($r("app.media.ic_navigation")).width(22).height(22)
          Text("开始导航").fontSize(14).margin({ top: 10, bottom: 10 })
        }
        .onClick(() => {
          //开启导航
          this.beginNav()
        })
        .justifyContent(FlexAlign.SpaceBetween)
        .margin({
          top: 20
        })
      }

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
      icon: $r('app.media.ic_phone'),
      iconClick: () => {
        this.callHandover()
      }
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
        Text(this.taskDetailData.startProvince)
          .fontSize(16)
          .fontColor($r('app.color.text_primary'))
          .lineHeight(22)
          .fontWeight(600)
        Text(this.taskDetailData.startCity).fontSize(14).lineHeight(22)
      }.width(50)

      Image($r("app.media.ic_right_arrow")).width(36).height(16)
      Column() {
        Text(this.taskDetailData.endProvince)
          .fontSize(16)
          .fontColor($r('app.color.text_primary'))
          .lineHeight(22)
          .fontWeight(600)
        Text(this.taskDetailData.endCity).fontSize(14).lineHeight(22)
      }.width(50)
    }.justifyContent(FlexAlign.SpaceBetween).alignItems(VerticalAlign.Center).width('100%').padding({
      left: 60,
      right: 60
    })
  }

  //提货信息
  @Builder
  getPickUpContent() {
    //link修饰符只能修饰一层数据
    HmUpload({
      title: "请拍照上传回单凭证",
      imgList: this.taskDetailData.cargoPickUpPictureList || [],
      onListChange: (list: ImageList[]) => {
        this.taskDetailData.cargoPickUpPictureList = list
      },
      canUpload: !this.submitting && this.taskDetailData.status === TaskTypeEnum.Waiting
    })
    HmUpload({
      title: "请拍照上传回单照片",
      imgList: this.taskDetailData.cargoPictureList || [],
      onListChange: (list: ImageList[]) => {
        this.taskDetailData.cargoPictureList = list
      },
      canUpload: !this.submitting && this.taskDetailData.status === TaskTypeEnum.Waiting
    })
  }

  //交货信息
  @Builder
  getDeliverContent() {
    //link修饰符只能修饰一层数据
    HmUpload({
      title: "请拍照上传交货回单凭证",
      imgList: this.taskDetailData.certificatePictureList || [],
      onListChange: (list: ImageList[]) => {
        this.taskDetailData.certificatePictureList = list
      },
      canUpload: !this.submitting && this.taskDetailData.status === TaskTypeEnum.Line
    })
    HmUpload({
      title: "请拍照上传交货回单照片",
      imgList: this.taskDetailData.deliverPictureList || [],
      onListChange: (list: ImageList[]) => {
        this.taskDetailData.deliverPictureList = list
      },
      canUpload: !this.submitting && this.taskDetailData.status === TaskTypeEnum.Line
    })
  }

  // 获取异常信息
  @Builder
  getExceptionContent() {
    ForEach(this.taskDetailData.exceptionList, (item: ExceptionList) => {
      Row() {
        Column() {
          Row() {
            Text("上报时间").fontSize(14).fontColor($r('app.color.text_primary'))
            Text(item.exceptionTime).margin({ left: 20 }).fontColor($r('app.color.text_secondary'))
          }.height(50).alignItems(VerticalAlign.Center).width('100%')

          Row() {
            Text("异常类型").fontSize(14).fontColor($r('app.color.text_primary'))
            Text(item.exceptionType).margin({ left: 20 }).fontColor($r('app.color.text_secondary'))
          }.height(50).alignItems(VerticalAlign.Center).width('100%')

          Row() {
            Text("处理结果").fontSize(14).fontColor($r('app.color.text_primary'))
            Text(item.handleResult || '暂无处理结果').margin({ left: 20 }).fontColor($r('app.color.text_secondary'))
          }.height(50).alignItems(VerticalAlign.Center).width('100%')
        }

        // 跳转到详情
        Image($r("app.media.ic_btn_more")).width(24).height(24)
      }
      .width('100%')
      .padding({ left: 15, right: 15 })
      .alignItems(VerticalAlign.Center)
      .justifyContent(FlexAlign.SpaceBetween)
      .onClick(() => {
        router.pushUrl({
          url: "pages/ExceptionReport/ExceptionDetail",
          params: {
            formData: item
          }
        })
      })
    })
  }

  aboutToAppear(): void {
    const params = router.getParams() as CommonRouterParams
    if (params && params.id) {
      this.getTaskDetail(params.id)
    }
  }

  onPageShow(): void {
    const params = router.getParams() as CommonRouterParams
    if (params && params.addExcept) {
      //如果params.addExcept里有返回结果说明有重新上传的异常内容，此时需要更新页面异常信息，其他信息不更新
      this.updateException()
    }
  }

  async openCarRecord() {
    if (!this.taskDetailData.id) {
      promptAction.showToast({ message: '任务详情尚未加载，请稍后重试' })
      return
    }
    try {
      await router.pushUrl({
        url: 'pages/CarRecord/CarRecord',
        params: { id: this.taskDetailData.id }
      })
    } catch (error) {
      promptAction.showToast({ message: '无法打开回车登记页面，请稍后重试' })
    }
  }

  async callHandover() {
    const phone = (this.taskDetailData.startHandoverPhone || '').trim()
    if (!phone) {
      promptAction.showToast({ message: '暂无对接人电话' })
      return
    }
    try {
      await call.makeCall(phone)
    } catch (error) {
      promptAction.showToast({ message: '无法打开拨号，请稍后重试' })
    }
  }

  //去导航的方法  拉起第三方应用传参数
  async beginNav() {
    const address = (this.taskDetailData.endAddress || '').trim()
    if (!address) {
      promptAction.showToast({ message: '暂无目的地地址' })
      return
    }
    try {
      const context = getContext() as common.UIAbilityContext
      await context.startAbility({
        action: 'ohos.want.action.viewData', //拉起浏览器应用
        entities: ['entity.system.browsable'],
        uri: 'https://gaode.com/search?query=' + encodeURIComponent(address)
      })
    } catch (error) {
      promptAction.showToast({ message: '无法打开导航，请稍后重试' })
    }
  }

  async updateException() {
    if (!this.taskDetailData.id) { return }
    try {
      //只更新异常信息，保留用户已经选择的提货和交付图片。
      this.taskDetailData.exceptionList = (await GTD(this.taskDetailData.id)).exceptionList || []
    } catch (error) {
      // 请求层提示失败，保留已有异常信息。
    }
  }

  async getTaskDetail(id: string) {
    try {
      this.taskDetailData = await GTD(id)
    } catch (error) {
      // 请求层提示失败，保留当前页面数据。
    }
  }

  // 压缩失败、上传失败和超时均交由提交流程处理。
  async compressAndUpload(files: ImageList[]): Promise<ImageList[]> {
    const compressor = new worker.ThreadWorker('entry/ets/workers/UploadWorker.ets')
    let compressed: ImageList[] = []
    let timeoutId: number = -1
    try {
      compressed = await new Promise<ImageList[]>((resolve, reject) => {
        timeoutId = setTimeout(() => reject(new Error('Image compression timed out')), 60000)
        compressor.onmessage = (event: MessageEvents) => {
          const result = event.data as CompressResult
          if (result.error) {
            reject(new Error(result.error))
          } else {
            resolve(result.files)
          }
        }
        compressor.onerror = () => reject(new Error('Image compression failed'))
        compressor.onmessageerror = () => reject(new Error('Invalid worker message'))
        compressor.postMessage({ files: [...files], filePath: getContext(this).cacheDir })
      })
      clearTimeout(timeoutId)
      const localFiles = compressed.filter((file: ImageList) => !file.url.startsWith('http://') && !file.url.startsWith('https://'))
      const uploaded = localFiles.length > 0 ? await UploadFile(localFiles) : []
      let uploadIndex = 0
      return compressed.map((file: ImageList) => {
        if (file.url.startsWith('http://') || file.url.startsWith('https://')) { return file }
        return uploaded[uploadIndex++]
      })
    } finally {
      if (timeoutId !== -1) { clearTimeout(timeoutId) }
      try { compressor.terminate() } catch (_) {}
      for (const file of compressed) {
        if (file.url.startsWith(getContext(this).cacheDir + '/')) {
          try { fileIo.unlinkSync(file.url) } catch (_) {}
        }
      }
    }
  }

  async btnPickUp() {
    if (!this.getPickUpState() || this.taskDetailData.status !== TaskTypeEnum.Waiting) { return }
    this.submitting = true
    try {
      this.loading.open()
      const cargoPickUpPictureList = await this.compressAndUpload(this.taskDetailData.cargoPickUpPictureList)
      const cargoPictureList = await this.compressAndUpload(this.taskDetailData.cargoPictureList)
      await pick_Up(new PickUpParamsModel({ id: this.taskDetailData.id, cargoPickUpPictureList, cargoPictureList }))
      this.taskDetailData.status = TaskTypeEnum.Line
      this.taskDetailData.cargoPickUpPictureList = cargoPickUpPictureList
      this.taskDetailData.cargoPictureList = cargoPictureList
      await this.getTaskDetail(this.taskDetailData.id)
      this.scroller.scrollEdge(Edge.Top)
      promptAction.showToast({ message: '提货成功' })
    } catch (_) {
      promptAction.showToast({ message: '提货失败，请重试' })
    } finally {
      this.submitting = false
      this.loading.close()
    }
  }

  async btnDeliver() {
    if (!this.getDeliverState() || this.taskDetailData.status !== TaskTypeEnum.Line) { return }
    this.submitting = true
    try {
      this.loading.open()
      const certificatePictureList = await this.compressAndUpload(this.taskDetailData.certificatePictureList)
      const deliverPictureList = await this.compressAndUpload(this.taskDetailData.deliverPictureList)
      await deliver(new DeliverParamsTypeModel({ id: this.taskDetailData.id, certificatePictureList, deliverPictureList }))
      this.taskDetailData.status = TaskTypeEnum.Delivered
      this.taskDetailData.certificatePictureList = certificatePictureList
      this.taskDetailData.deliverPictureList = deliverPictureList
      await this.getTaskDetail(this.taskDetailData.id)
      this.scroller.scrollEdge(Edge.Top)
      promptAction.showToast({ message: '交货成功' })
    } catch (_) {
      promptAction.showToast({ message: '交货失败，请重试' })
    } finally {
      this.submitting = false
      this.loading.close()
    }
  }

  @Builder
  getBottomBtn() {
    //已完成不显示任何按钮
    Row() {
      if (this.taskDetailData.status === TaskTypeEnum.Waiting) {
        Button("延迟收货", { type: ButtonType.Capsule })
          .backgroundColor($r('app.color.btn_gray'))
          .fontColor($r('app.color.text_primary'))
          .fontSize(16)
          .height(50)
          .width(125)
          .onClick(() => {
            router.pushUrl({
              url: "pages/Delay/Delay",
              params: {
                id: this.taskDetailData.id,
                oldTime: this.taskDetailData.planDepartureTime//计划时间
              }
            })
          })
        Button("提货", { type: ButtonType.Capsule })
          .enabled(this.getPickUpState())
          .backgroundColor(this.getPickUpState() ? $r('app.color.primary') : $r('app.color.primary_disabled'))
          .fontColor($r('app.color.white'))
          .height(50)
          .flexGrow(1)
          .margin({ left: 13 })
          .onClick(() => {
            this.btnPickUp()
          })
      } else if (this.taskDetailData.status === TaskTypeEnum.Line) {
        Button("上报异常", { type: ButtonType.Capsule })
          .onClick(() => {
            router.pushUrl({
              url: "pages/ExceptionReport/ExceptionReport",
              params: {
                id: this.taskDetailData.transportTaskId
              }
            })
          })
          .backgroundColor($r('app.color.btn_gray'))
          .fontColor($r('app.color.text_primary'))
          .fontSize(16)
          .height(50)
          .width(125)
        Button("交货", { type: ButtonType.Capsule })
          .onClick(() => {
            this.btnDeliver()
          })
          .backgroundColor(this.getDeliverState() ? $r('app.color.primary') : $r('app.color.primary_disabled'))
          .fontColor($r('app.color.white'))
          .height(50)
          .enabled(this.getDeliverState())
          .flexGrow(1)
          .margin({ left: 13 })
      } else if (this.taskDetailData.status === TaskTypeEnum.Delivered) {
        Row() {
          // 已交付显示回车登记
          Button("回车登记", { type: ButtonType.Capsule })
            .backgroundColor($r('app.color.primary'))
            .fontColor($r('app.color.white'))
            .height(50)
            .width('80%')
            .onClick(() => {
              this.openCarRecord()
            })
        }.width('100%').justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
    .padding({ left: 15, right: 15 })
    .height(70)
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(VerticalAlign.Center)
    .backgroundColor($r('app.color.white'))
  }

  //控制提货按钮的可用性
  getPickUpState() {
    if (this.submitting || !this.taskDetailData.id) {
      return false
    }
    //凭证和货品有图片  可用
    if (this.taskDetailData.cargoPickUpPictureList?.length
      && this.taskDetailData.cargoPickUpPictureList?.every(item => !!item.url)
      && this.taskDetailData.cargoPictureList?.length
      && this.taskDetailData.cargoPictureList?.every(item => !!item.url)) {
      return true
    }
    return false
  }

  //控制交货按钮的可用性
  getDeliverState() {
    if (this.submitting || !this.taskDetailData.id) {
      return false
    }
    //凭证和货品有图片  可用
    if (this.taskDetailData.deliverPictureList?.length
      && this.taskDetailData.deliverPictureList?.every(item => !!item.url)
      && this.taskDetailData.certificatePictureList?.length
      && this.taskDetailData.certificatePictureList?.every(item => !!item.url)) {
      return true
    }
    return false
  }

  build() {
    Column() {
      if (this.taskDetailData.id) {
        //说明数据加载出来了
        HmNavBar({ title: '任务详情' })
        Scroll(this.scroller) {
          Column() {
            HmToggleCard({ title: '基本信息' }) {
              this.getBaseContent()
            }

            HmToggleCard({ title: "车辆运输信息" }) {
              this.getDriverContent()
            }

            HmToggleCard({ title: "运输路线" }) {
              this.getTransLineContent()
            }

            //当有异常信息时，显示异常信息
            if (this.taskDetailData.exceptionList?.length > 0) {
              HmToggleCard({ title: "异常上报" }) {
                this.getExceptionContent()
              }
            }
            if (this.taskDetailData.status === TaskTypeEnum.Waiting
              || this.taskDetailData.status === TaskTypeEnum.Delivered
              || this.taskDetailData.status === TaskTypeEnum.Finish) {
              HmToggleCard({ title: "提货信息" }) {
                //放置上传组件 基础组件
                this.getPickUpContent()
              }
            }
            if (this.taskDetailData.status === TaskTypeEnum.Line
              || this.taskDetailData.status === TaskTypeEnum.Delivered
              || this.taskDetailData.status === TaskTypeEnum.Finish) {
              HmToggleCard({ title: "交货信息" }) {
                //放置上传组件 基础组件
                this.getDeliverContent()
              }
            }
          }
        }
        .padding({
          bottom: 50
        })
        .layoutWeight(1)

        if (this.taskDetailData.status!==TaskTypeEnum.Finish) {
          this.getBottomBtn()
        }
      } else {
        //显示骨架屏
        HmSkeleton({ count: 4, showAvatar: true })
      }
    }
    .backgroundColor("#F4F4F4")
    .height('100%')
    .width('100%')
  }
}

@Extend(Text)
function baseTextOneStyle() {
  .fontSize(12)
  .fontColor($r('app.color.white'))
  .backgroundColor($r('app.color.text_primary'))
  .width(22)
  .height(22)
  .borderRadius(11)
  .textAlign(TextAlign.Center)
}

@Extend(Text)
function baseTextTwoStyle() {
  .margin({ left: 11.5 }).fontColor($r('app.color.text_secondary')).fontSize(14).lineHeight(20)
}

class BaseBuilderClass {
  title: string = ""
  value: string = ""
  icon?: ResourceStr = ""
  iconClick?: () => void
}
