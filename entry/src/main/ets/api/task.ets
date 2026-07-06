import { TaskListData, TaskListParams, UserInfo } from '../models'
import { Request } from '@hm/basic'

// 获取任务列表

export const getTaskList = (params: TaskListParams) => {
  return Request.get<TaskListData>("/tasks/list", params)
}

