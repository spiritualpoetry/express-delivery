import { Request } from '@hm/basic'
import { LoginForm, LoginFormModel,UserInfoModel} from '../models'

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