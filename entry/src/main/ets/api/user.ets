import { Request } from '@hm/basic'
import { LoginForm, LoginFormModel,UserInfoModel, UserTaskInfoParamsModel} from '../models'
import { UserTaskInfoModel } from '../models/User_Task'

export const login = (data: LoginFormModel) => {
  const plainData: LoginForm = {
    account: data.account,
    password: data.password
  }
  return Request.post<string>("/login/account", plainData)
}



// 获取用户信息
export const getUserInfo = () => {
  return Request.get<UserInfoModel>("/users")
}

//获取用户任务数据
export const getUserTaskInfo = (data:UserTaskInfoParamsModel) => {
  return Request.get<UserTaskInfoModel>("/users/taskReport", data)
}