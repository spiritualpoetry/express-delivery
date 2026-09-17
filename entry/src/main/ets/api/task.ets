import { TaskListData, TaskListParams, UserInfo } from '../models'
import { Request } from '@hm/basic'
import { TaskDetailInfoModel } from '../models/task_detail'

// 获取任务列表
export const getTaskList = (params: TaskListParams) => {
  return Request.get<TaskListData>("/tasks/list", params)
}


//获取用户任务详情
export const getTaskDetail = (id:string) => {
  return Request.get<TaskDetailInfoModel>(`/tasks/details/${id}`)
}
