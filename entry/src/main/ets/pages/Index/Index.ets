import  {TabClass} from  '@hm/basic'
import My from './My/My'
import TaskTabs from './Task/TaskTab'

@Entry
@Component

struct Index {


  @State
  @Watch("updateName")
  currentIndex: number = 0 //当前激活项
  @Provide //在父组件通过Provide传入一个当前name
  currentName: string = ""
  updateName () {
    this.currentName = this.tabsData[this.currentIndex].name
  }


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
              TaskTabs()
            }else if (item.name==="message") {
              TestCom({titile:'消息'})
            }else {
              My()
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


@Component
struct TestCom{
  titile:string=''
  aboutToAppear(): void {
    AlertDialog.show({message:this.titile})
  }
  build() {
    Text(this.titile)
  }
}