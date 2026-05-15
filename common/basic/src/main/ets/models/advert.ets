@ObservedV2
export class AdvertClass {
  @Trace
  showAd: boolean = false // 显示广告
  @Trace
  adTime: number = 5 // 广告时长
  @Trace
  adUrl?: string = '' // 广告链接
  @Trace
  adImg?: ResourceStr = '' // 广告图片
}