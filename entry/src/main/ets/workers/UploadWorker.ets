import { ImageList } from '@hm/basic';
import { MessageEvents, ThreadWorkerGlobalScope, util, worker } from '@kit.ArkTS';
import { fileIo } from '@kit.CoreFileKit';
import { image } from '@kit.ImageKit';

interface PostParams {
  files: ImageList[]
  filePath: string
}

const workerPort: ThreadWorkerGlobalScope = worker.workerPort;
workerPort.onmessage = async (event: MessageEvents) => {
  const params = event.data as PostParams
  const files: ImageList[] = []
  const temporaryPaths: string[] = []
  try {
    for (const file of params.files) {
      // 已上传图片沿用 URL，不将网络地址当成本地文件打开。
      if (file.url.startsWith('https://') || file.url.startsWith('http://')) {
        files.push(file)
        continue
      }
      let source: fileIo.File | undefined = undefined
      let target: fileIo.File | undefined = undefined
      let imageSource: image.ImageSource | undefined = undefined
      let packer: image.ImagePacker | undefined = undefined
      try {
        source = fileIo.openSync(file.url, fileIo.OpenMode.READ_ONLY)
        const path = params.filePath + '/' + util.generateRandomUUID() + '.jpg'
        temporaryPaths.push(path)
        target = fileIo.openSync(path, fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE)
        imageSource = image.createImageSource(source.fd)
        packer = image.createImagePacker()
        await packer.packToFile(imageSource, target.fd, { format: 'image/jpeg', quality: 20 })
        files.push({ url: path })
      } finally {
        try { if (packer) { await packer.release() } } catch (_) {}
        try { if (imageSource) { await imageSource.release() } } catch (_) {}
        try { if (target) { fileIo.closeSync(target.fd) } } catch (_) {}
        try { if (source) { fileIo.closeSync(source.fd) } } catch (_) {}
      }
    }
    workerPort.postMessage({ files })
  } catch (_) {
    for (const path of temporaryPaths) {
      try { fileIo.unlinkSync(path) } catch (_) {}
    }
    workerPort.postMessage({ files: [], error: '图片压缩失败' })
  }
  // 由主线程收到结果后统一终止 Worker。
};
