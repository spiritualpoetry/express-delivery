# 接口核对清单

所有接口以完整路径和HTTP方法区分，不只根据页面菜单名称判断。

| 文档名称 | 方法与路径 | 文档状态 | 关键区分 |
| --- | --- | --- | --- |
| 账号登录 | POST /driver/login/account | 已收到 | account/password；App从data读取token，文档msg描述也提到token，模拟响应两处均提供 |
| 图片上传 | POST /driver/files/imageUpload | 已收到 | multipart的file；data为图片URL |
| 任务列表 | GET /driver/tasks/list | 已收到 | status=2包含在途和已交付；startTime/endTime日期格式yyyy-MM-dd；编号transportTaskId |
| 任务详情 | GET /driver/tasks/details/{jobId} | 已收到 | 路径为司机作业单ID；详情status为数字，列表status为字符串 |
| 提货 | POST /driver/tasks/takeDelivery | 已收到 | id为司机作业单ID；cargoPickUpPictureList/cargoPictureList |
| 交付 | POST /driver/tasks/deliver | 已收到 | id为司机作业单ID；certificatePictureList/deliverPictureList |
| 延迟提货 | PUT /driver/tasks/delay | 已收到 | id为司机作业单ID；delayTime精确到分钟 |
| 回车登记 | POST /driver/tasks/truckRegistration | 已收到 | id为运输任务ID；startTime/endTime精确到秒 |
| 上报异常 | POST /driver/tasks/reportException | 已收到 | transportTaskId为运输任务ID；exceptionType传9种独立中文类型；成功code字符串200 |
| 用户信息 | GET /driver/users | 已收到 | avatar/name/number/phone |
| 任务数据 | GET /driver/users/taskReport | 已收到 | year/month；completedAmounts/dailyMileage/taskAmounts/transportMileage |

目前无需补充文档即可模拟已有api目录中的全部请求。
待后续功能需要时再索要：验证码、注册账号并生成任务、文件上传、根据图片名称获取URL、消息四个接口、联系调度中心、条件查询货物信息列表、车辆信息、车辆上报位置。

需要核实但不阻碍本地模拟的细节：任务列表日期对应哪个业务时间、真实后端状态转换限制、图片数组允许的数量、任务数据的实际完成时间口径。
模拟规则和样例写在README，不将推测当成原接口保证。
