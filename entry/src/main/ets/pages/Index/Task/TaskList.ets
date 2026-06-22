// import {getTaskList} from "../../../api"
// import {
//   TaskInfoItem,
//   TaskListData,
//   TaskListDataModel,
//   TaskListParams, TaskListParamsModel, TaskTypeEnum } from "../../../models/Task"
// import { JSON } from "@kit.ArkTS"
//
// @Component
// struct TaskList {
//   @State queryParams:TaskListParamsModel  =new TaskListParamsModel(
//     {
//     status:TaskTypeEnum.Waiting,//待提货的类型
//     page:1,//第几页
//     pageSize:5//每页多少条数据
//     }as TaskListParams)
//
//   @State taskListData:TaskInfoItem[]=[]
//
//   aboutToAppear(): void {
//     this.getTaskList()
//   }
//
//   async getTaskList(){
//     const  result = await getTaskList(this.queryParams)
//     this.taskListData=result.items//拿到返回的数组
//   }
//   build() {
//     Text(JSON.stringify(this.taskListData))
//   }
// }
// export default TaskList

import { getTaskList } from '../../../api/task'
import { TaskInfoItem, TaskListParams, TaskListParamsModel, TaskTypeEnum } from '../../../models'

@Preview
@Component
struct TaskList {
  @State
  querrParams:TaskListParamsModel = new TaskListParamsModel({
    status: TaskTypeEnum.Waiting,
    page: 1,
    pageSize: 5,
  } as TaskListParams)
  @State
  taskListData: TaskInfoItem[] = []
  aboutToAppear() {
    this.getTaskList()
  }
  async getTaskList() {
    const result = await getTaskList(this.querrParams)
    this.taskListData = result.items
  }
  build() {
    Text(JSON.stringify(this.taskListData))
  }
}
export default  TaskList
