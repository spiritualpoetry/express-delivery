import  {TabClass} from  '@hm/basic'
@Entry
@Component

struct Index {
  @State
  currentIndex: number = 0 //当前激活项
  @State tabsData: TabClass[] = [{
    title: '任务',
    name: 'task',
    icon: $r("app.media.ic_tab_btn_task")
  },{
    title: '消息',
    name: 'message',
    icon: $r("app.media.ic_tab_btn_mess_nor")
  },{
    title: '我的',
    name: 'my',
    icon: $r("app.media.ic_tab_btn_mine_nor")
  }]

  @Builder
  getTabBar(item:TabClass){
    Column(){
      Image(item.icon)
        .width(22)
        .height(22)
        .fillColor(item.name===this.tabsData[this.currentIndex].name ?
          $r('app.color.primary'):$r('app.color.text_secondary'))
      Text(item.title)
        .fontSize(12)
        .fontWeight(400)
        .fontColor(item.name===this.tabsData[this.currentIndex].name?
          $r("app.color.primary"):$r("app.color.text_secondary"))
        .margin({
          top:5
        })
    }.alignItems(HorizontalAlign.Center)
  }
  build() {
    Tabs({barPosition:BarPosition.End,index:$$this.currentIndex}){
      ForEach(this.tabsData, (item: TabClass) => {
          TabContent() {
            if (item.name==="task") {
              Text("任务组件")
            }else if (item.name==="message") {
              Text("消息组件")
            }else {
              Text("我的组件")
            }

          }
          .tabBar(
            //自定义tabBar
            this.getTabBar(item)
          )
        })
    }
    .animationDuration(0)
    .height('100%')
    .width('100%')
    }

}