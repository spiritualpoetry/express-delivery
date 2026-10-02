import { CommonRouterParams, DateFormat, HmCard, HmCardItem, HmCheckBox, HmNavBar, } from '@hm/basic'
import { promptAction, router } from '@kit.ArkUI'
import {TaskDetailInfoModel,TaskDetailInfo, CarRecordTypeModel, CarRecordType } from '../../models'
import {getTaskDetail as GTD ,carRecord as cR } from "../../api";


@Entry
@Component
struct CarRecord {
  @State
  carRecord:CarRecordTypeModel=new CarRecordTypeModel({} as CarRecordType )
  @State
  submitting:boolean=false
  //详情数据
  @State
  taskDetailData:TaskDetailInfoModel=new TaskDetailInfoModel({}as TaskDetailInfo)

  aboutToAppear(): void {
    this.carRecord.isBreakRules=false
    this.carRecord.isFault=false
    this.carRecord.isAccident=false
    const params =router.getParams() as CommonRouterParams
    if (params && params.id) {
      this.getTaskDetail(params.id)
    }
  }
  //检查再提交
  async btnCarRecord(){
    if (this.submitting) {
      return
    }
    if (!this.carRecord.endTime) {
      promptAction.showToast({message:"请选择回车时间"})
      return
    }
    this.carRecord.startTime=this.taskDetailData.actualDepartureTime
    //运输任务的id
    this.carRecord.id=this.taskDetailData.transportTaskId
    if (!this.carRecord.id || !this.carRecord.startTime) {
      promptAction.showToast({message:"任务详情尚未加载，请稍后重试"})
      return
    }
    this.submitting=true
    try {
      await cR(this.carRecord)
      promptAction.showToast({message:"回车登记成功"})
      await router.replaceUrl({url:'pages/Index/Index'})
      router.clear()
    } catch (error) {
      // 请求封装已显示失败提示，保留表单供重试。
    } finally {
      this.submitting=false
    }
  }



  async getTaskDetail(id:string){
    try {
      this.taskDetailData=await GTD(id)
    } catch (error) {
      // 请求封装已显示失败提示。
    }
  }

  build() {
    Column(){
      HmNavBar({title:"回车登记"})
      Column(){
        HmCard(){
          HmCardItem({leftTitle:"出车时间",rightText:this.taskDetailData.actualDepartureTime||"",showRightIcon:false})
          HmCardItem({leftTitle:"回车时间",rightText:this.carRecord.endTime ||"请选择",showBottomBorder:false,
            onRightClick:()=>{
              DatePickerDialog.show({
                showTime:true,
                useMilitaryTime:true,
                onDateAccept:(value:Date)=>{
                  //结束时间
                  this.carRecord.endTime = DateFormat(value, true)
                }
              })
            }})

          HmCheckBox({title:'车辆违章',value:!! this.carRecord.isBreakRules,
            checkChange:(value)=>{
              this.carRecord.isBreakRules=value
          }})
          HmCheckBox({title:'车辆故障',value:!!this.carRecord.isFault,
            checkChange:(value)=>{
              this.carRecord.isFault=value
            }})
          HmCheckBox({title:'车辆事故',value:!!this.carRecord.isAccident,
            checkChange:(value)=>{
              this.carRecord.isAccident=value
            }})

        }
      }
      .layoutWeight(1)
      Row(){
        Button("交车")
          .enabled(!this.submitting)
          .height(50)
          .width("60%")
          .backgroundColor($r("app.color.primary"))
          .onClick(()=>{
            this.btnCarRecord()
          })
      }
      .justifyContent(FlexAlign.Center)
      .height(70)
      .width("100%")
      .backgroundColor($r("app.color.white"))
    }
    .backgroundColor($r("app.color.background_page"))
    .height("100%")
  }
}
