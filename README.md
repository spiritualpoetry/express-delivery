# 小时达司机端

使用 ArkTS 和 ArkUI 开发的 HarmonyOS 司机端应用。当前包含登录、任务列表、任务详情、照片选择与预览、照片上传、提货和交货流程。

异常上报页面支持选择时间、附近地点、异常类型、填写最多 200 字描述和选择最多 6 张图片；提交前校验必填项，先上传图片再调用 `POST /driver/tasks/reportException`，失败时保留填写内容。定位权限在进入地点选择页面时申请，定位及搜索失败会显示提示。

异常类型按接口说明拆为 9 个独立选项：发动机启动困难、不着车、漏油、漏水、照明失灵、有异响、排烟异常、温度异常、其他。选择列表支持滚动。

## 项目结构

| 目录 | 内容 |
| --- | --- |
| `AppScope` | 应用名称、图标等应用级配置和资源 |
| `entry/src/main/ets/pages` | 页面 |
| `entry/src/main/ets/api` | 任务、用户等业务接口 |
| `entry/src/main/ets/models` | 业务数据类型和模型 |
| `common/basic` | 公共组件、网络请求和工具 |

## 开发与验证

使用 DevEco Studio 打开项目，同步依赖后构建 `entry` 模块。当前项目配置使用 HarmonyOS 6.0.2（API 22）。运行到设备前，需要配置本机的签名信息；本机配置和构建产物由 `.gitignore` 排除。

2026-10-02 的代码基线已通过 `entry` 模块 debug HAP 构建。构建存在接口弃用及异常处理警告；登录、任务列表、图片上传、提货和交货仍需在模拟器或真机上验证。编译通过不代表所有业务流程都已验证。

2026-10-05 的异常上报及定位修复通过 `entry` debug HAP 构建和签名。审查覆盖必填字段、图片上传结果、异常处理和页面退出后的异步回调；未自动提交真实异常记录，定位、图片上传与异常类型仍需真机联调。根目录 `build-profile.json5` 中本机签名密码及证书路径不纳入此次提交。

## 分支约定

| 分支 | 用途 |
| --- | --- |
| `master` | 已确认版本的代码基线，默认分支 |
| `develop` | 日常开发和集成 |
| `feature/<功能名>` | 从 `develop` 创建的独立功能分支，例如 `feature/delivery-validation` |

日常修改在 `develop` 或功能分支完成。提交时使用能说明变化的标题，例如 `fix: close loading dialog after upload failure`。完成功能验证后，再把 `develop` 合并到 `master`。

```shell
git switch develop
# 修改、构建并验证代码
git add <修改的文件>
git commit -m "fix: describe the change"
git push

# 验证完成后更新 master
git switch master
git merge develop
git push
git switch develop
```

旧开发分支 `t't'y` 的全部提交已合入 `master` 和 `develop`，该分支已删除，提交历史仍然保留。发布新版本时，可在完成业务验证后添加版本标签。
