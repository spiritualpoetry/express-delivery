import { AdvertClass, UserSettingClass } from '@hm/basic'
import { window } from '@kit.ArkUI'

@Entry
@ComponentV2
struct Start {
  userSetting:UserSettingClass=new UserSettingClass(getContext(this))
  @Local
  adObj:AdvertClass=new AdvertClass()

  timer:number=-1

  closeWin () {
    window.findWindow('ad_window').destroyWindow()
  }

  async aboutToAppear(): Promise<void> {
    const res = await this.userSetting.getUserAd()
    this.adObj.showAd=res.showAd
    this.adObj.adTime=res.adTime
    this.adObj.adImg=res.adImg
    this.timer=setInterval(()=>{
      console.info(`当前倒计时：${this.adObj.adTime}`)
      if (this.adObj.adTime==0) {
        clearTimeout(this.timer)
        this.closeWin()
        return
      }
      this.adObj.adTime--
    },1000)
  }

  aboutToDisappear(): void {
    clearInterval(this.timer)
  }

  build() {
    Stack({alignContent:Alignment.TopEnd}){
      Image(this.adObj.adImg).objectFit(ImageFit.Cover)
      Text(`${this.adObj.adTime}秒后跳过`)
        .width(100)                          // ✅ 明确宽度
        .height(30)                          // ✅ 明确高度
        .backgroundColor('rgba(0, 0, 0, 0.6)')  // 半透明背景
        .fontColor('#FFFFFF')               // 白色文字
        .fontSize(14)
        .borderRadius(15)
        .padding({ left: 10, right: 10 })
        .margin({ right: 20, top: 20 })
        .textAlign(TextAlign.Center)
        .onClick(() => {                    // ✅ 正确绑定点击事件
          console.log('跳过按钮点击');
          this.closeWin()
        });
    }.height('100%')
    .width('100%')
  }


  }
