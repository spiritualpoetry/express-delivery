import {BASE_URL, TOKEN_KEY} from  '../constants'
import http from '@ohos.net.http';//请求原生的http库
import json from '@ohos.util.json';
import { promptAction, PromptAction, router } from '@kit.ArkUI';
import { UserSettingClass } from '../../../../Index';
import { ResponseData} from '../models'


async function requestHttp<T>(url: string = "", method: http.RequestMethod = http.RequestMethod.GET, data?: object): Promise<T> {
  const httpRequest = http.createHttp()
  let urlStr = BASE_URL + url

  // ===== 添加日志 =====
  console.log('=== 请求开始 ===')
  console.log('BASE_URL:', BASE_URL)
  console.log('完整URL:', urlStr)
  console.log('请求方法:', http.RequestMethod[method])
  console.log('请求数据:', JSON.stringify(data))
  console.log('请求数据类型:', typeof data)
  // ====================

  if (method === http.RequestMethod.GET) {
    if (data && Object.keys(data).length) {
      urlStr += "?" + Object.keys(data).map(key => {
        return `${key}=${data[key]}`
      }).join("&")
    }
  }

  // 添加日志：查看实际发送的数据
  console.log('请求URL:', urlStr)
  console.log('发送数据:', JSON.stringify(data))

  const config: http.HttpRequestOptions = {
    // 关键修复
    extraData: method !== http.RequestMethod.GET ? JSON.stringify(data) : "",
    header: {
      "Content-Type": "application/json",
      Authorization: AppStorage.get(TOKEN_KEY) || "",
    },
    method,
    readTimeout: 23000
  }
// //封装请求工具 get / put /post /patch /delete
// async function  requestHttp<T>(url:string="",method:http.RequestMethod=http.RequestMethod.GET,data?:object):Promise<T>{
//    //http需要创建一个请求对象
//    const  httpRequest = http.createHttp()
//    let urlStr = BASE_URL+url//基础地址拼接url地址
//
//    //进行处理，官方文档说get会进行拼接地址实际并没有
//
//    if(method===http.RequestMethod.GET) {
//      //data参数都拼接到低智商   ？a=1&b=2&c=3
//      if (data && Object.keys(data).length) {
//        urlStr += "?" + Object.keys(data).map(key => {
//          return `${key}=${data[key]}`
//        }).join("&")
//      }
//    }
//
//      //组装参数
//      const config:http.HttpRequestOptions={
//        extraData: method!== http.RequestMethod.GET?data:"",
//        header:{
//          "Content-Type":"application/json",
//          Authorization:AppStorage.get(TOKEN_KEY)||"",
//        },
//        method,
//        readTimeout:20000//如果多久没响应，直接断开
//      }



     //发请求
     try {
       const result = await httpRequest.request(urlStr,config)

       // ===== 添加响应日志 =====
       console.log('=== 响应详情 ===')
       console.log('HTTP状态码:', result.responseCode)
       console.log('响应头:', JSON.stringify(result.header))
       console.log('响应内容:', result.result)
       console.log('响应内容类型:', typeof result.result)
       // =======================


       //处理一些异常
       //判断状态码 1,http状态码 2,业务状态码
       if (result.responseCode===401) {
         //401表示token失效 超市 或者没传
         //移动端产品一般去做无感刷新=>token 失效用 refresh_token换取新token然后重新发请求


         //直接提示错误-删除目前token 跳到登录页
         promptAction.showToast({message:"登陆失效"})
         //删除token- 删两个地址 首选项，全局状态
         new UserSettingClass(getContext()).setUserToken("")//清空首选项token
         AppStorage.set(TOKEN_KEY,"")//设置为空 ，只能设置不能删除
         //跳转
         router.replaceUrl({
           url:'pages/Login/Login'//跳转到登录页
         })
         return Promise.reject(new Error("登录失效"))
       }else if (result.responseCode===404) {
         promptAction.showToast({
           message:'请求地址错误'
         })
         return Promise.reject(new Error('请求地址错误'))
       }else {
         //业务状态码，只有业务状态码是200的时候才成功
         const res =JSON.parse(result.result as string) as  ResponseData<T>

         // ===== 添加业务响应日志 =====
         console.log('=== 业务响应 ===')
         console.log('业务状态码:', res.code)
         console.log('业务消息:', res.msg)
         console.log('业务数据:', JSON.stringify(res.data))
         // ===========================


         if(res.code===200){
           return res.data as T
         }else {
           promptAction.showToast({
             message: res.msg || '服务器异常'
           })
           return Promise.reject(new Error(res.msg))
         }
       }
     }catch (error){

       // ===== 添加错误日志 =====
       console.error('=== 请求异常 ===')
       console.error('错误类型:', error.name)
       console.error('错误消息:', error.message)
       console.error('错误堆栈:', error.stack)
       // =======================



       promptAction.showToast({message:error.message})
       return Promise.reject(error)
     }

   }


export class Request {
  static get<T>(url: string, data?: object): Promise<T> {
    return requestHttp<T>(url, http.RequestMethod.GET, data)
  }

  static post<T>(url: string, data?: object): Promise<T> {
    return requestHttp<T>(url, http.RequestMethod.POST, data)
  }

  static delete<T>(url: string, data?: object): Promise<T> {
    return requestHttp<T>(url, http.RequestMethod.DELETE, data)
  }

  static put<T>(url: string, data?: object): Promise<T> {
    return requestHttp<T>(url, http.RequestMethod.PUT, data)
  }
}
