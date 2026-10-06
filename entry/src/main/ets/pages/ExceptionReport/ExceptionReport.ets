import {
  CommonRouterParams,
  DateFormat,
  HmCard,
  HmCardItem,
  HmNavBar,
  HmSelectCard,
  HmUpload,
  ImageList,
  UploadFile
} from '@hm/basic'
import { ExceptionParamsTypeModel, ExceptionParamsType } from '../../models'
import { promptAction, router } from '@kit.ArkUI'
import { reportException } from '../../api'

@Entry
@Component
struct ExceptionReport {
  @State
  selectIndex: number = -1
  @State
  exceptionForm: ExceptionParamsTypeModel = new ExceptionParamsTypeModel({
    exceptionDescribe: '',
    exceptionImagesList: [],
    exceptionPlace: '',
    exceptionTime: '',
    exceptionType: '',
    transportTaskId: ''
  })
  @State submitting: boolean = false
  private active: boolean = false

  getBtnEnable(): boolean {
    return !this.submitting && !!this.exceptionForm.transportTaskId &&
      !!this.exceptionForm.exceptionTime && !!this.exceptionForm.exceptionPlace.trim() &&
      !!this.exceptionForm.exceptionType
  }

  async submitReport(): Promise<void> {
    if (!this.getBtnEnable()) {
      return
    }
    this.submitting = true
    try {
      const images = this.exceptionForm.exceptionImagesList || []
      const uploaded = images.length ? await UploadFile(images) : []
      if (!this.active) {
        return
      }
      if (uploaded.length !== images.length) {
        promptAction.showToast({ message: '图片上传不完整，请重试' })
        return
      }
      const payload: ExceptionParamsType = {
        transportTaskId: this.exceptionForm.transportTaskId,
        exceptionTime: this.exceptionForm.exceptionTime,
        exceptionPlace: this.exceptionForm.exceptionPlace.trim(),
        exceptionType: this.exceptionForm.exceptionType,
        exceptionDescribe: this.exceptionForm.exceptionDescribe || '',
        exceptionImagesList: uploaded
      }
      await reportException(payload)
      if (!this.active) {
        return
      }
      promptAction.showToast({ message: '异常上报成功' })
      router.back({
        url:"pages/TaskDetail/TaskDetail",
        params:{
          addExcept:true//表示上传成功
        }
      })
    } catch (error) {
      if (this.active) {
        promptAction.showToast({ message: '上报失败，填写内容已保留，请重试' })
      }
    } finally {
      this.submitting = false
    }
  }

  aboutToDisappear(): void {
    this.active = false
    this.selectTypeDialog.close()
  }

  onPageHide(): void {
    this.active = false
    this.selectTypeDialog.close()
  }

  //选择类型的弹层
  selectTypeDialog: CustomDialogController = new CustomDialogController({
    builder: HmSelectCard({
      cardContent: () => {
        //必须调用一个builder的函数
        this.getCardContent()
      },
      confirm: () => {
        if (this.selectIndex > -1) {
          this.exceptionForm.exceptionType = this.exceptionList[this.selectIndex]
        }
        this.selectTypeDialog.close()
      }
    }),
    customStyle: true,
    alignment: DialogAlignment.Bottom,
  })
  exceptionList: string[] =
    ["发动机启动困难", "不着车", "漏油", "漏水", "照明失灵", "有异响", "排烟异常", "温度异常", "其他"]

  @Builder
  getSingleItem(item: string, index: number, showBorder: boolean) {
    Row() {
      Text(item)
        .fontSize(14)
        .fontColor($r('app.color.text_primary'))
      Image(this.selectIndex === index ? $r('app.media.ic_check_true') : $r('app.media.ic_check_false'))
        .width(32)
        .height(32)
        .onClick(() => {
          this.selectIndex = index //赋值索引
        })
    }
    .height(60)
    .width("100%")
    .border({
      color: $r('app.color.background_divider'),
      width: {
        bottom: showBorder ? 1 : 0
      }
    })
    .justifyContent(FlexAlign.SpaceBetween)
  }

  //传入HmSelectCard组件
  @Builder
  getCardContent() {
    Scroll() {
      Column() {
        ForEach(this.exceptionList, (item: string, index: number) => {
          this.getSingleItem(item, index, index !== this.exceptionList.length - 1)
        })
      }
    }.height(360).width('100%')
  }

  onPageShow(): void {
    this.active = true
    const params = router.getParams() as CommonRouterParams
    if (params && params.location) {
      this.exceptionForm.exceptionPlace = params.location
    }
    if (params && params.id) {
      this.exceptionForm.transportTaskId = params.id
    }
  }

  build() {
    Column() {
      HmNavBar({ title: '上报异常' })
      Scroll() {
        Column() {
          HmCard() {
            HmCardItem({
              leftTitle: '异常时间',
              rightText: this.exceptionForm.exceptionTime || '请选择',
              onRightClick: () => {
                if (this.submitting) {
                  return
                }
                DatePickerDialog.show({
                  showTime: true,
                  useMilitaryTime: true,
                  onDateAccept: (value) => {
                    this.exceptionForm.exceptionTime = DateFormat(value)
                  }
                })
              }
            })
            HmCardItem({
              leftTitle: '上报位置', rightText: this.exceptionForm.exceptionPlace || '请选择', onRightClick: () => {
                if (this.submitting) {
                  return
                }
                router.pushUrl({
                  url: "pages/SelectLocation/SelectLocation"
                })
              }
            })
            HmCardItem({
              leftTitle: '异常类型', rightText: this.exceptionForm.exceptionType || "请选择",
              onRightClick: () => {
                if (this.submitting) {
                  return
                }
                this.selectTypeDialog.open()
              }
            })
            HmCardItem({
              leftTitle: '异常描述',
              rightText: '',
              showRightIcon: false,
              showBottomBorder: false
            })
            TextArea({
              placeholder: '请输入异常描述',
              text: this.exceptionForm.exceptionDescribe || ''
            })
              .height(130)
              .borderRadius(8)
              .placeholderColor($r('app.color.text_secondary'))
              .fontSize(14)
              .maxLength(200)
              .enabled(!this.submitting)
              .onChange((value: string) => {
                this.exceptionForm.exceptionDescribe = value
              })
            Text(`${(this.exceptionForm.exceptionDescribe || '').length}/200`)
              .margin({
                top: -30
              })
              .textAlign(TextAlign.End)
              .width('100%')
              .padding({ right: 15 })
              .fontColor($r('app.color.text_secondary'))
            Row().height(20)

          }

          HmCard() {
            HmUpload({
              title: '上传图片(最多6张)',
              imgList: this.exceptionForm.exceptionImagesList || [],
              maxNumber: 6,
              canUpload: !this.submitting,
              onListChange: (list: ImageList[]) => {
                this.exceptionForm.exceptionImagesList = list
              }
            })
            Row().height(20)
          }
        }
      }.padding({
        bottom: 80
      })
      .layoutWeight(1)


      Row() {
        Button("提交")
          .height(50)
          .width(207)
          .backgroundColor($r('app.color.primary_disabled'))
          .enabled(this.getBtnEnable())
          .backgroundColor(this.getBtnEnable() ? $r('app.color.primary') : $r('app.color.primary_disabled'))
          .onClick(() => {
            this.submitReport()
          })
      }
      .position({
        y: '100%'
      })
      .height(70)
      .translate({
        y: -70
      })
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .backgroundColor($r('app.color.white'))
    }
    .height('100%').backgroundColor($r('app.color.background_page'))
  }
}
