import request from '@ohos.request'
import { BASE_URL, TOKEN_KEY } from '../constants'
import { ImageList, ResponseData } from '../models'

// 接口接收一个 file，并返回该图片的 URL。
async function uploadSingleImage(context: Context, file: request.File): Promise<ImageList> {
  const config: request.UploadConfig = {
    url: BASE_URL + '/files/imageUpload', // 拼接上传完整地址
    method: 'POST',
    header: {
      Authorization: AppStorage.get(TOKEN_KEY) || "", // 应用中的token
      "Content-Type": "multipart/form-data" // 上传文件的参数类型
      // application/json  { name: '张三', age: 18 }
      // application/x-www-form-urlencoded 拼接   name=张三&age=18
      // text/xhtml 结构
      // multipart/form-data  专门传文件的结构
    },
    files: [file],
    data: [] // 批量上传需要携带的参数 用不上
  }
  const task = await request.uploadFile(context, config)
  return new Promise<ImageList>((resolve, reject) => {
      let imageUrl: string = ''
      let failureMessage: string = ''
      let timeoutId: number = -1
      const cleanup = (): void => {
        if (timeoutId !== -1) { clearTimeout(timeoutId) }
        try {
          task.off('headerReceive')
          task.off('complete')
          task.off('fail')
        } catch (error) {
          // 不让取消事件监听的错误覆盖上传结果。
        }
      }
      // 系统上传可能持续重试；给页面一个明确的失败恢复时间。
      timeoutId = setTimeout(() => {
        cleanup()
        try { task.remove().catch(() => {}) } catch (_) {}
        reject(new Error('图片上传超时，请检查网络后重试'))
      }, 30000)
      task.on("fail", () => {
        // 上传失败
        cleanup()
        reject(new Error("上传失败"))
      })
      // 每上传成功一次就会进来
      task.on("headerReceive", (headers: object) => {
        if (headers["body"]) {
          try {
          const result = JSON.parse(headers["body"]) as ResponseData<string>
          if (String(result.code) === '200' && typeof result.data === 'string' && result.data.trim()) {
            imageUrl = result.data
          } else {
            failureMessage = result.msg || '图片上传失败'
          }
          } catch (error) { failureMessage = '图片上传响应异常' }
        }
      })
      task.on("complete", (states: request.TaskState[]) => {
        cleanup()
        // 上传完成
        // 也不能拿到上传成功的地址
        // 走到这里认为 要返回的结构已经ok了
        if (states.some((state: request.TaskState) => state.responseCode !== 0)) {
          reject(new Error('图片上传失败'))
        } else if (!failureMessage && imageUrl) {
          resolve({ url: imageUrl })
        } else {
          reject(new Error(failureMessage || '图片上传不完整，请重试'))
        }
      })
      // 4.0 上传完成之后 用文件的一个标识 又去后台查了一下  当时是最优方案
  })

}

export const uploadImage = async (context: Context, files: request.File[]): Promise<ImageList[]> => {
  const images: ImageList[] = []
  for (const file of files) {
    images.push(await uploadSingleImage(context, file))
  }
  return images
}
