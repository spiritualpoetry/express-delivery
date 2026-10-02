import { HmList } from '@hm/basic/Index'
import { getTaskList } from '../../../api'
import { TaskInfoItem, TaskInfoItemModel, TaskListParams, TaskListParamsModel, TaskTypeEnum } from '../../../models'
import TaskItemCard from './TaskItemCard'
import { promptAction } from '@kit.ArkUI'

// 待提货
@Component
struct TaskList {

  @State
  queryParams: TaskListParamsModel = new TaskListParamsModel(
    {
      status: TaskTypeEnum.Waiting, // 待提货的类型
      page: 1, // 第几页
      pageSize: 5 // 每页几条数据
    } as TaskListParams
  )
  @State
  taskListData: TaskInfoItem[] = []
  @State
  allPage: number = 1 // 默认只有一页

  async getTaskList(append: boolean) {
    const result = await getTaskList(this.queryParams)
    // 追加数据
    // this.taskListData = this.taskListData.concat(result.items) // 拿到返回的数组
    if (append) {
      this.taskListData.push(...result.items) // 延展运算符的写法
    } else {
      this.taskListData = result.items // 直接赋值
    }

    this.allPage = result.pages // 总页数
    this.queryParams.page++ // 下次请求的页码
  }

  @Builder
  renderItem(item: object) {
    TaskItemCard({ taskItemData: item as TaskInfoItemModel })
  }

  // 下拉刷新函数
  async onRefresh() {
    // 重新请求第一页数据
    this.queryParams.page = 1 // 重置第一页
    await this.getTaskList(false) // 直接赋值
  }

  build() {
    HmList({
      dataSource: this.taskListData, // 数据源
      finished: this.allPage < this.queryParams.page, // 是否还有下一页
      // 上拉加载的函数
      onLoad: async () => {
        // 上拉加载
        await this.getTaskList(true) // 追加逻辑
      },
      onRefresh: async () => {
        // 下拉刷新
        await this.onRefresh()
      },
      renderItem: (item: object) => {
        // 如果需要的是builderParams的参数 可以用普通函数包裹一个Builder的函数
        this.renderItem(item)
      },
      loadingText: '拼命加载中',
      finishText: '没啦没啦'
    })
      .height("100%")
  }
}

export default TaskList