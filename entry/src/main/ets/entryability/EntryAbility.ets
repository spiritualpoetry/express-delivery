import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { AdvertClass, defaultAd, TOKEN_KEY, UserSettingClass } from '@hm/basic'


const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  async onWindowStageCreate(windowStage: window.WindowStage): Promise<void> {

    //检查是否有广告
    const setting = new UserSettingClass(this.context)
    // Main window is created, set main page for this ability
    //通过模拟请求拿到模拟信息
    const ad = await new Promise<AdvertClass>((resolve,reject)=>{
      setTimeout(()=>{
        resolve(defaultAd)
      },500)
    })
    await setting.setUserAd(ad)
    if (ad.showAd) {
      const win = await windowStage.createSubWindow("ad_window")
      await win.showWindow()
      win.setUIContent("pages/Start/start")
    }

    const token = await setting.getUserToken()
    if (token) {
      AppStorage.setOrCreate(TOKEN_KEY, token)
      windowStage.loadContent('pages/Index/Index')
    }else {
      windowStage.loadContent('pages/Login/Login')
    }
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');


  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}

