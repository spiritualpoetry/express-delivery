import { TabClass } from "@hm/basic"
import TaskItemCard from "./TaskItemCard"
import TaskList from "./TaskList"

@Preview
@Component
struct TaskTabs{
  tabController:TabsController= new TabsController()
  @State
  tabsData: TabClass[] = [{
    name: 'waiting',
    title: '待提货'
  },{
    name: 'line',
    title: '在途'
  },{
    name: 'finish',
    title: '已完成'
  }]
  @State
  currentIndex: number  = 0

  @Builder
  getTabBar(item:TabClass){
    Column(){
      Text(item.title)
        .animation({
          duration:500
        })
        .fontSize(16)
        .margin({bottom:7})
        .fontWeight(this.tabsData[this.currentIndex].name===item.name?600:FontWeight.Regular)
        .fontColor(this.tabsData[this.currentIndex].name===item.name?$r("app.color.text_primary"):$r("app.color.text_secondary"))
      Divider()
        .animation({
          duration:500
        })
        .width(this.tabsData[this.currentIndex].name===item.name?23:0)
        .strokeWidth(4)
        .color($r("app.color.primary"))
        .lineCap(LineCapStyle.Round)
    }.onClick(()=>{
      const index=this.tabsData.findIndex(obj=>obj.name===item.name)
      this.tabController.changeIndex(index)
    })
  }

  build() {
    Stack({alignContent:Alignment.Top}){
      Tabs({index:$$this.currentIndex,controller:this.tabController}){
        ForEach(this.tabsData,(item:TabClass)=>{
          TabContent(){
            if (item.name==="waiting") {
              TaskList()
            }else if (item.name==="line") {

            }else if (item.name==="finish") {

            }
          }
          .tabBar(item.title)
        })
      }
      .backgroundColor($r("app.color.background_page"))
      Row({space:30}){
        ForEach(this.tabsData,(item:TabClass)=>{
          this.getTabBar(item)
        })
      }
      .padding({
        left:40,right:40
      })
      .width("100%")
      .height(50)
      .backgroundColor($r("app.color.white"))
    }
    .margin({top:7})
  }
}
export default TaskTabs