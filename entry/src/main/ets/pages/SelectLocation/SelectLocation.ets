import { HmNavBar, HmCard, HmCardItem } from '@hm/basic'
import { MapComponent } from '@hms.core.map.MapComponent'
import { geoLocationManager } from '@kit.LocationKit'
import { map, mapCommon, site } from "@kit.MapKit"
import { promptAction, router } from '@kit.ArkUI'
import { abilityAccessCtrl, common } from '@kit.AbilityKit'

@Entry
@Component
struct SelectLocation {
  @State
  list: site.Site[] = []
  private active: boolean = false

  aboutToAppear(): void { this.active = true }
  aboutToDisappear(): void { this.active = false }
  mapController: map.MapComponentController = new map.MapComponentController()

  async getLocation() {
    try {
    const permission = await abilityAccessCtrl.createAtManager().requestPermissionsFromUser(
      getContext(this) as common.UIAbilityContext,
      ['ohos.permission.LOCATION', 'ohos.permission.APPROXIMATELY_LOCATION'])
    if (!this.active) { return }
    if (permission.authResults.some((result: number) => result !== 0)) {
      promptAction.showToast({ message: '请允许定位权限后重新进入此页面' })
      return
    }
    const position = await geoLocationManager.getCurrentLocation()
    if (!this.active) { return }
    // 系统定位坐标转换为地图使用的 GCJ02 坐标。
    const rightResult = await map.convertCoordinate(mapCommon.CoordinateType.WGS84,
      mapCommon.CoordinateType.GCJ02, { longitude: position.longitude, latitude: position.latitude })
    if (!this.active) { return }
    //将地图上的可挪动相机移动到具体的位置
    this.mapController.moveCamera(map.newCameraPosition({
      target: {
        longitude: rightResult.longitude,
        latitude: rightResult.latitude
      },
      zoom: 16
    }))
    //添加一个标记
    this.mapController.addPointAnnotation({
      position: {
        longitude: rightResult.longitude,
        latitude: rightResult.latitude
      },
      titles: [
        {
          content: '您当前的位置'
        }
      ]
    })
    const res = await site.nearbySearch({
      pageSize: 4,
      radius: 50,
      pageIndex: 1,
      location: {
        longitude: rightResult.longitude,
        latitude: rightResult.latitude
      }
    })
    if (!this.active) { return }
    this.list = (res.sites || []).slice(0, 4)
    if (!this.list.length) {
      promptAction.showToast({ message: '附近暂无地点，请稍后重试' })
    }
    } catch (error) {
      if (this.active) {
        this.list = []
        promptAction.showToast({ message: '定位或地点搜索失败，请检查权限、定位开关和网络' })
      }
    }
  }

  build() {
    Column() {
      HmNavBar({ title: '当前位置' })
      Stack({ alignContent: Alignment.Bottom }) {
        //  地图区域
        MapComponent({
          mapOptions: {
            position: {
              target: {
                latitude: 39.9,
                longitude: 116.4
              },
              zoom: 10
            }
          },
          mapCallback: (err, controller) => {
            if (!err) {
              this.mapController = controller //此时此刻地图渲染完毕 地图控制器也有值了
              this.getLocation() //获取定位
            } else {
              promptAction.showToast({ message: '地图加载失败，请稍后重试' })
            }
          }
        })
          .width('100%')
          .height('100%')
        Column() {
          HmCard() {
            ForEach(this.list, (item: site.Site) => {
              HmCardItem({
                leftTitle: item.name || item.formatAddress || '附近地点',
                rightText: item.distance === undefined ? '' : `${Math.round(item.distance)}m`
              })
                .onClick(()=>{
                  router.back({
                    url:"pages/ExceptionReport/ExceptionReport",
                    params:{
                      location:item.name || item.formatAddress || '附近地点'
                    }
                  })
                })
            })
          }
        }
        .padding({
          bottom: 60
        })
      }
    }
    .height('100%').backgroundColor($r('app.color.background_page'))
  }
}
