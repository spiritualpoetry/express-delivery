import { AdvertClass } from '../models'
import preferences from '@ohos.data.preferences'
import { TOKEN_KEY, USER_SETTING, USER_SETTING_AD } from '../constants'
// 默认广告选项
export  const defaultAd: AdvertClass = {
  showAd: true,
  adTime: 5,
  adImg: $r('app.media.start')
}
export class UserSettingClass {
  context: Context
  constructor(context: Context) {
    this.context = context
  }
  // 获取存储用户信息的首选项仓库
  //ui/ability中 getcontext()拿不到任何上下文
  getStore () {
    return preferences.getPreferences(this.context, USER_SETTING)
  }
  // 设置用户广告设置
  async setUserAd (ad: AdvertClass) {
    const adStore = await this.getStore()
    await adStore.put(USER_SETTING_AD, JSON.stringify(ad))
    await adStore.flush()
  }
  // 获取广告配置
  async getUserAd (): Promise<AdvertClass> {
    const  adStore = await this.getStore()
    return  JSON.parse(await adStore.get(USER_SETTING_AD, JSON.stringify(defaultAd)) as string) as AdvertClass
  }
  //获取token
  async setUserToken(token:String){
    const  adStore = await this.getStore()
    await adStore.putSync(TOKEN_KEY,token)
    await adStore.flush()
  }
  //读取token
  async getUserToken(){
    const  adStore = await this.getStore()
    return adStore.getSync(TOKEN_KEY,"")  as string
  }
}

