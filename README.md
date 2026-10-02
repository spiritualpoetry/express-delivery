# 小时达司机端

使用 ArkTS 和 ArkUI 开发的 HarmonyOS 司机端应用。当前包含登录、任务列表、任务详情、照片选择与预览、照片上传、提货和交货流程。

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

## 分支约定

| 分支 | 用途 |
| --- | --- |
| `master` | 已确认版本的代码基线，默认分支 |
| `develop` | 日常开发和集成 |
| `feature/<功能名>` | 从 `develop` 创建的独立功能分支，例如 `feature/delivery-validation` |
| `t't'y` | 保留的旧开发分支，用于查阅历史 |

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

历史提交和旧分支在此次整理中保留。发布新版本时，可在完成业务验证后添加版本标签。
