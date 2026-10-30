# 快送本地模拟后端

接口展示文案使用正常业务名称：司机、联系人、机构、车辆、公告及错误提示不附加“演示”“模拟”标注。已有数据库可在停止服务后运行 `node normalize-display.cjs` 更新历史展示字段，脚本先备份，仅修改指定文字，不改变任务状态、图片、已读状态和用户填写的异常记录。账号、鉴权及部署方式仍按下文配置。

使用 Node.js 内置模块，无需安装 npm 依赖。仅用于本地学习和模拟器演示，不连接原后端。

## 启动

在 PowerShell 执行（使用已安装的 DevEco Studio Node）：

```powershell
Set-Location 'C:\Users\Administrator\DevEcoStudioProjects\fast_driver\mock-server'
& 'E:\Program Files\DevEco Studio\tools\node\node.exe' server.cjs
```

保持终端运行，关闭服务按 Ctrl+C。默认监听 `0.0.0.0:3000`。启动时显示电脑网卡 IP 和对应 `BASE_URL`。

测试账号：`demo`，密码：`mock123456`。这是模拟账号，不是原平台账号。

## App 接入

1. 在模拟器浏览器打开 `http://电脑IP:3000/health`，应返回 `code: 200`。
2. 修改 `common/basic/src/main/ets/constants/url.ets`：

```typescript
export const BASE_URL = 'http://电脑IP:3000/driver'
```

3. 重新构建 App，退出原账号，使用模拟账号登录。业务接口和页面不用重新改写。

电脑 IP 需要从服务启动输出中选取模拟器能访问的网卡地址；不要直接给模拟器填写 `localhost`。
如果无法访问，检查模拟器路由和 Windows 防火墙对本地网络端口的放行。服务不会自动修改防火墙。
当前 App 的 BASE_URL 已设为 `http://192.168.124.3:3000/driver`，登录页预填模拟账号；原地址和账号在代码旁保留为注释。换电脑或网卡 IP 后，需要更新地址并重新构建。

## 已实现接口

| 方法 | 路径（前缀 `/driver`） | 行为 |
| --- | --- | --- |
| POST | `/login/account` | 返回测试 token |
| GET | `/users` | 模拟司机资料 |
| GET | `/users/truck` | 模拟车辆资料，包含载重、机构、车牌、车型和图片列表 |
| GET | `/messages/page` | 按 contentType（200公告、201任务通知）、page、pageSize 分页 |
| PUT | `/messages/{id}` | 单条消息标记已读，重复调用保留首次阅读时间 |
| PUT | `/messages/readAll/{contentType}` | 仅将指定分类消息标记已读 |
| GET | `/users/taskReport` | 按年月统计模拟任务；模拟里程为每个完成任务20公里 |
| GET | `/tasks/list` | 状态、运输任务编号、日期筛选和分页 |
| GET | `/tasks/details/{jobId}` | 司机作业单详情 |
| POST | `/files/imageUpload` | multipart `file` 图片，返回 HTTP 图片 URL |
| POST | `/tasks/takeDelivery` | 待提货1 → 在途2 |
| POST | `/tasks/deliver` | 在途2 → 已交付4 |
| POST | `/tasks/truckRegistration` | 已交付4 → 已完成6 |
| PUT | `/tasks/delay` | 保存延迟原因和时间 |
| POST | `/tasks/reportException` | 追加异常记录，处理结果为“待处理” |

除登录、health、图片读取外，需要 `Authorization` 为登录返回的 token。接受原始 token 或 Bearer token。
响应统一为 `{code, data, msg}`；上报异常成功时 code 为字符串 `"200"`，其他成功为数字200。
失败使用非200业务码，App 请求封装会处理。不存在的接口会明确返回404。

注意 ID：详情、提货、交付、延迟使用 `job-1` 这样的司机作业单 ID；异常上报和回车登记使用 `100001` 这样的运输任务 ID。

## 模拟数据与规则

全新数据库生成24条待提货任务，采用上海青浦→苏州昆山→无锡新吴→常州武进→杭州余杭→嘉兴南湖→上海青浦的区域线路，网点和人员为虚构业务样例。司机编号SJ310027、车辆编号SH-0072，车辆信息与任务一致；手机号保持为空，未填入任意真实号码。
计划从次日06:30开始，每天安排06:30、11:30、16:30三个时段，预计行程2—4小时，预留交接和休息间隔；实际出发/到达时间在完成操作前为空。
公告覆盖装车回单、雨雾行车、卸货预约、出车检查和异常填写；任务通知包含线路、计划时间及交接要求。司机头像复用项目已有`ic_avatar_driver.svg`。
已有数据库启动时完全保留，不再自动添加历史任务。运行数据可按演示需要追加或清理，列表以本地 `data/db.json` 的当前内容为准。
执行提货、交付和回车登记后，列表会随着实际操作重新产生在途、已完成任务；重启不会补回已清理的旧任务。
`clean-tasks.cjs`用于停止服务后清理非待提货数据、更新待提货展示信息，执行前自动备份；不要在服务运行时执行。
列表日期筛选暂按 `planDepartureTime` 日期实现，接口文档没有说明筛选对应哪个业务时间；这是模拟约定。
提货、交付要求两类图片均至少1张、最多6张，遵循现有页面校验。异常上报允许状态2、4，最多6张图片、描述最多200字。
这些状态限制是模拟规则，不能用于推断真实后端全部规则。地图定位、附近地点搜索仍使用原 Map Kit，不由本服务替代。

业务数据保存在 `data/db.json`，图片在 `data/uploads/`。这些运行数据被忽略，不提交 Git。

旧数据库首次启动新版服务时，保留原有任务和其他字段，仅在缺少消息数组时追加5条业务公告及现有任务的通知。已读状态持久保存，重启不重复生成消息；空消息数组也不会重新填充。任务通知的 `relevantId` 使用作业单 ID（如 `job-1`），与任务详情接口一致。消息按创建时间、ID倒序排列，pageSize 范围1—100。当前未模拟后续新增任务的实时消息推送，车辆图片列表为空。

更新现有业务样例：停止服务后运行 `node refresh-business-data.cjs`。脚本先备份数据库，再统一线路、网点、联系人及车辆，将待提货计划安排到近期，修正历史计划时间的前后关系。保留任务ID、状态、实际事件时间、回车登记、图片、异常记录和已有消息的阅读状态；追加缺少的业务公告。
更新采用临时文件写入再替换，失败不发布新状态。服务重启保留数据；不要同时启动多个进程共用一个 data 目录。
如需全新样例，停止服务后重命名 `data` 目录留作备份，再启动。
上传文件支持 PNG/JPEG/WebP，总 multipart 请求不超过12MB。头像素材来自项目已有资源。

如果电脑 IP 改变，已保存的图片 URL 仍指向旧 IP。保持访问地址稳定，或备份后重新生成模拟数据。
可选环境变量：`PORT` 更换端口，`MOCK_DATA_DIR` 更换数据目录，`MOCK_PUBLIC_URL` 固定图片访问地址（不含 `/driver`）。
本服务使用固定演示 token，不能部署成公网生产服务。

## 自动验证

```powershell
& 'E:\Program Files\DevEco Studio\tools\node\node.exe' --test server.test.cjs business-data.test.cjs
```

测试使用独立临时目录和随机端口，覆盖登录、查询、上传、异常、状态变化及重启持久化，不改变演示数据。
