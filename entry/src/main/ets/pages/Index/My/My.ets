import {HmCard,HmCardItem}from '@hm/basic'
import {getUserInfo,getUserTaskInfo} from '../../../api'
import { UserInfo, UserInfoModel,UserTaskInfoModel,UserTaskInfo, UserTaskInfoParams,
  UserTaskInfoParamsModel } from '../../../models/index'
import json from '@ohos.util.json'
import { JSON } from '@kit.ArkTS'
import { promptAction } from '@kit.ArkUI'

@Preview
@Component
struct My {
  @State
  userInfo:UserInfoModel=new UserInfoModel({} as UserInfo)
  //用户任务数据
  @State
  userTaskInfo:UserTaskInfoModel=new UserTaskInfoModel({} as UserTaskInfo)
  //声明请求参数
  queryTaskParams:UserTaskInfoParamsModel= new UserTaskInfoParamsModel({
    //必填
    year:new Date().getFullYear().toString(),
    month:(new Date().getMonth()+1).toString().padStart(2,"0")
  })



  //获取用户信息方法
  @Consume
  @Watch("updataName")
  currentName: string


  //只执行一次
  aboutToAppear(): void {
    this.getUserInfo()
  }


  //更新页签，通过页签的name得知
  updataName(){
    if(this.currentName === 'my') {
      this.getUserTaskInfo()
    }
  }

  async getUserInfo(){
      this.userInfo = await getUserInfo()
  }

  //获取用户的任务数据
  async getUserTaskInfo(){
    this.userTaskInfo=await getUserTaskInfo(this.queryTaskParams)
  }

  build() {
    Column(){
        Column(){
          Image(this.userInfo.avatar||$r("app.media.ic_avatar_driver"))
            .width(60)
            .height(60)
            .margin({top:70})
            .borderRadius(34.5)
            .backgroundColor(Color.White)
          Text(`${this.userInfo.name}`)
            .margin({top:10})
            .fontColor($r('app.color.white'))
          Text(`司机编号:${this.userInfo.number}`)
            .fontSize(12)
            .margin(10)
            .fontColor($r('app.color.white'))
          Text(`手机号:${this.userInfo.phone}`)
            .fontSize(12)
            .fontColor($r('app.color.white'))
            .margin({bottom:30})
        }
        .backgroundColor(Color.Red)
        .width('100%')
        .height(260)
        .borderRadius({bottomLeft:30,bottomRight:30})

        //本月任务
        Column(){
          Text('- 本月任务 -')
            .fontSize(11)
            .fontColor($r('app.color.gray_6'))

          Row(){
            //任务总量
            Column(){
              Text(this.userTaskInfo.taskAmounts?.toString()).fontSize(18).fontColor($r('app.color.text_primary')).lineHeight(25).margin({ bottom: 17 })
              Text('任务总量').fontSize(12).fontColor($r('app.color.text_primary')).lineHeight(17)
            }.justifyContent(FlexAlign.SpaceAround).layoutWeight(1)
            //完成任务量
            Column(){
              Text(this.userTaskInfo.completedAmounts?.toString()).fontSize(18).fontColor($r('app.color.text_primary')).lineHeight(25).margin({ bottom: 17 })
              Text('完成任务量').fontSize(12).fontColor($r('app.color.text_primary')).lineHeight(17)
            }.justifyContent(FlexAlign.SpaceAround).layoutWeight(1)

            //运输历程（km）
            Column(){
              Text(this.userTaskInfo.transportMileage?.toString()).fontSize(18).fontColor($r('app.color.text_primary')).lineHeight(25).margin({ bottom: 17 })
              Text('运输历程（km）').fontSize(12).fontColor($r('app.color.text_primary')).lineHeight(17)
            }.justifyContent(FlexAlign.SpaceAround).layoutWeight(1)
          }.margin({bottom:15})

        }
        .borderRadius(8)
        .margin({ left: 14.5, right: 14.5, top: -50, bottom: 15 })
        .height(134)
        .padding({ top: 12.5, bottom: 13.5 })
        .justifyContent(FlexAlign.SpaceBetween)
        .backgroundColor($r('app.color.white'))
        .width('90%')


      //车辆信息，任务数据，系统设置
      //尾随闭包形式
      HmCard(){
          HmCardItem({
            leftTitle:"车辆信息",
            rightText:"",
          })
        HmCardItem({
          leftTitle:"任务数据",
          rightText:"",
        })
        HmCardItem({
          leftTitle:"系统设置",
          rightText:"",
          showBottomBorder:false
        })
      }
    }.width('100%').height('100%').backgroundColor($r('app.color.background_page')).borderRadius(8)














    // Column(){
    //   // 基本信息
    //   Column() {
    //     Image($r("app.media.ic_avatar_driver"))
    //       .width(67)
    //       .height(67)
    //       .borderRadius(34.5)
    //       .backgroundColor($r('app.color.white'))
    //     Text("司机")
    //       .fontSize(18)
    //       .fontWeight(600)
    //       .lineHeight(25)
    //       .margin({
    //         top: 9,
    //         bottom: 9
    //       })
    //       .fontColor($r('app.color.white'))
    //     Text(`司机编号: 66666666`).fontSize(14).fontWeight(400).lineHeight(20).fontColor($r('app.color.white'))
    //     Text(`手机号: 66666666`)
    //       .fontSize(14)
    //       .fontWeight(400)
    //       .lineHeight(20)
    //       .margin({
    //         top: 10
    //       })
    //       .fontColor($r('app.color.white'))
    //   }
    //   .backgroundImage($r("app.media.bg_page_my"))
    //   .backgroundImageSize(ImageSize.Cover)
    //   .width('100%')
    //   .alignItems(HorizontalAlign.Center)
    //   .justifyContent(FlexAlign.Center)
    //   .height(292)
    //   .margin({
    //     top: -2
    //   })
    //
    //   // 本月任务
    //   Column() {
    //     Text("- 本月任务 -").fontSize(14).fontColor($r('app.color.text_secondary')).lineHeight(20)
    //     Row() {
    //       Column() {
    //         Text("1000").fontSize(18).fontColor($r('app.color.text_primary')).lineHeight(25).margin({
    //           bottom: 17
    //         })
    //         Text("任务总量").fontSize(12).fontColor($r('app.color.text_primary')).lineHeight(17)
    //       }.justifyContent(FlexAlign.SpaceAround).layoutWeight(1)
    //
    //       Column() {
    //         Text("1000")
    //           .fontSize(18)
    //           .fontColor($r('app.color.text_primary'))
    //           .lineHeight(25)
    //           .margin({ bottom: 17 })
    //         Text("完成任务量").fontSize(12).fontColor($r('app.color.text_primary')).lineHeight(17)
    //       }.justifyContent(FlexAlign.SpaceAround).layoutWeight(1)
    //
    //       Column() {
    //         Text("1000")
    //           .fontSize(18)
    //           .fontColor($r('app.color.text_primary'))
    //           .lineHeight(25)
    //           .margin({ bottom: 17 })
    //         Text("运输里程(km)").fontSize(12).fontColor($r('app.color.text_primary')).lineHeight(17)
    //       }.justifyContent(FlexAlign.SpaceAround).layoutWeight(1)
    //     }.justifyContent(FlexAlign.SpaceBetween).width('100%').layoutWeight(1)
    //   }
    //   .backgroundColor($r('app.color.white'))
    //   .borderRadius(8)
    //   .margin({ left: 14.5, right: 14.5, top: -55, bottom: 15 })
    //   .height(134)
    //   .padding({ top: 13.5, bottom: 13.5 })
    //   .justifyContent(FlexAlign.SpaceBetween)
    //
    //   // 信息列表
    //   Column() {
    //     Row() {
    //       Text("车辆信息").fontSize(16).fontWeight(400).fontColor($r('app.color.text_primary'))
    //       Image($r("app.media.ic_btn_more")).width(24).height(24)
    //     }
    //     .justifyContent(FlexAlign.SpaceBetween)
    //     .alignItems(VerticalAlign.Center)
    //     .border({ width: { bottom: 1 }, color: $r('app.color.background_page') })
    //     .width('100%')
    //     .height(60)
    //
    //     Row() {
    //       Text("任务数据").fontSize(16).fontWeight(400).fontColor($r('app.color.text_primary'))
    //       Image($r("app.media.ic_btn_more")).width(24).height(24)
    //     }
    //     .justifyContent(FlexAlign.SpaceBetween)
    //     .alignItems(VerticalAlign.Center)
    //     .border({ width: { bottom: 1 }, color: $r('app.color.background_page') })
    //     .width('100%')
    //     .height(60)
    //
    //     Row() {
    //       Text("系统设置").fontSize(16).fontWeight(400).fontColor($r('app.color.text_primary'))
    //       Image($r("app.media.ic_btn_more")).width(24).height(24)
    //     }
    //     .justifyContent(FlexAlign.SpaceBetween)
    //     .alignItems(VerticalAlign.Center)
    //     .width('100%')
    //     .height(60)
    //   }
    //   .padding({ left: 17.5, right: 17.5 })
    //   .backgroundColor($r('app.color.white'))
    //   .margin({ left: 14.5, right: 14.5, bottom: 15 })
    //   .borderRadius(8)
    //
    // }.width('100%').height('100%').backgroundColor($r('app.color.background_page')).borderRadius(8)

  }
}

export default My