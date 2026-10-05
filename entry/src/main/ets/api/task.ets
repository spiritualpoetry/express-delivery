import { DelayParamsTypeModel,DeliverParamsTypeModel, PickUpParamsModel, TaskListData, TaskListParams, UserInfo,CarRecordTypeModel } from '../models'
import { Request } from '@hm/basic'
import { TaskDetailInfoModel } from '../models/task_detail'
import { ExceptionParamsType } from '../models/exception'

// 获取任务列表
export const getTaskList = (params: TaskListParams) => {
  return Request.get<TaskListData>("/tasks/list", params)
}


//获取用户任务详情
export const getTaskDetail = (id:string) => {
  return Request.get<TaskDetailInfoModel>(`/tasks/details/${id}`)
}

//提货
export const pick_Up = (params:PickUpParamsModel) => {
  return Request.post<null>("/tasks/takeDelivery",params)
}

//交货
export const deliver = (params:DeliverParamsTypeModel) => {
  return Request.post<null>("/tasks/deliver",params)
}

//回车登记
export const carRecord = (params:CarRecordTypeModel) => {
  return Request.post<null>("/tasks/truckRegistration",params)
}

//延迟提货
export const delay = (params:DelayParamsTypeModel) => {
  return Request.put<null>("/tasks/delay",params)
}

export const reportException = (params: ExceptionParamsType) => {
  return Request.post<null>("/tasks/reportException", params)
}
