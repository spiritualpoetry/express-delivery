import { HmList } from '@hm/basic/Index'
import { getTaskList } from '../../../api'
import { TaskInfoItem, TaskInfoItemModel, TaskListParams, TaskListParamsModel, TaskTypeEnum } from '../../../models'
import TaskItemCard from './TaskItemCard'
import { promptAction } from '@kit.ArkUI'

// 待提货
@Component
struct TaskList {
  @Prop @Watch('refreshWhenVisible') active: boolean = true
  @Prop @Watch('refreshWhenVisible') refreshVersion: number = 0
  private refreshPending: boolean = false

  aboutToAppear(): void {
    this.refreshWhenVisible()
  }

  refreshWhenVisible() {
    if (!this.active) { return }
    if (this.requesting) {
      this.refreshPending = true // 等当前请求结束后补一次刷新，避免遗漏返回页面的更新。
      return
    }
    this.refreshPending = false
    this.onRefresh()
  }
  @State
  reset: boolean = false // 是否已经应用筛选条件
  @State
  queryParams: TaskListParamsModel = new TaskListParamsModel(
    {
      status: TaskTypeEnum.Waiting, // 待提货的类型
      page: 1, // 第几页
      pageSize: 5, // 每页几条数据
      startTime: null,
      endTime: null,
      transportTaskId: null
    }
  )
  @State
  taskListData: TaskInfoItem[] = []
  @State
  allPage: number = 1 // 默认只有一页
  @State requesting: boolean = false
  @State taskNumber: string = ''
  @State startDate: string = ''
  @State endDate: string = ''

  async getTaskList(append: boolean): Promise<boolean> {
    if (this.requesting) {
      return false
    }
    this.requesting = true
    try {
      const result = await getTaskList(this.queryParams)
      if (append) {
        this.taskListData.push(...(result.items || []))
      } else {
        this.taskListData = result.items || []
      }
      this.allPage = result.pages // 总页数
      this.queryParams.page++ // 下次请求的页码
      return true
    } catch (error) {
      // 请求层提示失败；不推进页码，允许重试。
      return false
    } finally {
      this.requesting = false
      if (this.refreshPending && this.active) {
        // 让当前刷新完成页码恢复，再开始下一次刷新。
        setTimeout(() => { this.refreshWhenVisible() }, 0)
      }
    }
  }

  @Builder
  renderItem(item: object) {
    TaskItemCard({ taskItemData: item as TaskInfoItemModel })
  }

  // 下拉刷新函数
  async onRefresh() {
    if (this.requesting) {
      return
    }
    // 重新请求第一页数据
    const previousPage = this.queryParams.page
    this.queryParams.page = 1 // 重置第一页
    if (!await this.getTaskList(false)) {
      this.queryParams.page = previousPage // 刷新失败时保留原分页，避免重复追加第一页。
    }
  }

  // 控制筛选按钮可点
  getSearchEnable() {
    return !!this.taskNumber.trim() || !!(this.startDate && this.endDate)
  }

  selectDate(start: boolean) {
    const selectedDate = start ? this.startDate : this.endDate
    DatePickerDialog.show({
      selected: selectedDate ? new Date(selectedDate + 'T00:00:00') : new Date(),
      onDateAccept: (value: Date) => {
        const date = `${value.getFullYear()}-${String(value.getMonth() + 1).padStart(2, '0')}-${String(value.getDate())
          .padStart(2, '0')}`
        if (start) {
          this.startDate = date
        } else {
          this.endDate = date
        }
      }
    })
  }

  async applyFilter(resetFilters: boolean = false) {
    if (this.requesting) {
      return
    }
    if (resetFilters) {
      this.taskNumber = ''
      this.startDate = ''
      this.endDate = ''
    } else {
      if (!this.getSearchEnable()) { return }
      if (!this.taskNumber.trim() && this.startDate > this.endDate) {
        promptAction.showToast({ message: '开始时间不能晚于结束时间' })
        return
      }
    }
    const taskNumber = this.taskNumber.trim()
    if (taskNumber) {
      // 保留原来的编号优先规则，并同时清除实际请求中的日期条件。
      this.startDate = ''
      this.endDate = ''
    }
    this.queryParams.transportTaskId = taskNumber || null
    this.queryParams.startTime = this.startDate || null
    this.queryParams.endTime = this.endDate || null
    this.reset = !resetFilters
    this.taskListData = [] // 新条件不能继续追加到旧条件的结果。
    this.queryParams.page = 1
    this.allPage = 1
    await this.onRefresh()
  }

  @Builder
  getSearchForm() {
    Column() {
      Row() {
        Search({ value: this.taskNumber, placeholder: '请输入任务编号' })
          .backgroundColor($r('app.color.background_page')).height(32)
          .onChange((value: string) => {
            this.taskNumber = value
          })
          .onSubmit(() => {
            this.applyFilter()
          })
      }
      .justifyContent(FlexAlign.Center)
      .padding({ left: 15, right: 15, bottom: 5 })

      Row() {
        // 完成搜索页需要测试点击之后键盘和弹层同时弹出的情况
        Button(this.startDate || '开始时间')
          .fontSize(14)
          .width(106)
          .height(32)
          .padding({ left: 0, right: 0 })
          .fontColor('#999')
          .backgroundColor($r('app.color.background_page'))
          .onClick(() => {
            this.selectDate(true)
          })

        Text("至")
        Button(this.endDate || '结束时间')
          .fontSize(14)
          .width(110)
          .height(32)
          .padding({ left: 0, right: 0 })
          .fontColor('#999')
          .backgroundColor($r('app.color.background_page'))
          .onClick(() => {
            this.selectDate(false)
          })
        Button(this.reset? "重置":"筛选")
          .backgroundColor($r('app.color.primary'))
          .height(32)
          .width(60)
          .enabled(!this.requesting && (this.reset || this.getSearchEnable()))
          .onClick(() => {
            this.applyFilter(this.reset)
          })
      }.width('100%').alignItems(VerticalAlign.Center).justifyContent(FlexAlign.SpaceAround)
    }
    .backgroundColor($r('app.color.white'))
    .padding(15)
    .justifyContent(FlexAlign.Center)
    .width('100%')
  }

  build() {
    Column() {
      //是否显示搜索的条件
      if (this.queryParams.status === TaskTypeEnum.Finish) {
        //显示搜索条件
        this.getSearchForm()
      }
      HmList({
        dataSource: this.taskListData, // 数据源
        finished: this.allPage < this.queryParams.page, // 是否还有下一页
        // 上拉加载的函数
        onLoad: async () => {
          // 上拉加载
          await this.getTaskList(true) // 追加下一页，保留已有任务。
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
        .layoutWeight(1)
    }.height('100%')
  }
}

export default TaskList
