import { Request } from '@hm/basic'
import { LoginForm, LoginFormModel } from '../models'

export const login = (data: LoginFormModel) => {
  const plainData: LoginForm = {
    account: data.account,
    password: data.password
  }
  return Request.post<string>("/login/account", plainData)
}