import {Request} from "@hm/basic"
import { TaskListDataModel, TaskListParamsModel } from "../models/Task"


//获取用户任务列表
export const  getTaskList=(params:TaskListParamsModel)=>{
  return Request.get<TaskListDataModel>("/tasks/list",params)
}