# 食刻选择（WhatToEatToday）

一个用于解决“今天吃什么”的 HarmonyOS/ArkUI 应用：支持登录/注册、多用户数据隔离、菜品库管理、智能推荐、历史记录与统计分析。

> 工程目录名：`WhatToEatToday`  
> 应用名称：**食刻选择**


## 功能特性

- **登录/注册**
  - 用户注册、登录校验与提示
  - 记录当前登录用户，支持多用户切换后的数据隔离

- **全局状态管理**
  - 通过 **AppStorage/Store** 管理全局数据与页面联动

- **智能推荐**
  - 按餐别推荐（早餐/午餐/下午茶/晚餐/夜宵）
  - 基础过滤：餐别匹配、启用状态、屏蔽标签
  - 近期不重复：按设置的天数过滤近期吃过的菜品
  - 偏好加权：根据“喜欢”历史做相似度加权
  - 节日加权：节日菜品优先（如项目内节日工具/映射存在）

- **菜品库管理**
  - 搜索、餐别筛选
  - 启用/禁用菜品
  - 新增菜品（Sheet 表单）

- **历史记录**
  - 按日期分组展示
  - 支持筛选/回看吃过的内容

- **统计分析**
  - 常吃 TOP、餐别分布等统计视图（以项目内实现为准）

- **数据持久化**
  - 基于 Preferences 存储（foods/history/settings/users/login 等）
  - 以用户维度隔离数据（形如 `WhatToEatData_${username}`）



## 项目结构


- `entry/src/main/ets/pages/`
  - `Index.ets`：入口/导航/初始化
  - `LoginPage.ets`：登录与注册
  - `TodayRecommendPage.ets`：推荐页
  - `FoodListPage.ets`：菜品管理
  - `HistoryPage.ets`：历史记录
  - `StatsPage.ets`：统计分析
  - `SettingsPage.ets`：设置
- `entry/src/main/ets/store/`
  - `FoodStore.ts`：菜品、历史、设置、推荐算法
  - `UserManager.ts`：用户注册/登录/登录态
- `entry/src/main/ets/common/`
  - 常量、工具函数（日期/节日/格式化等，依项目实际文件）



## 推荐算法流程（概览）

1. 读取 `foods/settings/history`
2. 构建候选集：餐别匹配 + 启用 + 不命中屏蔽标签
3. 依据 `noRepeatDays` 过滤近期吃过的菜
4. 分析偏好（likes 等）得到权重/相似度
5. 叠加节日加权（若当日命中节日推荐集合）
6. 加权随机抽样得到推荐结果并写入 `currentSuggestion`



## 环境要求

- Windows + **DevEco Studio 5.x**
- HarmonyOS SDK（与工程配置匹配）
- Python（可选：用于生成流程图脚本，如 `diagrams/*.py`）



## 运行方式（DevEco Studio）

1. 用 DevEco Studio 打开项目根目录 `WhatToEatToday`
2. 等待依赖与索引完成
3. 选择运行设备（模拟器或真机）
4. 点击 **Run** 启动应用




## 流程图

项目可配合 Graphviz 生成数据流/登录/推荐算法流程图：

- 依赖：
  - `pip install graphviz`
  - 安装 Graphviz 并确保 `dot` 在 PATH

生成示例：

```bat
python draw_dataflow_diagram.py
python draw_login_flow.py
python draw_recommend_flow.py
```

输出在 `diagrams/`。



